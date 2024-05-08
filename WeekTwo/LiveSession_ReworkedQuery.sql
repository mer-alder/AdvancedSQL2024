with chefs_recipe as (
    select
        r.*
    from chefs.recipe as r
    join chefs.chef_profile c on r.chef_id = c.chef_id
    where step_count <= 11 
        and minutes < 60 
        and ingredient_count < 10
        and lower(chef_email) in ('elaine.pope@email.com','bobby.lindquist@email.com','sandra.perez@email.com',
            'kevin.meza@email.com','kris.wilson@email.com','leon.quinlan@email.com','glenna.berg@email.com',
            'ora.soliz@email.com','rosetta.gill@email.com','virginia.moran@email.com')
),

recipe_steps as (
    select
        recipe_id,
        recipe_steps.index as step_number,
        trim(replace(recipe_steps.value, '"', '')) as step_details
    from chefs_recipe,
    table(flatten(steps)) as recipe_steps
),

recipe_ingredients as (
    select
        recipe_id,
        recipe_ingredients.index as ingredient_number,
        trim(replace(recipe_ingredients.value, '"', '')) as ingredient
    from chefs_recipe,
    table(flatten(ingredients)) as recipe_ingredients
),

recipe_tags as (
    select
        recipe_id
    from chefs_recipe,
    table(flatten(tag_list)) as recipe_tags
    where trim(replace(recipe_tags.value, '"', '')) = 'main-ingredient'
),

filtered_recipes as (
    select 
        recipe_id
    from recipe_steps
    where (step_details ilike '%BAKE%' or step_details ilike '%OVEN%')
        and (step_details not ilike '%BOIL%' and step_details not ilike '%STOVE%')
    -- intersect removes duplicates, so we don't need all the distincts from the original query
    intersect     
    select 
        recipe_id
    from recipe_ingredients
    where (ingredient ilike '%CHEESE%' or ingredient ilike '%ONION%')
)

select 
    chefs_recipe.* 
from filtered_recipes
join chefs_recipe on filtered_recipes.recipe_id = chefs_recipe.recipe_id
join recipe_tags on chefs_recipe.recipe_id = recipe_tags.recipe_id
