# 🏭 Retail Vendor Analytics Pipeline

<p align="center">
  <img src="https://img.shields.io/badge/Azure_Data_Factory-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white"/>
  <img src="https://img.shields.io/badge/Azure_Blob_Storage-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white"/>
  <img src="https://img.shields.io/badge/Azure_SQL-CC2927?style=for-the-badge&logo=microsoftazure&logoColor=white"/>
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white"/>
</p>

<p align="center">
  <b>A production-grade cloud-native data pipeline on Azure</b><br/>
  Processing <b>15.8 million rows</b> of retail vendor data from raw CSVs to business-ready KPI tables<br/>
  using the <b>Medallion Architecture</b> (Bronze → Silver → Gold)
</p>

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   📁 Kaggle Dataset          🐍 Python Script                       │
│   7 CSV Files                upload_to_blob.py                      │
│   15.8M rows total           azure-storage-blob SDK                 │
│          │                          │                               │
│          └──────────────────────────┘                               │
│                        │                                            │
│                        ▼                                            │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  🟫  BRONZE LAYER  —  Azure Blob Storage                    │   │
│   │  raw/purchases.csv        raw/sales.csv                     │   │
│   │  raw/begin_inventory.csv  raw/end_inventory.csv             │   │
│   │  raw/purchase_prices.csv  raw/vendor_invoice.csv            │   │
│   │  raw/vendor_sales_summary.csv                               │   │
│   │  Untouched · Immutable · Source of Truth                    │   │
│   └──────────────────────────┬──────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  🔄  SILVER LAYER  —  Azure Data Factory (Data Flows)       │   │
│   │                                                             │   │
│   │  df_top_vendors              df_vendor_sales_contribution   │   │
│   │  df_inventory_gap            df_invoice_reconciliation      │   │
│   │  df_sales_trend                                             │   │
│   │                                                             │   │
│   │  Clean · Transform · Aggregate · Join                       │   │
│   └──────────────────────────┬──────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  🥇  GOLD LAYER  —  Azure SQL Database                      │   │
│   │                                                             │   │
│   │  gold_top_vendors            gold_vendor_sales_contribution │   │
│   │  gold_inventory_gap          gold_invoice_reconciliation    │   │
│   │  gold_sales_trend                                           │   │
│   │                                                             │   │
│   │  Analytics-Ready · KPI Tables · Query-Optimized             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Ingestion** | Python + `azure-storage-blob` SDK | Upload raw CSVs to Bronze |
| **Bronze Storage** | Azure Blob Storage | Immutable raw data lake |
| **Transformation** | Azure Data Factory — Data Flows | Silver layer (clean, join, aggregate) |
| **Orchestration** | ADF Pipeline `pl_vendor_analytics` | Run all 5 Data Flows in parallel |
| **Gold Storage** | Azure SQL Database (Free Tier) | Analytics-ready KPI tables |
| **Infrastructure** | ARM Templates | Pipeline as code |
| **Version Control** | GitHub | Full commit history |

### AWS Equivalents (for reference)

| Azure Service | AWS Equivalent |
|--------------|---------------|
| Azure Blob Storage | Amazon S3 |
| Azure Data Factory | AWS Glue |
| Azure SQL Database | Amazon RDS |
| ARM Templates | AWS CloudFormation |
| Azure Monitor | Amazon CloudWatch |

---

## 📊 Dataset

