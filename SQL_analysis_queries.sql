-- 1. DATA PREPARATION & VALIDATION
-- =====================================================

-- Create unified dataset by joining all three tables
WITH unified_data AS (
    SELECT 
        c.customer_id,
        c.name,
        c.region,
        c.state,
        c.organization_type,
        c.plan_type,
        c.mrr as customer_mrr,
        i.payment_type,
        i.days_to_payment,
        i.amount as invoice_amount,
        i.invoice_date,
        i.paid_date,
        i.expiration_date,
        s.annual_contract_value,
        s.status as subscription_status,
        s.cancellation_reason,
        s.mrr as subscription_mrr,
        -- Derive churn indicator from subscription status and cancellation reason
        CASE 
            WHEN s.status = 'Cancelled' OR s.cancellation_reason IS NOT NULL THEN 1 
            ELSE 0 
        END as is_churned
    FROM customers c
    LEFT JOIN invoices i ON c.customer_id = i.customer_id
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    WHERE i.invoice_date >= '2024-01-01'  -- Focus on recent data
)

-- Basic data validation and summary statistics
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT customer_id) as unique_customers,
    AVG(days_to_payment) as avg_payment_delay,
    AVG(CAST(is_churned AS FLOAT)) as overall_churn_rate,
    COUNT(CASE WHEN payment_type IS NULL THEN 1 END) as missing_payment_types
FROM unified_data;

-- =====================================================
-- 2. INSIGHT 1: PAYMENT TYPE AS CHURN DRIVER
-- =====================================================

-- Calculate churn rate and average payment delay by payment type
SELECT 
    payment_type,
    COUNT(*) as total_customers,
    SUM(is_churned) as churned_customers,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as churn_rate_percent,
    ROUND(AVG(days_to_payment), 0) as avg_payment_delay_days
FROM unified_data
WHERE payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY churn_rate_percent DESC;

-- Detailed payment type analysis with confidence intervals
SELECT 
    payment_type,
    COUNT(*) as sample_size,
    SUM(is_churned) as churned_count,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as churn_rate_percent,
    ROUND(AVG(days_to_payment), 1) as avg_delay_days,
    ROUND(STDDEV(days_to_payment), 1) as delay_std_dev,
    ROUND(AVG(annual_contract_value), 0) as avg_contract_value
FROM unified_data
WHERE payment_type IN ('Credit Card', 'ACH', 'Wire', 'Check')
GROUP BY payment_type
ORDER BY churn_rate_percent;

-- =====================================================
-- 3. INSIGHT 2: PAYMENT DELAYS EXPONENTIAL IMPACT  
-- =====================================================

-- Create payment delay buckets and calculate churn rates
SELECT 
    CASE 
        WHEN days_to_payment BETWEEN 0 AND 5 THEN '0-5 days'
        WHEN days_to_payment BETWEEN 6 AND 15 THEN '6-15 days'
        WHEN days_to_payment BETWEEN 16 AND 30 THEN '16-30 days'
        WHEN days_to_payment > 30 THEN '30+ days'
        ELSE 'Unknown'
    END as delay_bucket,
    COUNT(*) as total_customers,
    SUM(is_churned) as churned_customers,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as churn_rate_percent
FROM unified_data
WHERE days_to_payment IS NOT NULL
GROUP BY 
    CASE 
        WHEN days_to_payment BETWEEN 0 AND 5 THEN '0-5 days'
        WHEN days_to_payment BETWEEN 6 AND 15 THEN '6-15 days'
        WHEN days_to_payment BETWEEN 16 AND 30 THEN '16-30 days'
        WHEN days_to_payment > 30 THEN '30+ days'
        ELSE 'Unknown'
    END
ORDER BY 
    MIN(days_to_payment);

-- Payment delay distribution by payment type
SELECT 
    payment_type,
    AVG(CASE WHEN days_to_payment BETWEEN 0 AND 5 THEN 1.0 ELSE 0 END) * 100 as pct_0_5_days,
    AVG(CASE WHEN days_to_payment BETWEEN 6 AND 15 THEN 1.0 ELSE 0 END) * 100 as pct_6_15_days,
    AVG(CASE WHEN days_to_payment BETWEEN 16 AND 30 THEN 1.0 ELSE 0 END) * 100 as pct_16_30_days,
    AVG(CASE WHEN days_to_payment > 30 THEN 1.0 ELSE 0 END) * 100 as pct_30_plus_days
FROM unified_data
WHERE payment_type IN ('Credit Card', 'ACH', 'Wire', 'Check')
GROUP BY payment_type;

-- =====================================================
-- 4. INSIGHT 3: PLAN TYPE & REGIONAL DIFFERENCES
-- =====================================================

-- Enterprise customer churn analysis by payment type
SELECT 
    plan_type,
    payment_type,
    region,
    COUNT(*) as customer_count,
    SUM(is_churned) as churned_count,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as churn_rate_percent,
    ROUND(AVG(annual_contract_value), 0) as avg_contract_value
FROM unified_data
WHERE plan_type IN ('Enterprise', 'Enterprise Multi-Site')
    AND payment_type IS NOT NULL
