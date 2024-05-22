with 

urgent_orders as (
    select
        c.c_custkey,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        row_number() over (partition by c.c_custkey order by o.o_totalprice desc) as order_id
    from snowflake_sample_data.tpch_sf1.customer as c
    join snowflake_sample_data.tpch_sf1.orders as o on c.c_custkey = o.o_custkey
    where c.c_mktsegment = 'AUTOMOBILE'
        and o.o_orderpriority = '1-URGENT'),

urgent_orders_by_customers as (
    select
        c_custkey,
        listagg(o_orderkey, ', ') as order_numbers,
        max(o_orderdate) as last_order_date,
        sum(o_totalprice) as order_total_spent
    from urgent_orders
    where order_id <= 3
    group by c_custkey
),

urgent_order_parts as (
    select
        u.c_custkey,
        u.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice
    from urgent_orders as u
    join snowflake_sample_data.tpch_sf1.lineitem as l on u.o_orderkey = l.l_orderkey
),

order_parts_ranked as (
    select 
        c_custkey,
        l_partkey,
        sum(l_quantity) as part_quantity,
        sum(l_extendedprice) as total_spent_on_part,
        row_number() over (partition by c_custkey order by total_spent_on_part desc) as part_rank_id
    from urgent_order_parts 
    group by 
        c_custkey,
        l_partkey
    order by c_custkey, part_rank_id)
    
select
    u.c_custkey,
    u.last_order_date,
    u.order_numbers,
    u.order_total_spent as total_spent,
    r1.l_partkey as part_1_key,
    r1.part_quantity as part_1_quantity,
    r1.total_spent_on_part as part_1_total_spent,
    r2.l_partkey as part_2_key,
    r2.part_quantity as part_2_quantity,
    r2.total_spent_on_part as part_2_total_spent,
    r3.l_partkey as part_3_key,
    r3.part_quantity as part_3_quantity,
    r3.total_spent_on_part as part_3_total_spent
from urgent_orders_by_customers as u
join order_parts_ranked as r1 on u.c_custkey = r1.c_custkey
left join order_parts_ranked as r2 on r1.c_custkey = r2.c_custkey
left join order_parts_ranked as r3 on r1.c_custkey = r3.c_custkey
where r1.part_rank_id = 1
    and r2.part_rank_id = 2
    and r3.part_rank_id = 3
order by u.last_order_date desc
limit 100
