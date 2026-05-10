# 📊 Brazilian E-Commerce: Business Intelligence & Data Analytics Portfolio

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Looker Studio](https://img.shields.io/badge/Looker_Studio-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Data Analysis](https://img.shields.io/badge/Data_Analysis-121011?style=for-the-badge&logo=data:image/png;base64,iVBORw0KGgo=)

## 📌 Project Overview
This repository contains a comprehensive end-to-end data analysis of the **Olist Brazilian E-Commerce dataset**. The goal of this project is to showcase advanced SQL querying, data transformation, and the development of stakeholder-ready Business Intelligence dashboards.

The project is divided into core analytical stages:
1. **Advanced SQL Analytics:** Deep-dive metrics including Month-over-Month (MoM) growth, cumulative revenue, and logistics SLA tracking.
2. **Business Intelligence Dashboarding:** Transforming raw transactional data into a "One Big Table" (OBT) to power a dynamic executive dashboard in Looker Studio.

---

## 🚀 Part 1: Advanced SQL Analytics
**Directory:** [`/1_Advanced_SQL`](./1_Advanced_SQL)

In this section, I utilized advanced PostgreSQL features (CTEs, Window Functions, and dynamic aggregations) to extract complex business health metrics.

* **Key Deliverables:**
  * **[SQL Queries](./1_Advanced_SQL/advanced_metrics_queries.sql):** Scripts calculating MoM revenue growth, payment type distribution (Credit Card vs. Boleto), and delivery delay impact.
  * **[Analysis Report](./1_Advanced_SQL/query_results_and_analysis.pdf):** Tabular results and data extraction logic.

* **Highlight Insight:** Identified specific product categories (e.g., Office Furniture) that suffer from disproportionately high late-delivery rates, severely impacting customer satisfaction.

---

## 📈 Part 2: Executive BI Dashboard
**Directory:** [`/2_BI_Dashboard`](./2_BI_Dashboard)

To make the data accessible to Senior Management, I engineered a highly denormalized dataset and visualized the business's macro-growth and operational bottlenecks.

🔗 **[View the Live Interactive Dashboard Here](https://datastudio.google.com/u/0/reporting/f3264d91-adc6-46eb-8540-a6dc53141289/page/m8jxF)**

* **Key Deliverables:**
  * **[One Big Table (OBT) SQL](./2_BI_Dashboard/one_big_table_dashboard.sql):** The unified SQL query designed to feed the BI tool efficiently, handling text-to-timestamp casting and delivery SLA logic.
  * **[Dashboard Interpretation](./2_BI_Dashboard/dashboard_interpretation.pdf):** A detailed slide deck breaking down the visualizations into actionable business insights.

* **Actionable Insights Uncovered:**
  1. **The Cost of Late Deliveries:** Orders delivered "On-Time" average a 4.21 satisfaction rating, while "Late" deliveries plummet to 2.57. Logistics is the primary lever for brand retention.
  2. **System Inefficiencies:** The `Delivery Delay Trend` indicates that packages frequently arrive weeks *earlier* than the estimated date, suggesting the checkout algorithm is wildly pessimistic, likely causing unnecessary cart abandonment.
  3. **Merchandising Quality:** High-revenue categories like "Furniture" and "Female Clothing" suffer from the lowest average reviews (~3.0), necessitating a strict supplier audit to prevent brand degradation.

---
*If you are a recruiter or hiring manager, feel free to reach out to me regarding this analysis or my capabilities in the modern data stack!*