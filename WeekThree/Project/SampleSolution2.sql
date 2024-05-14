-- We want to create a daily report to track:
-- Total unique sessions
-- The average length of sessions in seconds
-- The average number of searches completed before displaying a recipe 
-- The ID of the recipe that was most viewed 

with events as (
    select distinct
        session_id,
        event_timestamp,
        parse_json(event_details):event::varchar as event_type,
        parse_json(event_details):recipe_id::varchar as recipe_id
    from vk_data.events.website_activity),

sessions as (
    select
        session_id,
        min(event_timestamp::date) as session_date,
        datediff(second, min(event_timestamp), max(event_timestamp)) as session_length
    from events
    group by session_id
    having session_length > 0
),

search_count_per_session as (
    select 
        e1.session_id,
        count(*) as search_count
    from events as e1
    join events as e2 on e1.session_id = e2.session_id
        and e2.event_timestamp < e1.event_timestamp
        and e1.event_type = 'view_recipe'
        and e2.event_type = 'search'
    group by e1.session_id),

recipe_views_by_day as (
    select 
        event_timestamp::date as session_date,
        recipe_id,
        count(*) as recipe_views
    from events
    where event_type = 'view_recipe'
    group by session_date, recipe_id),

max_views_by_day as (
    select
        session_date,
        max(recipe_views) as max_view_count
    from recipe_views_by_day
    group by session_date),

most_viewed_recipe_by_day as (
    select
        r.session_date,
        r.recipe_id  
    from recipe_views_by_day as r
    join max_views_by_day as m on r.session_date = m.session_date
        and r.recipe_views = m.max_view_count)

select
    s.session_date,
    count(*) as session_count,
    round(avg(session_length), 2) as avg_session_seconds,
    round(avg(search_count), 2) as avg_search_count,
    max(m.recipe_id) as most_viewed_recipe_id
from sessions as s
join search_count_per_session as cs on s.session_id = cs.session_id
join most_viewed_recipe_by_day as m on s.session_date = m.session_date
group by s.session_date
order by s.session_date
