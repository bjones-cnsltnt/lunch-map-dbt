# lunch-map-dbt

A small, complete dbt project: the restaurant data behind the
[Tulsa Lunch Map](https://lunch.jonesgroup.dev/) app, modeled into tested
dimensional marts with a reconciliation layer on top.

The app is a companion to a local TV station's weekly lunch segment. Each
record is one restaurant visit: what the host ordered, what it cost, where it
is, and the advertised specials. It is a tiny dataset (101 restaurants), which
is the point. Every modeling decision is readable in an afternoon and every
test runs in seconds.

```
python scripts/extract_spots.py   # optional: refresh the seed from the public feed
uv sync                            # installs dbt (v2) with the bundled DuckDB driver
uv run dbt build                   # seed -> unit tests -> models -> data tests
uv run dbt docs generate           # lineage and column docs in target/
```

No credentials, no warehouse account. `dbt build` writes a local DuckDB file
under `target/` and finishes in about three seconds.

## What is in here

| Layer | Models | What they do |
|---|---|---|
| seed | `raw_spots` | Snapshot of the app's public feed. The nested `metadata` object is kept as a JSON string so every parsing decision lives in SQL, not in the extract script. |
| staging | `stg_lunch__spots`, `stg_lunch__host_order_items`, `stg_lunch__guest_orders`, `stg_lunch__guest_order_items`, `stg_lunch__specials` | Unpack and type the JSON: price label to decimal, address to city/state/zip, video URL to YouTube id, receipts and specials exploded to one row per line. |
| intermediate | `int_receipt_items`, `int_receipts` | Host and guest receipts on one grain, with subtotal, tax and total. |
| marts | `dim_restaurant`, `dim_diner`, `dim_date`, `fct_episode`, `fct_receipt_line`, `fct_restaurant_special` | Star schema. Facts at episode grain, receipt-line grain and special grain, conformed on restaurant, diner and date. |
| audit | `audit_receipt_reconciliation`, `audit_record_quality` | Rebuild every receipt from its line items and reconcile it to the displayed price. List source records that need fixing. |

```
raw_spots
 ├─ stg_lunch__spots ──────────┬─ dim_restaurant
 │                             ├─ dim_date
 │                             ├─ fct_episode ────────── audit_receipt_reconciliation
 │                             └─ audit_record_quality
 ├─ stg_lunch__host_order_items ─┐
 ├─ stg_lunch__guest_orders ─────┼─ int_receipt_items ─┬─ int_receipts ─┬─ dim_diner
 │    └─ stg_lunch__guest_order_items ┘                 │                └─ fct_episode
 │                                                      └─ fct_receipt_line
 └─ stg_lunch__specials ─────────── fct_restaurant_special
```

## Tests

`dbt build` runs 97 data tests and 2 unit tests. The ones worth reading:

- **Unit tests** (`models/staging/_staging.yml`) pin the parsing rules with
  hand-written rows: a typical record parses to the expected city, state,
  zip, YouTube id and decimal price; an odd record degrades to nulls instead
  of errors; free-text special days ("Daily", "Tuesday", "Mon-Fri",
  "Veterans Day") normalize to a fixed set.
- **`within_range`** (`tests/generic/`) is a custom generic test used for
  coordinates, prices and ISO weekdays.
- **Relationships** tie every fact key to its dimension, so an orphaned
  restaurant or date fails the build.
- **`assert_host_receipt_totals_match_lines`** checks that the episode fact's
  subtotal equals the sum of its receipt lines to the cent. Two models that
  must agree are tested against each other, not just individually.
- **`assert_receipts_reconcile_to_price_label`** fails the build if any
  displayed price cannot be explained by the receipt.
- **`assert_no_record_quality_issues`** warns, never fails. It is the worklist.

## What the reconciliation found

The app shows one number per restaurant, the price label. The receipt behind
it is a list of items plus tax. Rebuilding every receipt and comparing:

| status | episodes |
|---|---|
| match (to the cent) | 5 |
| match_rounded (label = receipt rounded to the dollar) | 96 |
| mismatch | 0 |

So the label is a rounded total, not a stored one, and the rule holds for all
101 records. The largest variances are the ones you would expect from
rounding: a $6.50 receipt labeled $6, a $10.52 receipt labeled $11. That rule
is now written down in `audit_receipt_reconciliation` and enforced by a test,
which is the difference between "the numbers look right" and "the numbers are
right and will stay right."

The record-quality worklist currently holds 21 rows: 16 restaurants with no
cuisine recorded, 2 whose video link is not a YouTube watch URL, 1 whose
address does not fit the `street, City, ST 99999` pattern, 1 located just
across the Kansas line, and 1 free meal with a $0 label. None of those are
wrong, exactly, which is why they warn instead of fail.

## Design notes

- **Seed, not source.** The real table is Postgres on Supabase. For a public,
  credential-free repo the extract script snapshots the public feed into a
  seed, and dbt treats that as the raw layer. Swapping in the live table is a
  `source:` block and an `attach:` entry in `profiles.yml`; the staging models
  do not change.
- **JSON parsed in SQL.** The extract keeps `metadata` opaque on purpose. The
  struct shapes are declared once in `macros/json_types.sql`, and the staging
  models own every parsing rule, so the rules show up in lineage, docs and
  unit tests.
- **Dimensional marts.** `fct_episode` is the grain people ask questions at
  (what did lunch cost in Owasso last fall), `fct_receipt_line` is the grain
  the data is actually recorded at, and both conform on `dim_restaurant`,
  `dim_date` and `dim_diner`. `dim_date` is generated to cover the full years
  in the data so date joins never drop rows.
- **Audit models are models.** Reconciliation results are materialized tables
  with a status column, not just a pass/fail test. The test reads the model.
  That way the detail is queryable when something does fail.
- **dbt v2 with DuckDB.** Installed with `uv sync`; the DuckDB driver is
  bundled. The YAML uses the v2 `arguments:` form for generic tests and
  `dbt lint` runs clean against the included `.sqlfluff`.

## Layout

```
dbt_project.yml        project config: seed column types, per-layer materializations and schemas
profiles.yml           local DuckDB target (checked in; nothing secret)
seeds/raw_spots.csv    101 rows, regenerated by scripts/extract_spots.py
models/                staging/ intermediate/ marts/ audit/, each with a _layer.yml of docs and tests
macros/                JSON struct types, cuisine grouping, special-day normalization
tests/                 singular tests and the within_range generic test
.github/workflows/     dbt build + docs on every push
```
