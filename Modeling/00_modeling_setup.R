# ==============================
# Script: 00_modeling_setup.R
# Purpose: Configure modeling environment
# ==============================

library(dplyr)
library(readr)

# Load data
df <- readRDS("Data/nvda_data_with_targets.rds")

# Feature groups
technical_features <- c("SMA20", "RSI14", "MACD", "Signal", "log_return", "volatility_20")
economic_features  <- c("cpi", "fed_funds", "treasury_10y", "unemployment", "gdp", "usd_index")
all_features <- c(technical_features, economic_features)

# Targets
price_targets     <- c("Target_5_Price", "Target_10_Price", "Target_21_Price")
direction_targets <- c("Target_5_Direction", "Target_10_Direction", "Target_21_Direction")

# Results directory
results_folder <- "Results"
if (!dir.exists(results_folder)) dir.create(results_folder)
results_log_file <- file.path(results_folder, "all_model_metrics.csv")

cat("✅ Modeling setup complete.\n")