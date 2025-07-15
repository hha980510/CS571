# 00_model_setup.R

# --- 1. Load Libraries ---
library(dplyr)
library(quantmod)
library(forecast)
library(xgboost)
library(caret)
library(timeSeries)
library(PerformanceAnalytics)
library(Metrics)

# --- 2. Load Cleaned Data ---
cleaned_data_path <- "Data_Clean/cleaned_nvda_data.rds"
if (!file.exists(cleaned_data_path)) {
  stop("❌ Cleaned data not found. Run data cleaning script first.")
}
nvda_data_cleaned <- readRDS(cleaned_data_path)

# Ensure data is a data.frame and Date column is correct
if (!inherits(nvda_data_cleaned, "data.frame")) {
  message("Converting loaded data to data.frame.")
  nvda_data_cleaned <- as.data.frame(nvda_data_cleaned)
}
if (!("Date" %in% names(nvda_data_cleaned)) && ("date" %in% names(nvda_data_cleaned))) {
  colnames(nvda_data_cleaned)[colnames(nvda_data_cleaned) == "date"] <- "Date"
}
if ("Date" %in% names(nvda_data_cleaned)) {
  nvda_data_cleaned$Date <- as.Date(nvda_data_cleaned$Date)
  nvda_data_cleaned <- nvda_data_cleaned %>% select(Date, everything())
} else {
  stop("❌ 'Date' column not found in cleaned data.")
}

# Order by date
nvda_data_cleaned <- nvda_data_cleaned[order(nvda_data_cleaned$Date), ]

message(paste0("✅ Cleaned data loaded. Total rows: ", nrow(nvda_data_cleaned)))
message(paste0("   Data starts: ", min(nvda_data_cleaned$Date), " ends: ", max(nvda_data_cleaned$Date)))

# --- 3. Define Target Variables (Future Stock Prices and Direction) ---

# Define prediction horizons in business days
horizon_1_week <- 5
horizon_2_weeks <- 10
horizon_1_month <- 21

# Identify current Close price column
current_close_col_name <- "NVDA.Close"
if (!(current_close_col_name %in% names(nvda_data_cleaned))) {
  stop(paste0("❌ Close price column '", current_close_col_name, "' not found."))
}

# Create lagged future close prices (targets)
nvda_data_cleaned <- nvda_data_cleaned %>%
  mutate(
    Target_1W_Price = lead(!!sym(current_close_col_name), n = horizon_1_week),
    Target_2W_Price = lead(!!sym(current_close_col_name), n = horizon_2_weeks),
    Target_1M_Price = lead(!!sym(current_close_col_name), n = horizon_1_month)
  )

# Create directional targets (1 for increase, 0 for decrease/no change)
nvda_data_cleaned <- nvda_data_cleaned %>%
  mutate(
    Target_1W_Direction = ifelse(sign(Target_1W_Price - !!sym(current_close_col_name)) == 1, 1, 0),
    Target_2W_Direction = ifelse(sign(Target_2W_Price - !!sym(current_close_col_name)) == 1, 1, 0),
    Target_1M_Direction = ifelse(sign(Target_1M_Price - !!sym(current_close_col_name)) == 1, 1, 0)
  )

# Remove rows with NAs introduced by lead() for targets
initial_rows_after_target <- nrow(nvda_data_cleaned)
nvda_data_cleaned <- na.omit(nvda_data_cleaned)
removed_rows_target_na <- initial_rows_after_target - nrow(nvda_data_cleaned)
if (removed_rows_target_na > 0) {
  message(paste0("🧹 Removed ", removed_rows_target_na, " rows due to NA in target variables."))
}

# --- 4. Define Feature Columns ---
# All columns except Date and Target columns
feature_cols <- names(nvda_data_cleaned)[!names(nvda_data_cleaned) %in% c("Date",
                                                                           "Target_1W_Price", "Target_2W_Price", "Target_1M_Price",
                                                                           "Target_1W_Direction", "Target_2W_Direction", "Target_1M_Direction")]

# Remove zero-variance features
numeric_feature_cols <- feature_cols[sapply(nvda_data_cleaned[, feature_cols], is.numeric)]
zero_variance_features <- numeric_feature_cols[sapply(nvda_data_cleaned[, numeric_feature_cols], var) == 0]

if(length(zero_variance_features) > 0) {
  message(paste0("🧹 Removing ", length(zero_variance_features), " zero-variance feature(s): ", paste(zero_variance_features, collapse = ", ")))
  feature_cols <- setdiff(feature_cols, zero_variance_features)
} else {
  message("✅ No zero-variance features found.")
}

message(paste0("✅ Feature columns identified. Number of features: ", length(feature_cols)))
message("Common setup complete. Data is loaded, targets are created, and features are defined.")

# Removed the rm(list = c(...)) line here. This was the issue.