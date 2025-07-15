# 01_linear_regression_model.R

# --- Source setup and evaluation scripts ---
source("Modeling/00_model_setup.R")
source("Modeling/05_evaluation_metrics.R")

# --- Model configuration ---
model_name <- "Linear_Regression"
current_horizon <- "1W" # Change for "1W", "2W", "1M" as needed for each run

target_col <- paste0("Target_", current_horizon, "_Price")
directional_target_col <- paste0("Target_", current_horizon, "_Direction")

# --- Check if target column exists ---
if (!(target_col %in% names(nvda_data_cleaned))) {
  stop(paste0("❌ Target column '", target_col, "' not found. Check 00_model_setup.R."))
}

message(paste0("\n--- Running ", model_name, " for ", current_horizon, " horizon ---"))

# --- Walk-Forward Validation Setup ---
total_data_points <- nrow(nvda_data_cleaned)
message(paste0("Total usable data points: ", total_data_points))

initial_train_window_days <- 3 * 252 # ~3 years for initial training
test_window_days <- 21              # ~1 month for each prediction step

initial_train_start_idx <- 1
initial_train_end_idx <- initial_train_window_days

# Ensure enough data for at least one train + test window
if (total_data_points < initial_train_window_days + test_window_days) {
  stop("❌ Not enough data for the specified initial training and testing window sizes.")
}

# --- Initialize storage ---
all_predictions_price <- numeric()
all_actuals_price <- numeric()
all_actuals_direction <- numeric()
all_dates <- as.Date(character())
all_prediction_origin_close_prices <- numeric() # Store close price from day prediction was made

# --- Walk-Forward Loop ---
current_train_end_idx <- initial_train_end_idx
iteration <- 0

while (current_train_end_idx + test_window_days <= total_data_points) {
  iteration <- iteration + 1
  message(paste0("Iteration ", iteration, ": Training on data up to ", nvda_data_cleaned$Date[current_train_end_idx]))

  # Define training and testing indices
  train_indices <- initial_train_start_idx:current_train_end_idx
  test_indices <- (current_train_end_idx + 1):(current_train_end_idx + test_window_days)

  # Create datasets
  train_data <- nvda_data_cleaned[train_indices, ]
  test_data <- nvda_data_cleaned[test_indices, ]

  # Model Training (Linear Regression)
  formula_str <- paste(target_col, "~", paste(feature_cols, collapse = " + "))
  model_formula <- as.formula(formula_str)

  tryCatch({
    lm_model <- lm(model_formula, data = train_data) # Fit model

    predictions_price <- predict(lm_model, newdata = test_data) # Make predictions

    # Combine data for this iteration and remove NAs before storing
    iteration_results <- data.frame(
      Date = test_data$Date,
      Actual_Price = test_data[[target_col]],
      Predicted_Price = predictions_price,
      Actual_Direction = test_data[[directional_target_col]]
    ) %>%
    na.omit() # Removes rows with NA values

    # Store results
    all_predictions_price <- c(all_predictions_price, iteration_results$Predicted_Price)
    all_actuals_price <- c(all_actuals_price, iteration_results$Actual_Price)
    all_actuals_direction <- c(all_actuals_direction, iteration_results$Actual_Direction)
    all_dates <- c(all_dates, iteration_results$Date)

    # Store close price from end of training window (prediction origin)
    prediction_origin_close_for_this_window <- nvda_data_cleaned$NVDA.Close[current_train_end_idx]
    all_prediction_origin_close_prices <- c(all_prediction_origin_close_prices, rep(prediction_origin_close_for_this_window, NROW(iteration_results)))

  }, error = function(e) {
    message(paste0("⚠️ Error in iteration ", iteration, " for Linear Regression: ", e$message))
    # Skip this iteration's test window data on error
  })

  current_train_end_idx <- current_train_end_idx + test_window_days
}

# --- Combine Results for Evaluation ---
results_df <- data.frame(
  Date = all_dates,
  Actual_Price = all_actuals_price,
  Predicted_Price = all_predictions_price,
  Actual_Direction = all_actuals_direction,
  Prediction_Origin_Close = all_prediction_origin_close_prices
) %>%
  na.omit() # Final NA removal

# --- Calculate Predicted Direction with 1% buffer ---
results_df <- results_df %>%
  mutate(Predicted_Direction = ifelse(Predicted_Price > Prediction_Origin_Close * 1.01, 1, 0))

# --- Evaluate Model Performance ---
message("\n--- Model Performance Evaluation ---")

# Price Prediction Metrics
rmse_val <- calculate_rmse(results_df$Actual_Price, results_df$Predicted_Price)
mape_val <- calculate_mape(results_df$Actual_Price, results_df$Predicted_Price)
message(paste0("RMSE (", current_horizon, "): ", round(rmse_val, 4)))
message(paste0("MAPE (", current_horizon, "): ", round(mape_val, 4), "%"))

# Directional Prediction Metrics
accuracy_val <- calculate_directional_accuracy(results_df$Actual_Direction, results_df$Predicted_Direction)
precision_val <- calculate_precision(results_df$Actual_Direction, results_df$Predicted_Direction)
recall_val <- calculate_recall(results_df$Actual_Direction, results_df$Predicted_Direction)
f1_val <- calculate_f1_score(results_df$Actual_Direction, results_df$Predicted_Direction)

message(paste0("Directional Accuracy (", current_horizon, "): ", round(accuracy_val * 100, 2), "%"))
message(paste0("Precision (Upward Moves) (", current_horizon, "): ", round(precision_val * 100, 2), "%"))
message(paste0("Recall (Upward Moves) (", current_horizon, "): ", round(recall_val * 100, 2), "%"))
message(paste0("F1-Score (Upward Moves) (", current_horizon, "): ", round(f1_val, 4)))

# --- Financial Performance Metrics ---
# Calculate actual horizon return. Handle division by zero.
strategy_df <- results_df %>%
  mutate(
    Actual_Horizon_Return = ifelse(
      Prediction_Origin_Close != 0,
      (Actual_Price / Prediction_Origin_Close) - 1,
      NA
    )
  ) %>%
  # Apply strategy: if predicted up (1) based on your buffered logic,
  # take the Actual_Horizon_Return; otherwise, the strategy return is 0.
  mutate(
    Strategy_Return = Predicted_Direction * Actual_Horizon_Return
  ) %>%
  na.omit() # Remove rows where Strategy_Return might be NA (e.g., from NA in Actual_Horizon_Return)

cumulative_strategy_return <- calculate_cumulative_return(strategy_df$Strategy_Return)
sharpe_ratio_val <- calculate_sharpe_ratio(strategy_df$Strategy_Return)
max_drawdown_val <- calculate_max_drawdown(strategy_df$Strategy_Return)

message(paste0("Cumulative Strategy Return (", current_horizon, "): ", round(cumulative_strategy_return * 100, 2), "%"))
message(paste0("Sharpe Ratio (", current_horizon, "): ", round(sharpe_ratio_val, 4)))
message(paste0("Max Drawdown (", current_horizon, "): ", round(max_drawdown_val * 100, 2), "%"))

# --- Save Results ---
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

predictions_file <- file.path(results_output_dir, paste0(model_name, "_predictions_", current_horizon, ".rds"))
saveRDS(results_df, file = predictions_file)

message(paste0("✅ ", model_name, " for ", current_horizon, " horizon complete. Results saved."))