# ============================
# Script: data_quality_checks.R
# Purpose: Final data cleanup (remove NAs, duplicates check)
# Output: cleaned_nvda_data.csv, cleaned_nvda_data.rds
# ============================

library(dplyr)
library(xts)

# Load data
nvda_data <- readRDS("Data_Clean/nvda_data_structured_clean.rds")
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing.")

# Check for duplicates
dup_count <- sum(duplicated(index(nvda_data)))
message("🔍 Duplicate timestamps in index: ", dup_count)

# Remove rows with NA
initial_rows <- NROW(nvda_data)
nvda_data <- na.omit(nvda_data)
removed_rows <- initial_rows - NROW(nvda_data)
message("🧹 Removed ", removed_rows, " rows with NA values.")

# Save as data frame
nvda_data_df <- data.frame(date = index(nvda_data), coredata(nvda_data))

# Save cleaned dataset
dir.create("Data_Clean", showWarnings = FALSE)
write.csv(nvda_data_df, "Data_Clean/cleaned_nvda_data.csv", row.names = FALSE)
saveRDS(nvda_data_df, "Data_Clean/cleaned_nvda_data.rds")

message("✅ Final cleaned dataset saved.")