# ============================================
# File: Modeling/03_modeling_utils.R
# Purpose: Utility functions for regression evaluation and saving results
# ============================================

# ----------------------------
# Evaluate regression performance
# ----------------------------
evaluate_regression_model <- function(actual, predicted) {
  rmse <- sqrt(mean((actual - predicted)^2, na.rm = TRUE))
  mae  <- mean(abs(actual - predicted), na.rm = TRUE)
  mape <- mean(abs((actual - predicted) / actual), na.rm = TRUE)
  r2   <- 1 - sum((actual - predicted)^2, na.rm = TRUE) / sum((actual - mean(actual, na.rm = TRUE))^2, na.rm = TRUE)

  return(list(RMSE = rmse, MAE = mae, MAPE = mape, R2 = r2))
}

# ----------------------------
# Save evaluation metrics to a .txt file
# ----------------------------
save_metrics <- function(metrics_list, filepath) {
  metrics_df <- as.data.frame(t(unlist(metrics_list)))
  write.table(metrics_df, file = filepath, row.names = FALSE, sep = ",", quote = FALSE)
}

# ----------------------------
# Save predictions to CSV
# ----------------------------
save_predictions <- function(actual, predicted, dates, filepath) {
  df <- data.frame(Date = dates, Actual = actual, Predicted = predicted)
  write.csv(df, file = filepath, row.names = FALSE)
}

# ----------------------------
# Plot predictions vs actual values
# ----------------------------
plot_predictions <- function(actual, predicted, dates, title = "Predicted vs Actual") {
  library(ggplot2)
  df <- data.frame(Date = as.Date(dates), Actual = actual, Predicted = predicted)

  ggplot(df, aes(x = Date)) +
    geom_line(aes(y = Actual), color = "blue", linewidth = 1) +
    geom_line(aes(y = Predicted), color = "red", linewidth = 1, linetype = "dashed") +
    labs(title = title, y = "Price", x = "Date") +
    theme_minimal()
}

# ----------------------------
# Append model results to a central CSV file
# ----------------------------
append_model_results <- function(model_name, target_var, metrics, strategy_metrics, filepath) {
  new_row <- data.frame(
    Model = model_name,
    Target = target_var,
    RMSE = metrics$RMSE,
    MAE = metrics$MAE,
    MAPE = metrics$MAPE,
    R2 = metrics$R2,
    Cumulative_Return = strategy_metrics$Cumulative_Return,
    Sharpe_Ratio = strategy_metrics$Sharpe_Ratio,
    Max_Drawdown = strategy_metrics$Max_Drawdown
  )

  # Safe file read
  existing_data <- tryCatch({
    read.csv(filepath)
  }, error = function(e) {
    message("⚠️ File exists but is unreadable or empty. Creating new.")
    data.frame()
  })

  # Check for duplicates
  if (nrow(existing_data) > 0 && any(existing_data$Model == model_name & existing_data$Target == target_var)) {
    message("⚠️ Skipping duplicate entry: ", model_name, " - ", target_var)
    return(invisible(NULL))
  }

  updated_data <- if (nrow(existing_data) > 0) {
    rbind(existing_data, new_row)
  } else {
    new_row
  }

  write.csv(updated_data, filepath, row.names = FALSE)
  message("✅ Appended: ", model_name, " - ", target_var)
}
