# SaaS Billing Churn Analysis  

## Executive Summary  
A SaaS B2B company, faced persistent churn despite high customer satisfaction. Deeper analysis revealed the primary driver was **involuntary churn** caused by billing friction—late payments and manual methods like Wire and Check.  

Using **SQL, Excel, and Tableau**, I unified data from invoices, subscriptions, and customers to uncover the relationship between billing practices and churn. The findings showed that **payment method and payment delays are strong churn predictors**, and eliminating billing friction could protect **$29.4M in ARR over 5 years**.  

**Recommendations include:**  
- Migrating high-risk Check/Wire customers to automated payments  
- Implementing proactive dunning and automated retries  
- Prioritizing enterprise and regional accounts most at risk  

---

## Business Problem  
SaaS companies rely on **Annual Recurring Revenue (ARR)** stability. While this company's product adoption was strong, billing inefficiencies were silently eroding revenue. Without intervention, ARR was projected to fall from **$30M → $15.3M** in 5 years.  

**The question: How can we reduce involuntary churn caused by billing and payment processes?**  

---

## Schema Diagram  
_Data model combining Invoices, Subscriptions, and Customers for analysis._  
<img width="1220" height="1150" alt="Schema Diagram" src="https://github.com/user-attachments/assets/4d92f836-0e70-4d7b-8ad2-839479d6f1ef" />



---

## Methodology & Skills  
- **SQL** – Built a unified dataset by joining customers, invoices, and subscriptions. Used CTEs, CASE logic, and aggregates to calculate churn, payment delays, ARR erosion, and segment risks by payment method and region.  
- **Excel** – Validated SQL outputs with PivotTables and modeled ARR scenarios using SUMIFS, IF, and INDEX-MATCH. Applied conditional formatting and ad-hoc financial modeling to highlight churn risks and late payment patterns.  
- **Tableau** – Designed interactive dashboards with filters (region, plan type, payment method, date range) for stakeholder use. Created churn and ARR visuals (bar, line, heatmap, stacked bar) with calculated fields and KPIs to quantify $29.4M revenue at risk.  

---
## Key Insights  
- **Payment Method Matters**  
  - **Data:** Credit Card has the lowest churn (1.3%) and fastest payments (~4 days). Check has the highest churn (11.8%) and longest delays (~22 days).  
  - **Insight:** Customers on manual payment methods are far more likely to churn.  

- **Delays Predict Churn**  
  - **Data:** 0–5 days late → 0.8% churn. 16–30 days late → 11.5% churn. 30+ days late → 25% churn.  
  - **Insight:** The longer a payment is delayed, the greater the risk of churn.  

- **Enterprise Accounts Exposed**  
  - **Data:** Wire-heavy enterprise accounts churn at 9.1%, putting ~$2.56M ARR at risk.  
  - **Insight:** High-value enterprise customers are at greater risk due to reliance on manual payments.  

- **Regional Differences**  
  - **Data:** Midwest & South use 68–75% manual payments with higher churn, while East & West rely more on automated payments with lower churn.  
  - **Insight:** Regional adoption of manual vs. automated payments directly affects retention outcomes.  

---

## Recommendations  
**Transition High-Risk Customers**  
- Migrate Wire and Check users to Credit Card/ACH with targeted incentives.  
- Prioritize enterprise accounts first to protect ~$2.56M ARR.  

**Strengthen Collections Process**  
- Launch proactive reminders and retry logic for failed payments.  
- Reduce long delays before they escalate into churn.  

**Target At-Risk Regions**  
- Run adoption campaigns in the Midwest & South to shift customers to automated payments.  
- Potential to save ~$756K ARR annually.  

**Continuous Monitoring**  
- Track churn, delay days, payment success, and ARR at risk monthly.  
- Provide dashboards for Sales and Customer Success to act quickly.  
---
## Dashboard Visuals  
<img width="452" height="272" alt="image" src="https://github.com/user-attachments/assets/28373123-3d14-4b68-922a-fd859fcd179d" />
<img width="271" height="228" alt="image" src="https://github.com/user-attachments/assets/1176cba3-6c9c-49b7-8ba6-59c067f5e6a3" />
<img width="917" height="210" alt="image" src="https://github.com/user-attachments/assets/ea39caef-763f-445e-88d2-869c2a020838" />
<img width="449" height="264" alt="image" src="https://github.com/user-attachments/assets/a3357c02-6836-496e-b46c-7d06260629a0" />
<img width="446" height="263" alt="image" src="https://github.com/user-attachments/assets/5b50e3fe-50d7-4d11-92bc-cb4f33485b26" />

---

## Next Steps  

- **Establish a Baseline** – Define current churn %, average payment delay, payment success %, automated vs. manual adoption, and ARR at risk. Use these as the starting point for tracking improvements.  

- **Pilot Interventions** –  
  • Test dunning (reminders/retries) with a small set of accounts.  
  • Run a migration campaign to move a sample of Wire/Check users to ACH or Credit Card.  
  • Focus pilots on enterprise and Midwest/South accounts where risk is highest.  

- **Measure Impact** – Track pilot results weekly in Excel/Power BI dashboards: collections improved, delay days reduced, automation adoption up, churn down. Share results with Sales and Customer Success.  

- **Enable Ongoing Monitoring** – Automate data refreshes and publish a shared dashboard so CS and Finance can quickly see at-risk accounts and take action.  

- **Expand & Scale** – Roll out successful tactics to more accounts. Set simple SLAs (e.g., all failed payments contacted within 48 hours). Review results monthly and report on ARR saved and churn reduction.   
