"""
build_xlsx.py
Step 1 of 3 in building capstone_spreadsheet.xlsx (the Part 2 deliverable,
an exact mirror of the Part 2 Google Sheet: Monthly Data, Category Targets,
Pivot Table, Category Summary).

This script writes only "Monthly Data" (verbatim copy of
monthly_category_revenue.csv) and "Category Targets". It deliberately does
NOT write "Category Summary" here, because that sheet's formulas reference
the "Pivot Table" sheet, which does not exist until add_pivot_table.py (step
2) creates it — openpyxl cannot author a native OOXML PivotTable object
itself, so a separate LibreOffice/UNO pass is required for that sheet.
Writing Category Summary before "Pivot Table" exists would let LibreOffice
mis-parse the forward reference when it later opens the file (a real bug
hit and fixed during development — see ai_log.md).

Full build order:
    python3 build_xlsx.py            # this script: Monthly Data, Category Targets
    python3 add_pivot_table.py       # LibreOffice/UNO: native "Pivot Table" sheet
    python3 add_category_summary.py  # openpyxl: "Category Summary" sheet + formulas
"""
import csv
from openpyxl import Workbook

wb = Workbook()

# ------------------------------------------------------------------
# Sheet 1: Monthly Data (verbatim copy of monthly_category_revenue.csv)
# ------------------------------------------------------------------
ws1 = wb.active
ws1.title = "Monthly Data"

with open("monthly_category_revenue.csv", newline="") as f:
    reader = csv.reader(f)
    rows = list(reader)

for r_idx, row in enumerate(rows, start=1):
    for c_idx, val in enumerate(row, start=1):
        if r_idx == 1:
            ws1.cell(row=r_idx, column=c_idx, value=val)
        else:
            # numeric columns: order_count (3), total_revenue (4), avg_revenue (5)
            if c_idx in (3, 4, 5):
                ws1.cell(row=r_idx, column=c_idx, value=float(val) if "." in val else int(val))
            else:
                ws1.cell(row=r_idx, column=c_idx, value=val)

from openpyxl.styles import Font
header_font = Font(bold=True)
for c_idx in range(1, 6):
    ws1.cell(row=1, column=c_idx).font = header_font
for col, width in zip("ABCDE", (22, 12, 13, 15, 14)):
    ws1.column_dimensions[col].width = width

n_data_rows = len(rows) - 1  # 36

# ------------------------------------------------------------------
# Sheet 2: Category Targets
# ------------------------------------------------------------------
ws2 = wb.create_sheet("Category Targets")
targets = [
    ("Fruits & Vegetables", 12000),
    ("Dairy & Eggs", 16500),
    ("Snacks & Beverages", 13000),
    ("Personal Care", 15500),
    ("Household Essentials", 17000),
    ("Bakery", 12000),
]
ws2.append(["category", "target_revenue_inr"])
for cat, tgt in targets:
    ws2.append([cat, tgt])
for c_idx in range(1, 3):
    ws2.cell(row=1, column=c_idx).font = header_font
ws2.column_dimensions["A"].width = 22
ws2.column_dimensions["B"].width = 18

wb.save("capstone_spreadsheet.xlsx")
print("Saved capstone_spreadsheet.xlsx (Monthly Data, Category Targets)")
