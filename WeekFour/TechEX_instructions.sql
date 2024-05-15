-- We have 35 lost orders
/*
select
    *
from customers.customer_lost_orders
*/

-- For each recipe, rank the orders by order date so we can prioritize the oldest orders first

with orders as (
    select 
        recipe_id,
        customer_id,
        order_id,
        ordered_at,
        row_number() over (partition by recipe_id order by ordered_at) as fulfill_order
    from customers.customer_lost_orders),

-- For each order find the closest supplier 

cities as (
    select
        trim(upper(city_name)) as city_name,
        trim(upper(state_abbr)) as state_abbr,
        geo_location as geo_location
    from resources.us_cities),

lost_orders as (
    select
        order_id,
        trim(upper(customer_city)) as customer_city,
        trim(upper(customer_state)) as customer_state
    from customers.customer_lost_orders as l
    join customers.customer_address as a on l.customer_id = a.customer_id),

suppliers as (
    select
        supplier_id,
        supplier_name,
        trim(upper(supplier_city)) as supplier_city,
        trim(upper(supplier_state)) as supplier_state
    from suppliers.supplier_info),

orders_by_supplier as (
    select
        l.order_id,
        s.supplier_id,
        s.supplier_name,
        round(st_distance(c.geo_location, c2.geo_location) / 1609, 2) as distance_miles
    from lost_orders as l
    join suppliers as s
    join cities as c on l.customer_city = c.city_name and l.customer_state = c.state_abbr
    join cities as c2 on s.supplier_city = c2.city_name and s.supplier_state = c2.state_abbr
    qualify 
        row_number() over (partition by l.order_id order by distance_miles) = 1)

-- Write a report by supplier to return the number of orders categorized by distance and priority to fulfill

select
    supplier_id,
    supplier_name,
    distance_miles,
    fulfill_order,
    count(*) as order_count
from orders_by_supplier as s
join orders as o on s.order_id = o.order_id
group by all
order by supplier_id, fulfill_order
