-- Deliberately added AFTER the project's first refresh, to exercise the "brand new fqn"
-- path in Census's `initialize_dbt_manifest_model` (giza app/models/dbt_project.rb:379):
-- `census_test.marts.customer_category_summary` has never had a `Model` row before, so the
-- first refresh_models call that picks this up goes through the create branch, not an update
-- of an existing row. Tagged `census` via the marts/ default in dbt_project.yml.

select
    customer_id,
    category,
    count(*) as order_count,
    sum(order_total) as category_total
from {{ ref('orders') }}
group by 1, 2
