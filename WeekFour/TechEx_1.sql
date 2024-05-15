with orders as (
    select 
        recipe_id,
        customer_id,
        order_id,
        ordered_at,
        row_number() over (partition by recipe_id order by ordered_at) as fulfill_order
    from customers.customer_lost_orders),

cities as (
    select
        lo.order_id,
        lo.fulfill_order,
        us.city_id,
        us.city_name,
        us.state_abbr,
        us.geo_location
    from orders as lo
    join customers.customer_address as ca on lo.customer_id = ca.customer_id
    join resources.us_cities as us 
        on trim(upper(ca.customer_city)) = trim(upper(us.city_name)) and trim(upper(ca.customer_state)) = trim(upper(us.state_abbr))),

locations as (
    select 
        si.supplier_id,
        si.supplier_name,
        uc.geo_location
    from vk_data.suppliers.supplier_info as si
    join resources.us_cities as uc on trim(lower(si.supplier_city)) = trim(lower(uc.city_name))
        and trim(lower(si.supplier_state)) = trim(lower(uc.state_abbr))),
        
details as (
    select 
        lo.*,
        s.supplier_id,
        s.supplier_name,
        round(st_distance(s.geo_location, lo.geo_location) / 1609, 2) as distance_miles
    from cities as lo
    join locations as s),
    
closest as (
    select 
        d.supplier_id,
        d.supplier_name,
        d.distance_miles,
        d.fulfill_order,
        row_number() over (partition by o.order_id order by d.distance_miles desc) as location_rank
    from orders as o
    join details as d
        on o.order_id = d.order_id)
        
select 
    supplier_id,
    supplier_name,
    distance_miles,
    fulfill_order,
    count(*) as total_orders
from closest
where location_rank = 1
group by 1, 2, 3, 4
order by 1, 4

