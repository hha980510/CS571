# ============================
# Script: clean_column_structure.R
# Purpose: Clean column structure of nvda_data (remove constants)
# Input: Data_Clean/nvda_data_fully_engineered.rds
# Save: nvda_data_structured_clean.rds
# ============================

library(dplyr)
library(xts)

# --- Load data from previous stage ---
nvda_data <- readRDS("Data_Clean/nvda_data_fully_engineered.rds")

if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run feature_engineering.R first.")

# Drop constant columns
cols_to_keep <- sapply(nvda_data, function(col) {
  unique_vals <- unique(na.omit(coredata(col)))
  length(unique_vals) > 1
})

nvda_data <- nvda_data[, cols_to_keep]

# --- Save Data After Structure Cleaning ---
saveRDS(nvda_data, file = "Data_Clean/nvda_data_structured_clean.rds")

print("✅ Clean column structure complete and data saved.")