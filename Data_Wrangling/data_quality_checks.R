# ============================
# Script: data_quality_checks.R
# Purpose: Check for duplicates and save cleaned data
# ============================

library(dplyr)
library(xts)

# Confirm nvda_data exists
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run feature_engineering.R first.")

# Convert xts to data frame with date column
nvda_data_df <- data.frame(date = index(nvda_data), coredata(nvda_data))

# --- Check for duplicates ---
dup_count <- sum(duplicated(nvda_data_df$date))
print(paste("🔍 Duplicate timestamps:", dup_count))

# (Optional) Remove duplicates
# nvda_data_df <- nvda_data_df[!duplicated(nvda_data_df$date), ]

# --- Save cleaned data ---
dir.create("Data_Clean", showWarnings = FALSE)
write.csv(nvda_data_df, "Data_Clean/cleaned_nvda_data.csv", row.names = FALSE)
saveRDS(nvda_data_df, file = "Data_Clean/cleaned_nvda_data.rds")

print("✅ Data quality check complete. Cleaned dataset saved.")
