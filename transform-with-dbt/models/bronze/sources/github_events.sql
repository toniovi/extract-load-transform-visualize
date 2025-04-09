

SELECT 
    * 
    ,_metadata.file_modification_time as file_modification_time
FROM stream read_files("abfss://{{ env_var('LANDING_CONTAINER_NAME') }}{{ env_var('LANDING_DEPLOYMENT_ENVIRONMENT_SUFFIX', '') }}@{{ env_var('DBT_ENV_AZURE_DATALAKE_STORAGE_ACCOUNT') }}.dfs.core.windows.net/data.gharchive.org/", format=>'json')
