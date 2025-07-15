# ============================
# Script: data_quality_checks.R
# Purpose: Check for duplicates, remove NAs, and save cleaned data
# ============================

library(dplyr)
library(xts)

# Confirm nvda_data exists
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run feature_engineering.R first.")

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

# (Optional) Remove duplicates from data.frame after conversion
nvda_data_df <- nvda_data_df[!duplicated(nvda_data_df$date), ]

# --- Save cleaned data ---
dir.create("Data_Clean", showWarnings = FALSE)
write.csv(nvda_data_df, "Data_Clean/cleaned_nvda_data.csv", row.names = FALSE)
saveRDS(nvda_data_df, file = "Data_Clean/cleaned_nvda_data.rds")

print("✅ Data quality check complete. Cleaned dataset saved.")
