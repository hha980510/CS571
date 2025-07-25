# ============================
# Script: feature_engineering.R
# Purpose: Calculate technical indicators, returns, lags, scaling, and merge macro data
# Output: nvda_data_fully_engineered.rds
# ============================

library(TTR)
library(zoo)
library(dplyr)

# Load data
nvda_data <- readRDS("Data/nvda_data_after_missing_handling.rds")
macro_data_combined_daily <- readRDS("Data/macro_data_combined_daily.rds")

if (!exists("nvda_data")) stop("❌ 'nvda_data' missing. Run handle_missing.R first.")
if (!exists("macro_data_combined_daily")) stop("❌ 'macro_data_combined_daily' missing. Run handle_missing.R first.")

# Technical indicators
nvda_data$SMA20  <- SMA(Cl(nvda_data), n = 20)
nvda_data$RSI14  <- RSI(Cl(nvda_data), n = 14)
macd_vals        <- MACD(Cl(nvda_data), nFast = 12, nSlow = 26, nSig = 9, maType = EMA)
nvda_data$MACD   <- macd_vals$macd
nvda_data$Signal <- macd_vals$signal

# Returns and volatility
nvda_data$log_return    <- diff(log(Cl(nvda_data)))
nvda_data$volatility_20 <- rollapply(nvda_data$log_return, 20, sd, fill = NA)

# Lag features
nvda_data$lag_close_1  <- stats::lag(Cl(nvda_data), 1)
nvda_data$lag_return_1 <- stats::lag(nvda_data$log_return, 1)

# Scaled features
nvda_data$scaled_close <- scale(Cl(nvda_data))
nvda_data$scaled_rsi   <- scale(nvda_data$RSI14)

# Outliers
nvda_data$z_return <- scale(nvda_data$log_return)
nvda_data$outlier  <- abs(nvda_data$z_return) > 3

# Merge macro data
nvda_data <- merge(nvda_data, macro_data_combined_daily, join = "left")

# Rename macro columns
macro_old <- c("CPIAUCNS", "FEDFUNDS", "DGS10", "UNRATE", "GDP", "DTWEXM")
macro_new <- c("cpi", "fed_funds", "treasury_10y", "unemployment", "gdp", "usd_index")
valid_cols <- macro_old[macro_old %in% colnames(nvda_data)]

if (length(valid_cols) == length(macro_new)) {
  colnames(nvda_data)[match(valid_cols, colnames(nvda_data))] <- macro_new
} else {
  warning("⚠️ Not all macro columns found for renaming.")
}

# Save output
saveRDS(nvda_data, file = "Data/nvda_data_fully_engineered.rds")
message("✅ Feature engineering complete.")