**Source:** [Vendor Performance Analysis](https://www.kaggle.com/datasets/harshmadhavan/vendor-performance-analysis) — Kaggle (CC0-1.0 License)

| File | Rows | Columns | Description |
|------|------|---------|-------------|
| `purchases.csv` | 2,372,474 | 16 | Vendor purchase orders with pricing |
| `sales.csv` | 12,825,363 | 14 | Individual sales transactions |
| `begin_inventory.csv` | 206,529 | 9 | Starting inventory snapshot |
| `end_inventory.csv` | 224,489 | 9 | Ending inventory snapshot |
| `purchase_prices.csv` | 12,261 | 9 | Vendor pricing reference |
| `vendor_invoice.csv` | 5,543 | 10 | Invoice records per PO |
| `vendor_sales_summary.csv` | 10,692 | 18 | Aggregated vendor KPIs |
| **Total** | **15,657,351** | — | **15.8M rows processed** |

### Data Quality Findings (from `validate_data.py`)

| Issue | File | Column | Action Taken |
|-------|------|--------|-------------|
| 3 null values | `purchases.csv` | `Size` | Retained (negligible 0.0%) |
| 1,284 nulls (0.6%) | `end_inventory.csv` | `City` | Schema drift in ADF |
| 5,169 nulls (**93.3%**) | `vendor_invoice.csv` | `Approval` | Dropped column — unusable |

---

## 🔄 ADF Pipeline — `pl_vendor_analytics`

All 5 Data Flows run in **parallel** via `AutoResolveIntegrationRuntime` on Azure Spark.

```
pl_vendor_analytics
│
├── df_top_vendors              (4m 48s) ✅
├── df_vendor_sales_contribution (6m 37s) ✅
├── df_inventory_gap             (6m 06s) ✅
├── df_invoice_reconciliation    (5m 08s) ✅
└── df_sales_trend               (5m 43s) ✅

Pipeline status: SUCCEEDED
Total rows processed: 15,800,000+
```

### Data Flow Detail

#### `df_top_vendors`
```
Source: purchases.csv (2.3M rows)
  └── Aggregate
        Group by: VendorNumber, VendorName
        sum(Dollars)        → TotalPurchaseDollars
        sum(Quantity)       → TotalQuantity
        avg(PurchasePrice)  → AvgPurchasePrice
          └── Sink: gold_top_vendors (Azure SQL)
```

#### `df_vendor_sales_contribution`
```
Source: sales.csv (12.8M rows)
  └── Aggregate
        Group by: VendorNo, VendorName
        sum(SalesDollars)   → TotalSalesDollars
          └── Derived Column
                SalesContributionPct = TotalSalesDollars / total * 100
                  └── Sink: gold_vendor_sales_contribution (Azure SQL)
```

#### `df_inventory_gap`
```
Source A: begin_inventory.csv (206K rows)
Source B: end_inventory.csv   (224K rows)
  └── Inner Join on InventoryId + Store
        └── Derived Column
              InventoryGap = endOnHand - beginOnHand
                └── Sink: gold_inventory_gap (Azure SQL)
```

#### `df_invoice_reconciliation`
```
Source A: purchases.csv      (2.3M rows)
Source B: vendor_invoice.csv (5.5K rows)
  └── Inner Join on PONumber
        └── Aggregate
              Group by: VendorNumber, VendorName, PONumber
              sum(purchases.Dollars)  → PurchaseDollars
              sum(invoice.Dollars)    → InvoiceDollars
              Variance = PurchaseDollars - InvoiceDollars
                └── Sink: gold_invoice_reconciliation (Azure SQL)
```

#### `df_sales_trend`
```
Source: sales.csv (12.8M rows)
  └── Derived Column
        SalesMonth = left(SalesDate, 7)   → "YYYY-MM"
          └── Aggregate
                Group by: SalesMonth
                sum(SalesDollars)  → TotalSalesDollars
                sum(SalesQuantity) → TotalQuantity
                avg(SalesPrice)    → AvgSalesPrice
                  └── Sink: gold_sales_trend (Azure SQL)
```

---

## 🥇 Gold Layer — KPI Results

### 1. Top 10 Vendors by Purchase Value

```sql
SELECT TOP 10 VendorName, TotalPurchaseDollars
FROM gold_top_vendors
ORDER BY TotalPurchaseDollars DESC;
```

| Rank | Vendor | Total Purchase $ |
|------|--------|-----------------|
| 1 | DIAGEO NORTH AMERICA INC | $50,959,796 |
| 2 | MARTIGNETTI COMPANIES | $27,821,473 |
| 3 | JIM BEAM BRANDS COMPANY | $24,203,151 |
| 4 | PERNOD RICARD USA | $24,124,091 |
| 5 | BACARDI USA INC | $17,624,378 |

### 2. Vendor Sales Contribution %

```sql
SELECT TOP 10 VendorName,
  ROUND(TotalSalesDollars * 100.0 / SUM(TotalSalesDollars) OVER(), 2) AS SalesContributionPct
FROM gold_vendor_sales_contribution
ORDER BY TotalSalesDollars DESC;
```

| Vendor | Sales $ | Contribution % |
|--------|---------|---------------|
| DIAGEO NORTH AMERICA INC | $68,742,416 | **15.21%** |
| MARTIGNETTI COMPANIES | $40,992,395 | 9.07% |
| PERNOD RICARD USA | $32,281,247 | 7.14% |
| JIM BEAM BRANDS COMPANY | $31,906,320 | 7.06% |
| BACARDI USA INC | $25,014,556 | 5.53% |

### 3. Month-over-Month Sales Trend

```sql
SELECT SalesMonth, TotalSalesDollars, TotalQuantity
FROM gold_sales_trend
ORDER BY SalesMonth ASC;
```

| Month | Total Sales | Units Sold |
|-------|-------------|-----------|
| 2024-01 | $29,854,027 | 2,194,959 |
| 2024-02 | $28,876,607 | 2,125,292 |
| 2024-03 | $28,988,411 | 2,219,626 |
| 2024-04 | $30,723,734 | 2,289,425 |
| 2024-05 | $36,041,210 | 2,624,496 |
| 2024-06 | $39,290,701 | 2,858,944 |
| **2024-07** | **$49,696,466** | **3,439,648** ← Peak month |
| 2024-08 | $39,056,166 | 2,892,266 |
| 2024-09 | $38,477,538 | 2,840,043 |
| 2024-10 | $36,433,141 | 2,724,657 |
| 2024-11 | $42,312,696 | 2,950,515 |
| 2024-12 | $43,XXX,XXX | 3,XXX,XXX |

> **Key Insight:** July 2024 was the peak month — $49.7M in sales and 3.44M units. Sales trend shows strong H2 seasonality.

---

## ☁️ Azure Resources

| Resource | Name | Region |
|----------|------|--------|
| Resource Group | `retail-vendor-rg` | East US |
| Storage Account | `retailvendorstorage` | East US |
| Blob Containers | `bronze` / `silver` / `gold` | East US |
| SQL Server | `retailvendorsrv2026` | Central US |
| SQL Database | `retail-vendor-db` | Central US |
| Data Factory | `retail-vendor-adf` | East US |

---

## 📁 Project Structure

```
retail-vendor-pipeline/
│
├── README.md                          # This file
│
├── data/
│   └── raw/                           # Kaggle CSVs (gitignored — 1.8GB)
│
├── pipeline/
│   └── adf_templates/                 # ADF ARM Templates (Infrastructure as Code)
│       ├── ARMTemplateForFactory.json
│       ├── ARMTemplateParametersForFactory.json
│       ├── factory/
│       │   ├── retail-vendor-adf_ARMTemplateForFactory.json
│       │   └── retail-vendor-adf_ARMTemplateParametersForFactory.json
│       └── linkedTemplates/
│           ├── ArmTemplate_0.json
│           ├── ArmTemplate_master.json
│           └── ArmTemplateParameters_master.json
│
├── sql/
│   ├── create_tables.sql              # Gold layer DDL (5 KPI tables)
│   └── analytics_queries.sql         # 5 analytics queries
│
├── scripts/
│   ├── validate_data.py              # Data profiling — row counts, nulls, types
│   └── upload_to_blob.py             # Bronze ingestion via Python SDK
│
├── docs/                             # Architecture diagrams
│
├── .env.example                      # Environment variable template
└── .gitignore                        # Excludes data/, .env, credentials
```

---

## 🚀 Setup & Reproduction

### Prerequisites

```bash
python3 --version    # 3.11+
az --version         # Azure CLI 2.x
pip3 show azure-storage-blob  # 12.x
```

### Steps

**1. Clone the repo**
```bash
git clone https://github.com/SAGARKOLIPAKA/retail-vendor-pipeline.git
cd retail-vendor-pipeline
```

**2. Install dependencies**
```bash
pip3 install azure-storage-blob python-dotenv
```

**3. Configure environment**
```bash
cp .env.example .env
# Edit .env and add your Azure Storage connection string
```

**4. Download dataset**
```bash
kaggle datasets download -d harshmadhavan/vendor-performance-analysis \
  -p data/raw --unzip
```

**5. Profile the data**
```bash
python3 scripts/validate_data.py
```

**6. Upload to Bronze layer**
```bash
python3 scripts/upload_to_blob.py
```

**7. Create Gold tables in Azure SQL**
```sql
-- Run sql/create_tables.sql in Azure SQL Query Editor
```

**8. Run the ADF Pipeline**
```
Azure Data Factory Studio → pl_vendor_analytics → Debug → Use Integration Runtime
```

**9. Query the Gold layer**
```sql
-- Run sql/analytics_queries.sql in Azure SQL Query Editor
```

---

## 🎯 Key Design Decisions

### Why Medallion Architecture?
Separating Bronze/Silver/Gold gives clear data lineage. If a transformation fails, we replay from Bronze without re-ingesting from the source. Each layer has a single responsibility.

### Why Azure Data Factory over Databricks?
The transformations are aggregations and joins — not ML or complex Spark logic. ADF Data Flows run Spark under the hood but provide a visual, code-free interface that's operationally simpler and cheaper for this use case.

### Why Azure SQL over Synapse Analytics?
The Gold layer produces 5 small aggregated tables (hundreds to thousands of rows). Azure SQL is the right tool — lower cost, lower latency, simpler setup. Synapse is for massive parallel processing at petabyte scale.

### Why Python SDK for Bronze ingestion?
The `azure-storage-blob` SDK handles large file uploads using the Block Blob pattern — splitting files into parallel chunks. This is essential for `sales.csv` at 1.49 GB.

---

## 🔒 Security Notes

- Credentials stored in `.env` (gitignored — never committed)
- `.env.example` shows the format without real values
- Azure SQL firewall: only `AutoResolveIntegrationRuntime` IPs + client IP allowed
- Storage account: private containers (no anonymous access)
- Rotate storage account keys periodically

---

## 👤 Author

**Sagar Kolipaka**  
4 years Data Engineering | AWS Certified (3x) | Azure  
[GitHub](https://github.com/SAGARKOLIPAKA)

---

## 📄 License

Dataset: [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) (Public Domain)  
Code: MIT