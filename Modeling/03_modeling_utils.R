# =============================
# File: 03_modeling_utils.R
# Purpose: Utility functions for model evaluation and results logging
# =============================

# Null coalescing operator
`%||%` <- function(x, y) if (!is.null(x)) x else y

# --- Regression Metrics ---
evaluate_regression_model <- function(actual, predicted) {
  rmse <- sqrt(mean((actual - predicted)^2, na.rm = TRUE))
  mae  <- mean(abs(actual - predicted), na.rm = TRUE)
  mape <- mean(abs((actual - predicted) / actual), na.rm = TRUE)
  r2   <- 1 - sum((actual - predicted)^2, na.rm = TRUE) /
               sum((actual - mean(actual, na.rm = TRUE))^2, na.rm = TRUE)
  return(list(RMSE = rmse, MAE = mae, MAPE = mape, R2 = r2))
}

# --- Save Metrics to File ---
save_metrics <- function(metrics_list, filepath) {
  df <- as.data.frame(t(unlist(metrics_list)))
  dir.create(dirname(filepath), showWarnings = FALSE, recursive = TRUE)
  write.table(df, file = filepath, row.names = FALSE, sep = ",", quote = FALSE)
}

# --- Save Predictions to CSV ---
save_predictions <- function(actual, predicted, dates, filepath) {
  df <- data.frame(Date = dates, Actual = actual, Predicted = predicted)
  dir.create(dirname(filepath), showWarnings = FALSE, recursive = TRUE)
  write.csv(df, file = filepath, row.names = FALSE)
}

# --- Plot Predictions ---
plot_predictions <- function(actual, predicted, dates, title = "Predicted vs Actual", save_path = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required.")

  library(ggplot2)
  df <- data.frame(Date = as.Date(dates), Actual = actual, Predicted = predicted)

  p <- ggplot(df, aes(x = Date)) +
    geom_line(aes(y = Actual), color = "blue", linewidth = 1) +
    geom_line(aes(y = Predicted), color = "red", linewidth = 1, linetype = "dashed") +
    labs(title = title, y = "Price", x = "Date") +
    theme_minimal()

  if (!is.null(save_path)) ggsave(filename = save_path, plot = p, width = 8, height = 4)
  return(p)
}

# --- Append Evaluation Summary ---
append_model_results <- function(model_name, target_var, metrics, strategy_metrics, filepath, run_id = Sys.time()) {
  new_row <- data.frame(
    Timestamp = format(run_id, "%Y-%m-%d %H:%M:%S"),
    Model = model_name,
    Target = target_var,
    RMSE = round(metrics$RMSE %||% NA, 4),
    MAE = round(metrics$MAE %||% NA, 4),
    MAPE = round(metrics$MAPE %||% NA, 4),
    R2 = round(metrics$R2 %||% NA, 4),
    Accuracy = round(metrics$Accuracy %||% NA, 4),
    Cumulative_Return = round(strategy_metrics$Cumulative_Return %||% NA, 4),
    Sharpe_Ratio = round(strategy_metrics$Sharpe_Ratio %||% NA, 4),
    Max_Drawdown = round(strategy_metrics$Max_Drawdown %||% NA, 4),
    Directional_Accuracy = round(strategy_metrics$Directional_Accuracy %||% NA, 4)
  )

  existing_data <- if (file.exists(filepath) && file.info(filepath)$size > 0) {
    tryCatch(read.csv(filepath), error = function(e) NULL)
  } else NULL

  is_duplicate <- !is.null(existing_data) && any(
    existing_data$Model == model_name & 
    existing_data$Target == target_var & 
    existing_data$Timestamp == new_row$Timestamp
  )

  if (is_duplicate) {
    message("⚠️ Duplicate entry skipped: ", model_name, " - ", target_var)
    return(invisible(NULL))
  }

  updated_data <- if (!is.null(existing_data)) rbind(existing_data, new_row) else new_row
  dir.create(dirname(filepath), showWarnings = FALSE, recursive = TRUE)
  write.csv(updated_data, filepath, row.names = FALSE)
  message("✅ Appended: ", model_name, " - ", target_var)
}