# ============================================
# Script: 05_baseline_classifier.R
# Purpose: Create a simple classification baseline using continuation logic
# ============================================

source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

df_test <- readRDS("Modeling/Data_Splits/test_set.rds")
dates <- df_test$date
current_prices <- df_test$NVDA.Close

# Generate naive baseline: predict "same direction as yesterday"
# We use lag of direction target
for (target_var in direction_targets) {
  model_name <- "BaselineClassifier"
  actuals <- df_test[[target_var]]
  preds <- dplyr::lag(actuals)

  # Align lengths
  min_len <- min(length(preds), length(actuals), length(dates))
  preds <- preds[1:min_len]
  actuals <- actuals[1:min_len]
  dates <- dates[1:min_len]

  actual_future_price_var <- sub("Direction", "Price", target_var)
  actual_future_prices <- df_test[[actual_future_price_var]][1:min_len]
  current_prices_subset <- current_prices[1:min_len]

  strategy_metrics <- evaluate_strategy_metrics(
    predictions = preds,
    current_prices = current_prices_subset,
    actual_future_prices = actual_future_prices
  )

  metrics <- list(RMSE = NA, MAE = NA, MAPE = NA, R2 = NA)

  append_model_results(
    model_name = model_name,
    target_var = target_var,
    metrics = metrics,
    strategy_metrics = strategy_metrics,
    filepath = file.path(results_folder, "all_model_metrics.csv")
  )
}
cat("✅ Baseline classification complete.\n")