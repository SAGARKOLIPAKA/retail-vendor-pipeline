import os
from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv

# ── Config ────────────────────────────────────────────────────────────────────
load_dotenv()

CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
CONTAINER_NAME    = "bronze"
DATA_DIR          = os.path.join(os.path.dirname(__file__), "../data/raw")

FILES = [
    "purchases.csv",
    "sales.csv",
    "begin_inventory.csv",
    "end_inventory.csv",
    "purchase_prices.csv",
    "vendor_invoice.csv",
    "vendor_sales_summary.csv",
]

# ── Upload ────────────────────────────────────────────────────────────────────
def upload_to_bronze():
    client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
    container = client.get_container_client(CONTAINER_NAME)

    print(f"Uploading to Bronze container: {CONTAINER_NAME}\n")

    for filename in FILES:
        filepath = os.path.join(DATA_DIR, filename)
        blob_path = f"raw/{filename}"

        print(f"  Uploading {filename}...", end=" ")

        with open(filepath, "rb") as data:
            container.upload_blob(
                name=blob_path,
                data=data,
                overwrite=True
            )
        print("✓")

    print("\nAll files uploaded to Bronze layer successfully.")

if __name__ == "__main__":
    upload_to_bronze()