library(shiny)
library(dplyr)
library(ggplot2)
library(lubridate)
library(zoo)

# ── Set working directory ─────────────────────────────────────────────────────
setwd("D:/PROJECT PSS")

# ── Baca data di level global (bukan reactive) ────────────────────────────────
df_global <- local({
  f <- "Data Historis USD_IDR.csv"
  df <- read.csv(f, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  df %>%
    select(Tanggal, Terakhir) %>%
    mutate(
      Kurs    = as.numeric(gsub(",", ".", gsub("\\.", "", Terakhir))),
      Tanggal = as.Date(Tanggal, format = "%d/%m/%Y")
    ) %>%
    select(Tanggal, Kurs) %>%
    arrange(Tanggal)
})

df_return_global <- df_global %>%
  mutate(Log_Return = log(Kurs / lag(Kurs))) %>%
  filter(!is.na(Log_Return))

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  tags$head(
    tags$link(
      href = "https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=Lora:ital,wght@0,400;0,600;1,400&display=swap",
      rel  = "stylesheet"
    ),
    tags$style(HTML("

      /* ── BASE ── */
      * { box-sizing: border-box; margin: 0; padding: 0; }

      body {
        background: linear-gradient(135deg, #f0f7ff 0%, #fafffe 50%, #f5f0ff 100%);
        font-family: 'Plus Jakarta Sans', sans-serif;
        color: #1a2332;
        min-height: 100vh;
      }

      /* ── HEADER ── */
      .app-header {
        background: linear-gradient(135deg, #1a2332 0%, #1e3a5f 60%, #0f4c75 100%);
        padding: 40px 52px 36px;
        position: relative;
        overflow: hidden;
      }
      .app-header::after {
        content: '';
        position: absolute;
        right: -80px; top: -80px;
        width: 320px; height: 320px;
        background: radial-gradient(circle, rgba(56,189,248,0.15) 0%, transparent 65%);
        pointer-events: none;
      }
      .app-header::before {
        content: '';
        position: absolute;
        left: 40%; bottom: -40px;
        width: 200px; height: 200px;
        background: radial-gradient(circle, rgba(99,102,241,0.1) 0%, transparent 65%);
        pointer-events: none;
      }
      .header-tag {
        display: inline-block;
        background: rgba(56,189,248,0.15);
        border: 1px solid rgba(56,189,248,0.3);
        color: #38bdf8;
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 3px;
        text-transform: uppercase;
        padding: 4px 12px;
        border-radius: 20px;
        margin-bottom: 14px;
      }
      .header-title {
        font-family: 'Lora', serif;
        font-size: clamp(28px, 4vw, 44px);
        font-weight: 600;
        color: #f8fafc;
        line-height: 1.15;
        margin-bottom: 10px;
      }
      .header-title em {
        font-style: italic;
        color: #38bdf8;
      }
      .header-sub {
        font-size: 12px;
        font-weight: 400;
        color: #94a3b8;
        letter-spacing: 0.3px;
      }

      /* ── STAT STRIP ── */
      .stat-strip {
        background: #ffffff;
        border-bottom: 1px solid #e2e8f0;
        padding: 0 52px;
        display: flex;
        gap: 0;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
      }
      .stat-item {
        flex: 1;
        padding: 20px 24px;
        border-right: 1px solid #f1f5f9;
        transition: background 0.2s;
      }
      .stat-item:last-child { border-right: none; }
      .stat-item:hover { background: #f8fafc; }
      .stat-item-label {
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 2px;
        text-transform: uppercase;
        color: #94a3b8;
        margin-bottom: 6px;
      }
      .stat-item-value {
        font-family: 'Lora', serif;
        font-size: 20px;
        font-weight: 600;
        color: #1a2332;
        line-height: 1;
      }
      .stat-item-value.up   { color: #059669; }
      .stat-item-value.down { color: #dc2626; }
      .stat-item-note {
        font-size: 11px;
        font-weight: 400;
        color: #94a3b8;
        margin-top: 3px;
      }

      /* ── LAYOUT ── */
      .main-wrap {
        display: grid;
        grid-template-columns: 240px 1fr;
        min-height: calc(100vh - 200px);
      }

      /* ── SIDEBAR ── */
      .side-panel {
        background: #ffffff;
        border-right: 1px solid #e2e8f0;
        padding: 28px 20px;
      }
      .side-section { margin-bottom: 28px; }
      .side-title {
        font-size: 9px;
        font-weight: 700;
        letter-spacing: 3px;
        text-transform: uppercase;
        color: #cbd5e1;
        margin-bottom: 12px;
        padding-bottom: 8px;
        border-bottom: 1px solid #f1f5f9;
      }

      /* ── NAV BUTTONS ── */
      .nav-group { display: flex; flex-direction: column; gap: 3px; }
      .nav-btn {
        background: transparent;
        border: 1px solid transparent;
        border-radius: 8px;
        padding: 9px 12px;
        color: #64748b;
        font-family: 'Plus Jakarta Sans', sans-serif;
        font-size: 13px;
        font-weight: 500;
        cursor: pointer;
        text-align: left;
        transition: all 0.18s;
        display: flex;
        align-items: center;
        gap: 9px;
        width: 100%;
      }
      .nav-btn:hover { background: #f8fafc; color: #1a2332; }
      .nav-btn.active {
        background: #eff6ff;
        border-color: #bfdbfe;
        color: #2563eb;
        font-weight: 600;
      }
      .nav-btn .ni { font-size: 15px; opacity: 0.7; }

      /* ── INPUTS ── */
      .ctrl-group { margin-bottom: 18px; }
      .ctrl-label {
        display: block;
        font-size: 10px;
        font-weight: 700;
        letter-spacing: 1.5px;
        text-transform: uppercase;
        color: #94a3b8;
        margin-bottom: 7px;
      }
      .form-control, .selectize-input {
        background: #f8fafc !important;
        border: 1px solid #e2e8f0 !important;
        border-radius: 8px !important;
        color: #1a2332 !important;
        font-family: 'Plus Jakarta Sans', sans-serif !important;
        font-size: 12px !important;
        font-weight: 500 !important;
      }
      .form-control:focus, .selectize-input.focus {
        border-color: #93c5fd !important;
        box-shadow: 0 0 0 3px rgba(147,197,253,0.2) !important;
        outline: none !important;
      }
      .selectize-dropdown {
        background: #ffffff !important;
        border: 1px solid #e2e8f0 !important;
        border-radius: 8px !important;
        box-shadow: 0 4px 12px rgba(0,0,0,0.08) !important;
        font-family: 'Plus Jakarta Sans', sans-serif !important;
        font-size: 12px !important;
      }
      .selectize-dropdown-content .option {
        color: #475569 !important;
        font-weight: 500 !important;
        padding: 8px 12px !important;
      }
      .selectize-dropdown-content .option.active {
        background: #eff6ff !important;
        color: #2563eb !important;
      }
      .irs--shiny .irs-bar {
        background: linear-gradient(90deg, #2563eb, #38bdf8) !important;
        border-top: none !important; border-bottom: none !important;
      }
      .irs--shiny .irs-handle {
        background: #2563eb !important;
        border: 2px solid #ffffff !important;
        box-shadow: 0 2px 6px rgba(37,99,235,0.35) !important;
      }
      .irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single {
        background: #2563eb !important;
        font-family: 'Plus Jakarta Sans', sans-serif !important;
        font-size: 10px !important;
        font-weight: 600 !important;
      }
      .irs--shiny .irs-line {
        background: #e2e8f0 !important;
        border: none !important;
      }
      .irs--shiny .irs-grid-text {
        color: #94a3b8 !important;
        font-size: 10px !important;
        font-weight: 600 !important;
        font-family: 'Plus Jakarta Sans', sans-serif !important;
      }
      .shiny-input-checkboxgroup label,
      .shiny-input-radiogroup label,
      label {
        color: #475569 !important;
        font-size: 12px !important;
        font-weight: 500 !important;
        font-family: 'Plus Jakarta Sans', sans-serif !important;
      }
      input[type='checkbox']:checked,
      input[type='radio']:checked { accent-color: #2563eb; }

      /* ── CONTENT ── */
      .content-panel {
        padding: 32px 40px;
        background: transparent;
      }
      .tab-content { display: none; }
      .tab-content.active { display: block; }

      /* ── PLOT CARD ── */
      .plot-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        overflow: hidden;
        box-shadow: 0 1px 4px rgba(0,0,0,0.04), 0 4px 16px rgba(0,0,0,0.04);
        margin-bottom: 20px;
      }
      .plot-card-header {
        padding: 20px 24px 16px;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
      }
      .plot-card-title {
        font-family: 'Lora', serif;
        font-size: 18px;
        font-weight: 600;
        color: #1a2332;
      }
      .plot-card-desc {
        font-size: 12px;
        font-weight: 400;
        color: #94a3b8;
        margin-top: 3px;
      }
      .plot-badge {
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 1px;
        text-transform: uppercase;
        padding: 4px 10px;
        border-radius: 20px;
        background: #eff6ff;
        color: #2563eb;
        border: 1px solid #bfdbfe;
        white-space: nowrap;
      }
      .plot-body { padding: 16px; }

      /* ── INSIGHT GRID ── */
      .ins-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 12px;
      }
      .ins-card {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 14px 16px;
        transition: border-color 0.2s, box-shadow 0.2s;
      }
      .ins-card:hover {
        border-color: #93c5fd;
        box-shadow: 0 2px 8px rgba(37,99,235,0.08);
      }
      .ins-card-label {
        font-size: 9px;
        font-weight: 700;
        letter-spacing: 2px;
        text-transform: uppercase;
        color: #94a3b8;
        margin-bottom: 5px;
      }
      .ins-card-value {
        font-family: 'Lora', serif;
        font-size: 17px;
        font-weight: 600;
        color: #1a2332;
      }
      .ins-card-note {
        font-size: 11px;
        font-weight: 400;
        color: #94a3b8;
        margin-top: 3px;
        line-height: 1.4;
      }

      /* ── FOOTER ── */
      .app-footer {
        background: #ffffff;
        border-top: 1px solid #e2e8f0;
        padding: 16px 52px;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      .footer-txt {
        font-size: 11px;
        font-weight: 500;
        color: #94a3b8;
      }
      .footer-dot {
        display: inline-block;
        width: 6px; height: 6px;
        background: #2563eb;
        border-radius: 50%;
        margin-right: 7px;
        animation: pulse 2s infinite;
      }

      /* ── ANIMATIONS ── */
      @keyframes pulse {
        0%,100% { opacity:1; transform:scale(1); }
        50%      { opacity:0.4; transform:scale(0.7); }
      }
      @keyframes fadeUp {
        from { opacity:0; transform:translateY(12px); }
        to   { opacity:1; transform:translateY(0); }
      }
      .app-header, .stat-strip, .main-wrap {
        animation: fadeUp 0.5s ease forwards;
      }

    "))
  ),

  # ── HEADER ──
  div(class = "app-header",
    div(class = "header-tag", "FOREX ANALYSIS DASHBOARD"),
    div(class = "header-title", "USD / ", tags$em("IDR"), " Historical Data"),
    div(class = "header-sub",
        "Geometric Brownian Motion · Monte Carlo Simulation · 2021–2025")
  ),

  # ── STAT STRIP ──
  div(class = "stat-strip",
    div(class = "stat-item",
      div(class = "stat-item-label", "Kurs Terakhir"),
      div(class = "stat-item-value", uiOutput("stat_last")),
      div(class = "stat-item-note", "IDR per USD")
    ),
    div(class = "stat-item",
      div(class = "stat-item-label", "Perubahan YTD"),
      div(class = "stat-item-value", uiOutput("stat_ytd")),
      div(class = "stat-item-note", "year-to-date 2025")
    ),
    div(class = "stat-item",
      div(class = "stat-item-label", "Volatilitas σ"),
      div(class = "stat-item-value", uiOutput("stat_vol")),
      div(class = "stat-item-note", "harian annualized")
    ),
    div(class = "stat-item",
      div(class = "stat-item-label", "Drift µ"),
      div(class = "stat-item-value", uiOutput("stat_mu")),
      div(class = "stat-item-note", "log-return harian")
    ),
    div(class = "stat-item",
      div(class = "stat-item-label", "Total Observasi"),
      div(class = "stat-item-value", uiOutput("stat_n")),
      div(class = "stat-item-note", "hari perdagangan")
    )
  ),

  # ── MAIN ──
  div(class = "main-wrap",

    # SIDEBAR
    div(class = "side-panel",
      div(class = "side-section",
        div(class = "side-title", "Navigasi"),
        div(class = "nav-group",
          actionButton("tab_ts",   HTML('<span class="ni">◈</span> Time Series'),   class = "nav-btn active"),
          actionButton("tab_hist", HTML('<span class="ni">▦</span> Distribusi Return'), class = "nav-btn"),
          actionButton("tab_qq",   HTML('<span class="ni">◎</span> QQ-Plot'),        class = "nav-btn")
        )
      ),
      div(class = "side-section",
        div(class = "side-title", "Filter Data"),
        div(class = "ctrl-group",
          tags$label(class = "ctrl-label", "Rentang Tahun"),
          sliderInput("year_range", label = NULL,
                      min = 2021, max = 2025, value = c(2021, 2025), step = 1, sep = "")
        )
      ),
      div(class = "side-section",
        div(class = "side-title", "Opsi Tampilan"),
        div(class = "ctrl-group",
          tags$label(class = "ctrl-label", "Warna Aksen"),
          selectInput("color_theme", label = NULL,
                      choices = c("Biru (Blue)" = "blue",
                                  "Hijau (Emerald)" = "emerald",
                                  "Ungu (Violet)" = "violet"),
                      selected = "blue")
        ),
        div(class = "ctrl-group",
          tags$label(class = "ctrl-label", "Overlay"),
          checkboxGroupInput("overlay_opts", label = NULL,
                             choices = c("Moving Average 50H" = "ma50",
                                         "Moving Average 200H" = "ma200"),
                             selected = "ma50")
        ),
        div(class = "ctrl-group",
          tags$label(class = "ctrl-label", "Bins Histogram"),
          sliderInput("hist_bins", label = NULL, min = 20, max = 100, value = 50, step = 5)
        )
      )
    ),

    # CONTENT
    div(class = "content-panel",

      # Tab 1
      div(id = "panel_ts", class = "tab-content active",
        div(class = "plot-card",
          div(class = "plot-card-header",
            div(
              div(class = "plot-card-title", "Pergerakan Kurs Penutupan"),
              div(class = "plot-card-desc", "Harga penutupan harian USD/IDR dengan moving average overlay.")
            ),
            div(class = "plot-badge", "CLOSING PRICE")
          ),
          div(class = "plot-body", plotOutput("plot_ts", height = "380px"))
        ),
        div(class = "ins-grid",
          div(class = "ins-card",
            div(class = "ins-card-label", "Nilai Minimum"),
            div(class = "ins-card-value", uiOutput("ins_min")),
            div(class = "ins-card-note", uiOutput("ins_min_date"))
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Nilai Maksimum"),
            div(class = "ins-card-value", uiOutput("ins_max")),
            div(class = "ins-card-note", uiOutput("ins_max_date"))
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Rata-rata"),
            div(class = "ins-card-value", uiOutput("ins_mean")),
            div(class = "ins-card-note", "Mean kurs pada periode dipilih")
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Std. Deviasi"),
            div(class = "ins-card-value", uiOutput("ins_sd")),
            div(class = "ins-card-note", "Volatilitas absolut kurs IDR")
          )
        )
      ),

      # Tab 2
      div(id = "panel_hist", class = "tab-content",
        div(class = "plot-card",
          div(class = "plot-card-header",
            div(
              div(class = "plot-card-title", "Distribusi Log-Return Harian"),
              div(class = "plot-card-desc", "Histogram dengan overlay kurva distribusi normal teoretis.")
            ),
            div(class = "plot-badge", "LOG-RETURN")
          ),
          div(class = "plot-body", plotOutput("plot_hist", height = "380px"))
        ),
        div(class = "ins-grid",
          div(class = "ins-card",
            div(class = "ins-card-label", "Mean Return µ"),
            div(class = "ins-card-value", uiOutput("ins_mu")),
            div(class = "ins-card-note", "Drift harian rata-rata")
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Std. Dev σ"),
            div(class = "ins-card-value", uiOutput("ins_sigma")),
            div(class = "ins-card-note", "Volatilitas harian")
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Skewness"),
            div(class = "ins-card-value", uiOutput("ins_skew")),
            div(class = "ins-card-note", "Kemiringan distribusi return")
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Kurtosis"),
            div(class = "ins-card-value", uiOutput("ins_kurt")),
            div(class = "ins-card-note", "Keruncingan — leptokurtik > 3")
          )
        )
      ),

      # Tab 3
      div(id = "panel_qq", class = "tab-content",
        div(class = "plot-card",
          div(class = "plot-card-header",
            div(
              div(class = "plot-card-title", "QQ-Plot — Uji Visual Normalitas"),
              div(class = "plot-card-desc",
                  "Membandingkan distribusi empiris log-return terhadap distribusi normal teoretis.")
            ),
            div(class = "plot-badge", "NORMALITY CHECK")
          ),
          div(class = "plot-body", plotOutput("plot_qq", height = "380px"))
        ),
        div(class = "ins-grid",
          div(class = "ins-card",
            div(class = "ins-card-label", "Interpretasi"),
            div(class = "ins-card-value", style = "font-size:14px;", "Fat Tails"),
            div(class = "ins-card-note",
                "Titik menyimpang di ujung garis → ekor lebih tebal dari normal.")
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Implikasi GBM"),
            div(class = "ins-card-value", style = "font-size:14px;", "Asumsi ≈ Valid"),
            div(class = "ins-card-note",
                "Bagian tengah mendekati garis normal. GBM masih dapat digunakan.")
          ),
          div(class = "ins-card",
            div(class = "ins-card-label", "Uji Formal"),
            div(class = "ins-card-value", style = "font-size:14px;", "KS-Test"),
            div(class = "ins-card-note",
                "Validasi formal pada Bagian 4 menggunakan Kolmogorov-Smirnov.")
          )
        )
      )
    )
  ),

  # ── FOOTER ──
  div(class = "app-footer",
    div(class = "footer-txt",
        tags$span(class = "footer-dot"),
        "USD/IDR Analysis · GBM & Monte Carlo · 2021–2025"),
    div(class = "footer-txt", "Built with R Shiny")
  ),

  tags$script(HTML("
    function switchTab(id, btnId) {
      document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
      document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
      document.getElementById('panel_' + id).classList.add('active');
      document.getElementById(btnId).classList.add('active');
    }
    $(document).on('click','#tab_ts',   () => switchTab('ts',   'tab_ts'));
    $(document).on('click','#tab_hist', () => switchTab('hist', 'tab_hist'));
    $(document).on('click','#tab_qq',   () => switchTab('qq',   'tab_qq'));
  "))
)

# ── SERVER ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # Warna aksen
  accent <- reactive({
    switch(input$color_theme,
      "blue"    = list(p = "#2563eb", s = "#38bdf8", ma50 = "#f59e0b", ma200 = "#8b5cf6"),
      "emerald" = list(p = "#059669", s = "#34d399", ma50 = "#f59e0b", ma200 = "#6366f1"),
      "violet"  = list(p = "#7c3aed", s = "#a78bfa", ma50 = "#f59e0b", ma200 = "#0891b2")
    )
  })

  # Data terfilter
  df_f <- reactive({
    df_global %>%
      filter(year(Tanggal) >= input$year_range[1],
             year(Tanggal) <= input$year_range[2])
  })

  # Return terfilter
  df_r <- reactive({
    df_f() %>%
      mutate(Log_Return = log(Kurs / lag(Kurs))) %>%
      filter(!is.na(Log_Return))
  })

  # ggplot theme bersih (light)
  theme_clean <- function() {
    theme_minimal(base_family = "sans") +
    theme(
      plot.background  = element_rect(fill = "#ffffff", color = NA),
      panel.background = element_rect(fill = "#ffffff", color = NA),
      panel.grid.major = element_line(color = "#f1f5f9", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      axis.text        = element_text(color = "#64748b", size = 10, face = "bold"),
      axis.title       = element_text(color = "#475569", size = 11, face = "bold"),
      plot.subtitle    = element_text(color = "#94a3b8", size = 10, face = "bold"),
      legend.text      = element_text(color = "#64748b", size = 10),
      legend.title     = element_blank(),
      legend.key       = element_rect(fill = "transparent", color = NA),
      plot.margin      = margin(12, 16, 12, 12)
    )
  }

  # ── STAT CARDS ──
  output$stat_last <- renderUI({
    val <- tail(df_f()$Kurs, 1)
    HTML(formatC(val, format = "f", digits = 0, big.mark = "."))
  })
  output$stat_ytd <- renderUI({
    d <- df_global %>% filter(year(Tanggal) == 2025)
    if (nrow(d) < 2) return(HTML("N/A"))
    pct <- (tail(d$Kurs,1) - d$Kurs[1]) / d$Kurs[1] * 100
    cls <- if (pct >= 0) "up" else "down"
    arrow <- if (pct >= 0) "▲" else "▼"
    HTML(sprintf('<span class="%s">%s %.2f%%</span>', cls, arrow, abs(pct)))
  })
  output$stat_vol <- renderUI({
    HTML(sprintf("%.2f%%", sd(df_return_global$Log_Return) * sqrt(252) * 100))
  })
  output$stat_mu <- renderUI({
    mu <- mean(df_return_global$Log_Return)
    cls <- if (mu >= 0) "up" else "down"
    HTML(sprintf('<span class="%s">%.6f</span>', cls, mu))
  })
  output$stat_n <- renderUI({
    HTML(formatC(nrow(df_f()), format = "d", big.mark = "."))
  })

  # ── PLOT TIME SERIES ──
  output$plot_ts <- renderPlot({
    col <- accent()
    df  <- df_f() %>%
      mutate(
        MA50  = rollmean(Kurs, k = 50,  fill = NA, align = "right"),
        MA200 = rollmean(Kurs, k = 200, fill = NA, align = "right")
      )

    p <- ggplot(df, aes(x = Tanggal, y = Kurs)) +
      geom_line(color = col$p, linewidth = 0.8, alpha = 0.9)

    if ("ma50"  %in% input$overlay_opts)
      p <- p + geom_line(aes(y = MA50),  color = col$ma50,  linewidth = 0.7, na.rm = TRUE, alpha = 0.85)
    if ("ma200" %in% input$overlay_opts)
      p <- p + geom_line(aes(y = MA200), color = col$ma200, linewidth = 0.7, na.rm = TRUE, alpha = 0.85)

    p +
      scale_y_continuous(labels = function(x) formatC(x, format="f", digits=0, big.mark=".")) +
      scale_x_date(date_breaks = "6 months", date_labels = "%b '%y") +
      labs(x = NULL, y = "Kurs (IDR)",
           subtitle = sprintf("Periode: %s — %s  |  n = %d hari perdagangan",
             format(min(df$Tanggal), "%d %b %Y"),
             format(max(df$Tanggal), "%d %b %Y"),
             nrow(df))) +
      theme_clean()
  })

  # ── PLOT HISTOGRAM ──
  output$plot_hist <- renderPlot({
    col <- accent()
    rt  <- df_r()$Log_Return
    mu  <- mean(rt)
    sig <- sd(rt)

    ggplot(data.frame(rt = rt), aes(x = rt)) +
      geom_histogram(aes(y = after_stat(density)),
                     bins = input$hist_bins,
                     fill = col$p, alpha = 0.25, color = col$p, linewidth = 0.3) +
      stat_function(fun = dnorm, args = list(mean = mu, sd = sig),
                    color = col$s, linewidth = 1.2) +
      geom_vline(xintercept = mu, color = "#ef4444",
                 linewidth = 0.9, linetype = "dashed", alpha = 0.8) +
      geom_vline(xintercept = 0, color = "#94a3b8",
                 linewidth = 0.5, linetype = "dotted", alpha = 0.7) +
      annotate("text", x = mu, y = Inf,
               label = sprintf("  µ = %.5f", mu),
               vjust = 1.8, hjust = -0.05,
               color = "#ef4444", size = 3.5, fontface = "bold") +
      labs(x = "Log-Return  rₜ = ln(Sₜ / Sₜ₋₁)", y = "Densitas",
           subtitle = sprintf("µ = %.6f  |  σ = %.6f  |  n = %d", mu, sig, length(rt))) +
      theme_clean()
  })

  # ── PLOT QQ ──
  output$plot_qq <- renderPlot({
    col <- accent()
    rt  <- df_r()$Log_Return

    df_qq <- data.frame(
      theoretical = qnorm(ppoints(length(rt))),
      sample      = sort(rt)
    )
    q_t  <- qnorm(c(0.25, 0.75))
    q_s  <- quantile(rt, c(0.25, 0.75))
    sl   <- diff(q_s) / diff(q_t)
    intc <- q_s[1] - sl * q_t[1]

    ggplot(df_qq, aes(x = theoretical, y = sample)) +
      geom_abline(intercept = intc, slope = sl,
                  color = "#94a3b8", linewidth = 1, alpha = 0.7) +
      geom_point(color = col$p, alpha = 0.4, size = 1.3, shape = 16) +
      labs(x = "Kuantil Teoretis (Normal)", y = "Kuantil Sampel (Log-Return)",
           subtitle = sprintf(
             "Penyimpangan di ekor → distribusi leptokurtik  |  n = %d", length(rt))) +
      theme_clean()
  })

  # ── INSIGHT BOXES ──
  output$ins_min  <- renderUI({ HTML(formatC(min(df_f()$Kurs),  format="f", digits=0, big.mark=".")) })
  output$ins_min_date <- renderUI({ HTML(format(df_f()$Tanggal[which.min(df_f()$Kurs)], "%d %b %Y")) })
  output$ins_max  <- renderUI({ HTML(formatC(max(df_f()$Kurs),  format="f", digits=0, big.mark=".")) })
  output$ins_max_date <- renderUI({ HTML(format(df_f()$Tanggal[which.max(df_f()$Kurs)], "%d %b %Y")) })
  output$ins_mean <- renderUI({ HTML(formatC(mean(df_f()$Kurs), format="f", digits=0, big.mark=".")) })
  output$ins_sd   <- renderUI({ HTML(formatC(sd(df_f()$Kurs),   format="f", digits=0, big.mark=".")) })
  output$ins_mu   <- renderUI({ HTML(sprintf("%.6f", mean(df_r()$Log_Return))) })
  output$ins_sigma<- renderUI({ HTML(sprintf("%.6f", sd(df_r()$Log_Return))) })
  output$ins_skew <- renderUI({
    rt <- df_r()$Log_Return; n <- length(rt)
    s  <- (n/((n-1)*(n-2))) * sum(((rt-mean(rt))/sd(rt))^3)
    cls <- if (s < -0.5) "down" else if (s > 0.5) "up" else ""
    HTML(sprintf('<span class="%s">%.4f</span>', cls, s))
  })
  output$ins_kurt <- renderUI({
    rt <- df_r()$Log_Return; n <- length(rt)
    k  <- (n*(n+1)/((n-1)*(n-2)*(n-3))) * sum(((rt-mean(rt))/sd(rt))^4) -
          3*(n-1)^2/((n-2)*(n-3))
    HTML(sprintf("%.4f", k))
  })
}

shinyApp(ui = ui, server = server)
