-- ── GOLD LAYER TABLES ─────────────────────────────────────────────────────

-- 1. Top vendors by total purchase value
CREATE TABLE gold_top_vendors (
    VendorNumber        INT,
    VendorName          NVARCHAR(255),
    TotalPurchaseDollars FLOAT,
    TotalQuantity       INT,
    AvgPurchasePrice    FLOAT
);

-- 2. Vendor sales contribution %
CREATE TABLE gold_vendor_sales_contribution (
    VendorNumber        INT,
    VendorName          NVARCHAR(255),
    TotalSalesDollars   FLOAT,
    SalesContributionPct FLOAT
);

-- 3. Inventory gap analysis
CREATE TABLE gold_inventory_gap (
    InventoryId         NVARCHAR(100),
    Store               INT,
    Brand               INT,
    Description         NVARCHAR(255),
    BeginOnHand         INT,
    EndOnHand           INT,
    InventoryGap        INT
);

-- 4. Invoice vs purchase reconciliation
CREATE TABLE gold_invoice_reconciliation (
    VendorNumber        INT,
    VendorName          NVARCHAR(255),
    PONumber            INT,
    PurchaseDollars     FLOAT,
    InvoiceDollars      FLOAT,
    Variance            FLOAT
);

-- 5. Month over month sales trend
CREATE TABLE gold_sales_trend (
    SalesMonth          NVARCHAR(7),
    TotalSalesDollars   FLOAT,
    TotalQuantity       INT,
    AvgSalesPrice       FLOAT
);