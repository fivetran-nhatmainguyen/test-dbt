-- Another distinctly new model/fqn, added for the same reason as customer_category_summary and
-- regional_sales_summary: `census_test.marts.product_performance_summary` has never existed at
-- any prior commit, so it's a clean "brand new model" precondition for Census's next refresh --
-- guaranteed to go through the create branch in `initialize_dbt_manifest_model`
-- (giza app/models/dbt_project.rb:379), not an update to an existing row.

select
    product_name,
    category,
    count(*) as times_ordered,
    sum(quantity) as total_units_sold,
    sum(order_total) as total_revenue
from {{ ref('int_order_totals') }}
group by 1, 2
