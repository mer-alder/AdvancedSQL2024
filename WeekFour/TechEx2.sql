with lost_orders as (
    select 
        recipe_id,
        customer_id,
        order_id,
        row_number() over (partition by recipe_id order by ordered_at) as fulfill_order
    from customers.customer_lost_orders),

city_to_lost_order as (
    select
        lo.order_id,
        lo.fulfill_order,
        us.city_id,
        us.city_name,
        us.state_abbr,
        us.geo_location
    from lost_orders as lo
    inner join customers.customer_address as ca on lo.customer_id = ca.customer_id
    inner join resources.us_cities as us 
        on TRIM(UPPER(ca.customer_city)) = TRIM(UPPER(us.city_name)) and TRIM(UPPER(ca.customer_state)) = TRIM(UPPER(us.state_abbr))),

supplier_location as (
    select 
        si.supplier_id,
        si.supplier_name,
        uc.geo_location
    from vk_data.suppliers.supplier_info as si
    join resources.us_cities as uc on TRIM(LOWER(si.supplier_city)) = TRIM(LOWER(uc.city_name))
        and TRIM(LOWER(si.supplier_state)) = TRIM(LOWER(uc.state_abbr))),
        
lost_order_to_supplier as (
    select 
        lo.*,
        s.supplier_id,
        s.supplier_name,
        round(st_distance(s.geo_location, lo.geo_location) / 1609, 2) as distance_miles
    from city_to_lost_order as lo
    join supplier_location as s),

closest_supplier as (
    select 
        los.*
    from lost_orders as lo
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
group by 1, 2, 3, 4
order by 1, 4
