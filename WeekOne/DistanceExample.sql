-- source tables
-- select * from chicago_grocery.product_analytics.customers    
-- select * from chicago_grocery.product_analytics.stores
-- select * from chicago_grocery.product_analytics.purchases 


-- problem 1:  find each customer's closest store, 13 customers, 10 stores

with store_info as (
    select 
        c.customer_id,
        s.store_id as closest_store_id,
        st_distance(s.geo_location, c.address_geo_location) / 1609 as distance_to_store_miles
    from chicago_grocery.product_analytics.customers as c
    cross join chicago_grocery.product_analytics.stores as s),

closest_store as (
    select
        *
    from store_info
    qualify row_number() over (partition by customer_id order by distance_to_store_miles) = 1),

-- problem 2: for each customer determine what percent of their spending is in specialty goods, both home and away
--      and what percentage is not specialty, order by the customers with the highest amount of specialty spending
-- 109 purchases

spend_summary as (
    select
        p.customer_id,
        case when p.store_id = s.closest_store_id then TRUE else FALSE end as is_home_store,
        p.total_spend,
        p.specialty_spend
    from chicago_grocery.product_analytics.purchases as p
    inner join closest_store as s on p.customer_id = s.customer_id),

customer_spend as (
    select
        customer_id,
        sum(total_spend) as total_spend,
        sum(case when is_home_store = TRUE then specialty_spend else 0 end) as home_store_specialty_spend,
        sum(case when is_home_store = FALSE then specialty_spend else 0 end) as away_store_specialty_spend
    from spend_summary
    group by customer_id),

results as (
    select
        customer_id,
        home_store_specialty_spend / total_spend * 100 as home_store_specialty_percent,
        away_store_specialty_spend / total_spend * 100 as away_store_specialty_percent,
        (total_spend - home_store_specialty_spend - away_store_specialty_spend) / total_spend * 100 as non_specialty_spend_percent,
        home_store_specialty_spend,
        away_store_specialty_spend,
        total_spend
    from customer_spend
    order by non_specialty_spend_percent)

select * from results

-- problem 3:  what test cases can we identify 

-- select sum(total_spend) from chicago_grocery.product_analytics.purchases
-- union
-- select sum(total_spend) from results
