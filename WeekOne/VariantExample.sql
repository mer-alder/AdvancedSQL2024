
-- for one specific chef, generate a list of all his recipe ingredients to make a shopping list
with recipes as (
    select
        *
    from vk_data.chefs.recipe
    where chef_id = '398e04fc-e74c-4bdf-9890-13817e74d0c2')

select
    replace(value, '"', '') as ingredient,
    count(*) as count_of_recipes
from recipes,
table(flatten(ingredients))
group by 1
order by 1
