# ============================
# Script: data_quality_checks.R
# Purpose: Check for duplicates, remove NAs, and save final cleaned data
# Input: Data_Clean/nvda_data_structured_clean.rds
# Output: cleaned_nvda_data.csv, cleaned_nvda_data.rds
# ============================

library(dplyr)
library(xts)

# --- Load data from previous stage ---
nvda_data <- readRDS("Data_Clean/nvda_data_structured_clean.rds")

if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run clean_column_structure.R first.")

# --- Check for duplicates ---
dup_count <- sum(duplicated(index(nvda_data)))
print(paste("🔍 Duplicate timestamps in nvda_data index:", dup_count))

# --- Remove NA rows (Best Practice for Modeling) ---
initial_rows <- NROW(nvda_data)
nvda_data <- na.omit(nvda_data)
removed_rows <- initial_rows - NROW(nvda_data)
if (removed_rows > 0) {
  print(paste("🧹 Removed", removed_rows, "rows due to NA values."))
} else {
  print("✅ No NA rows found after feature engineering (or all NAs already handled).")
}

# Convert xts to data frame with date column for saving as CSV/RDS
nvda_data_df <- data.frame(date = index(nvda_data), coredata(nvda_data))

# --- Save cleaned data ---
dir.create("Data_Clean", showWarnings = FALSE) # Ensure directory exists
write.csv(nvda_data_df, "Data_Clean/cleaned_nvda_data.csv", row.names = FALSE)
saveRDS(nvda_data_df, file = "Data_Clean/cleaned_nvda_data.rds")

print("✅ Data quality check complete. Cleaned dataset saved.")