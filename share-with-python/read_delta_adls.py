import os
import duckdb
import pandas as pd

storage_account_name = os.environ["DBT_ENV_AZURE_DATALAKE_STORAGE_ACCOUNT"]

duckdb.sql(f"""
    CREATE SECRET (
        TYPE azure,
        PROVIDER credential_chain,
        CHAIN 'cli;env',
        ACCOUNT_NAME '{storage_account_name}'
    );
""")

# Query the data into a pandas DataFrame
df = duckdb.sql("""
SELECT *
FROM delta_scan('az://published-dev/dbt_antonio/publlished_zone_github_data_users')
""").df()

# Export to Excel
df.to_excel("github_data_users.xlsx", index=False)

