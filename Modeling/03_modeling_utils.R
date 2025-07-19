# ============================================
# File: Modeling/03_modeling_utils.R
# Purpose: Utility functions for regression evaluation and saving results
# ============================================

# ----------------------------
# Null coalescing operator for safe defaults
# ----------------------------
`%||%` <- function(x, y) if (!is.null(x)) x else y

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
  dir.create(dirname(filepath), showWarnings = FALSE, recursive = TRUE)
  write.table(metrics_df, file = filepath, row.names = FALSE, sep = ",", quote = FALSE)
}

# ----------------------------
# Save predictions to CSV
# ----------------------------
save_predictions <- function(actual, predicted, dates, filepath) {
  df <- data.frame(Date = dates, Actual = actual, Predicted = predicted)
  dir.create(dirname(filepath), showWarnings = FALSE, recursive = TRUE)
  write.csv(df, file = filepath, row.names = FALSE)
}

# ----------------------------
# Plot predictions vs actual values
# ----------------------------
plot_predictions <- function(actual, predicted, dates, title = "Predicted vs Actual") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required but not installed.")
  }

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
    RMSE = round(metrics$RMSE, 4),
    MAE = round(metrics$MAE, 4),
    MAPE = round(metrics$MAPE, 4),
    R2 = round(metrics$R2, 4),
    Cumulative_Return = round(strategy_metrics$Cumulative_Return %||% NA, 4),
    Sharpe_Ratio = round(strategy_metrics$Sharpe_Ratio %||% NA, 4),
    Max_Drawdown = round(strategy_metrics$Max_Drawdown %||% NA, 4),
    Directional_Accuracy = round(strategy_metrics$Directional_Accuracy %||% NA, 4)
  )

  # Safe file read
  existing_data <- tryCatch({
    read.csv(filepath)
  }, error = function(e) {
    message("ℹ️ Creating new result file or loading failed.")
    data.frame()
  })

  # Check for duplicates
  if (nrow(existing_data) > 0 && any(existing_data$Model == model_name & existing_data$Target == target_var)) {
    message("⚠️ Skipping duplicate entry: ", model_name, " - ", target_var)
    return(invisible(NULL))
  }

  # Append and save
  updated_data <- if (nrow(existing_data) > 0) {
    rbind(existing_data, new_row)
  } else {
    new_row
  }

  dir.create(dirname(filepath), showWarnings = FALSE, recursive = TRUE)
  write.csv(updated_data, filepath, row.names = FALSE)
  message("✅ Appended: ", model_name, " - ", target_var)
}
