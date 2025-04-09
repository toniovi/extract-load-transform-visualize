## Needed variables in .env file:
AZURE_STORAGE_ACCOUNT_URL, AZURE_STORAGE_CONTAINER_NAME

## Quick Start

--- For Databricks Lakehouse in Azure

Login to azure : 
    az login

Run :
    uv run python el.py -elp

    from this directory,

    to Extract public data from Github into the local local-data-landing-zone folder,
    and Load it into the Azure Storage Landing zone

Run :
    uv run python el.py -lp

    from this directory,

    to take data Already Extracted already present in the local local-data-landing-zone,
    and Load it into the Azure Storage Landing zone


——— For Local Lakehouse
Run :
    uv run python el.py -el

    from this directory,

    to Extract public data from Github into the local local-data-landing-zone folder,
    and Load it into the local duckDB

Run :
    uv run python el.py -l

    from this directory,

    to take data Already Extracted already present in the local local-data-landing-zone,
    and Load it into the local duckDB
