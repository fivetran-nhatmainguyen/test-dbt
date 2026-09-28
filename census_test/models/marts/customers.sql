-- Table model (default materialization for marts/, see dbt_project.yml). Census will
-- `SELECT *` from the materialized `customers` relation once dbt has built it.

with customers as (
    select * from {{ ref('stg_customers') }}
),

order_totals as (
    select
        customer_id,
        count(*) as order_count,
        sum(order_total) as lifetime_value,
        max(order_date) as most_recent_order_date
    from {{ ref('int_order_totals') }}
    where status = 'completed'
    group by 1
)

select
    customers.customer_id,
    customers.first_name,
    customers.last_name,
    customers.email,
    customers.phone,
    customers.created_at,
    coalesce(order_totals.order_count, 0) as order_count,
    coalesce(order_totals.lifetime_value, 0) as lifetime_value,
    order_totals.most_recent_order_date
from customers
left join order_totals on customers.customer_id = order_totals.customer_id
