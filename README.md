# 🛒 TheLook eCommerce: Revenue Leakage & Customer Retention Analysis

![SQL](https://img.shields.io/badge/Language-SQL-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Google%20BigQuery-orange.svg)
![Focus](https://img.shields.io/badge/Focus-Business%20Metrics%20%26%20Retention-green.svg)

## 📌 Executive Summary
Proyek *Exploratory Data Analysis* (EDA) ini membedah data operasional **TheLook eCommerce** menggunakan Google Cloud BigQuery. Fokus utama analisis ini adalah mengevaluasi kesehatan finansial platform di luar metrik *Gross Merchandise Value* (GMV), memetakan profitabilitas portofolio produk, dan mengukur tingkat loyalitas pelanggan baru (cohort retention).

---

## 🎯 Business Problem & Objectives
Manajemen membutuhkan visibilitas terhadap margin riil platform yang selama ini terdistorsi oleh pesanan batal dan retur. Proyek ini bertujuan untuk menjawab 3 pertanyaan strategis:
1. **Financial Leakage:** Berapa besar kerugian pendapatan (*revenue leakage*) akibat pesanan batal atau diretur?
2. **Product Profitability:** Kategori produk mana yang memberikan laba kotor tertinggi, dan mana yang menjadi *margin drainer* akibat tingkat retur logistik yang tinggi?
3. **Customer Retention:** Apakah pelanggan baru kembali bertransaksi (*repeat order*) dalam 6 bulan pertama setelah akuisisi?

---

## 🔍 Deep-Dive Analysis & Key Insights

### Phase 1: Tingkat Kebocoran Pendapatan (*Revenue Leakage*)
![GMV vs Realized Revenue](./images/GMV_vs_Realized_Revenue.png)
* **Insight:** Platform secara konsisten mengalami kebocoran pendapatan di kisaran **24% - 27%** setiap bulannya. 
* **Dampak:** Meskipun GMV terlihat bertumbuh pesat (mencapai puncak >$800k pada pertengahan 2026), pendapatan riil yang berhasil dicairkan (*realized revenue*) rata-rata hanya tertahan di angka 55% - 60%.

### Phase 2: Matriks Profitabilitas Produk
![Product Risk Matrix](./images/Product_Risk_Profitability.png)
* **Insight:** Terjadi polarisasi pada portofolio produk. Produk *Tier 1* mencetak profit riil di atas $800 dengan tingkat retur sangat rendah (<5%). Namun, teridentifikasi produk *Tier 3 (Loss Maker)* yang dijual dengan *negative margin* dan produk *Tier 2* yang volume penjualannya tinggi tetapi returnya mencapai 15% - 20%.

### Phase 3: Krisis Retensi Pelanggan (M1 Drop-off)
![Cohort Retention Heatmap](./images/cihuyyyy.jpeg)
* **Insight:** Bisnis ini sangat bergantung pada akuisisi pelanggan baru. Retensi pelanggan pada bulan pertama (M1) langsung anjlok drastis ke angka rata-rata **1.5%**. Sekitar 98.5% pengguna adalah pembeli satu kali (*one-time buyers*).

---

## 💡 Strategic Recommendations

1. **Pencegahan Retur Logistik (Operational):** Lakukan audit deskripsi ukuran, kualitas bahan, dan *quality control* (QC) secara spesifik untuk kategori produk di kuadran *Tier 2 (High Return Risk)*.
2. **Koreksi Harga (Pricing):** Bekukan sementara promosi atau evaluasi biaya pokok (COGS) untuk item-item yang terdeteksi memiliki riwayat transaksi *negative margin*.
3. **Fokus Re-aktivasi Pelanggan (Marketing):** Platform wajib meluncurkan program loyalitas atau mendistribusikan *voucher* re-aktivasi otomatis pada hari ke-15 hingga ke-30 pasca-transaksi perdana untuk menyelamatkan tingkat retensi M1.

---

## 📂 Repository Structure & SQL Pipeline

Proses pembersihan data dan transformasi kompleks (menggunakan *Chained CTEs*, *Conditional Aggregations*, dan *Window Functions*) dipisahkan ke dalam tiga skrip modular:

| Phase | Description | SQL Script |
| :--- | :--- | :--- |
| **Phase 1** | GMV vs Realized Revenue & Leakage Audit | [`01_financial_leakage_audit.sql`](./sql/01_financial_leakage_audit.sql) |
| **Phase 2** | Product Risk & Profitability Matrix | [`02_product_profitability_matrix.sql`](./sql/02_product_profitability_matrix.sql) |
| **Phase 3** | Customer Cohort Retention (M0-M6) | [`03_customer_cohort_retention.sql`](./sql/03_customer_cohort_retention.sql) |

---

## 👤 Author
**Rendi Dwi Andika**  
*Mahasiswa Bisnis Digital & Data Enthusiast*  
[LinkedIn](https://www.linkedin.com/in/rendidwiandika/) | [Email](mailto:email-kamu@example.com)
