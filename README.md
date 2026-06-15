# 📈 Proyeksi Nilai Tukar USD/IDR dengan Geometric Brownian Motion & Simulasi Monte Carlo

<div align="center">

![R Version](https://img.shields.io/badge/R-4.5.1-276DC3?style=flat-square&logo=r&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-RPubs%20%7C%20Shiny-blue?style=flat-square)

**Analisis stokastik untuk memproyeksikan pergerakan kurs USD/IDR harian  
menggunakan model Geometric Brownian Motion dan Simulasi Monte Carlo.**

[📄 Laporan RPubs](#-publikasi-rpubs) • [🖥️ Dashboard Shiny](#️-dashboard-interaktif-shiny) • [📊 Hasil Utama](#-hasil-utama)

</div>

---

## 📌 Deskripsi Proyek

Proyek ini menerapkan **model Geometric Brownian Motion (GBM)** untuk memodelkan
dinamika nilai tukar USD/IDR, dilanjutkan dengan **Simulasi Monte Carlo** untuk
menghasilkan distribusi proyeksi ke depan dalam tiga skenario: *bearish*, *base*, dan *bullish*.

Analisis mencakup pipeline lengkap mulai dari *data wrangling*, statistik deskriptif,
uji normalitas, hingga visualisasi hasil proyeksi berupa *fan chart* dan interval kepercayaan 90%.

### Mengapa GBM?

Model GBM adalah standar dalam pemodelan aset keuangan karena:
- Memodelkan **log-return** yang secara empiris mendekati distribusi normal
- Memiliki solusi analitik yang elegan: $S_t = S_0 \cdot e^{(\mu - \frac{\sigma^2}{2})t + \sigma W_t}$
- Mampu menangkap **drift** (tren) dan **volatilitas** secara simultan
- Cocok sebagai fondasi untuk analisis risiko nilai tukar (*currency risk*)

---

## 📂 Struktur Repository

```
usd-idr-gbm-montecarlo/
│
├── 📁 data/
│   └── Data Historis USD_IDR.csv          # Data kurs penutupan harian (1.267 obs)
│
├── 📁 scripts/
│   ├── 01_usd_idr_data_wrangling.Rmd      # Import, cleaning, transformasi
│   ├── 02_usd_idr_statistik_deskriptif.Rmd # Statistik deskriptif + time series plot
│   ├── 03_usd_idr_uji_normalitas.Rmd      # KS-Test, Jarque-Bera, histogram, QQ-plot
│   ├── 04_usd_idr_monte_carlo.Rmd         # Estimasi parameter GBM + 3 skenario simulasi
│   └── 05_usd_idr_analisis_hasil.Rmd      # Fan chart, CI 90%, analisis konvergensi
│
├── 📁 output/
│   └── (hasil knit .html tersimpan di sini)
│
├── app.R                                   # R Shiny dashboard interaktif
├── README.md
├── .gitignore
└── LICENSE
```

### Penjelasan File

| File | Isi | Output Utama |
|------|-----|--------------|
| `01_data_wrangling.Rmd` | Membaca CSV, parsing tanggal, menghitung log-return harian, cleaning missing values | Data frame bersih `df_clean` |
| `02_statistik_deskriptif.Rmd` | Mean, median, SD, skewness, kurtosis; time series plot kurs dan log-return | Tabel ringkasan + 2 plot |
| `03_uji_normalitas.Rmd` | KS-Test, Jarque-Bera Test; histogram log-return + QQ-plot | 4 output uji + 2 plot |
| `04_monte_carlo.Rmd` | Estimasi µ dan σ dari data historis; 1.000 jalur simulasi × 3 skenario | 3.000 jalur simulasi |
| `05_analisis_hasil.Rmd` | Fan chart, CI 90%, analisis konvergensi, tabel proyeksi H+30/60/90 | Fan chart + tabel proyeksi |
| `app.R` | Dashboard Shiny: tab Data, Time Series, Histogram, QQ-Plot, Simulasi | Aplikasi web interaktif |

---

## ⚙️ Cara Menjalankan

### Prerequisites

```r
# Versi R yang digunakan
R version 4.5.1

# Paket yang diperlukan
install.packages(c(
  "dplyr",      # Data manipulation
  "lubridate",  # Parsing tanggal
  "zoo",        # Rolling statistics
  "moments",    # Skewness & kurtosis
  "tseries",    # Jarque-Bera test, KS-test
  "ggplot2",    # Visualisasi
  "knitr",      # Knit Rmd
  "kableExtra", # Tabel HTML
  "shiny"       # Dashboard interaktif
))
```

### Urutan Menjalankan File

> ⚠️ **Penting:** Jalankan file Rmd secara berurutan. Setiap file membaca ulang
> dari CSV sehingga tidak ada dependensi objek lintas sesi.

```
1. 01_usd_idr_data_wrangling.Rmd
2. 02_usd_idr_statistik_deskriptif.Rmd
3. 03_usd_idr_uji_normalitas.Rmd
4. 04_usd_idr_monte_carlo.Rmd
5. 05_usd_idr_analisis_hasil.Rmd
```

### Menjalankan Shiny App

```r
# Dari RStudio, buka app.R lalu klik "Run App"
# Atau dari console:
shiny::runApp("app.R")
```

### Pengaturan Working Directory

Pastikan file CSV (`Data Historis USD_IDR.csv`) berada di folder `data/`
dan sesuaikan path di setiap file Rmd:

```r
# Ganti path sesuai lokasi lokal Anda
setwd("D:/PROJECT PSS")
df_raw <- read.csv("data/Data Historis USD_IDR.csv")
```

---

## 📊 Hasil Utama

### Parameter GBM yang Diestimasi

| Parameter | Simbol | Nilai |
|-----------|--------|-------|
| Daily Drift | µ | *[hasil estimasi]* |
| Daily Volatility | σ | *[hasil estimasi]* |
| Annual Volatility | σ × √252 | *[hasil estimasi]* |

### Proyeksi Nilai Tukar (30 / 60 / 90 Hari)

| Horizon | Skenario Bearish | Skenario Base | Skenario Bullish |
|---------|-----------------|---------------|-----------------|
| +30 hari | *[nilai]* | *[nilai]* | *[nilai]* |
| +60 hari | *[nilai]* | *[nilai]* | *[nilai]* |
| +90 hari | *[nilai]* | *[nilai]* | *[nilai]* |

> *Tabel akan diperbarui setelah hasil simulasi final diperoleh.*

### Preview Visualisasi

| Time Series Plot | Fan Chart Proyeksi |
|-----------------|-------------------|
| *[screenshot]* | *[screenshot]* |

---

## 📄 Publikasi RPubs

Laporan analisis dipublikasikan secara terpisah di RPubs sesuai urutan pipeline:

| # | Judul | Link |
|---|-------|------|
| 1 | Data Wrangling & Preprocessing | *[coming soon]* |
| 2 | Statistik Deskriptif | *[coming soon]* |
| 3 | Uji Normalitas Log-Return | *[coming soon]* |
| 4 | Estimasi Parameter & Simulasi Monte Carlo | *[coming soon]* |
| 5 | Analisis Hasil & Proyeksi | *[coming soon]* |

---

## 🖥️ Dashboard Interaktif Shiny

Dashboard tersedia di: **[coming soon — shinyapps.io]**

Fitur dashboard:
- 📋 **Tab Data** — Tampilan tabel data historis dengan filter rentang tanggal
- 📈 **Tab Time Series** — Plot kurs penutupan harian interaktif
- 📊 **Tab Histogram** — Distribusi log-return dengan kurva normal
- 📉 **Tab QQ-Plot** — Uji visual normalitas log-return
- 🎲 **Tab Simulasi** — Visualisasi 3 skenario Monte Carlo interaktif

---

## 📚 Referensi

- Black, F., & Scholes, M. (1973). The Pricing of Options and Corporate Liabilities. *Journal of Political Economy*, 81(3), 637–654.
- Hull, J. C. (2018). *Options, Futures, and Other Derivatives* (10th ed.). Pearson.
- Glasserman, P. (2004). *Monte Carlo Methods in Financial Engineering*. Springer.
- Investing.com. (2025). *Historical Data USD/IDR*. https://www.investing.com

---

## 👤 Tentang Penulis

**Muhammad Faeruz Wafi Abidin**  
Mahasiswa S1 Statistika Terapan dan Komputasi  
Universitas Negeri Semarang (UNNES)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat-square&logo=linkedin)](https://linkedin.com/in/[username])
[![RPubs](https://img.shields.io/badge/RPubs-Profile-75AADB?style=flat-square)](https://rpubs.com/[username])
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=flat-square&logo=github)](https://github.com/[username])

---

## 📝 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).  
Data historis bersumber dari Investing.com untuk keperluan akademik non-komersial.
