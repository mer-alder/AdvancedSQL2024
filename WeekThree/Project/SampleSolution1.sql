-- We want to create a daily report to track:
-- Total unique sessions
-- The average length of sessions in seconds
-- The average number of searches completed before displaying a recipe 
-- The ID of the recipe that was most viewed 

with 

all_sessions_greater_than_zero_seconds as (
    select
        a.session_id,
        min(a.event_timestamp::date) as session_date,
        min(a.event_timestamp) as begin_time,
        max(a.event_timestamp) as end_time,
        datediff(second, begin_time, end_time) as session_seconds
    from vk_data.events.website_activity as a
    group by a.session_id
    having begin_time < end_time),

all_events as (
    select
        session_id,
        event_timestamp,
        row_number() over (partition by session_id order by event_timestamp) as event_id,
        parse_json(event_details):event::varchar as event_type,
        parse_json(event_details):recipe_id::varchar as recipe_id
    from vk_data.events.website_activity
    where event_type in ('search', 'view_recipe')
),

sessions_by_day as (
    select
        session_date,
        count(*) as session_count,
        round(avg(session_seconds), 2) as avg_session_seconds
    from all_sessions_greater_than_zero_seconds
    group by session_date
    order by session_date),

recipes_viewed as (
    select
        e1.session_id,
        e1.event_timestamp::date as session_date,
        e2.event_id - 1 as search_count,
        e2.recipe_id,
        row_number() over (partition by session_date, e2.recipe_id order by e2.recipe_id) as recipe_view_number
    from all_events as e1
    join all_events as e2 on e1.session_id = e2.session_id
    where e1.event_id = 1
        and e2.event_type = 'view_recipe'),

highest_view_count as (
    select
        session_date,
        max(recipe_view_number) as most_views
    from recipes_viewed
    group by session_date),

most_viewed_recipe as (
    select
        v.session_date,
        listagg(v.recipe_id, ', ') as most_viewed_recipe
    from recipes_viewed as v
    join highest_view_count as h on v.session_date = h.session_date
        and v.recipe_view_number = h.most_views
    group by v.session_date)

select
    s.session_date,
    s.session_count,
    s.avg_session_seconds,
    round(avg(r.search_count), 2) as avg_searches_before_recipe,
    min(m.most_viewed_recipe) as most_viewed_recipe
from sessions_by_day as s
left join recipes_viewed as r on s.session_date = r.session_date
left join most_viewed_recipe as m on s.session_date = m.session_date
group by s.session_date,
    s.session_count,
    s.avg_session_seconds
order by s.session_date












