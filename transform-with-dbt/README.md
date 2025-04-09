## Needed secrets in .env or secrets.env to run:

DBT_USER=#YOUR_NAME
DBT_ENV_SECRET_DATABRICKS_TOKEN=#YOUR_TOKEN

## Quick Start

A helper file to set all the env variables (everything in deployment.env + your secrets):
- In Linux and Mac : . ./set_env.sh
- (Or in Windows : set_env.bat)

You'll find both files in the repo's root folder.

### Some dbt commands

uv run dbt deps
uv run dbt debug
uv run dbt seed
uv run dbt run


uv run dbt run -s "tag:gold"