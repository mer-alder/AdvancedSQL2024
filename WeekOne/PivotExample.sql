-- for all customers with three tags, return one row per customer_id with a separate column for each of the three tags 
-- 705 customers have three tags
with three_tags as (
    select
        customer_id
    from vk_data.customers.customer_survey
    where is_active = TRUE
    group by customer_id
    having count(*) = 3),
    
customer_tags as (
    select
        s.customer_id,
        rt.tag_property,
        row_number() over (partition by s.customer_id order by rt.tag_property) as tag_id
    from three_tags as t
    join vk_data.customers.customer_survey as s on t.customer_id = s.customer_id
    join vk_data.resources.recipe_tags as rt on s.tag_id = rt.tag_id)

select
    *
from customer_tags
pivot(min(tag_property) for tag_id in (1, 2, 3))
    as p(customer_id, tag1, tag2, tag3)
