# ============================
# Script: clean_column_structure.R
# Purpose: Clean column structure of nvda_data
# ============================

library(dplyr)
library(xts) # Ensure xts is loaded for proper xts operations, even if dplyr is used

if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run feature_engineering.R first.")

# Drop constant columns
# Use coredata() to work on the numeric matrix, as sapply on xts directly can be tricky
# And then re-create xts if necessary, or ensure the operation is xts-compatible
# A safer way is to identify columns to keep and subset
cols_to_keep <- sapply(nvda_data, function(col) {
  # Use na.omit to ignore NAs when checking for unique values
  unique_vals <- unique(na.omit(coredata(col)))
  length(unique_vals) > 1
})

nvda_data <- nvda_data[, cols_to_keep]

print("✅ Clean column structure complete.")