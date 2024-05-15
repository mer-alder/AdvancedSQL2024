select 
    supplier_id,
    distance,
    fulfill_order
from (
    select 
        lo.*,
        s.supplier_id,
        s.supplier_name,
        st_distance(s.geo_location, lo.geo_location) as distance
    from (
        select
            lo.order_id,
            lo.fulfill_order,
            us.city_id,
            us.city_name,
            us.state_abbr,
            us.geo_location
        from (
            select 
                recipe_id,
                customer_id,
                order_id,
                row_number() over (partition by recipe_id order by ordered_at) as fulfill_order
            from customers.customer_lost_orders) as lo
        join customers.customer_address as ca on lo.customer_id = ca.customer_id
        join resources.us_cities as us 
            on trim(lower(ca.customer_city)) = trim(lower(us.city_name)) and trim(lower(ca.customer_state)) = trim(lower(us.state_abbr))
    ) as lo
    join (
        select 
            si.supplier_id,
            si.supplier_name,
            uc.geo_location
        from vk_data.suppliers.supplier_info as si
        join resources.us_cities as uc on trim(lower(si.supplier_city)) = trim(lower(uc.city_name))
            and trim(lower(si.supplier_state)) = trim(lower(uc.state_abbr))) as s
    qualify row_number() over (partition by order_id order by distance) = 1)

group by 1, 2, 3
order by 1
