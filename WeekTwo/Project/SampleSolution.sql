with 
    city_reference as (
        select 
            city_id,
            upper(trim(city_name)) as city_name,
            upper(trim(state_abbr)) as state_abbr,
            geo_location
        from vk_data.resources.us_cities
    ),

    chicago_geolocation as (
        select
            city_id,
            city_name,
            geo_location
        from city_reference
        where city_name = 'CHICAGO' and state_abbr = 'IL'
        limit 1
    ),

    gary_geolocation as (
        select
            city_id,
            city_name,
            geo_location
        from city_reference
        where city_name = 'GARY' and state_abbr = 'IN'
        limit 1
    ),

    customer_info as (
        select
            c.customer_id,
            c.first_name || ' ' || c.last_name as customer_name,
            upper(trim(ca.customer_city)) as customer_city,
            upper(trim(ca.customer_state)) as customer_state
        from vk_data.customers.customer_data as c
        join vk_data.customers.customer_address as ca
            on c.customer_id = ca.customer_id
    ),

    customer_preferences as (
        select 
            customer_id,
            count(*) as food_pref_count
        from vk_data.customers.customer_survey
        where is_active = true
        group by 1),

    customer as (
        select
            customer_info.customer_id,
            customer_info.customer_name,
            customer_info.customer_city,
            customer_info.customer_state,
            city_reference.geo_location,
            customer_preferences.food_pref_count
        from customer_info
        join city_reference on customer_info.customer_city = city_reference.city_name
            and customer_info.customer_state = city_reference.state_abbr
        join customer_preferences on customer_info.customer_id = customer_preferences.customer_id
        where (customer_state = 'KY'
                and (customer_city ilike '%concord%' or customer_city ilike '%georgetown%' or customer_city ilike '%ashland%'))
            or (customer_state = 'CA' 
                and (customer_city ilike '%oakland%' or customer_city ilike '%pleasant hill%'))
            or (customer_state = 'TX' 
                and (customer_city ilike '%arlington%' or customer_city ilike '%brownsville%'))
    )

select
    customer.customer_name,
    customer.customer_city,
    customer.customer_state,
    customer.food_pref_count,
    (st_distance(customer.geo_location, chicago_geolocation.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(customer.geo_location, gary_geolocation.geo_location) / 1609)::int as gary_distance_miles
from customer
join chicago_geolocation
join gary_geolocation
order by customer.customer_name

-- *******************************
-- THIS IS THE ORIGINAL QUERY
-- *******************************

-- select 
--     first_name || ' ' || last_name as customer_name,
--     ca.customer_city,
--     ca.customer_state,
--     s.food_pref_count,
--     (st_distance(us.geo_location, chic.geo_location) / 1609)::int as chicago_distance_miles,
--     (st_distance(us.geo_location, gary.geo_location) / 1609)::int as gary_distance_miles
-- from vk_data.customers.customer_address as ca
-- join vk_data.customers.customer_data c on ca.customer_id = c.customer_id
-- left join vk_data.resources.us_cities us 
-- on UPPER(rtrim(ltrim(ca.customer_state))) = upper(TRIM(us.state_abbr))
--     and trim(lower(ca.customer_city)) = trim(lower(us.city_name))
-- join (
--     select 
--         customer_id,
--         count(*) as food_pref_count
--     from vk_data.customers.customer_survey
--     where is_active = true
--     group by 1
-- ) s on c.customer_id = s.customer_id
--     cross join 
--     ( select 
--         geo_location
--     from vk_data.resources.us_cities 
--     where city_name = 'CHICAGO' and state_abbr = 'IL') chic
-- cross join 
--     ( select 
--         geo_location
--     from vk_data.resources.us_cities 
--     where city_name = 'GARY' and state_abbr = 'IN') gary
-- where 
--     ((trim(city_name) ilike '%concord%' or trim(city_name) ilike '%georgetown%' or trim(city_name) ilike '%ashland%')
--     and customer_state = 'KY')
--     or
--     (customer_state = 'CA' and (trim(city_name) ilike '%oakland%' or trim(city_name) ilike '%pleasant hill%'))
--     or
--     (customer_state = 'TX' and ((trim(city_name) ilike '%arlington%') or trim(city_name) ilike '%brownsville%'))
