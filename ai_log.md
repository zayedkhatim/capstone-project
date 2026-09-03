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

## Prompt 2 — Part 4, Pandas cleaning code (to be added when Part 4 is built)

_Reserved — Part 4 (IQR outlier capping / merge debugging) has not been
started yet. This section will be filled in with its own RCTCF prompt and
its own concrete verification step once that part is built, per the brief's
requirement of two prompts total across the whole project._
