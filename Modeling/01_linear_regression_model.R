# --- Source setup and evaluation scripts ---
source("Modeling/00_model_setup.R")
source("Modeling/05_evaluation_metrics.R")
source("Modeling/06_feature_grouping.R")

feature_cols <- combined_features

# --- Model configuration ---
model_name <- "Linear_Regression"
current_horizon <- "1W"  # Change for "1W", "2W", or "1M" as needed

target_col <- paste0("Target_", current_horizon, "_Price")
directional_target_col <- paste0("Target_", current_horizon, "_Direction")

if (!(target_col %in% names(nvda_data_cleaned))) {
  stop(paste0("❌ Target column '", target_col, "' not found."))
}

message(paste0("\n--- Running ", model_name, " for ", current_horizon, " horizon ---"))

# --- Walk-Forward Setup ---
total_data_points <- nrow(nvda_data_cleaned)
initial_train_window_days <- 3 * 252  # ~3 years
test_window_days <- 21  # ~1 month

if (total_data_points < initial_train_window_days + test_window_days) {
  stop("❌ Not enough data for training and testing windows.")
}

initial_train_start_idx <- 1
initial_train_end_idx <- initial_train_window_days

# --- Initialize Storage ---
all_predictions_price <- numeric()
all_actuals_price <- numeric()
all_actuals_direction <- numeric()
all_dates <- as.Date(character())
all_prediction_origin_close_prices <- numeric()

# --- Walk-Forward Validation ---
current_train_end_idx <- initial_train_end_idx
iteration <- 0

while (current_train_end_idx + test_window_days <= total_data_points) {
  iteration <- iteration + 1
  message(paste0("Iteration ", iteration, ": Training up to ", nvda_data_cleaned$Date[current_train_end_idx]))

  train_indices <- initial_train_start_idx:current_train_end_idx
  test_indices <- (current_train_end_idx + 1):(current_train_end_idx + test_window_days)

  train_data <- nvda_data_cleaned[train_indices, ]
  test_data <- nvda_data_cleaned[test_indices, ]

  formula_str <- paste(target_col, "~", paste(feature_cols, collapse = " + "))
  model_formula <- as.formula(formula_str)

  tryCatch({
    lm_model <- lm(model_formula, data = train_data)
    predictions_price <- predict(lm_model, newdata = test_data)

    iteration_results <- data.frame(
      Date = test_data$Date,
      Actual_Price = test_data[[target_col]],
      Predicted_Price = predictions_price,
      Actual_Direction = test_data[[directional_target_col]]
    ) %>% na.omit()

    all_predictions_price <- c(all_predictions_price, iteration_results$Predicted_Price)
    all_actuals_price <- c(all_actuals_price, iteration_results$Actual_Price)
    all_actuals_direction <- c(all_actuals_direction, iteration_results$Actual_Direction)
    all_dates <- c(all_dates, iteration_results$Date)

    prediction_origin_close <- nvda_data_cleaned$NVDA.Close[current_train_end_idx]
    all_prediction_origin_close_prices <- c(all_prediction_origin_close_prices,
                                            rep(prediction_origin_close, nrow(iteration_results)))
  }, error = function(e) {
    message(paste0("⚠️ Error in iteration ", iteration, ": ", e$message))
  })

  current_train_end_idx <- current_train_end_idx + test_window_days
}

# --- Combine & Evaluate Results ---
results_df <- data.frame(
  Date = all_dates,
  Actual_Price = all_actuals_price,
  Predicted_Price = all_predictions_price,
  Actual_Direction = all_actuals_direction,
  Prediction_Origin_Close = all_prediction_origin_close_prices
) %>% na.omit()

results_df <- results_df %>%
  mutate(Predicted_Direction = ifelse(Predicted_Price > Prediction_Origin_Close * 1.01, 1, 0))

