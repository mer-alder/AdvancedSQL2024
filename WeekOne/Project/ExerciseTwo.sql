-- The city table has some duplicate records.
-- You can still get the right answer without removing duplicates.
with 
city_unique as (
    select 
        city_name, 
        state_abbr,
        min(city_id) as first_row
    from vk_data.resources.us_cities
    group by 1, 2
),

city_geo_location as (
    select
        c.city_name,
        c.state_abbr,
        c.geo_location
    from vk_data.resources.us_cities as c
    join city_unique as cu on c.city_id = cu.first_row
),

-- Join the customer address table to our reference table of cities and states.
-- To ensure that our match rate is as high as possible, make sure the city/state are in the same format.
-- Convert all values to lowercase and trim to eliminate any leading or trailing spaces.
customer_location as (
    select 
        ca.customer_id,
        uc.geo_location
    from vk_data.customers.customer_address as ca
    join city_geo_location as uc on trim(lower(ca.customer_city)) = trim(lower(uc.city_name))
        and trim(lower(ca.customer_state)) = trim(lower(uc.state_abbr))
),

-- Join to the customer survey table.
-- The survey table has a row for every recipe type preference the customer selected.
-- The result of this CTE will be one to many rows per customer_id.
-- It's important to standardize (trim & case) the tag_property because we need to join on it.
customer_tags as (
    select 
        c.customer_id,
        trim(lower(t.tag_property)) as tag_property,
        row_number() over (partition by c.customer_id order by t.tag_property) as customer_row_id
    from customer_location as c
    join vk_data.customers.customer_survey as s on c.customer_id = s.customer_id
    join vk_data.resources.recipe_tags as t on s.tag_id = t.tag_id
    where s.is_active = 1
),

-- The pivot will result in one row per customer_id.
-- You could have used a different method, like a self-join to get the top three preferences.
customer_list as (
    select
        *
    from customer_tags
        pivot(min(tag_property) for customer_row_id in (1, 2, 3))
            as p (customer_id, food_pref_1, food_pref_2, food_pref_3)
),

-- The tag_list column holds one to many values, all stored in one column.
-- The flatten operation will return one row per value, so we'll have one to many rows per recipe.
-- But since we only need one sample recipe for each tag, I added min to just return one.
recipe_tags as (
    select 
        replace(trim(lower(flat_tag_list.value)), '"', '') as recipe_tag,
        min(recipe_id) as first_recipe
    from vk_data.chefs.recipe
    , table(flatten(tag_list)) as flat_tag_list
    group by recipe_tag
)

-- This should return 1048 rows.
select 
    cl.customer_id,
    c.email,
    c.first_name,
    cl.food_pref_1,
    cl.food_pref_2,
    cl.food_pref_3,
    r.recipe_name as suggested_recipe
from customer_list as cl
join vk_data.customers.customer_data as c on cl.customer_id = c.customer_id
join recipe_tags as rt on cl.food_pref_1 = rt.recipe_tag
join vk_data.chefs.recipe as r on rt.first_recipe = r.recipe_id
order by email
