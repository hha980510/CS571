# ============================
# Script: clean_column_structure.R
# Purpose: Clean column structure of nvda_data
# ============================

library(dplyr)

if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run feature_engineering.R first.")

# Drop constant columns
nvda_data <- nvda_data[, !sapply(nvda_data, function(col) {
  unique_vals <- unique(na.omit(col))
  length(unique_vals) <= 1
})]

print("✅ Clean column structure complete.")
