# Template for Extract Load, Transform, Visualize
This repo contains all the tools needed to:
- Extract, Load Data into a Databricks Lakehouse
- Transform the Data in the Lakehouse with dbt
- Visualize the Data in the Lakehouse with evidence

Its goal: to Demo the operation of a lean Modern Data Platform.

A big inspiration for this repo has been the original [gwenwindflower's](https://github.com/gwenwindflower) [octocatalog](https://github.com/gwenwindflower/octocatalog) repo: an open-source, open-data data-platform-in-a-box[^1] based on [DuckDB](https://duckdb.org/) + [dbt](https://www.getdbt.com/) + [Evidence](https://evidence.dev/).

# Needed envs vars and secrets:
In `.env`:
- `DBT_USER` (used 'developerX' to initialize, but can be anything)
- `DBT_ENV_SECRET_DATABRICKS_TOKEN`
- `DBT_ENV_AZURE_DATALAKE_STORAGE_ACCOUNT`, `DBT_ENV_DATABRICKS_CLUSTER_COMPUTE_HTTP_PATH`, `DBT_ENV_SECRET_AZURE_TENANT_ID`
- `DBT_ENV_SECRET_DATABRICKS_CLIENT_ID`, `DBT_ENV_SECRET_DATABRICKS_CLIENT_NAME`
- `DBT_ENV_SECRET_DATABRICKS_CLUSTER_ID`, `DBT_ENV_SECRET_DATABRICKS_HOST`, `DBT_ENV_SECRET_DATABRICKS_SQL_WAREHOUSE_HTTP_PATH`
- `AZURE_STORAGE_ACCOUNT_URL`, `AZURE_STORAGE_CONTAINER_NAME`

In `create-reports-with-evidence/.env`:
- `EVIDENCE_SOURCE__databricks__token`

In `create-reports-with-evidence/sources/databricks/connection.yaml`:
```yml
# This file was automatically generated
name: databricks
type: databricks
options:
  host: adb-XXXXXXXXXXXXXX.X.azuredatabricks.net
  path: /sql/1.0/warehouses/XXXXXXXXXXXX
```

## Quickstart
1. Install [uv](https://docs.astral.sh/uv/getting-started/installation/) ; Install the [azure-cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) ; Install [nvm](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating)
2. (Or just launch a _Github Codespace_ in github.com from this repo; or a _Dev container_ from this repo on your local VS Code: everything will be pre-installed for you.)
3. Run `az login`, authenticate in Azure
4. Run `. ./set_env.sh` to set the necessary env vars and secrets
5. Go to the `extract-and-load-with-python` folder and run `uv run python el.py -e`
6. Go to the `extract-and-load-with-python` folder and run `uv run python el.py -l`
7. Go to the `transform-with-dbt` folder and run  `uv run dbt deps`
8. Go to the `transform-with-dbt` folder and run  `uv run dbt seed`
9. Go to the `transform-with-dbt` folder and run  `uv run dbt build`
10. Go to the `create-reports-with-evidence` folder and run  `npm install && npm run sources && npm run dev -- --host 0.0.0.0`

_Or in two commmands: First login to azure with `az login`, then run `. ./set_env.sh && cd extract-and-load-with-python && uv run python el.py -elp && cd .. && cd transform-with-dbt && uv run dbt deps && uv run dbt seed && uv run dbt run && cd .. && cd create-reports-with-evidence && nvm use 22 && npm install && npm run sources && npm run dev -- --host 0.0.0.0`_

## Project Structure
Each part of the project has a dedicated folder:
1. The **extract-and-load-with-python** folder
    - You need to be inside this folder to run the _Extract and Load_ script (_el.py_) that will get public GitHub data into the Azure/Databricks Cloud Lakehouse (default mode), or the local DuckDB Data Warehouse (local mode)
2. The **local-data-landing-zone** folder will be used for temporarily storing the raw GitHub data, before loading it into the Local DuckDB Data Warehouse or the Azure/Databricks Cloud Lakehouse
    - If using the Local DuckDB Data Warehouse, the **store-and-compute-with-duckdb** folder is where the Local DuckDB Data Warehouse will be stored (_duckdb_data_store.db_)
4. The **transform-with-dbt** folder
    - Contains the dbt project
    - It is from inside this folder that you need to run all dbt commands (for ex. `dbt run`, `dbt debug`, ...)
5. The **create-reports-with-evidence** folder
    - Contains the [Evidence](https://evidence.dev/) project
    - From inside this folder you can run the commands to launch the Evidence BI dashboards



## Setup

There are a few steps to get started with this project if you want to develop locally. We'll need to:

1. [Clone the project locally](#clone-the-project-github-codespaces-or-local-dev-container).
    - Or develop on GitHub Codespaces
3. [Python: Install uv](#python).
4. [Extract and load the data locally](#extract-and-load).
5. [Transform the data with dbt](#transform-the-data-with-dbt).
6. [Build the BI platform with Evidence](#build-the-bi-platform-with-evidence).


### Clone the project: Github Codespaces or local Dev Container
The easiest is to start developing immediatly on a GitHub Codespace:

<img width="1131" alt="image" src="https://github.com/user-attachments/assets/e5918c22-6d56-4026-b936-f40aab56a207" />

Or you can install [VS Code](https://code.visualstudio.com/), [Docker Desktop](https://www.docker.com/products/docker-desktop/) and the [Dev Contaniners](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for VS Code in your local computer.

Then open VS Code, then Cmd+Shift+P (in mac) or Ctrl+Shift+P (in windows) and run _'Dev Containers: Clone Repository in Container Volume...'_

<img width="601" alt="image" src="https://github.com/user-attachments/assets/a8979a55-4d48-41d4-a5e2-3786a184d917" />

<img width="622" alt="image" src="https://github.com/user-attachments/assets/73b95504-ddf9-4da1-ae75-07efc7d01c48" />




### Python

You'll need to install uv in your local computer: https://docs.astral.sh/uv/getting-started/installation/
- uv will come pre-installed if using the Dev Container or GitHub Codespace

## Extract and Load
> extract-and-load-with-python

Extract and Load is the process of taking data from one source, like an API, and loading it into another source, typically a data warehouse. In our case our source is the GitHub Archive, and our load targets is either an Azure Storage Container (default mode), or a local DuckDB database (local mode).

### Local usage
> extract-and-load-with-python/el.py

If you run the script directly, it takes two arguments: a start and end datetime string, both formatted as `'YYYY-MM-DD-HH'`. It is inclusive of both, so for example running `uv run python el.py '2023-09-01-01' '2023-09-01-02'` will load _two_ hours: 1am and 2am on September 9th 2023. Pass the same argument for both to pull just that hour.
Please note that the GitHub Archive is available from 2011-02-12 to the present day and that being event data it is very large. Running more than a few days or weeks will push the limits of DuckDB (that's part of the interest and goal of this project though so have at).

> [!NOTE]
> **Careful of data size**. DuckDB is an in-process database engine, which means it runs primarily in memory. This is great for speed and ease of use, but it also means that it's (somewhat) limited by the amount of memory on your machine. The GitHub Archive data is event data that stretches back years, so is very large, and you'll likely run into memory issues if you try to load more than a few days of data at a time. We recommend using a single hour locally when developing. When you want to go bigger for production use you'll probably want to leverage the option below.

### Running the EL script

You can manually run the `el.py` script with `uv run python el.py [args]` to pull a custom date range, run on small test data file, and isolate the extract or load steps. P

The args are:

```shell
python el.py [start_date in YYYY-MM-DD format, defaults to yesterday] [end_date in YYYY-MM-DD format, defaults to today] [-e --extract Run the extract part only] [-l --load Run the load part only] [-p --prod Run in production mode against MotherDuck]
```

Running the the `el.py` script without an `-e` or `-l` flag is a no-op as all flags default to `false`. Combine the flags to create the commands you want to run. For example:

```shell
uv run python el.py -e # extract the data for the past day
uv run python el.py -lp # load any data into the production database
uv run python el.py 2023-09-20 2023-09-23 -elp # extract and load 3 days of data into the production database
```

## Local mode: Store the extracted data in local duckDB
> store-and-compute-with-duckdb

You can choose to store the data in your Azure/Databricks Lakehouse (default mode), or to store the data locally in a DuckDB Local Warehouse.
- When working with a DuckDB Local Warehouse: In order for Evidence to work, the DuckDB Local Warehouse needs to be built into the `store-and-compute-with-duckdb/` directory. If you're looking to access it via the DuckDB CLI you can find it at `store-and-compute-with-duckdb/duckdb_data_store.db`.

## Transform the data with dbt
> transform-with-dbt

dbt is the industry-standard control plane for data transformations. We use it to get our data in the shape we want for analysis.

Some fundamental dbt commands (launched using [_uv_](https://github.com/astral-sh/uv)):
```shell
uv run dbt deps # install the dependencies
uv run dbt seed # to load into duckDB the jaffle-shop data stored in the seeds folder
uv run dbt build # build and test the models
uv run dbt run # just build the models
uv run dbt test # just test the models
uv run dbt run -s marts # just build the models int the marts folder
```

(To delete the schemas written:)
```sh
. ./set_env.sh && cd transform-with-dbt
uv run dbt run-operation delete_all_data_in_databricks --args '{"dry_run": false}'
```

## Build the BI platform with Evidence
> create-reports-with-evidence

Evidence is an open-source, code-first BI platform. It integrates beautifully with dbt and DuckDB (or dbt and Databricks), and lets analysts author version-controlled, literate data products with Markdown and SQL. 
To install an run the Evidence server:
```shell
cd create-reports-with-evidence
npm install # install the dependencies
npm run sources # build fresh data from the sources
npm run dev # run the development server
```

### Developing pages for Evidence

Evidence uses Markdown and SQL to create beautiful data products. It's powerful and simple, focusing on what matters: the _information_. You can add and edit markdown pages in the `create-reports-with-evidence/pages/` directory, and SQL queries those pages can reference in the `create-reports-with-evidence/queries/` directory. You can also put queries inline in the Markdown files inside of code fences, although stylistically this project prefers queries go in SQL files in the `queries` directory for reusability and clarity. Because Evidence uses a WASM DuckDB implementation to make pages dynamic, you can even chain queries together, referencing other queries as the input to your new query. We recommend you utilize this to keep queries tight and super readable. CTEs in the BI section's queries are a sign that you might want to chunk your query up into a chain for flexibility and clarity. Sources point to tables in your local DuckDB database file. To add new sources/tables you add a `select * [model]` query to the `create-reports-with-evidence/sources/` directory and re-run `npm run sources` and you're good to go.

Evidence's dev server uses hot reloading, so you can see your changes in real time as you develop. It's a really neat tool, and I'm excited to see what you build with it.

---

## Modeling the GitHub Archive event data

Schemas for the event data [are documented here](https://docs.github.com/en/rest/overview/github-event-types?apiVersion=2022-11-28).

So far we've modeled:

- [x] Issues
- [x] Pull Requests
- [x] Users
- [x] Repos
- [ ] Stars
- [ ] Forks
- [ ] Comments
- [ ] Pushes

[^1]: Based on the patterns developed by Jacob Matson for the original [MDS-in-a-box](https://duckdb.org/2022/10/12/modern-data-stack-in-a-box.html).
