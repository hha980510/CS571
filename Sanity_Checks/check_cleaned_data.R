# ============================================
# Script: check_cleaned_data.R
# Purpose: Check final cleaned data for anomalies or missing targets
# ============================================

library(dplyr)

cat("📦 Starting sanity check for nvda_data_with_targets...\n")

# Load cleaned data
df <- readRDS("Data_Clean/nvda_data_with_targets.rds")
cat(paste("✅ Data loaded. Rows:", nrow(df), "Columns:", ncol(df), "\n"))

# Check for NAs
na_summary <- colSums(is.na(df))
cat("🔍 Columns with missing values:\n")
print(na_summary[na_summary > 0])

# Expected target columns
expected_targets <- c("Target_5_Price", "Target_10_Price", "Target_21_Price",
                      "Target_5_Direction", "Target_10_Direction", "Target_21_Direction")

missing_targets <- setdiff(expected_targets, colnames(df))
if (length(missing_targets) > 0) {
  cat("❌ Missing expected target columns:\n")
  print(missing_targets)
} else {
  cat("✅ All expected target columns are present.\n")
}

# Check for extreme values
cat("\n📊 Basic stats for price targets:\n")
summary(df %>% select(all_of(expected_targets[grepl("Price", expected_targets)])))

cat("\n📊 Distribution of directional targets:\n")
print(sapply(df %>% select(all_of(expected_targets[grepl("Direction", expected_targets)])), table))

# Check correlation with current price (should be positive, not too high)
if ("NVDA.Close" %in% colnames(df)) {
  cat("\n📈 Correlation between NVDA.Close and targets:\n")
  cors <- sapply(df %>% select(all_of(expected_targets[grepl("Price", expected_targets)])),
                 function(x) cor(df$NVDA.Close, x, use = "complete.obs"))
  print(cors)
}

cat("\n✅ Sanity checks complete.\n")
