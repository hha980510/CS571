# ============================
# Script: feature_engineering.R
# Purpose: Calculate indicators, returns, lags, scaling, and outlier flags
# Input: Data_Clean/nvda_data_after_missing_handling.rds, Data_Clean/macro_data_combined_daily.rds
# Output: nvda_data with new engineered features
# Save: nvda_data_fully_engineered.rds
# ============================

library(TTR)
library(zoo)
library(dplyr)

# --- Load data from previous stage ---
nvda_data <- readRDS("Data_Clean/nvda_data_after_missing_handling.rds")
macro_data_combined_daily <- readRDS("Data_Clean/macro_data_combined_daily.rds")

# Confirm data exists
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run handle_missing.R first.")
if (!exists("macro_data_combined_daily")) stop("❌ 'macro_data_combined_daily' is missing. Please run handle_missing.R first.")

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
nvda_data <- merge(nvda_data, macro_data_combined_daily, join = "left")
new_macro_names <- c("cpi", "fed_funds", "treasury_10y", "unemployment", "gdp", "usd_index")
original_macro_names <- c("CPIAUCNS", "FEDFUNDS", "DGS10", "UNRATE", "GDP", "DTWEXM")
existing_macro_cols <- original_macro_names[original_macro_names %in% colnames(nvda_data)]

if (length(existing_macro_cols) == length(new_macro_names)) {
  colnames(nvda_data)[match(existing_macro_cols, colnames(nvda_data))] <- new_macro_names
} else {
  warning("Not all macroeconomic columns found for renaming.")
}

# --- Save Fully Engineered Data ---
saveRDS(nvda_data, file = "Data_Clean/nvda_data_fully_engineered.rds")

print("✅ Feature engineering complete and fully engineered data saved.")