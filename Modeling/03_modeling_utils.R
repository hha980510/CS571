# ============================================
# File: Modeling/03_modeling_utils.R
# Purpose: Utility functions for model evaluation and result saving
# ============================================

library(dplyr)
library(ggplot2)
library(readr)

# ============================
# Regression Evaluation Metrics
# ============================
evaluate_regression_model <- function(actual, predicted) {
  rmse <- sqrt(mean((actual - predicted)^2, na.rm = TRUE))
  mae <- mean(abs(actual - predicted), na.rm = TRUE)
  mape <- mean(abs((actual - predicted) / actual), na.rm = TRUE) * 100
  r2 <- 1 - sum((actual - predicted)^2, na.rm = TRUE) / sum((actual - mean(actual, na.rm = TRUE))^2, na.rm = TRUE)

  metrics <- list(
    RMSE = rmse,
    MAE = mae,
    MAPE = mape,
    R2 = r2
  )

  return(metrics)
}

# ============================
# Directional Accuracy
# ============================
directional_accuracy <- function(actual, predicted) {
  correct <- sign(diff(predicted)) == sign(diff(actual))
  return(mean(correct, na.rm = TRUE))
}

# ============================
# Baseline RMSE (no-change model)
# ============================
baseline_rmse <- function(actual) {
  baseline_pred <- dplyr::lag(actual)  # yesterday's price as today's prediction
  sqrt(mean((actual - baseline_pred)^2, na.rm = TRUE))
}

rmse_improvement <- function(actual, predicted) {
  baseline <- baseline_rmse(actual)
  model_rmse <- sqrt(mean((actual - predicted)^2, na.rm = TRUE))
  improvement <- 100 * (baseline - model_rmse) / baseline
  return(improvement)
}

# ============================
# Save Metrics to File
# ============================
save_metrics <- function(metrics, filepath) {
  lines <- sapply(names(metrics), function(name) paste(name, ":", round(metrics[[name]], 4)))
  writeLines(lines, filepath)
}

# ============================
# Save Predictions to CSV
# ============================
save_predictions <- function(actual, predicted, dates, filepath) {
  df <- data.frame(
    Date = dates,
    Actual_Price = actual,
    Predicted_Price = predicted
  )
  write_csv(df, filepath)
}

# ============================
# Plot Predicted vs Actual Prices
# ============================
plot_predictions <- function(actual, predicted, dates, title = "Predicted vs Actual Prices") {
  df <- data.frame(
    Date = as.Date(dates),
    Actual = actual,
    Predicted = predicted
  )

  p <- ggplot(df, aes(x = Date)) +
    geom_line(aes(y = Actual, color = "Actual")) +
    geom_line(aes(y = Predicted, color = "Predicted")) +
    labs(title = title, y = "Price", x = "Date") +
    scale_color_manual(values = c("Actual" = "blue", "Predicted" = "red")) +
    theme_minimal()

  return(p)
}
