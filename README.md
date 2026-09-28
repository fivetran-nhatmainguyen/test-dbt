# test-dbt

A small, self-contained dbt project used to exercise Census's [dbt Projects
feature](https://docs.getdbt.com/docs). It runs against Postgres and seeds its own
fixture data, so it doesn't depend on any other warehouse tables.

## Layout

```
census_test/                 # the dbt project itself, in a subdirectory
├── dbt_project.yml
├── packages.yml              # dbt_utils, to exercise `dbt deps`
├── seeds/                    # fixture data: customers, orders, products
├── models/
│   ├── staging/               # stg_customers, stg_orders, stg_products (views)
│   ├── intermediate/          # int_order_totals (ephemeral)
│   └── marts/                 # customers, orders (table); customer_events (incremental);
│                               # active_customers (view) -- tagged `census`
└── macros/
    └── generate_schema_name.sql   # kept alone in its own file (see note below)
```

## What this tests

Census only ever runs `dbt deps` and `dbt compile` against this repo -- it never runs
`dbt run` or `dbt seed`. That means:

- **table / view / incremental models** (everything in `marts/` and `staging/`) must
  already be materialized in the warehouse. Census just does `SELECT * FROM <relation>`
  against whatever dbt built there. **You need to run `dbt seed` and `dbt build` yourself**
  before connecting the project in Census, and again after any change to seed data or model
  logic that should show up in Census.
- **ephemeral models** (`int_order_totals`) are never materialized. Census instead reads
  the compiled SQL out of the manifest and inlines it as the model's query directly.

Other things this project is set up to test:

| Feature | Where |
|---|---|
| Model selector | Marts are tagged `census` -- try a selector of `tag:census`, `models/marts/*`, or `*` |
| Materializations | table (`customers`, `orders`), view (`active_customers`), incremental (`customer_events`), ephemeral (`int_order_totals`) |
| Column descriptions & PII | `email`/`phone` marked `meta: {contains_pii: true}` in `_staging.yml` / `_marts.yml` |
| `dbt deps` | `orders.sql` uses `dbt_utils.generate_surrogate_key` |
| Environment variables | `int_order_totals.sql` reads `env_var('CENSUS_TEST_MIN_ORDER', '0')` |
| dbt version pinning | `require-dbt-version: ">=1.7.0,<1.11.0"` in `dbt_project.yml` |
| Duplicate-macro failure | `generate_schema_name.sql` is deliberately alone in its own file -- Census's compile step fails if two macros of the same name exist in one file, so don't add another macro to that file |

## Running it locally

You'll need a local (or reachable) Postgres instance and `dbt-postgres` installed:

```bash
pip install "dbt-postgres>=1.7,<1.11"
```

Copy `profiles.example.yml` somewhere dbt will find it (e.g. `~/.dbt/profiles.yml`) and
fill in your Postgres credentials. **This file is not used by Census** -- Census generates
its own `profiles.yml` at compile time from the source connection configured in its UI.
It's only here so you can build the fixture data locally.

```bash
cd census_test
dbt deps
dbt seed      # loads seeds/*.csv into raw_customers, raw_orders, raw_products
dbt build     # materializes staging + mart models, runs tests
```

## Connecting it to Census

1. **Push this repo to GitHub** and install/authorize the Census GitHub app on it.
2. **Grant the Postgres user Census will use** `USAGE` on the `census_test` schema and
   `SELECT` on its tables (Census only ever reads).
3. **Create a Postgres source connection** in Census pointing at this database.
4. **Create a dbt project** in Census:
   - Repo: this repo, branch `main`.
   - Project path: `census_test` (the dbt project lives in a subdirectory, not the repo
     root -- this exercises Census's embedded-project-path setting).
   - Source connection: the Postgres connection from step 3.
   - Default table catalog: your database name.
   - Default schema: `census_test`.
   - Model selector: `tag:census` (or `*` to publish everything, or `models/marts/*`).
   - Environment variable (optional): `CENSUS_TEST_MIN_ORDER` = e.g. `50`, to test that
     Census's compile step passes env vars through correctly.
5. **Refresh the project.** Census should show `customers`, `orders`, `customer_events`,
   and `active_customers` (if selected) with their descriptions and PII-flagged columns,
   and you should be able to build a sync from `customers`.

### Things to try afterward

- Change the selector and refresh -- confirm the right models appear/disappear.
- Remove or rename a mart that a sync depends on and refresh -- check
  `DbtProject#broken_syncs` surfaces it.
- Change `dbt_force_version` in the Census project and refresh.
- Push a commit that breaks a model (e.g. a typo in a `ref()`) and open a PR, if dbt
  checks / CI is configured, to see the check run fail.
