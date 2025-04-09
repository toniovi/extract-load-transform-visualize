with

pull_request_events_cte as (

    select event_id, actor_id, payload, repo_id, repo_name, actor_login, event_created_at,
    '$.pull_request.id', '$.pull_request.url', '$.pull_request.state', '$.pull_request.title', '$.pull_request.body',
    '$.pull_request.created_at', '$.pull_request.updated_at', '$.pull_request.closed_at', '$.pull_request.merged_at',
    '$.pull_request.commits', '$.pull_request.comments', '$.pull_request.user.login', '$.pull_request.user.id',
    '$.pull_request.repo.full_name', '$.action', '$.number', '$.changes', '$.reason'
    
    from {{ ref('stg_events') }}

    where
        event_type = 'PullRequestEvent'

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
        get_json_object(cast(payload as string), '$.pull_request.created_at')::timestamp as pull_request_created_at,
        get_json_object(cast(payload as string), '$.pull_request.closed_at')::timestamp as pull_request_closed_at,
        get_json_object(cast(payload as string), '$.pull_request.merged_at')::timestamp as pull_request_merged_at,
        get_json_object(cast(payload as string), '$.pull_request.commits') as pull_request_commits,
        get_json_object(cast(payload as string), '$.action') as pull_request_action,
        get_json_object(cast(payload as string), '$.number') as pull_request_number,
        get_json_object(cast(payload as string), '$.changes') as pull_request_changes,
        get_json_object(cast(payload as string), '$.reason') as pull_request_remove_reason,
        get_json_object(cast(payload as string), '$.pull_request.id') as pull_request_id,
        get_json_object(cast(payload as string), '$.pull_request.url') as pull_request_url,
        get_json_object(cast(payload as string), '$.pull_request.state') as pull_request_state,
        get_json_object(cast(payload as string), '$.pull_request.title') as pull_request_title,
        get_json_object(cast(payload as string), '$.pull_request.body') as pull_request_body,
        get_json_object(cast(payload as string), '$.pull_request.updated_at') as pull_request_updated_at,
        get_json_object(cast(payload as string), '$.pull_request.commits') as pull_request_commits_count,
        get_json_object(cast(payload as string), '$.pull_request.comments') as pull_request_comment_count,
        get_json_object(cast(payload as string), '$.pull_request.user.login') as user_login,
        get_json_object(cast(payload as string), '$.pull_request.user.id') as user_id,
        get_json_object(cast(payload as string), '$.pull_request.repo.full_name') as repo_full_name

    from pull_request_events_cte

)

select * from unnest_json
