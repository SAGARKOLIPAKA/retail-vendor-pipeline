# Retail Vendor Analytics Pipeline

A production-grade Azure data pipeline that processes 15.8M rows of retail vendor data using the Medallion Architecture (Bronze → Silver → Gold).

## Architectur## Tech Stack

| Layer | Technology |
|-------|-----------|
| Ingestion | Python + azure-storage-blob SDK |
| Bronze Storage | Azure Blob Storage |
| Transformation | Azure Data Factory (Data Flows) |
| Gold Storage | Azure SQL Database (Free Tier) |
| Orchestration | ADF Pipeline (pl_vendor_analytics) |
| Infrastructure as Code | ARM Templates |
| Version Control | GitHub |

## Dataset

Source: [Vendor Performance Analysis](https://www.kaggle.com/datasets/harshmadhavan/vendor-performance-analysis) (Kaggle)

7 CSV files — 15.8M total rows:

| File | Rows | Description |
|------|------|-------------|
| purchases.csv | 2,372,474 | Vendor purchase orders |
| sales.csv | 12,825,363 | Sales transactions |
| begin_inventory.csv | 206,529 | Starting inventory |
| end_inventory.csv | 224,489 | Ending inventory |
| purchase_prices.csv | 12,261 | Vendor pricing |
| vendor_invoice.csv | 5,543 | Invoice records |
| vendor_sales_summary.csv | 10,692 | Aggregated vendor KPIs |

## Pipeline

### ADF Data Flows
- `df_top_vendors` — Aggregates purchases by vendor → `gold_top_vendors`
- `df_vendor_sales_contribution` — Calculates vendor sales % → `gold_vendor_sales_contribution`
- `df_inventory_gap` — Joins begin/end inventory → `gold_inventory_gap`
- `df_invoice_reconciliation` — Joins purchases + invoices → `gold_invoice_reconciliation`
- `df_sales_trend` — Month-over-month sales → `gold_sales_trend`

## Gold Layer KPIs

### 1. Top Vendors by Purchase Value
```sql
SELECT TOP 10 VendorName, TotalPurchaseDollars
FROM gold_top_vendors
ORDER BY TotalPurchaseDollars DESC;
```
→ DIAGEO NORTH AMERICA INC leads with $50.9M in purchases

### 2. Vendor Sales Contribution %
```sql
SELECT TOP 10 VendorName, TotalSalesDollars,
  ROUND(TotalSalesDollars * 100.0 / SUM(TotalSalesDollars) OVER(), 2) AS SalesContributionPct
FROM gold_vendor_sales_contribution
ORDER BY TotalSalesDollars DESC;
```
→ Top vendor (DIAGEO) contributes 15.21% of total sales

### 3. Inventory Gap Analysis
```sql
SELECT TOP 10 Description, Store, InventoryGap
FROM gold_inventory_gap
ORDER BY ABS(InventoryGap) DESC;
```
→ Identifies products with largest stock discrepancies

### 4. Invoice vs Purchase Reconciliation
```sql
SELECT TOP 10 VendorName, PONumber, PurchaseDollars, InvoiceDollars, Variance
FROM gold_invoice_reconciliation
ORDER BY ABS(Variance) DESC;
```
→ Flags financial discrepancies between POs and invoices

### 5. Month-over-Month Sales Trend
```sql
SELECT SalesMonth, TotalSalesDollars, TotalQuantity
FROM gold_sales_trend
ORDER BY SalesMonth ASC;
```
→ July 2024 peak: $49.7M in sales, 3.44M units

## Azure Resources

| Resource | Name |
|----------|------|
| Resource Group | retail-vendor-rg |
| Storage Account | retailvendorstorage |
| Blob Containers | bronze, silver, gold |
| SQL Server | retailvendorsrv2026 |
| SQL Database | retail-vendor-db |
| Data Factory | retail-vendor-adf |

## Project Structure## Setup

1. Clone the repo
2. Copy `.env.example` to `.env` and add your Azure connection string
3. Run `python3 scripts/validate_data.py` to profile the data
4. Run `python3 scripts/upload_to_blob.py` to upload to Bronze
5. Run the ADF pipeline `pl_vendor_analytics` in Azure Data Factory
6. Query the Gold tables in Azure SQLe