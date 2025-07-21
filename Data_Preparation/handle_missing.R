# ============================================
# Script: handle_missing.R
# Purpose: Align macroeconomic and stock data to daily frequency
# Output: Aligned and forward-filled RDS files
# ============================================

library(xts)
library(zoo)
library(lubridate)

# Load raw data
nvda_data <- readRDS("Data_Clean/nvda_data_raw.rds")
macro_data_raw <- readRDS("Data_Clean/macro_data_raw.rds")

if (!exists("macro_data_raw") || NCOL(macro_data_raw) < 6) {
  stop("❌ Missing or incomplete macro data. Run import_data.R.")
}

# Extract individual macro series
CPIAUCNS <- macro_data_raw$CPIAUCNS
FEDFUNDS <- macro_data_raw$FEDFUNDS
DGS10    <- macro_data_raw$DGS10
UNRATE   <- macro_data_raw$UNRATE
GDP      <- macro_data_raw$GDP
DTWEXM   <- macro_data_raw$DTWEXM

# Create daily template
start <- min(index(nvda_data)[1], index(macro_data_raw)[1])
end <- max(index(nvda_data)[NROW(nvda_data)], index(macro_data_raw)[NROW(macro_data_raw)])
all_dates <- seq(start, end, by = "day")
daily_template <- xts(order.by = all_dates)

# CPI: monthly, released mid-next month
cpi_dates <- index(CPIAUCNS) + months(1) + days(14)
valid <- !is.na(cpi_dates) & !is.infinite(cpi_dates)
CPIAUCNS_daily <- xts(coredata(CPIAUCNS)[valid], order.by = cpi_dates[valid])
CPIAUCNS_daily <- na.locf(merge(daily_template, CPIAUCNS_daily), na.rm = FALSE)
CPIAUCNS_daily <- na.locf(CPIAUCNS_daily, fromLast = TRUE)
colnames(CPIAUCNS_daily) <- "CPIAUCNS"

# UNRATE: monthly, released early next month
unrate_dates <- index(UNRATE) + months(1)
valid <- !is.na(unrate_dates) & !is.infinite(unrate_dates)
UNRATE_daily <- xts(coredata(UNRATE)[valid], order.by = unrate_dates[valid])
UNRATE_daily <- na.locf(merge(daily_template, UNRATE_daily), na.rm = FALSE)
UNRATE_daily <- na.locf(UNRATE_daily, fromLast = TRUE)
colnames(UNRATE_daily) <- "UNRATE"

# GDP: quarterly, released in first month of next quarter
gdp_dates <- index(GDP) + months(3) - days(1)
valid <- !is.na(gdp_dates) & !is.infinite(gdp_dates)
GDP_daily <- xts(coredata(GDP)[valid], order.by = gdp_dates[valid])
GDP_daily <- na.locf(merge(daily_template, GDP_daily), na.rm = FALSE)
GDP_daily <- na.locf(GDP_daily, fromLast = TRUE)
colnames(GDP_daily) <- "GDP"

# Daily/biz-daily indicators
FEDFUNDS_daily <- na.locf(na.locf(merge(daily_template, FEDFUNDS), fromLast = TRUE))
colnames(FEDFUNDS_daily) <- "FEDFUNDS"

DGS10_daily <- na.locf(na.locf(merge(daily_template, DGS10), fromLast = TRUE))
colnames(DGS10_daily) <- "DGS10"

DTWEXM_daily <- na.locf(na.locf(merge(daily_template, DTWEXM), fromLast = TRUE))
colnames(DTWEXM_daily) <- "DTWEXM"

# Merge all macro series
macro_data_combined_daily <- merge(
  CPIAUCNS_daily, FEDFUNDS_daily, DGS10_daily,
  UNRATE_daily, GDP_daily, DTWEXM_daily
)

assign("macro_data_combined_daily", macro_data_combined_daily, envir = globalenv())

# Align NVDA data with daily calendar
nvda_data_daily <- merge(daily_template, nvda_data, join = "left")
nvda_data_daily <- na.locf(nvda_data_daily, na.rm = FALSE)
nvda_data_daily <- na.locf(nvda_data_daily, fromLast = TRUE)

nvda_data_after_missing_handling <- nvda_data_daily

# Save cleaned data
saveRDS(nvda_data_after_missing_handling, "Data_Clean/nvda_data_after_missing_handling.rds")
saveRDS(macro_data_combined_daily, "Data_Clean/macro_data_combined_daily.rds")

message("✅ Macroeconomic data aligned to daily frequency.")
message("✅ NVDA data aligned and cleaned.")