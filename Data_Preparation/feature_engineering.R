# ============================
# Script: feature_engineering.R
# Purpose: Calculate indicators, returns, lags, scaling, and outlier flags
# Input: nvda_data (from import_data.R), macro_data_combined_daily (from handle_missing.R)
# Output: nvda_data with new engineered features
# ============================

# Load required libraries
library(TTR)
library(zoo)
library(dplyr) # Loaded last, but be aware it masks lag()

# Source the previous scripts to ensure data is loaded and handled
source("Data_Preparation/import_data.R") # Loads nvda_data and raw macro_vars
source("Data_Preparation/handle_missing.R") # Processes macro_vars into macro_data_combined_daily

# Confirm nvda_data exists
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run import_data.R first.")
# Confirm processed macro data exists
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
# Use stats::lag to ensure you're using the base R lag for xts objects, not dplyr's
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
# Find original macro names in nvda_data after merge (they should be CPIAUCNS, FEDFUNDS, etc.)
original_macro_names <- c("CPIAUCNS", "FEDFUNDS", "DGS10", "UNRATE", "GDP", "DTWEXM")

# Check if original macro names exist in nvda_data's columns
existing_macro_cols <- original_macro_names[original_macro_names %in% colnames(nvda_data)]

if (length(existing_macro_cols) == length(new_macro_names)) {
  # If all original macro names are found, rename them in order
  colnames(nvda_data)[match(existing_macro_cols, colnames(nvda_data))] <- new_macro_names
} else {
  warning("Not all macroeconomic columns found for renaming. Check `original_macro_names` and `nvda_data` columns.")
 
}


# ✅ Confirm macro variables added
print("✅ Macroeconomic features added to nvda_data.")

# ✅ Confirmation
print("✅ Feature engineering complete.")
print(tail(nvda_data[, c("SMA20", "RSI14", "MACD", "Signal", "volatility_20", "lag_close_1", "scaled_rsi", "cpi", "fed_funds")]))