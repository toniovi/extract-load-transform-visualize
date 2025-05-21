import duckdb

duckdb.sql(f"""
    CREATE SECRET (
        TYPE azure,
        PROVIDER credential_chain,
        CHAIN 'cli;env'
    );
""")

# Query the data into a pandas DataFrame
df = duckdb.sql("""
SELECT *
FROM delta_scan('abfss://gold-dev@talanmdpdpdatalakesa.dfs.core.windows.net/dbt_antonio/gold_zone_github_data_users')
""").df()


# Export to Excel
df.to_excel("gold_zone_github_data_users.xlsx", index=False)

