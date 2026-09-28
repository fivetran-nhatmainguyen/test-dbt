with source as (
    select * from {{ ref('raw_orders') }}
)

select
    id as order_id,
    customer_id,
    product_id,
    status,
    quantity,
    order_date
from source
