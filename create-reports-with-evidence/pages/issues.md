---
title: GitHub Data — Analyzing Issues
---

In the last <Value data={issue_summary} column="last_hours"/> hours there have been <b><Value data={issue_summary} column="issues" fmt="num0 auto"/></b> events across <Value data={issue_summary} column="repo_count" fmt="num0 auto"/> repositories! This has involved <Value data={issue_summary} column="actor_count" fmt="num0 auto"/> contributors opening and closing issues, <Value data={issue_summary} column="opened_events" fmt="num0 auto"/> and <Value data={issue_summary} column="closed_events" fmt="num0 auto"/> respectively.

<b><Value data={top_actor} /></b> was the top contributor with <b><Value data={top_actor_repo} column="repo_events"/></b> issues added to <b><Value data={top_actor_repo} column="repo_name"/></b> repository!

<BigValue
    data={issue_summary}
    value='issues'
    maxWidth='10em'
/>

<BigValue
    data={issue_summary}
    value='repo_count'
    maxWidth='10em'
/>

<BigValue
    data={issue_summary}
    value='actor_count'
    maxWidth='10em'
/>

### Issues by hour

<BarChart
  data={issue_count_hour}
  x="hour_of_day"
  y="issues"
  series="issue_action"
/>


_The longest content issue in the data set reads:_ <Value data={issue_content_len} />

<Details title="Definitions">

```sql issue_summary
select
  count(1) as issues,
  count(distinct actor_id) as actor_count,
  count(distinct repo_id) as repo_count,
  datediff('hour', cast(min(event_created_at) as timestamp), cast(current_timestamp as timestamp)) as last_hours,
  count(1) filter(where issue_action = 'opened') as opened_events,
  count(1) filter(where issue_action = 'closed') as closed_events
from databricks.github_data_issue_events
```

<!-- Actor summary -->

```sql top_actor
select
  actor_login,
  count(1) as actor_events
from databricks.github_data_issue_events
group by actor_login
having actor_events > 1
order by actor_login desc
limit 1
```

```sql top_actor_repo
select repo_name,
  count(1) as repo_events
from databricks.github_data_issue_events
where actor_login = (select actor_login from (${top_actor}) as top_actor)
group by repo_name
limit 1
```

```sql issue_content_len
select
  left(issue_body, 400) as content_summary,
  issue_body,
  length(issue_body) as issue_body_len
from databricks.github_data_issue_events
order by issue_body_len desc
limit 1
```

```sql issue_count
select count(1) as issues, event_created_at, 
  count(1) - count(1) filter(where issue_created_at < cast(current_timestamp as timestamp) - interval 1 day) as count_day_prior
from databricks.github_data_issue_events
group by event_created_at
```

```sql issue_count_hour
select
  date_trunc('hour', cast(event_created_at as timestamp)) as hour_of_day,
  case
    when issue_action = 'opened' then 'Opened'
    when issue_action = 'closed' then 'Closed'
    else issue_action
  end as issue_action,
  count(1) as issues
from databricks.github_data_issue_events
group by hour_of_day, issue_action
order by hour_of_day
```


</Details>