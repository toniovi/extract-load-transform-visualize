-- To run it: 
-- dbt run-operation delete_all_data_in_databricks --args '{"verbose": true}'
-- dbt run-operation delete_all_data_in_databricks --args '{"verbose": true, "dry_run": false}'
-- dbt run-operation delete_all_data_in_databricks --args '{"dry_run": false}'
-- dbt run-operation delete_all_data_in_databricks --args '{"catalogs": ["catalog-silver-uat"], "verbose": true, "dry_run": false}'

{% macro delete_all_data_in_databricks(
    skip_schemas=[
        'poc_databricks_powerbi',
        
        'information_schema',
        'dbt_prd'
    ],
    verbose=false,
    dry_run=true,
    specific_catalogs=[]  
) %}
    {% if verbose %}
        {{ log("Running delete_all_data_in_databricks with catalogs: " ~ (specific_catalogs | length > 0 and specific_catalogs or catalogs), info=True) }}
    {% endif %}

    -- Step 1: Si 'specific_catalogs' est vide, récupérer les catalogues commençant par 'catalog*'
    {% if specific_catalogs | length == 0 %}
        {% set catalog_query %}
            SHOW CATALOGS LIKE 'catalog*'
        {% endset %}
        
        {% set catalog_results = run_query(catalog_query) %}
        {% set catalogs = catalog_results.columns[0].values() %}
    {% else %}
        {% set catalogs = specific_catalogs %}
    {% endif %}
  
    -- Afficher les catalogues trouvés si 'verbose' est activé
    {% if verbose %}
        {{ log("Found catalogs: " ~ catalogs | join(", "), info=true) }}
    {% endif %}
  
    -- Step 2: Itérer sur chaque catalogue et lister les schémas directement dans celui-ci
    {% for catalog in catalogs %}
    
        {% if verbose %}
            {{ log("Processing catalog: " ~ catalog, info=true) }}
        {% endif %}
        
        {% set use_catalog_query %}
            USE CATALOG `{{ catalog }}`
        {% endset %}
        
        {% do run_query(use_catalog_query) %}
        
        {% set schema_query %}
            SHOW SCHEMAS IN `{{ catalog }}`
        {% endset %}
        
        {% set results = run_query(schema_query) %}
        {% set schemas = results.columns[0].values() %}
        
        {% if verbose %}
            {{ log("Found schemas in " ~ catalog ~ ": " ~ schemas | join(", "), info=true) }}
        {% endif %}
        
        -- Step 3: Itérer sur chaque schéma et lister les tables et vues dans celui-ci
        {% for schema in schemas %}
            {% if schema not in skip_schemas %}
            
                {% set table_query %}
                    SHOW TABLES IN `{{ catalog }}`.`{{ schema }}`
                {% endset %}
                
                {% set table_results = run_query(table_query) %}
                {% set tables = table_results.columns[1].values() %}
                
                {% set view_query %}
                    SHOW VIEWS IN `{{ catalog }}`.`{{ schema }}`
                {% endset %}
                
                {% set view_results = run_query(view_query) %}
                {% set views = view_results.columns[1].values() %}
                
                {% set tables_set = set(tables) %}
                {% set views_set = set(views) %}
                {% set tables = tables_set - views_set %}
                
                {% if verbose %}
                    {{ log("Found tables in " ~ catalog ~ "." ~ schema ~ ": " ~ tables | join(", "), info=true) }}
                    {{ log("Found views in " ~ catalog ~ "." ~ schema ~ ": " ~ views | join(", "), info=true) }}
                {% endif %}
                
                -- Step 4: Itérer sur chaque table et vue et les supprimer
                {% for table in tables %}
                    {% if dry_run %}
                        {% set drop_query %}
                            -- Mode dry_run : La requête de suppression de table ne sera pas exécutée
                        {% endset %}
                        {{ log("Dry run mode: Table drop query not executed for catalog: " ~ catalog ~ ", schema: " ~ schema ~ ", table: " ~ table, info=true) }}
                    {% else %}
                        {% set drop_query %}
                            DROP TABLE `{{ catalog }}`.`{{ schema }}`.`{{ table }}`;
                        {% endset %}
                        
                        {% do run_query(drop_query) %}
                        {{ log("Catalog: " ~ catalog ~ ", Schema: " ~ schema ~ ", Table dropped: " ~ table, info=true) }}
                    {% endif %}
                {% endfor %}
                
                {% for view in views %}
                    {% if dry_run %}
                        {% set drop_query %}
                            -- Mode dry_run : La requête de suppression de vue ne sera pas exécutée
                        {% endset %}
                        {{ log("Dry run mode: View drop query not executed for catalog: " ~ catalog ~ ", schema: " ~ schema ~ ", view: " ~ view, info=true) }}
                    {% else %}
                        {% set drop_query %}
                            DROP VIEW `{{ catalog }}`.`{{ schema }}`.`{{ view }}`;
                        {% endset %}
                        
                        {% do run_query(drop_query) %}
                        {{ log("Catalog: " ~ catalog ~ ", Schema: " ~ schema ~ ", View dropped: " ~ view, info=true) }}
                    {% endif %}
                {% endfor %}
            
            {% endif %}
        {% endfor %}
    
    {% endfor %}
{% endmacro %}
