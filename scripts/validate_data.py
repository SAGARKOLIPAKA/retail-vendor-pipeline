import pandas as pd
import os

# ── Config ────────────────────────────────────────────────────────────────────
DATA_DIR = os.path.join(os.path.dirname(__file__), "../data/raw")

FILES = [
    "purchases.csv",
    "sales.csv",
    "begin_inventory.csv",
    "end_inventory.csv",
    "purchase_prices.csv",
    "vendor_invoice.csv",
    "vendor_sales_summary.csv",
]

# ── Helpers ───────────────────────────────────────────────────────────────────
def separator(title):
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60)

# ── Main validation ───────────────────────────────────────────────────────────
def validate_all():
    for filename in FILES:
        filepath = os.path.join(DATA_DIR, filename)
        df = pd.read_csv(filepath)

        separator(filename)
        print(f"  Rows        : {df.shape[0]:,}")
        print(f"  Columns     : {df.shape[1]}")
        print(f"\n  Column Names & Types:")
        for col, dtype in df.dtypes.items():
            null_count = df[col].isnull().sum()
            null_pct = (null_count / len(df)) * 100
            print(f"    {col:<35} {str(dtype):<12} nulls: {null_count} ({null_pct:.1f}%)")

        print(f"\n  Sample (first 2 rows):")
        print(df.head(2).to_string(index=False))

if __name__ == "__main__":
    validate_all()