-- A distinctly new model/fqn (never previously in any commit), added specifically to guarantee
-- Census's next refresh_models hits the "create" branch in `initialize_dbt_manifest_model`
-- (giza app/models/dbt_project.rb:379) rather than finding/updating an existing Model row.
-- `census_test.marts.regional_sales_summary` has never existed at any prior commit, so there's
-- no ambiguity about whether a Model row for it might already exist from an earlier successful
-- refresh -- this is the cleanest precondition for testing whether two concurrent
-- refresh_models calls produce duplicate Model rows sharing this name.

select
    category,
    count(*) as order_count,
    sum(order_total) as total_sales,
    count(distinct customer_id) as distinct_customers
from {{ ref('orders') }}
group by 1