GROUP BY plan_type, payment_type, region
ORDER BY churn_rate_percent DESC;

-- Regional payment type distribution and churn analysis  
SELECT 
    region,
    COUNT(*) as total_customers,
    
    -- Payment type distribution
    SUM(CASE WHEN payment_type IN ('Credit Card', 'ACH') THEN 1 ELSE 0 END) as automated_payments,
    SUM(CASE WHEN payment_type IN ('Wire', 'Check') THEN 1 ELSE 0 END) as manual_payments,
    ROUND(SUM(CASE WHEN payment_type IN ('Wire', 'Check') THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 0) as manual_payment_percent,
    
    -- Churn analysis
    SUM(is_churned) as total_churned,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as regional_churn_rate_percent
FROM unified_data
WHERE region IS NOT NULL AND payment_type IS NOT NULL
GROUP BY region
ORDER BY manual_payment_percent DESC;

-- Enterprise Wire vs Automated comparison
SELECT 
    CASE 
        WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type = 'Wire' THEN 'Enterprise Wire'
        WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type IN ('Credit Card', 'ACH') THEN 'Enterprise Automated'
        ELSE 'Other'
    END as customer_segment,
    COUNT(*) as customer_count,
    SUM(is_churned) as churned_count,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as churn_rate_percent,
    ROUND(SUM(annual_contract_value), 0) as total_contract_value
FROM unified_data
WHERE plan_type IN ('Enterprise', 'Enterprise Multi-Site')
    AND payment_type IN ('Wire', 'Credit Card', 'ACH')
GROUP BY 
    CASE 
        WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type = 'Wire' THEN 'Enterprise Wire'
        WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type IN ('Credit Card', 'ACH') THEN 'Enterprise Automated'
        ELSE 'Other'
    END
ORDER BY churn_rate_percent DESC;

-- =====================================================
-- 5. INSIGHT 4: ARR IMPACT CALCULATIONS
-- =====================================================

-- Calculate total ARR base and churn impact
SELECT 
    SUM(annual_contract_value) as total_arr_base,
    SUM(CASE WHEN is_churned = 1 THEN annual_contract_value ELSE 0 END) as churned_arr,
    ROUND(SUM(CASE WHEN is_churned = 1 THEN annual_contract_value ELSE 0 END) / SUM(annual_contract_value) * 100, 1) as arr_churn_rate_percent
FROM unified_data
WHERE annual_contract_value > 0;

-- ARR impact by payment type
SELECT 
    payment_type,
    COUNT(*) as customer_count,
    SUM(annual_contract_value) as total_arr,
    SUM(CASE WHEN is_churned = 1 THEN annual_contract_value ELSE 0 END) as churned_arr,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as churn_rate_percent,
    ROUND(SUM(CASE WHEN is_churned = 1 THEN annual_contract_value ELSE 0 END) / 1000000, 2) as churned_arr_millions
FROM unified_data
WHERE payment_type IS NOT NULL AND annual_contract_value > 0
GROUP BY payment_type
ORDER BY churn_rate_percent DESC;

-- Calculate cost per 1% churn increase
WITH churn_analysis AS (
    SELECT 
        SUM(annual_contract_value) as total_arr,
        AVG(CAST(is_churned AS FLOAT)) * 100 as current_churn_rate
    FROM unified_data
    WHERE annual_contract_value > 0
)
SELECT 
    total_arr,
    current_churn_rate,
    ROUND(total_arr * 0.01, 0) as cost_per_1_percent_churn
FROM churn_analysis;

-- Enterprise segment ARR at risk calculation
SELECT 
    'Enterprise Wire vs Automated' as scenario,
    SUM(CASE WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type = 'Wire' 
        THEN annual_contract_value ELSE 0 END) as wire_arr,
    AVG(CASE WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type = 'Wire' 
        THEN CAST(is_churned AS FLOAT) ELSE NULL END) * 100 as wire_churn_rate,
    AVG(CASE WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type IN ('Credit Card', 'ACH') 
        THEN CAST(is_churned AS FLOAT) ELSE NULL END) * 100 as automated_churn_rate,
    (AVG(CASE WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type = 'Wire' 
        THEN CAST(is_churned AS FLOAT) ELSE NULL END) - 
     AVG(CASE WHEN plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND payment_type IN ('Credit Card', 'ACH') 
        THEN CAST(is_churned AS FLOAT) ELSE NULL END)) * 100 as churn_rate_difference
FROM unified_data;

-- =====================================================
-- 6. REGIONAL HEATMAP DATA FOR TABLEAU
-- =====================================================

-- Regional churn rates by plan type for heatmap visualization
SELECT 
    plan_type,
    region,
    COUNT(*) as customer_count,
    SUM(is_churned) as churned_count,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 1) as churn_rate_percent,
    ROUND(AVG(annual_contract_value), 0) as avg_contract_value,
    SUM(CASE WHEN payment_type IN ('Wire', 'Check') THEN 1 ELSE 0 END) as manual_payment_count,
    ROUND(SUM(CASE WHEN payment_type IN ('Wire', 'Check') THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 0) as manual_payment_percent
FROM unified_data
WHERE plan_type IN ('Enterprise', 'Enterprise Multi-Site', 'Standard')
    AND region IN ('Midwest', 'South', 'East', 'West')
GROUP BY plan_type, region
ORDER BY plan_type, region;

-- =====================================================
-- 7. FINANCIAL OPPORTUNITY CALCULATIONS
-- =====================================================

-- Payment type optimization opportunity (Check to Credit Card)
WITH payment_opportunity AS (
    SELECT 
        AVG(CASE WHEN payment_type = 'Check' THEN CAST(is_churned AS FLOAT) ELSE NULL END) as check_churn_rate,
        AVG(CASE WHEN payment_type = 'Credit Card' THEN CAST(is_churned AS FLOAT) ELSE NULL END) as cc_churn_rate,
        SUM(CASE WHEN payment_type = 'Check' THEN annual_contract_value ELSE 0 END) as check_arr
    FROM unified_data
)
SELECT 
    check_churn_rate * 100 as check_churn_percent,
    cc_churn_rate * 100 as credit_card_churn_percent,
    (check_churn_rate - cc_churn_rate) * 100 as churn_rate_improvement,
    check_arr as check_customer_arr,
    ROUND((check_churn_rate - cc_churn_rate) * check_arr / 1000000, 2) as annual_arr_opportunity_millions
FROM payment_opportunity;

-- Regional automation opportunity (Midwest/South focus)
SELECT 
    region,
    SUM(annual_contract_value) as regional_arr,
    AVG(CAST(is_churned AS FLOAT)) * 100 as regional_churn_rate,
    SUM(CASE WHEN payment_type IN ('Wire', 'Check') THEN annual_contract_value ELSE 0 END) as manual_payment_arr,
    ROUND(SUM(CASE WHEN payment_type IN ('Wire', 'Check') THEN annual_contract_value ELSE 0 END) / SUM(annual_contract_value) * 100, 0) as manual_payment_arr_percent
FROM unified_data
WHERE region IN ('Midwest', 'South', 'East', 'West')
    AND annual_contract_value > 0
GROUP BY region
ORDER BY manual_payment_arr_percent DESC;

-- =====================================================
-- 8. DASHBOARD KPI CALCULATIONS
-- =====================================================

-- KPI metrics for dashboard
SELECT 
    'Credit Card' as metric,
    ROUND(AVG(CASE WHEN payment_type = 'Credit Card' THEN CAST(is_churned AS FLOAT) ELSE NULL END) * 100, 1) as value
FROM unified_data
UNION ALL
SELECT 
    'Wire Churn',
    ROUND(AVG(CASE WHEN payment_type = 'Wire' THEN CAST(is_churned AS FLOAT) ELSE NULL END) * 100, 1)
FROM unified_data
UNION ALL
SELECT 
    'Check Churn',
    ROUND(AVG(CASE WHEN payment_type = 'Check' THEN CAST(is_churned AS FLOAT) ELSE NULL END) * 100, 1)
FROM unified_data
UNION ALL
SELECT 
    'Total ARR Base (Millions)',
    ROUND(SUM(annual_contract_value) / 1000000, 1)
FROM unified_data
WHERE annual_contract_value > 0;

-- =====================================================
-- 9. DATA EXPORT FOR TABLEAU DASHBOARD
-- =====================================================

-- Comprehensive dataset for Tableau visualization
SELECT 
    c.customer_id,
    c.name,
    c.region,
    c.state,
    c.organization_type,
    c.plan_type,
    i.payment_type,
    i.days_to_payment,
    CASE 
        WHEN i.days_to_payment BETWEEN 0 AND 5 THEN '0-5 days'
        WHEN i.days_to_payment BETWEEN 6 AND 15 THEN '6-15 days'
        WHEN i.days_to_payment BETWEEN 16 AND 30 THEN '16-30 days'
        WHEN i.days_to_payment > 30 THEN '30+ days'
        ELSE 'Unknown'
    END as delay_bucket,
    CASE 
        WHEN s.status = 'Cancelled' OR s.cancellation_reason IS NOT NULL THEN 1 
        ELSE 0 
    END as is_churned,
    s.annual_contract_value,
    s.mrr,
    CASE WHEN i.payment_type IN ('Credit Card', 'ACH') THEN 'Automated' ELSE 'Manual' END as payment_category,
    CASE 
        WHEN c.plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND i.payment_type = 'Wire' THEN 'Enterprise Wire'
        WHEN c.plan_type IN ('Enterprise', 'Enterprise Multi-Site') AND i.payment_type IN ('Credit Card', 'ACH') THEN 'Enterprise Automated'
        ELSE 'Other'
    END as risk_segment
FROM customers c
JOIN invoices i ON c.customer_id = i.customer_id
JOIN subscriptions s ON c.customer_id = s.customer_id
WHERE i.invoice_date >= '2024-01-01'
    AND i.payment_type IS NOT NULL
    AND s.annual_contract_value > 0;

