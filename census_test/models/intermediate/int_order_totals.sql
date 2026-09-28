-- This model is configured as `ephemeral` (see dbt_project.yml). Census can't `SELECT *`
-- from an ephemeral model since it never materializes -- instead it reads the compiled
-- SQL out of the manifest and inlines it as the Census model's query.

with orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

joined as (
    select
        orders.order_id,
        orders.customer_id,
        orders.status,
        orders.order_date,
        orders.quantity,
        products.product_name,
        products.category,
        products.price,
        orders.quantity * products.price as order_total
    from orders
    inner join products on orders.product_id = products.product_id
)

-- CENSUS_TEST_MIN_ORDER is an env var you can set on the Census dbt project to
-- test that env vars flow through to compile.
select *
from joined
where order_total >= {{ env_var('CENSUS_TEST_MIN_ORDER', '0') }}
