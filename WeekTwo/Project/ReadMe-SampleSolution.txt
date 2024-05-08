This is one possible solution to make the original query more readable.

Your solution is likely different, and that is okay. 

Your solution should have:
1. Consist formatting throughout - capitalization, leading vs. trailing commas, indentation.
      It's okay if you used different formatting than the sample solution.
      You should not mix formatting choices in a single query.

2. After all the CTEs, one final select statement.
      This final select statement should be easy to understand.

A couple of choices to note in this sample solution:
1. Notice that when the query references joins source tables (see CTE "customer_info"), aliases are used to make the code more concise.
   But when a CTE is used in a join, no alias is specified.
2. Notice that filters and formatting are applied as early as possible. See CTE "city_reference". Instead of doing the upper and trim each time this
   table is used, it is done in one place at the beginning of the query. Because we are formatting early, we can clean up the final where clause
   from the original query, making it easier to read.

  ORIGINAL:
      where 
        ((trim(city_name) ilike '%concord%' or trim(city_name) ilike '%georgetown%' or trim(city_name) ilike '%ashland%')
        and customer_state = 'KY')
        or
        (customer_state = 'CA' and (trim(city_name) ilike '%oakland%' or trim(city_name) ilike '%pleasant hill%'))
        or
        (customer_state = 'TX' and ((trim(city_name) ilike '%arlington%') or trim(city_name) ilike '%brownsville%'))

   IN OUR SAMPLE SOLUTION
      where (customer_state = 'KY'
            and customer_city in ('CONCORD', 'GEORGETOWN', 'ASHLAND'))
        or (customer_state = 'CA' 
            and customer_city in ('OAKLAND', 'PLEASANT HILL'))
        or (customer_state = 'TX' 
            and customer_city in ('ARLINGTON', 'BROWNSVILLE'))
