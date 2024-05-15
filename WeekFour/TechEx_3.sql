with 

city as (
    select 
        trim(lower(state_abbr)) as state_abbr,
        trim(lower(city_name)) as city_name,
        city_id,
        geo_location
    from resources.us_cities
),

orders as (
    select
        lo.order_id,
        c.city_id,
        c.geo_location,
        row_number() over (partition by recipe_id order by ordered_at) as fulfill_order
    from customers.customer_lost_orders as lo
    join customers.customer_address as ca on lo.customer_id = ca.customer_id
    join city as c 
        on trim(lower(ca.customer_city)) = c.city_name and trim(lower(ca.customer_state)) = c.state_abbr),

suppliers as (
    select 
        si.supplier_id,
        si.supplier_name,
        c.geo_location
    from vk_data.suppliers.supplier_info as si
    left join city as c on si.supplier_city = c.city_name
        and si.supplier_state = c.state_abbr),

-- use a st_distance to calculate distance, 1609 converts it to miles
lost_order_to_supplier as (
    select 
        lo.*,
        s.supplier_id,
        s.supplier_name,
        round(st_distance(s.geo_location, lo.geo_location) / 1609, 2) as distance_miles
    from orders as lo
    join suppliers as s),

-- use a qualify and window function to only return the closest supplier
closest_supplier as (
    select 
        los.*
    from orders as lo
    join lost_order_to_supplier as los
        on lo.order_id = los.order_id
    qualify row_number() over (partition by lo.order_id order by los.distance_miles) = 1)

select 
    supplier_id,
    supplier_name,
    distance_miles,
    fulfill_order,
    count(*) as total_orders
from closest_supplier
group by supplier_id,
    supplier_name,
    distance_miles,
    fulfill_order

