select * from
(select distinct r.recipe_id from
(select distinct recipe_id from
(select recipe_id, chef_id, recipe_name, minutes, ingredients, ingredient_count, recipe_steps.index as step_number, 
upper(trim(replace(recipe_steps.value, '"', ''))) as step_details
from chefs.recipe, table(flatten(steps)) as recipe_steps 
where step_count <= 11 and minutes < 60 and ingredient_count < 10)
where (step_details ilike '%BAKE%' or step_details ilike '%OVEN%')
intersect select distinct recipe_id from
(select recipe_id, chef_id, recipe_name, minutes, ingredients, ingredient_count, recipe_ingredients.index as ingredient_number, 
upper(trim(replace(recipe_ingredients.value, '"', ''))) as ingredient
from chefs.recipe, table(flatten(ingredients)) as recipe_ingredients 
where step_count <= 11 and minutes < 60 and ingredient_count < 10)
where (ingredient ilike '%CHEESE%' or ingredient ilike '%ONION%')
intersect select distinct recipe_id from
(select recipe_id, chef_id, recipe_name, minutes, ingredients, ingredient_count, recipe_steps.index as step_number, 
upper(trim(replace(recipe_steps.value, '"', ''))) as step_details
from chefs.recipe, table(flatten(steps)) as recipe_steps 
where step_count <= 11 and minutes < 60 and ingredient_count < 10)
where (step_details not ilike '%BOIL%' and step_details not ilike '%STOVE%')) recipe_list
join chefs.recipe r on recipe_list.recipe_id = r.recipe_id,
table(flatten(tag_list)) as recipe_tags
where trim(replace(recipe_tags.value, '"', '')) = 'main-ingredient') recipe_list
join chefs.recipe r on recipe_list.recipe_id = r.recipe_id
join chefs.chef_profile c on r.chef_id = c.chef_id
where lower(chef_email) in ('elaine.pope@email.com','bobby.lindquist@email.com','sandra.perez@email.com','kevin.meza@email.com'
,'kris.wilson@email.com','leon.quinlan@email.com','glenna.berg@email.com','ora.soliz@email.com'
,'rosetta.gill@email.com','virginia.moran@email.com')
