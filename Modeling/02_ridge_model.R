# 02_ridge_regression_model.R

# --- Source Setup and Evaluation Scripts ---
source("Modeling/00_model_setup.R")
source("Modeling/05_evaluation_metrics.R")
source("Modeling/06_feature_grouping.R")

feature_cols <- combined_features

# --- Model Configuration ---
model_name <- "Ridge_Regression"
current_horizon <- "1M"

target_col <- paste0("Target_", current_horizon, "_Price")
directional_target_col <- paste0("Target_", current_horizon, "_Direction")

if (!(target_col %in% names(nvda_data_cleaned))) {
  stop(paste0("❌ Target column '", target_col, "' not found. Check 00_model_setup.R."))
}

message(paste0("\n--- Running ", model_name, " for ", current_horizon, " horizon ---"))

# --- Walk-Forward Validation Setup ---
total_data_points <- nrow(nvda_data_cleaned)
initial_train_window_days <- 3 * 252
test_window_days <- 21

initial_train_start_idx <- 1
initial_train_end_idx <- initial_train_window_days

if (total_data_points < initial_train_window_days + test_window_days) {
  stop("❌ Not enough data for the specified initial training and testing window sizes.")
}

# --- Initialize Storage ---
all_predictions_price <- numeric()
all_actuals_price <- numeric()
all_actuals_direction <- numeric()
all_dates <- as.Date(character())
all_prediction_origin_close_prices <- numeric()

# --- Walk-Forward Loop ---
current_train_end_idx <- initial_train_end_idx
iteration <- 0

while (current_train_end_idx + test_window_days <= total_data_points) {
  iteration <- iteration + 1
  message(paste0("Iteration ", iteration, ": Training on data up to ", nvda_data_cleaned$Date[current_train_end_idx]))

  train_indices <- initial_train_start_idx:current_train_end_idx
  test_indices <- (current_train_end_idx + 1):(current_train_end_idx + test_window_days)

  train_data <- nvda_data_cleaned[train_indices, ]
  test_data <- nvda_data_cleaned[test_indices, ]

  x_train <- as.matrix(train_data[, feature_cols])
  y_train <- train_data[[target_col]]
  x_test <- as.matrix(test_data[, feature_cols])

  # --- Cross-Validated Ridge Regression ---
  cv_model <- train(
    x = x_train,
    y = y_train,
    method = "ridge",
    tuneLength = 10,
    trControl = trainControl(method = "cv", number = 5)
  )

  predictions_price <- predict(cv_model, newdata = x_test)

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

  prediction_origin_close_for_this_window <- nvda_data_cleaned$NVDA.Close[current_train_end_idx]
  all_prediction_origin_close_prices <- c(all_prediction_origin_close_prices,
                                          rep(prediction_origin_close_for_this_window, NROW(iteration_results)))

  current_train_end_idx <- current_train_end_idx + test_window_days
}

# --- Combine Results and Evaluate ---
results_df <- data.frame(
  Date = all_dates,
  Actual_Price = all_actuals_price,
  Predicted_Price = all_predictions_price,
  Actual_Direction = all_actuals_direction,
  Prediction_Origin_Close = all_prediction_origin_close_prices
) %>%
  mutate(Predicted_Direction = ifelse(Predicted_Price > Prediction_Origin_Close * 1.01, 1, 0)) %>%
  na.omit()

# --- Evaluation ---
rmse_val <- calculate_rmse(results_df$Actual_Price, results_df$Predicted_Price)
mape_val <- calculate_mape(results_df$Actual_Price, results_df$Predicted_Price)
accuracy_val <- calculate_directional_accuracy(results_df$Actual_Direction, results_df$Predicted_Direction)
precision_val <- calculate_precision(results_df$Actual_Direction, results_df$Predicted_Direction)
recall_val <- calculate_recall(results_df$Actual_Direction, results_df$Predicted_Direction)
f1_val <- calculate_f1_score(results_df$Actual_Direction, results_df$Predicted_Direction)

# Financial Metrics
strategy_df <- results_df %>%
  mutate(Actual_Horizon_Return = (Actual_Price / Prediction_Origin_Close) - 1,
         Strategy_Return = Predicted_Direction * Actual_Horizon_Return) %>%
  na.omit()

cumulative_strategy_return <- calculate_cumulative_return(strategy_df$Strategy_Return)
sharpe_ratio_val <- calculate_sharpe_ratio(strategy_df$Strategy_Return)
max_drawdown_val <- calculate_max_drawdown(strategy_df$Strategy_Return)

# Save Results
results_output_dir <- "Results"
dir.create(results_output_dir, showWarnings = FALSE)

metrics_file <- file.path(results_output_dir, "model_performance_metrics.csv")
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

saveRDS(results_df, file = file.path(results_output_dir, paste0(model_name, "_predictions_", current_horizon, ".rds")))

message(paste0("✅ ", model_name, " for ", current_horizon, " horizon complete. Results saved."))