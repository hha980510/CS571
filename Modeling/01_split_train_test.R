# ============================================
# Script: 01_split_train_test.R
# Purpose: Split cleaned data into training and testing sets (time-aware)
# ============================================

library(dplyr)
library(lubridate)

cat("📦 Starting train/test split...\n")

# Load cleaned data
df <- readRDS("Data_Clean/nvda_data_with_targets.rds")
cat("✅ Cleaned data loaded. Total rows:", nrow(df), "\n")

# Ensure date is in Date format
df$date <- as.Date(df$date)

# Set split date (e.g., everything before this is training)
split_date <- as.Date("2023-01-01")

# Create splits
train_set <- df %>% filter(date < split_date)
test_set  <- df %>% filter(date >= split_date)

cat("✅ Train set rows:", nrow(train_set), "from", min(train_set$date), "to", max(train_set$date), "\n")
cat("✅ Test set rows :", nrow(test_set), "from", min(test_set$date), "to", max(test_set$date), "\n")

# Create folder if it doesn't exist
if (!dir.exists("Modeling/Data_Splits")) {
  dir.create("Modeling/Data_Splits", recursive = TRUE)
}

# Save RDS files
saveRDS(train_set, "Modeling/Data_Splits/train_set.rds")
saveRDS(test_set,  "Modeling/Data_Splits/test_set.rds")

cat("💾 Train and test sets saved in Modeling/Data_Splits/\n")
cat("✅ Train/test splitting complete.\n")
