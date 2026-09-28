-- Incremental model. Census treats this the same as `table` (SELECT * from the
-- materialized relation) -- it's here to confirm Census can compile a project that
-- mixes materializations without erroring, and that `is_incremental()` doesn't
-- break a first-time compile (Census never runs `dbt run`, so this only ever
-- executes the non-incremental branch when you build it yourself).

{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

select
    order_id,
    customer_id,
    status,
    order_date,
    order_total
from {{ ref('int_order_totals') }}

{% if is_incremental() %}
where order_date > (select coalesce(max(order_date), '1900-01-01') from {{ this }})
{% endif %}
