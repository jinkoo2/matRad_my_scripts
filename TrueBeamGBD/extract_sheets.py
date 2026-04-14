import pandas as pd
import os
import glob

base_dir = os.path.dirname(os.path.abspath(__file__))

xlsx_files = glob.glob(os.path.join(base_dir, "*.xlsx"))

for xlsx_path in sorted(xlsx_files):
    filename = os.path.basename(xlsx_path)
    # Skip temp/lock files
    if filename.startswith("~$"):
        print(f"Skipping lock file: {filename}")
        continue

    folder_name = os.path.splitext(filename)[0]
    out_dir = os.path.join(base_dir, folder_name)
    os.makedirs(out_dir, exist_ok=True)

    print(f"\nProcessing: {filename}")
    xl = pd.ExcelFile(xlsx_path)
    for sheet in xl.sheet_names:
        df = xl.parse(sheet, header=None)
        # Sanitize sheet name for use as filename
        safe_name = sheet.replace("/", "-").replace("\\", "-").replace(":", "-")
        csv_path = os.path.join(out_dir, f"{safe_name}.csv")
        df.to_csv(csv_path, index=False, header=False)
        print(f"  -> {safe_name}.csv")

print("\nDone.")
