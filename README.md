# 🛒 TheLook eCommerce: Revenue & Retention Analytics 

**Author:** Rendi Dwi Andika  
**Tools Used:** Google Cloud BigQuery, Standard SQL, Looker Studio  

## 📌 Project Overview
**TheLook eCommerce** adalah platform ritel pakaian dan aksesoris online yang sedang berkembang pesat (berbasis dataset publik Google Cloud). 

**Business Case:** Manajemen melihat pertumbuhan *Gross Merchandise Value (GMV)* yang sangat tinggi di *dashboard* utama. Namun, mereka curiga ada masalah operasional tersembunyi yang menggerus laba bersih dan tingkat loyalitas pembeli. Proyek ini mengeksekusi *Exploratory Data Analysis (EDA)* menyeluruh untuk membongkar realitas di balik angka GMV, memilah produk yang merugikan, dan menguji retensi pelanggan secara riil.

---

## 1. Financial Leakage: Uang Masuk vs Uang Batal
**Problem:** Berapa besar kerugian pendapatan (*revenue leakage*) yang diakibatkan oleh pesanan batal atau barang yang diretur oleh pelanggan?

*(Drag & drop gambar grafik GMV vs Realized Revenue di sini)*

**Key Findings:** 
Platform mengalami kebocoran pendapatan konstan di kisaran **24% - 27%** setiap bulannya. Meskipun GMV terlihat bertumbuh drastis (puncak >$800k pada pertengahan 2026), pendapatan riil yang masuk ke kas (*realized revenue*) rata-rata hanya bertahan di angka 55% - 60%.

🔗 **SQL Source Code:** [`01_financial_leakage_audit.sql`](01_financial_leakage_audit.sql)

---

## 2. Product Profitability: Barang Cuan vs Barang Boncos
**Problem:** Kategori produk mana yang memberikan margin kotor tertinggi, dan mana yang justru menjadi beban (*margin drainer*) akibat tingkat retur tinggi atau salah penetapan harga?

*(Drag & drop gambar grafik scatter matriks produk di sini)*

**Key Findings:** 
Terdapat polarisasi ekstrem pada katalog produk:
* **Tier 1 (Core):** Mencetak profit riil di atas $800 dengan tingkat retur sangat aman (<5%).
* **Tier 2 (Risk):** Volume penjualan tinggi, tetapi tingkat retur mencapai 15% - 20%, memicu bengkaknya biaya logistik.
* **Tier 3 (Loss Maker):** Ditemukan transaksi produk dengan *negative margin* (dijual di bawah harga modal).

🔗 **SQL Source Code:** [`02_product_profitability_matrix.sql`](02_product_profitability_matrix.sql)

---

## 3. Cohort Retention: Krisis Loyalitas Pembeli Baru
**Problem:** Apakah kampanye akuisisi platform berhasil membuat pelanggan baru kembali bertransaksi (*repeat order*) dalam 6 bulan pertama (M0-M6)?

*(Drag & drop gambar tabel cohort di sini)*

**Key Findings:** 
Data membuktikan adanya krisis retensi fatal. Pada bulan pertama (M1) setelah pembelian perdana, tingkat retensi langsung anjlok ke rata-rata **1.5%**. Artinya, 98.5% dari seluruh basis pengguna TheLook adalah pembeli satu kali (*one-time buyers*).

🔗 **SQL Source Code:** [`03_customer_cohort_retention.sql`](03_customer_cohort_retention.sql)

---

## 💡 Executive Conclusion & Recommendations
Platform TheLook sangat sehat dalam hal akuisisi dan GMV, namun keropos di efisiensi operasional dan loyalitas. Tindakan strategis yang wajib segera dieksekusi:

* **Operations (Pencegahan Retur):** Audit ketat panduan ukuran (*size chart*) dan *Quality Control* gudang khusus untuk produk kuadran *Tier 2* guna menekan angka retur 15%+.
* **Pricing Strategy:** Evaluasi ulang promo diskon atau sesuaikan Harga Pokok Penjualan (COGS) untuk memutus kerugian pada item *Tier 3* yang terjual dengan margin negatif.
* **Marketing (Re-aktivasi M1):** Mengingat retensi pelanggan hancur di bulan pertama, tim marketing harus mengotomatisasi penyebaran voucher diskon/poin loyalti pada H+15 hingga H+30 setelah transaksi perdana untuk memancing pembeli kembali datang.
