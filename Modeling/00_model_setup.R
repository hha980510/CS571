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
  stop("❌ Cleaned data not found at 'Data_Clean/cleaned_nvda_data.rds'. Please ensure your data cleaning script creates this file.")
}
nvda_data_cleaned <- readRDS(cleaned_data_path)

# Ensure it's a data.frame.
if (!inherits(nvda_data_cleaned, "data.frame")) {
  message("Converting loaded data to data.frame.")
  nvda_data_cleaned <- as.data.frame(nvda_data_cleaned)
}

# Ensure the 'Date' column is in Date format and is the first column for clarity
if (!("Date" %in% names(nvda_data_cleaned)) && ("date" %in% names(nvda_data_cleaned))) {
  colnames(nvda_data_cleaned)[colnames(nvda_data_cleaned) == "date"] <- "Date"
}
if ("Date" %in% names(nvda_data_cleaned)) {
  nvda_data_cleaned$Date <- as.Date(nvda_data_cleaned$Date)
  # Reorder to make 'Date' the first column
  nvda_data_cleaned <- nvda_data_cleaned %>%
    select(Date, everything())
} else {
  stop("❌ 'Date' column not found in cleaned data. Please ensure your cleaning script creates a 'Date' column.")
}

# Order by date to ensure proper time series operations
nvda_data_cleaned <- nvda_data_cleaned[order(nvda_data_cleaned$Date), ]

message(paste0("✅ Cleaned data loaded. Total rows: ", nrow(nvda_data_cleaned)))
message(paste0("   Data starts: ", min(nvda_data_cleaned$Date), " ends: ", max(nvda_data_cleaned$Date)))

# --- 3. Define Target Variables (Future Stock Prices and Direction) ---

# Define prediction horizons in business days
horizon_1_week <- 5   # Approximately 1 week
horizon_2_weeks <- 10 # Approximately 2 weeks
horizon_1_month <- 21 # Approximately 1 month 

# Identify the current NVIDIA Close price column.
# Common names: "NVDA.Close", "Close", "nvda.Close"
current_close_col_name <- "NVDA.Close"
if (!(current_close_col_name %in% names(nvda_data_cleaned))) {
  stop(paste0("❌ Current close price column '", current_close_col_name, "' not found. Please adjust 'current_close_col_name' in 00_model_setup.R"))
}

# Create lagged future close prices (targets) using dplyr::lead()
# We are predicting the *Close* price at a future date
nvda_data_cleaned <- nvda_data_cleaned %>%
  mutate(
    Target_1W_Price = lead(!!sym(current_close_col_name), n = horizon_1_week),
    Target_2W_Price = lead(!!sym(current_close_col_name), n = horizon_2_weeks),
    Target_1M_Price = lead(!!sym(current_close_col_name), n = horizon_1_month)
  )

# Create directional targets: 1 for increase, 0 for decrease (compared to current close)
# Using `sign()` for a robust 1/0/NA for up/down/no_change logic. No_change converted to 0 (down).
nvda_data_cleaned <- nvda_data_cleaned %>%
  mutate(
    Target_1W_Direction = ifelse(sign(Target_1W_Price - !!sym(current_close_col_name)) == 1, 1, 0),
    Target_2W_Direction = ifelse(sign(Target_2W_Price - !!sym(current_close_col_name)) == 1, 1, 0),
    Target_1M_Direction = ifelse(sign(Target_1M_Price - !!sym(current_close_col_name)) == 1, 1, 0)
  )

# Remove rows with NAs introduced by lead() for targets. These NAs are at the end of the dataset.
initial_rows_after_target <- nrow(nvda_data_cleaned)
nvda_data_cleaned <- na.omit(nvda_data_cleaned)
removed_rows_target_na <- initial_rows_after_target - nrow(nvda_data_cleaned)
if (removed_rows_target_na > 0) {
  message(paste0("🧹 Removed ", removed_rows_target_na, " rows due to NA values in target variables (end of dataset)."))
}

# --- 4. Define Feature Columns ---
# All columns except Date and the newly created Target columns
feature_cols <- names(nvda_data_cleaned)[!names(nvda_data_cleaned) %in% c("Date",
                                                                           "Target_1W_Price", "Target_2W_Price", "Target_1M_Price",
                                                                           "Target_1W_Direction", "Target_2W_Direction", "Target_1M_Direction")]

# Remove any features that have zero variance (constant columns) as they cause issues in some models
# Apply this only to the numeric features to avoid issues with character/factor columns if any slipped through
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

# Clean up environment to avoid conflicts in individual model files
rm(list = c("cleaned_data_path", "initial_rows_after_target", "removed_rows_target_na",
            "zero_variance_features", "numeric_feature_cols"))