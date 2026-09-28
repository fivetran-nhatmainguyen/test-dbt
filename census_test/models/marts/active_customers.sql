-- View model, overriding the marts/ default (table).

{{ config(materialized='view') }}

select
    customer_id,
    first_name,
    last_name,
    email,
    order_count,
    lifetime_value
from {{ ref('customers') }}
where order_count > 0
