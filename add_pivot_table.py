"""
add_pivot_table.py
Step 2 of 3. Run this AFTER build_xlsx.py, against the same
capstone_spreadsheet.xlsx (which at this point holds only "Monthly Data"
and "Category Targets" — Category Summary is added afterwards, in step 3,
by add_category_summary.py).

openpyxl (used by build_xlsx.py) cannot author a native OOXML PivotTable
object — only formula lookalikes. Part 2's brief explicitly requires
"Build a Pivot Table from Monthly Data: Rows = category, Values = SUM of
total_revenue (and, separately, SUM of order_count)" — a real PivotTable
feature.

This script drives LibreOffice Calc headlessly over the UNO bridge to insert
a genuine native pivot table (LibreOffice/Excel call this a "DataPilot"
internally) into a new "Pivot Table" sheet, sourced from the "Monthly Data"
sheet, with:
    Row field:   category
    Data fields: Sum - total_revenue, Sum - order_count (laid out as two
                 side-by-side columns, not stacked, via the "Data"
                 pseudo-field's own COLUMN orientation — see below)
Deliberately run BEFORE Category Summary exists: Category Summary's
formulas look up this sheet by name, and LibreOffice resolves sheet
references at parse (load) time — if it ever opened a file where
Category Summary already referenced "Pivot Table" before that sheet was
created, the reference would be parsed as broken and stay broken even
after the sheet is added later in the same run. Keeping this sheet's
creation in its own file generation, before Category Summary is written,
avoids that failure mode entirely (see ai_log.md).

Usage:
    soffice --headless --invisible --nocrashreport --nodefault --norestore \
        --nologo --nofirststartwizard \
        --accept="socket,host=localhost,port=2002;urp;" &
    sleep 6
    python3 add_pivot_table.py
"""
import sys

sys.path.insert(0, "/usr/lib/python3/dist-packages")
sys.path.insert(0, "/usr/lib/libreoffice/program")

import uno
from com.sun.star.beans import PropertyValue
from com.sun.star.sheet.DataPilotFieldOrientation import ROW, DATA, COLUMN
from com.sun.star.sheet.GeneralFunction import SUM
from com.sun.star.table import CellAddress, CellRangeAddress

XLSX_PATH = "/home/claude/capstone-project/capstone_spreadsheet.xlsx"


def make_prop(name, value):
    p = PropertyValue()
    p.Name = name
    p.Value = value
    return p


def main():
    local_ctx = uno.getComponentContext()
    resolver = local_ctx.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", local_ctx
    )
    ctx = resolver.resolve(
        "uno:socket,host=localhost,port=2002;urp;StarOffice.ComponentContext"
    )
    smgr = ctx.ServiceManager
    desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)

    url = uno.systemPathToFileUrl(XLSX_PATH)
    doc = desktop.loadComponentFromURL(url, "_blank", 0, (make_prop("Hidden", True),))

    sheets = doc.getSheets()
    monthly = sheets.getByName("Monthly Data")
    cursor = monthly.createCursor()
    cursor.gotoEndOfUsedArea(False)
    end_addr = cursor.getRangeAddress()  # header row is row 0

    if sheets.hasByName("Pivot Table"):
        sheets.removeByName("Pivot Table")
    sheets.insertNewByName("Pivot Table", 2)
    out_sheet = sheets.getByName("Pivot Table")

    src_range = CellRangeAddress()
    src_range.Sheet = monthly.RangeAddress.Sheet
    src_range.StartColumn = 0
    src_range.StartRow = 0
    src_range.EndColumn = end_addr.EndColumn
    src_range.EndRow = end_addr.EndRow

    dp_tables = out_sheet.DataPilotTables
    dp_desc = dp_tables.createDataPilotDescriptor()
    dp_desc.SourceRange = src_range

    fields = dp_desc.DataPilotFields
    fields.getByName("category").Orientation = ROW
    rev_field = fields.getByName("total_revenue")
    rev_field.Orientation = DATA
    rev_field.Function = SUM
    cnt_field = fields.getByName("order_count")
    cnt_field.Orientation = DATA
    cnt_field.Function = SUM

    # With two DATA fields, Calc's DataPilot has a hidden "Data" pseudo-field
    # whose own orientation decides whether the two measures stack vertically
    # (default) or sit side-by-side as separate columns. COLUMN gives a clean
    # one-row-per-category layout (category, SUM total_revenue, SUM order_count)
    # so the sheet can be referenced directly by a per-category VLOOKUP.
    fields.getByName("Data").Orientation = COLUMN

    out_addr = CellAddress()
    out_addr.Sheet = out_sheet.RangeAddress.Sheet
    out_addr.Column = 0
    out_addr.Row = 0
    dp_tables.insertNewByName("CategoryRevenuePivot", out_addr, dp_desc)

    doc.calculateAll()
    doc.storeToURL(url, (make_prop("FilterName", "Calc MS Excel 2007 XML"),))
    doc.close(False)
    print("Native Pivot Table sheet added to", XLSX_PATH)


if __name__ == "__main__":
    main()
