# AI-Assisted Prompting Log

This file records every prompt sent to a free AI chat assistant during this
project, structured against the five RCTCF elements (Role, Context, Task,
Constraints, Format), plus the concrete verification step actually performed
on the AI's suggested output before it was kept.

---

## Prompt 1 — Part 1, `03_reporting.sql` (Task 6c: target variance query)

**Assistant used:** Claude (Claude.ai / Claude Code, free-tier equivalent)

**Prompt (RCTCF):**

- **Role:** "You are a SQLite expert helping me debug an analytics query."
- **Context:** "I have a SQLite database `bigbasket_capstone.db` with an `orders` table (`amount_inr INTEGER`, `status TEXT`, `product_id`), a `products` table (`product_id`, `category TEXT`), and a `category_targets` table (`category TEXT PRIMARY KEY`, `target_revenue_inr INTEGER`). I'm computing, per category, total Delivered revenue vs. its target, and a percentage variance."
- **Task:** "Write a query that joins Delivered-order revenue (grouped by category) to `category_targets`, and computes `variance = target_revenue_inr - total_revenue` and `percentage_variance = ((total_revenue - target_revenue_inr) * 100) / target_revenue_inr`. My first attempt at `percentage_variance` keeps returning 0 for every row except when the variance is huge — explain why and fix it."
- **Constraints:** "Keep it as a single query (a CTE is fine). Both `total_revenue` and `target_revenue_inr` are INTEGER columns in SQLite — the fix must not change the underlying column types, only the query. Tag each row 'Above Target', 'Below Target - Watch' (shortfall ≤ 15%), or 'Below Target - Critical' (shortfall > 15%) using CASE WHEN."
- **Format:** "Return the corrected SQL query only, with a one-sentence explanation of the root cause above it."

**AI's diagnosis and fix:** SQLite performs integer division when both operands
of `/` are INTEGER columns, so `(total_revenue - target_revenue_inr) / target_revenue_inr`
truncates to `0` (or `-1`) *before* the `* 100` ever runs. The fix is to force
floating-point division by multiplying by `100.0` (a REAL literal) first —
`((total_revenue - target_revenue_inr) * 100.0) / target_revenue_inr` — so the
multiplication promotes the whole expression to REAL before division happens.

**Verification actually performed:** Ran the corrected query against
`bigbasket_capstone.db` and manually checked it by hand for two categories:
Dairy & Eggs (`total_revenue=14090`, `target=16500`) → expected
`((14090-16500)*100.0)/16500 = -14.606...`, which is exactly what the query
returned; and Bakery (`total_revenue=15410`, `target=12000`) → expected
`((15410-12000)*100.0)/12000 = 28.4166...`, also an exact match. Also
confirmed the pre-fix version (without the `.0`) returned `0` for both rows,
reproducing the bug before applying the fix. Cross-checked the six resulting
`target_status` tags against the tiering already stated in the assignment
brief (Above Target: Household Essentials, Personal Care, Bakery; Below
Target - Watch: Dairy & Eggs; Below Target - Critical: Snacks & Beverages,
Fruits & Vegetables) — all six matched.

---

## Prompt 2 — Part 4, `analysis.ipynb` (Section 5: IQR outlier capping)

**Assistant used:** Claude (Claude.ai / Claude Code, free-tier equivalent)

**Prompt (RCTCF):**

- **Role:** "You are a data-cleaning expert helping me write defensible outlier-handling code in Pandas."
- **Context:** "I have a Pandas DataFrame `orders` (from a messy raw CSV export) with columns `status` and `amount_inr` (some `amount_inr` values are `NaN`, i.e. unknown revenue). I need to flag orders whose `amount_inr` is abnormally high using the IQR method, computed only on Delivered, non-null orders."
- **Task:** "Show me how to compute Q1, Q3, IQR, and the upper fence with `.quantile()`, then cap (not drop) values above the fence with `.clip()`. Should I compute the fence from the whole `amount_inr` column or just Delivered orders? And should the fence be applied to the whole column or just Delivered rows?"
- **Constraints:** "Don't drop any rows — outliers must be capped, not removed, since Cancelled/Pending orders still matter for order-count analysis even if not for revenue. The NaN `amount_inr` rows must not break the `.quantile()`/`.clip()` calls."
- **Format:** "Give me the Pandas code plus a one-sentence explanation of why the fence should be computed on Delivered-only data."

**AI's guidance:** Compute Q1/Q3/IQR on `orders.loc[(status=='Delivered') & amount_inr.notna(), 'amount_inr']` specifically — mixing in Cancelled/Pending orders (which follow a different amount distribution in this dataset) or the NaN rows would skew the quartiles and produce a misleading fence; `.quantile()` already ignores NaNs by default so a `.notna()` filter is only needed to define the *Delivered-only* base population cleanly. Then apply `orders["amount_inr"].clip(upper=fence)` to the whole column (NaNs pass through `.clip()` unchanged) rather than dropping anything.

**Verification actually performed:** Ran the suggested code against `orders_raw.csv` after de-duplication and casing cleanup, printed `Q1=90.0, Q3=275.0, IQR=185.0, upper_fence=552.5`, then manually cross-checked 3 of the flagged rows by filtering `orders[orders["amount_inr"] > 552.5]` and confirming each one's `amount_inr_capped` value came back as exactly `552.5` after `.clip()` — not silently dropped, not left at its original (much higher) value. Also confirmed the total flagged-and-capped count (16 Delivered rows) is well above the 5 rows the generator script deliberately corrupted, which the assignment brief itself calls out as expected behavior for a real IQR fence — matching that stated expectation was itself a useful sanity check on the fix.
