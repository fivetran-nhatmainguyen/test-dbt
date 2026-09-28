-- Table model that depends on the dbt_utils package (exercises `dbt deps`).

select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'product_name']) }} as order_line_id,
    order_id,
    customer_id,
    product_name,
    category,
    status,
    quantity,
    price,
    order_total,
    order_date
from {{ ref('int_order_totals') }}
