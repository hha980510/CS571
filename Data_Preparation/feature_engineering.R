# ============================
# Script: feature_engineering.R
# Purpose: Calculate indicators, returns, lags, scaling, and outlier flags
# Input: nvda_data (from import_data.R)
# Output: nvda_data with new engineered features
# ============================

# Load required libraries
library(TTR)
library(zoo)
library(dplyr)  # Loaded last, but be aware it masks lag()

source("Data_Preparation/import_data.R")
source("Data_Preparation/handle_missing.R")

# Confirm nvda_data exists
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run import_data.R first.")

# === Technical Indicators ===
nvda_data$SMA20  <- SMA(Cl(nvda_data), n = 20)
nvda_data$RSI14  <- RSI(Cl(nvda_data), n = 14)
macd_vals        <- MACD(Cl(nvda_data), nFast = 12, nSlow = 26, nSig = 9, maType = EMA)
nvda_data$MACD   <- macd_vals$macd
nvda_data$Signal <- macd_vals$signal

# === Log Returns & Volatility ===
nvda_data$log_return    <- diff(log(Cl(nvda_data)))
nvda_data$volatility_20 <- rollapply(nvda_data$log_return, 20, sd, fill = NA)

# === Lagged Features ===
nvda_data$lag_close_1  <- stats::lag(Cl(nvda_data), 1)
nvda_data$lag_return_1 <- stats::lag(nvda_data$log_return, 1)

# === Feature Scaling ===
nvda_data$scaled_close <- scale(Cl(nvda_data))
nvda_data$scaled_rsi   <- scale(nvda_data$RSI14)

# === Outlier Detection ===
nvda_data$z_return <- scale(nvda_data$log_return)
nvda_data$outlier  <- abs(nvda_data$z_return) > 3

# === Merge Macroeconomic Indicators ===

# Ensure macro data is available
macro_xts <- merge(CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM)

# Align frequency: convert macro to daily using last observation carried forward
macro_daily <- na.locf(merge(index(nvda_data), macro_xts), fromLast = FALSE)

# Merge with nvda_data by date
nvda_data <- merge(nvda_data, macro_daily, join = "left")

# Rename macro columns for clarity
colnames(nvda_data)[(ncol(nvda_data)-5):ncol(nvda_data)] <- c(
  "cpi", "fed_funds", "treasury_10y", "unemployment", "gdp", "usd_index"
)

# ✅ Confirm macro variables added
print("✅ Macroeconomic features added to nvda_data.")

# ✅ Confirmation
print("✅ Feature engineering complete.")
print(tail(nvda_data[, c("SMA20", "RSI14", "MACD", "Signal", "volatility_20", "lag_close_1", "scaled_rsi")]))
