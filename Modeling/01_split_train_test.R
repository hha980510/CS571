# ==============================
# Script: 01_split_train_test.R
# Purpose: Split data into train/test sets (time-aware)
# ==============================

library(dplyr)
library(lubridate)

cat("📦 Starting train/test split...\n")

# Load data
df <- readRDS("Data/nvda_data_with_targets.rds")
cat("✅ Data loaded. Total rows:", nrow(df), "\n")

# Ensure date format
df$date <- as.Date(df$date)

# Remove invalid target rows
target_cols <- grep("Target", names(df), value = TRUE)
df <- df %>% filter(if_all(all_of(target_cols), ~ !is.na(.) & is.finite(.)))
cat("✅ Valid target rows retained. Remaining rows:", nrow(df), "\n")

# Time-based split
split_date <- as.Date("2023-01-01")
train_set  <- df %>% filter(date < split_date)
test_set   <- df %>% filter(date >= split_date)

cat("✅ Train set:", nrow(train_set), "rows (", min(train_set$date), "to", max(train_set$date), ")\n")
cat("✅ Test set :", nrow(test_set), "rows (", min(test_set$date), "to", max(test_set$date), ")\n")

# Save sets
dir.create("Modeling/Data_Splits", recursive = TRUE, showWarnings = FALSE)
saveRDS(train_set, "Modeling/Data_Splits/train_set.rds")
saveRDS(test_set,  "Modeling/Data_Splits/test_set.rds")

cat("💾 Train/test sets saved to Modeling/Data_Splits/\n")
cat("✅ Split complete.\n")