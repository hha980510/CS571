# 05_evaluation_metrics.R

# --- Evaluation Metrics Functions ---

# Root Mean Squared Error (RMSE) for price prediction
calculate_rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2, na.rm = TRUE))
}

# Mean Absolute Percentage Error (MAPE) for price prediction
calculate_mape <- function(actual, predicted) {
  mape_vals <- abs((actual - predicted) / actual)
  mape_vals[is.infinite(mape_vals) | is.na(mape_vals)] <- NA
  return(mean(mape_vals, na.rm = TRUE) * 100)
}

# Directional Accuracy
calculate_directional_accuracy <- function(actual_direction, predicted_direction) {
  correct_predictions <- sum(actual_direction == predicted_direction, na.rm = TRUE)
  total_predictions <- sum(!is.na(actual_direction) & !is.na(predicted_direction))
  return(correct_predictions / total_predictions)
}

# Precision for upward moves (class 1)
calculate_precision <- function(actual_direction, predicted_direction) {
  TP <- sum(actual_direction == 1 & predicted_direction == 1, na.rm = TRUE)
  FP <- sum(actual_direction == 0 & predicted_direction == 1, na.rm = TRUE)
  if ((TP + FP) == 0) return(NA)
  return(TP / (TP + FP))
}

# Recall for upward moves (class 1)
calculate_recall <- function(actual_direction, predicted_direction) {
  TP <- sum(actual_direction == 1 & predicted_direction == 1, na.rm = TRUE)
  FN <- sum(actual_direction == 1 & predicted_direction == 0, na.rm = TRUE)
  if ((TP + FN) == 0) return(NA)
  return(TP / (TP + FN))
}

# F1-Score for upward moves (class 1)
calculate_f1_score <- function(actual_direction, predicted_direction) {
  precision <- calculate_precision(actual_direction, predicted_direction)
  recall <- calculate_recall(actual_direction, predicted_direction)
  if (is.na(precision) || is.na(recall) || (precision + recall) == 0) return(NA)
  return(2 * ((precision * recall) / (precision + recall)))
}

# Cumulative Return of a Strategy (with outlier cap)
calculate_cumulative_return <- function(returns) {
  returns <- returns[!is.na(returns)]
  if (length(returns) == 0) return(NA)
  
  # Apply capping here (safeguard against overflows)
  returns <- pmin(pmax(returns, -0.9), 1.0)  # Cap between -90% and +100%
  
  return(prod(1 + returns) - 1)
}

# Sharpe Ratio
calculate_sharpe_ratio <- function(returns, risk_free_rate = 0, annualizing_factor = sqrt(252)) {
  if (length(returns) == 0 || all(is.na(returns))) return(NA)
  excess_returns <- returns - risk_free_rate / annualizing_factor
  mean_excess_return <- mean(excess_returns, na.rm = TRUE)
  sd_excess_return <- sd(excess_returns, na.rm = TRUE)
  if (sd_excess_return == 0) return(NA)
  return(mean_excess_return / sd_excess_return * annualizing_factor)
}

# Maximum Drawdown
calculate_max_drawdown <- function(returns) {
  if (length(returns) == 0 || all(is.na(returns))) return(NA)
  cumulative_returns <- cumprod(1 + returns)
  peak <- cummax(c(1, cumulative_returns))
  drawdown <- (peak - c(1, cumulative_returns)) / peak
  return(max(drawdown, na.rm = TRUE))
}

# --- Reference to Close Column ---
current_close_col_name <- "NVDA.Close"