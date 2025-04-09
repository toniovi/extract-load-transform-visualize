with

issue_events_cte as (

    select * 
    
    from {{ ref('stg_events') }}

    where
        event_type = 'IssuesEvent'
    
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
        get_json_object(cast(payload as string), '$.issue.created_at') as issue_created_at,
        get_json_object(cast(payload as string), '$.action') as issue_action,
        get_json_object(cast(payload as string), '$.issue.id') as issue_id,
        get_json_object(cast(payload as string), '$.issue.url') as issue_url,
        get_json_object(cast(payload as string), '$.issue.repository_url') as issue_repo_url,
        get_json_object(cast(payload as string), '$.issue.state') as issue_state,
        get_json_object(cast(payload as string), '$.issue.state_reason') as issue_state_reason,
        get_json_object(cast(payload as string), '$.issue.body') as issue_body,
        get_json_object(cast(payload as string), '$.changes') as issue_changes,
        get_json_object(cast(payload as string), '$.label') as issue_label,
        get_json_object(cast(payload as string), '$.assignee') as issue_assignee

    from issue_events_cte

)

select * from unnest_json
