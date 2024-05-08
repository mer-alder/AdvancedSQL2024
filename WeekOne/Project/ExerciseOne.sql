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

-- Join the supplier table to our reference table of cities and states.
-- To ensure that our match rate is as high as possible, make sure the city/state are in the same format.
-- Convert all values to lowercase and trim to eliminate any leading or trailing spaces.
supplier_location as (
    select 
        si.supplier_id,
        uc.geo_location
    from vk_data.suppliers.supplier_info as si
    join city_geo_location as uc on trim(lower(si.supplier_city)) = trim(lower(uc.city_name))
        and trim(lower(si.supplier_state)) = trim(lower(uc.state_abbr))
),

-- Cross join between customer and supplier so every customer matches with every supplier.
-- We need to calcuate the distance between every customer and every supplier.
-- st_distance returns the value in meters. We need to divide by 1609 to convert to miles (or 1000 to convert to kilometers).
-- I added the round function to make the output look nice, but it's not necessary.  
customer_to_supplier as (
    select 
        customer_id,
        supplier_id,
        round(st_distance(s.geo_location, c.geo_location) / 1609, 2) as distance_miles
    from customer_location as c
    cross join supplier_location as s
),

-- Order the customer to supplier distance using a window function.
-- I used row_number but you can get the same thing with either rank or dense_rank.
-- What is the difference?  
-- Rank and dense_rank will include ties if two rows have the same value.
-- Rank can give you two #1 values and then skip #2.
-- Dense_rank can give you two #1 values but will still include #2.
-- All of them will give us the same result in this exercise.
closeness as (
    select
        *,
        row_number() over (partition by customer_id order by distance_miles asc) as closeness_ranking
    -- rank() over (partition by customer_id order by distance_miles desc) as closeness_ranking
    -- dense_rank() over (partition by customer_id order by distance_miles desc) as closeness_ranking
    from customer_to_supplier
)

-- Join to the customer and supplier data to get the name values.
-- Filter the results to only return one row per customer:  closeness_ranking = 1
-- The instructions specify that we only want the closest supplier for each customer.
-- Total rows returned should be 2401.
select
    cd.customer_id,
    cd.first_name,
    cd.last_name,
    cd.email,
    c.supplier_id,
    si.supplier_name,
    c.distance_miles
from closeness as c
join vk_data.customers.customer_data as cd on c.customer_id = cd.customer_id
join vk_data.suppliers.supplier_info as si on c.supplier_id = si.supplier_id
where c.closeness_ranking = 1
order by cd.last_name, cd.first_name
