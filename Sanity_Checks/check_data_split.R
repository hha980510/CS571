# ============================================
# Script: check_data_split.R
# Purpose: Sanity check on train/test datasets
# ============================================

library(dplyr)

cat("📦 Starting train/test sanity check...\n")

# Load data
train_set <- readRDS("Modeling/Data_Splits/train_set.rds")
test_set  <- readRDS("Modeling/Data_Splits/test_set.rds")

cat("✅ Train set loaded. Rows:", nrow(train_set), "Columns:", ncol(train_set), "\n")
cat("✅ Test set loaded. Rows :", nrow(test_set),  "Columns:", ncol(test_set), "\n")

# Check for NA values
na_train <- sum(is.na(train_set))
na_test <- sum(is.na(test_set))

cat("\n🔍 NA check:\n")
cat("Train set NAs:", na_train, "\n")
cat("Test set NAs :", na_test, "\n")

# Check date ranges
cat("\n🗓️ Date range check:\n")
cat("Train set date range:", as.character(min(train_set$date)), "to", as.character(max(train_set$date)), "\n")
cat("Test set date range :", as.character(min(test_set$date)), "to", as.character(max(test_set$date)), "\n")

# Check structure
cat("\n📋 Column presence check:\n")
required_columns <- c("SMA20", "RSI14", "MACD", "Signal", "log_return", "volatility_20",
                      "cpi", "fed_funds", "treasury_10y", "unemployment", "gdp", "usd_index",
                      "Target_5_Price", "Target_10_Price", "Target_21_Price",
                      "Target_5_Direction", "Target_10_Direction", "Target_21_Direction")
missing_train <- setdiff(required_columns, colnames(train_set))
missing_test <- setdiff(required_columns, colnames(test_set))

if (length(missing_train) > 0) {
  cat("❌ Missing in train set:\n")
  print(missing_train)
} else {
  cat("✅ All required columns present in train set.\n")
}

if (length(missing_test) > 0) {
  cat("❌ Missing in test set:\n")
  print(missing_test)
} else {
  cat("✅ All required columns present in test set.\n")
}

# Check target distributions
cat("\n📊 Direction target distributions in train set:\n")
print(sapply(train_set %>% select(starts_with("Target_") & ends_with("Direction")), table))

cat("\n📊 Direction target distributions in test set:\n")
print(sapply(test_set %>% select(starts_with("Target_") & ends_with("Direction")), table))

cat("\n✅ Train/test split validation complete.\n")
