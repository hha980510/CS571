# =====================================
# Script: 00_modeling_setup.R
# Purpose: Setup environment and configs for modeling
# =====================================

# Load libraries
library(dplyr)
library(readr)

# Load cleaned dataset
df <- readRDS("Data_Clean/nvda_data_with_targets.rds")

# Define technical indicators
technical_features <- c("SMA20", "RSI14", "MACD", "Signal",
                        "log_return", "volatility_20")

# Define economic indicators
economic_features <- c("cpi", "fed_funds", "treasury_10y", "unemployment", "gdp", "usd_index")

# Combine into full feature set
all_features <- c(technical_features, economic_features)

# Define target columns
price_targets <- c("Target_5_Price", "Target_10_Price", "Target_21_Price")
direction_targets <- c("Target_5_Direction", "Target_10_Direction", "Target_21_Direction")

# Define modeling results directory
results_folder <- "Results"

# Create the folder if it doesn’t exist
if (!dir.exists(results_folder)) {
  dir.create(results_folder)
}

cat("✅ Modeling setup complete.\n")
