-- This CTE is ranking the price on individual items instead of order totals
-- The order by 1, 2 is unnecessary
with urgent_orders as (
    select
    	o_orderkey,
    	o_orderdate,
        c_custkey,
        p_partkey,
        l_quantity,
        l_extendedprice,
        row_number() over (partition by c_custkey order by l_extendedprice desc) as price_rank
    from snowflake_sample_data.tpch_sf1.orders as o
    inner join snowflake_sample_data.tpch_sf1.customer as c on o.o_custkey = c.c_custkey
    inner join snowflake_sample_data.tpch_sf1.lineitem as l on o.o_orderkey = l.l_orderkey
    inner join snowflake_sample_data.tpch_sf1.part as p on l.l_partkey = p.p_partkey
    where c.c_mktsegment = 'AUTOMOBILE'
    	and o.o_orderpriority = '1-URGENT'
    order by 1, 2),

-- Because the previous CTE was ranking by parts instead of by orders, 
-- notice there are duplicate order_numbers in the order_numbers field
-- The order by 1 is unnecessary
top_orders as (
    select
    	c_custkey,
        max(o_orderdate) as last_order_date,
        listagg(o_orderkey, ', ') as order_numbers,
        sum(l_extendedprice) as total_spent
    from urgent_orders
    where price_rank <= 3
    group by 1
    order by 1)

select 
	t.c_custkey,
    t.last_order_date,
    t.order_numbers,
    t.total_spent,
    u.p_partkey as part_1_key,
    u.l_quantity as part_1_quantity,
    u.l_extendedprice as part_1_total_spent,
    u2.p_partkey as part_2_key,
    u2.l_quantity as part_2_quantity,
    u2.l_extendedprice as part_2_total_spent,
    u3.p_partkey as part_3_key,
    u3.l_quantity as part_3_quantity,
    u3.l_extendedprice as part_3_total_spent
from top_orders as t
inner join urgent_orders as u on t.c_custkey = u.c_custkey
inner join urgent_orders as u2 on t.c_custkey = u2.c_custkey
inner join urgent_orders as u3 on t.c_custkey = u3.c_custkey
where u.price_rank = 1 and u2.price_rank = 2 and u3.price_rank = 3
order by t.last_order_date desc
limit 100
