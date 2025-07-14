# ============================
# Script: data_quality_checks.R
# Purpose: Check for duplicates, remove NAs, and save cleaned data
# ============================

library(dplyr)
library(xts)

# Confirm nvda_data exists
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run feature_engineering.R first.")

# --- Check for duplicates ---
# For xts objects, the index (timestamps) are inherently unique.
# Duplicates in the index would typically result from incorrect merges or data sources.
dup_count <- sum(duplicated(index(nvda_data)))
print(paste("🔍 Duplicate timestamps in nvda_data index:", dup_count))

# If duplicates are found, you might want to investigate the source.
# For now, we'll proceed assuming the `duplicated` check confirms uniqueness for xts indices.

# --- Remove NA rows (Best Practice for Modeling) ---
# This step is crucial. It removes any rows where *any* feature has an NA value.
# This handles initial NAs from indicator calculation 'burn-in' periods
# and NAs for macro data if your NVDA data starts before macro data is available.
initial_rows <- NROW(nvda_data)
nvda_data <- na.omit(nvda_data)
removed_rows <- initial_rows - NROW(nvda_data)
if (removed_rows > 0) {
  print(paste("🧹 Removed", removed_rows, "rows due to NA values."))
} else {
  print("✅ No NA rows found after feature engineering (or all NAs already handled).")
}

# Convert xts to data frame with date column for saving as CSV/RDS
# It's better to perform this conversion *after* all xts operations (like na.omit).
nvda_data_df <- data.frame(date = index(nvda_data), coredata(nvda_data))

# (Optional) Remove duplicates from data.frame after conversion
# This line is redundant if `duplicated(index(nvda_data))` above shows 0,
# but harmless if you want to be extra cautious after converting to data.frame.
nvda_data_df <- nvda_data_df[!duplicated(nvda_data_df$date), ]

# --- Save cleaned data ---
dir.create("Data_Clean", showWarnings = FALSE)
write.csv(nvda_data_df, "Data_Clean/cleaned_nvda_data.csv", row.names = FALSE)
saveRDS(nvda_data_df, file = "Data_Clean/cleaned_nvda_data.rds")

print("✅ Data quality check complete. Cleaned dataset saved.")