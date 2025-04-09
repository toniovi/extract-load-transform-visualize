import argparse
import os
from datetime import datetime, timedelta

import duckdb
import requests
from halo import Halo
from tqdm import tqdm

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv

import gzip
import shutil

# Load environment variables from .env file
load_dotenv()

# Ensure the script is run from the directory where it is saved
script_dir = os.path.dirname(os.path.abspath(__file__))
current_dir = os.getcwd()

if script_dir != current_dir:
    raise RuntimeError(f"Script must be run from its directory: {script_dir}")

columns = """
            columns={
                'id': 'VARCHAR',
                'type': 'VARCHAR',
                'actor': 'STRUCT(
                    id VARCHAR,
                    login VARCHAR,
                    display_login VARCHAR,
                    gravatar_id VARCHAR,
                    url VARCHAR,
                    avatar_url VARCHAR
                )',
                'repo': 'STRUCT(id VARCHAR, name VARCHAR, url VARCHAR)',
                'payload': 'JSON',
                'public': 'BOOLEAN',
                'created_at': 'TIMESTAMP',
                'org': 'STRUCT(
                    id VARCHAR,
                    login VARCHAR,
                    gravatar_id VARCHAR,
                    url VARCHAR,
                    avatar_url VARCHAR
                )'
            }
        """


def validate_date(datetime_str):
    try:
        input_datetime = datetime.strptime(datetime_str, "%Y-%m-%d-%H")
        current_datetime = datetime.utcnow()
        if input_datetime < datetime(2015, 1, 1) or input_datetime > current_datetime:
            raise argparse.ArgumentTypeError(
                f"Datetime {datetime_str} is outside the acceptable range."
            )
        return input_datetime
    except ValueError:
        raise argparse.ArgumentTypeError(
            f"Invalid datetime format: {datetime_str}. \
            Please use the format YYYY-MM-DD-HH."
        )


def download_data(active_datetime):
    url_datetime = datetime.strftime(active_datetime, "%Y-%m-%d-%-H")
    url = f"https://data.gharchive.org/{url_datetime}.json.gz"

    file_path = f"../local-data-landing-zone/{url_datetime}.json.gz"

    if not os.path.exists(file_path):
        response = requests.get(url, stream=True)
        total_size_in_bytes = int(response.headers.get("content-length", 0))
        progress_bar = tqdm(
            total=total_size_in_bytes,
            unit="kB",
            unit_scale=True,
            leave=False,
            desc=f"💾 Downloading data from Github Archive for {active_datetime}...",
        )

        if response.status_code == 200:
            with open(file_path, "wb") as output_file:
                for chunk in response.iter_content(chunk_size=1024):
                    output_file.write(chunk)
                    progress_bar.update(len(chunk))
            progress_bar.close()
        else:
            print(
                f"Error: {url_datetime} returned status code {response.status_code}."
            )
    else:
        print(f"Skip: {url_datetime} already exists. Skipping download.")


def extract_data(start_datetime, end_datetime):
    total_hours = int((end_datetime - start_datetime).total_seconds() / 3600)
    progress_bar = tqdm(total=total_hours)

    active_datetime = start_datetime

    while active_datetime <= end_datetime:
        download_data(active_datetime)
        if args.incremental and args.load:
            load_data(incremental=True)
            os.remove(
                f"data/{datetime.strftime(active_datetime, '%Y-%m-%d-%-H')}.json.gz"
            )
        active_datetime += timedelta(hours=1)
        progress_bar.update(1)

    progress_bar.close()


def load_data(incremental=False):
    if args.check:
        data_path = "../local-data-landing-zone/testing.json"
    else:
        data_path = "../local-data-landing-zone/*.json.gz"

    if args.prod:
        spinner_text = "🦆☁️  Loading data into MotherDuck..."
        connection = "md:octocatalog"
    else:
        spinner_text = "🦆💾 Loading data into DuckDB..."
        connection = "../store-and-compute-with-duckdb/duckdb_data_store.db"

    if incremental:
        table_create = "create table if not exists raw.github_events as "
    else:
        table_create = "create or replace table raw.github_events as "

    spinner = Halo(text=spinner_text, spinner="dots")
    spinner.start()

    con = duckdb.connect(database=connection, read_only=False)
    con.execute(
        "create schema if not exists raw;"
        + table_create
        + "select * from read_ndjson("
        + "'"
        + data_path
        + "'"
        + ","
        + columns
        + ");"
    )
    con.close()

    if args.prod:
        spinner.succeed("🦆☁️ Loading data into MotherDuck... Done!")
    else:
        spinner.succeed("🦆💾 Loading data into DuckDB... Done!")


def load_data_to_lakehouse(limit_rows=None):
    account_url = os.getenv('AZURE_STORAGE_ACCOUNT_URL')
    container_name = os.getenv('AZURE_STORAGE_CONTAINER_NAME')
    
    if not account_url or not container_name:
        raise RuntimeError("Azure Storage account URL or container name not set in environment variables.")
    
    credential = DefaultAzureCredential()
    blob_service_client = BlobServiceClient(account_url, credential=credential)
    container_client = blob_service_client.get_container_client(container_name)
    
    data_path = "../local-data-landing-zone/"
    for root, dirs, files in os.walk(data_path):
        for file in files:
            file_path = os.path.join(root, file)
            if file.endswith(".gz"):
                unzipped_file_path = file_path[:-3]
                with gzip.open(file_path, 'rb') as f_in:
                    with open(unzipped_file_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                
                if limit_rows:
                    with open(unzipped_file_path, 'r') as f_in:
                        lines = f_in.readlines()[:limit_rows]
                    with open(unzipped_file_path, 'w') as f_out:
                        f_out.writelines(lines)
                
                file_path = unzipped_file_path
                blob_client = container_client.get_blob_client(f"data.gharchive.org/{os.path.basename(file_path)}")
                with open(file_path, "rb") as data:
                    blob_client.upload_blob(data, overwrite=True)
                print(f"Uploaded {os.path.basename(file_path)} to Azure Storage at: {account_url}{container_name}/data.gharchive.org/")
                os.remove(file_path)  # Delete the uncompressed file after uploading


parser = argparse.ArgumentParser()
parser.add_argument(
    "start_datetime",
    help="The start date of the range",
    default=datetime.strftime(datetime.utcnow() - timedelta(days=1), "%Y-%m-%d-%H"),
    nargs="?",
    type=validate_date,
)
parser.add_argument(
    "end_datetime",
    help="The end date of the range (inclusive)",
    default=datetime.strftime(datetime.utcnow() - timedelta(days=1), "%Y-%m-%d-%H"),
    nargs="?",
    type=validate_date,
)
parser.add_argument(
    "-e",
    "--extract",
    help="Just pull data from the GitHub Archive don't load it into DuckDB",
    default=False,
    action="store_true",
)
parser.add_argument(
    "-l",
    "--load",
    help="Load data already existing from the data directory into DuckDB",
    default=False,
    action="store_true",
)
parser.add_argument(
    "-p",
    "--prod",
    help="Run in production mode connected to MotherDuck",
    default=False,
    action="store_true",
)
parser.add_argument(
    "-i",
    "--incremental",
    help="Run in incremental load mode, only works with a production target",
    default=False,
    action="store_true",
)
parser.add_argument(
    "-c",
    "--check",
    help="Run in CI mode using data in data-test directory",
    default=False,
    action="store_true",
)
args = parser.parse_args()

if args.extract:
    extract_data(args.start_datetime, args.end_datetime)

if args.load and not args.incremental and not args.extract:
    load_data()

if args.load and args.prod:
    load_data_to_lakehouse(limit_rows=10000)