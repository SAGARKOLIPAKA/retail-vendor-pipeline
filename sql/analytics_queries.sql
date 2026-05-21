-- ═══════════════════════════════════════════════════════
-- RETAIL VENDOR ANALYTICS - GOLD LAYER QUERIES
-- ═══════════════════════════════════════════════════════

-- 1. Top 10 Vendors by Total Purchase Value
SELECT TOP 10
    VendorName,
    TotalPurchaseDollars,
    TotalQuantity,
    AvgPurchasePrice
FROM gold_top_vendors
ORDER BY TotalPurchaseDollars DESC;

-- 2. Vendor Sales Contribution %
SELECT TOP 10
    VendorName,
    TotalSalesDollars,
    ROUND(TotalSalesDollars * 100.0 / SUM(TotalSalesDollars) OVER(), 2) AS SalesContributionPct
FROM gold_vendor_sales_contribution
ORDER BY TotalSalesDollars DESC;

-- 3. Inventory Gap Analysis (Top 10 biggest gaps)
SELECT TOP 10
    Description,
    Store,
    BeginOnHand,
    EndOnHand,
    InventoryGap
FROM gold_inventory_gap
ORDER BY ABS(InventoryGap) DESC;

-- 4. Invoice vs Purchase Reconciliation (Top variances)
SELECT TOP 10
    VendorName,
    PONumber,
    PurchaseDollars,
    InvoiceDollars,
    Variance
FROM gold_invoice_reconciliation
ORDER BY ABS(Variance) DESC;

-- 5. Month over Month Sales Trend
SELECT
    SalesMonth,
    TotalSalesDollars,
    TotalQuantity,
    AvgSalesPrice
FROM gold_sales_trend
ORDER BY SalesMonth ASC;