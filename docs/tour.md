# A 30-minute tour

Read in this order. Each stop says what to look at and what to notice. Run the
commands as you go; the project builds in seconds, so experimenting is cheap.

## 1. The raw row  (`seeds/raw_spots.csv`)

Open the file and read one row to the end. Seven flat columns and one
`metadata` column holding a JSON object with nested arrays (`ron_order`,
`restaurant_specials`, `guest_orders`). Everything downstream exists to turn
that one blob into typed, tested tables.

```
uv run dbt show --inline "select name, price_label, metadata from {{ ref('raw_spots') }}" --limit 2
```

## 2. The project config  (`dbt_project.yml`)

Notice three things: the seed's column types are pinned so DuckDB never
guesses, each layer gets its own materialization (views for staging and
intermediate, tables for marts and audit), and each layer lands in its own
schema (`main_staging`, `main_marts`, ...). That naming convention is what
makes `dbt build --select marts` meaningful.

## 3. Parsing scalars  (`models/staging/stg_lunch__spots.sql`)

Three CTEs: `source`, `typed`, `parsed`. The JSON operators `->` (returns
JSON) and `->>` (returns text) pull fields out; `regexp_extract` with a group
number splits the address; `try_cast` turns bad input into null instead of a
failed build. Every column here is named for what it means, not what the
source called it (`ron_order` becomes `host_item_count`).

```
uv run dbt show --select stg_lunch__spots --limit 3
```

## 4. Pinning the parsing rules  (`models/staging/_staging.yml`, bottom)

The two `unit_tests` blocks feed hand-written rows into the model and assert
the output. The second row is deliberately odd: a non-YouTube link, an
address that doesn't match, a $0 label. Read the `expect` rows and you know
exactly how the model degrades.

```
uv run dbt test --select "test_type:unit"
```

## 5. Exploding arrays  (`models/staging/stg_lunch__host_order_items.sql`)

`from_json(..., '[{"item_name":"VARCHAR", ...}]')` turns the JSON array into
a typed list of structs. `unnest()` makes one row per element and
`generate_subscripts()` numbers them. The struct type string lives in
`macros/json_types.sql` so the three exploding models share it.

## 6. One grain for receipts  (`models/intermediate/int_receipts.sql`)

Host receipts and guest receipts are stored differently in the source. This
model puts them on one grain (receipt = episode x diner) and attaches item
count, subtotal, tax and total. Marts never have to know the source stored
guests inside the host's record.

## 7. The star  (`models/marts/`)

`fct_episode` is the grain people ask questions at: one restaurant on one
date, with the host's receipt as measures. `fct_receipt_line` is the grain
the data is recorded at. Both carry `restaurant_key`, `date_key` and (for
lines) `diner_key`, and the `relationships` tests in `_marts.yml` guarantee
every key resolves. `dim_date` is generated, not loaded, so it always covers
the data.

```
uv run dbt show --inline "
  select d.month_name, count(*) as episodes, round(avg(e.host_total_usd), 2) as avg_lunch
  from {{ ref('fct_episode') }} e join {{ ref('dim_date') }} d on e.date_key = d.date_key
  group by 1, d.month_number order by d.month_number"
```

## 8. Reconciliation  (`models/audit/audit_receipt_reconciliation.sql`)

Rebuild the receipt from lines plus tax, compare to the displayed label,
classify. Then look at `tests/assert_receipts_reconcile_to_price_label.sql`:
the test is a one-line query against that model. Detail stays queryable when
something fails; the test just decides whether the build is green.

```
uv run dbt show --inline "select reconciliation_status, count(*) from {{ ref('audit_receipt_reconciliation') }} group by 1"
```

## 9. Three kinds of tests

- **Generic** tests are parameterized and reused: `not_null`, `unique`,
  `relationships`, `accepted_values`, and the custom `within_range` in
  `tests/generic/`.
- **Singular** tests are one SQL file each in `tests/`; any rows returned is
  a failure. `assert_no_record_quality_issues` sets `severity: warn`.
- **Unit** tests check a model's logic against fixed inputs without touching
  real data.

## 10. Rendered SQL and docs

dbt is a compiler. See what it produced:

```
uv run dbt compile --select fct_episode
cat target/compiled/lunch_map/models/marts/fct_episode.sql
uv run dbt docs generate && uv run dbt docs serve
```

The docs site shows lineage, every column description from the `_*.yml`
files, and which tests cover which columns.
