# ============================
# Script: clean_column_structure.R
# Purpose: Remove constant columns from nvda_data
# Output: nvda_data_structured_clean.rds
# ============================

library(dplyr)
library(xts)

# Load data
nvda_data <- readRDS("Data_Clean/nvda_data_fully_engineered.rds")
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing.")

# Remove constant columns
cols_to_keep <- sapply(nvda_data, function(col) {
  unique_vals <- unique(na.omit(coredata(col)))
  length(unique_vals) > 1
})
nvda_data <- nvda_data[, cols_to_keep]

# Save result
saveRDS(nvda_data, file = "Data_Clean/nvda_data_structured_clean.rds")
message("✅ Constant columns removed and data saved.")