# --- Prediction Metrics ---
message("\n--- Model Performance Evaluation ---")
rmse_val <- calculate_rmse(results_df$Actual_Price, results_df$Predicted_Price)
mape_val <- calculate_mape(results_df$Actual_Price, results_df$Predicted_Price)

accuracy_val <- calculate_directional_accuracy(results_df$Actual_Direction, results_df$Predicted_Direction)
precision_val <- calculate_precision(results_df$Actual_Direction, results_df$Predicted_Direction)
recall_val <- calculate_recall(results_df$Actual_Direction, results_df$Predicted_Direction)
f1_val <- calculate_f1_score(results_df$Actual_Direction, results_df$Predicted_Direction)

message(paste0("RMSE (", current_horizon, "): ", round(rmse_val, 4)))
message(paste0("MAPE (", current_horizon, "): ", round(mape_val, 4), "%"))
message(paste0("Directional Accuracy: ", round(accuracy_val * 100, 2), "%"))
message(paste0("Precision (Upward): ", round(precision_val * 100, 2), "%"))
message(paste0("Recall (Upward): ", round(recall_val * 100, 2), "%"))
message(paste0("F1 Score (Upward): ", round(f1_val, 4)))

# --- Financial Metrics with Error Handling ---
strategy_df <- tryCatch({
  results_df %>%
    mutate(
      # Compute raw return from prediction origin
      Actual_Horizon_Return = ifelse(Prediction_Origin_Close != 0,
                                     (Actual_Price / Prediction_Origin_Close) - 1,
                                     NA),
      # Cap extreme returns BEFORE using them
      Actual_Horizon_Return = pmin(pmax(Actual_Horizon_Return, -0.9), 1.0),
      Strategy_Return = ifelse(Predicted_Direction == 1, Actual_Horizon_Return, 0)
    ) %>% na.omit()
}, error = function(e) {
  message("⚠️ Strategy DF creation failed: ", e$message)
  return(data.frame())
})

if (!"Strategy_Return" %in% names(strategy_df) || nrow(strategy_df) == 0) {
  cumulative_strategy_return <- NA
  sharpe_ratio_val <- NA
  max_drawdown_val <- NA
  message("⚠️ Skipping financial metrics due to missing Strategy_Return.")
} else {
  cumulative_strategy_return <- calculate_cumulative_return(strategy_df$Strategy_Return)
  sharpe_ratio_val <- calculate_sharpe_ratio(strategy_df$Strategy_Return)
  max_drawdown_val <- calculate_max_drawdown(strategy_df$Strategy_Return)

  message(paste0("Cumulative Strategy Return (", current_horizon, "): ", round(cumulative_strategy_return * 100, 2), "%"))
  message(paste0("Sharpe Ratio (", current_horizon, "): ", round(sharpe_ratio_val, 4)))
  message(paste0("Max Drawdown (", current_horizon, "): ", round(max_drawdown_val * 100, 2), "%"))
}

# --- Save Results ---
dir.create("Results", showWarnings = FALSE)

metrics_file <- file.path("Results", "model_performance_metrics.csv")
new_metrics_row <- data.frame(
  Model = model_name,
  Horizon = current_horizon,
  RMSE = rmse_val,
  MAPE = mape_val,
  Accuracy = accuracy_val,
  Precision = precision_val,
  Recall = recall_val,
  F1_Score = f1_val,
  Cumulative_Return = cumulative_strategy_return,
  Sharpe_Ratio = sharpe_ratio_val,
  Max_Drawdown = max_drawdown_val,
  Run_Date = Sys.time()
)

if (!file.exists(metrics_file)) {
  write.csv(new_metrics_row, metrics_file, row.names = FALSE)
} else {
  write.table(new_metrics_row, metrics_file, append = TRUE, sep = ",", col.names = FALSE, row.names = FALSE)
}

saveRDS(results_df, file = file.path("Results", paste0(model_name, "_predictions_", current_horizon, ".rds")))
message(paste0("✅ ", model_name, " for ", current_horizon, " horizon complete. Results saved."))
