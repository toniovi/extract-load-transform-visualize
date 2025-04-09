with

push_events_cte as (

    select event_id, actor_id, payload, repo_id, repo_name, actor_login, event_created_at,
    '$.push_id', '$.size', '$.distinct_size', '$.commits'
    
    from {{ ref('stg_events') }}

    where
        event_type in ('PushEvent')

    limit 10000

),

unnest_json as (

    select
        event_id,
        actor_id,
        payload,
        repo_id,
        repo_name,
        actor_login,
        event_created_at,
        get_json_object(cast(payload as string), '$.push_id') as push_id,
        get_json_object(cast(payload as string), '$.size') as push_size,
        get_json_object(cast(payload as string), '$.distinct_size') as push_distinct_size,
        get_json_object(cast(payload as string), '$.commits') as push_commits

    from push_events_cte

)

select * from unnest_json
