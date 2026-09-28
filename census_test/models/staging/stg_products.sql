with source as (
    select * from {{ ref('raw_products') }}
)

select
    id as product_id,
    name as product_name,
    category,
    price
from source
