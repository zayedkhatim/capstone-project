# BigBasket Category Performance Diagnostic

A four-part capstone analyzing category-level sales performance for a
BigBasket-style grocery delivery business, built entirely on one deterministic
synthetic dataset (`generate_data.py`, `random.seed(42)`). The project traces
the same numbers through SQL, Google Sheets/Excel, Tableau, and Python/Pandas
so every part reconciles against the same source of truth: six product
categories are measured against category-level revenue targets, tiered into
**Above Target**, **Below Target - Watch** (shortfall ≤ 15%), and
**Below Target - Critical** (shortfall > 15%), to flag where the business is
winning and where it needs to act.

## Live Tableau Public dashboard

**https://public.tableau.com/app/profile/masai.user/viz/BigBasketCategoryPerformanceDiagnostic/Dashboard1**

## File structure

| File | Part | Description |
|---|---|---|
| `generate_data.py` | Setup | Deterministic data generator (`random.seed(42)`). Creates `bigbasket_capstone.db` (SQLite) and the raw CSV exports below. Re-run it any time to reproduce the exact same dataset. |
| `orders_raw.csv`, `products.csv` | Setup | Raw CSV exports used as the messy input for the Part 4 cleaning notebook. |
| `bigbasket_capstone.db` | Part 1 | SQLite database: `products`, `customers`, `orders`, `category_targets` tables. |
| `01_foundations.sql` | Part 1 | Foundational SQL — `SELECT`/`WHERE`, `DISTINCT`, `ORDER BY`/`LIMIT`, aliasing, `IN`, `BETWEEN`/`NOT BETWEEN`, `IS NULL`. |
| `02_aggregation_joins.sql` | Part 1 | `INNER JOIN` + `GROUP BY`/`HAVING` category revenue report; `LEFT JOIN` products→orders order counts (including zero-order products). |
| `03_reporting.sql` | Part 1 | `CASE WHEN` revenue tiering; the monthly category report exported verbatim to `monthly_category_revenue.csv`; the target-variance query (category revenue vs. `category_targets`, with the SQLite integer-division fix). |
| `verify.sql`, `verify_output.txt` | Part 1 | Standalone sanity-check queries and their captured output, used to cross-check the Part 1 numbers while building Parts 2–4. |
| `monthly_category_revenue.csv` | Part 1 → 2/3 | Output of the Part 1 monthly report query; the single source feeding the Google Sheet, `capstone_spreadsheet.xlsx`, and the Tableau workbook. |
| `build_xlsx.py`, `add_pivot_table.py`, `add_category_summary.py`, `capstone_spreadsheet.xlsx` | Part 2 | `capstone_spreadsheet.xlsx` is an exact, live-formula mirror of the Part 2 Google Sheet (Monthly Data, Category Targets, Pivot Table, Category Summary with conditional formatting), built in three steps: `build_xlsx.py` (openpyxl) writes Monthly Data and Category Targets; `add_pivot_table.py` drives LibreOffice headlessly to insert a genuine native PivotTable object (the `Pivot Table` sheet — openpyxl alone can't author a real OOXML PivotTable, only formula lookalikes); `add_category_summary.py` (openpyxl) then adds Category Summary, whose `total_revenue`/`order_count` formulas look up that native Pivot Table directly — there is no separate formula-only "pivot" sheet standing in for it. |
| *(Tableau Public workbook)* | Part 3 | Hosted on Tableau Public — see the live link above. Built from `monthly_category_revenue.csv`. |
| `analysis.ipynb` | Part 4 | Pandas cleaning + analysis notebook: dedup/casing cleanup on `orders_raw.csv`, IQR-based outlier capping on `amount_inr`, and category-level reconciliation against the Part 1 SQL totals. |
| `ai_log.md` | All parts | RCTCF-structured log of every AI-assistant prompt used on this project, with the AI's suggested fix and the concrete verification performed before keeping it. |

## Regenerating the database

The entire project is reproducible from one script:

```bash
python generate_data.py
```

This rebuilds `bigbasket_capstone.db` from scratch (drops and recreates all
four tables) and is seeded with `random.seed(42)`, so every run produces
byte-identical data — the same orders, the same categories, the same
`monthly_category_revenue.csv` export, and therefore the same numbers in the
Sheet, the spreadsheet, the Tableau dashboard, and the notebook.

`capstone_spreadsheet.xlsx` is rebuilt the same way, in three steps (each
script's header explains why the order matters):

```bash
python build_xlsx.py           # writes Monthly Data / Category Targets
python add_pivot_table.py      # adds the native "Pivot Table" sheet via LibreOffice
python add_category_summary.py # adds Category Summary, formulas referencing the native Pivot Table
```

## Part 1 — SQL

Run `01_foundations.sql`, `02_aggregation_joins.sql`, and `03_reporting.sql`
against `bigbasket_capstone.db` in order. `03_reporting.sql` task 6(b) is the
query whose output is exported unmodified as `monthly_category_revenue.csv`;
task 6(c) is the target-variance query that every later part (Sheets, Excel,
Tableau) reconciles against. `verify.sql` / `verify_output.txt` hold the
sanity checks used to confirm those totals.

## Part 2 — Spreadsheet

`capstone_spreadsheet.xlsx` (built by `build_xlsx.py`, then
`add_pivot_table.py`, then `add_category_summary.py`) mirrors the Part 2
Google Sheet: a `Monthly Data` sheet (verbatim copy of
`monthly_category_revenue.csv`), `Category Targets`, a genuine native
**`Pivot Table`** sheet (category in Rows, `Sum of total_revenue` and
`Sum of order_count` side by side in Values — a real PivotTable object, not
a formula simulation), and a `Category Summary` sheet whose `total_revenue`
and `order_count` columns are `VLOOKUP` formulas reading directly from that
native Pivot Table (`=VLOOKUP(A2,'Pivot Table'!A:C,2,FALSE)`, and column 3
for order count) — there is no separate formula-only "pivot" sheet standing
in for it. `target_revenue_inr` is a genuine `XLOOKUP` against
`Category Targets`, using XLOOKUP's own not-found argument
(`=XLOOKUP(A2,'Category Targets'!A:A,'Category Targets'!B:B,"Not Found")`)
rather than a defensive `IFERROR`/`VLOOKUP` fallback wrapper. Variance,
percentage variance, and target status are then derived from those two
columns with `IF` formulas, colour-coded green/amber/red by conditional
formatting, and cross-checked cell-by-cell against the Part 1 SQL totals
(`Matches Part 1 SQL total?` = Yes on all 6 rows).

## Part 3 — Tableau

The dashboard (see the live link above) combines, in one floating-layout
Dashboard:

- **Monthly Revenue Trend (All Categories Combined)** — a single time-series
  line of `SUM(total_revenue)` by month across all 6 categories combined,
  covering the full Jan–Jun 2026 range.
- **Category Revenue** — a bar chart of Total Revenue by Category, sorted
  descending, colour-coded by Target Status (green = Above Target,
  amber = Below Target - Watch, red = Below Target - Critical).
- Four KPI cards: **Total Revenue**, **Total Delivered Orders**,
  **Average Order Value**, and **Categories Meeting Target** — all currency
  values formatted in ₹ (INR).
- A visible Target Status colour legend and a dashboard-wide **filter
  action**: clicking a category on the bar chart interactively filters every
  other sheet on the dashboard (including re-scoping the trend line to that
  one category); clicking again / clicking empty space clears the selection
  and restores all values.

### Data story

- **Total Revenue is ₹88,282** across **434** Delivered orders, for an
  **Average Order Value of ₹203.41**. Only **3 of 6 categories** are meeting
  their revenue target: Household Essentials (₹21,715 vs. a ₹17,000 target,
  +₹4,715 / +27.7%), Bakery (₹15,410 vs. ₹12,000, +₹3,410 / +28.4%), and
  Personal Care (₹16,382 vs. ₹15,500, +₹882 / +5.7%). The other three sit
  below target by ₹2,210 (Fruits & Vegetables), ₹2,105 (Snacks & Beverages),
  and ₹2,410 (Dairy & Eggs) — see the two recommendations below.
- **Recommendation 1 — fix the two "Below Target - Critical" categories
  first.** Fruits & Vegetables (₹9,790 vs. a ₹12,000 target, -18.4%) and
  Snacks & Beverages (₹10,895 vs. ₹13,000, -16.2%) are not only the two
  furthest below target, they are also the two lowest-revenue categories in
  absolute terms — a combined ₹4,315 shortfall against a combined ₹25,000
  target. The category team should prioritize these two categories for
  corrective review and measure the next reporting period specifically
  against their ₹2,210 and ₹2,105 revenue gaps before moving attention to
  the Watch category.
- **Recommendation 2 — Prioritize Dairy & Eggs as the nearest recovery
  opportunity.** It is only ₹2,410 below its ₹16,500 target (-14.6%),
  substantially closer to target than either critical category
  (Fruits & Vegetables at -18.4%, Snacks & Beverages at -16.2%). A focused
  category-level sales initiative should therefore be the next recovery
  initiative after the two Critical categories, with the objective of
  closing the ₹2,410 gap.

## Part 4 — Python / Pandas

See `analysis.ipynb`. It cleans `orders_raw.csv` (deduplication, casing
normalization), applies IQR-based outlier capping to `amount_inr` computed
on Delivered, non-null orders only (fence computed on the Delivered
population, then applied via `.clip()` to the whole column so Cancelled/
Pending rows are preserved for order-count analysis), and reconciles the
resulting category totals against the Part 1 SQL output.

## AI-assisted prompting log

`ai_log.md` documents every prompt sent to an AI assistant during this
project (the SQLite integer-division fix in Part 1, and the IQR
outlier-capping approach in Part 4), each structured with Role/Context/Task/
Constraints/Format and the concrete verification step performed on the
suggested output before it was kept.
