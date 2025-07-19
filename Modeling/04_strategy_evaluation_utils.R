# ============================================
# File: Modeling/04_strategy_evaluation_utils.R
# Purpose: Utility functions for evaluating financial strategy performance
# ============================================

# -----------------------------------
# Safe default operator (used in 03_modeling_utils.R)
# -----------------------------------
`%||%` <- function(x, y) if (!is.null(x)) x else y

# ----------------------------
# Calculate Cumulative Return
# ----------------------------
calculate_cumulative_return <- function(returns) {
  if (anyNA(returns)) warning("ℹ️ NA values detected in returns. Ignoring them.")
  return(prod(1 + returns, na.rm = TRUE) - 1)
}

# ----------------------------
# Calculate Sharpe Ratio (Annualized)
# ----------------------------
calculate_sharpe_ratio <- function(returns, risk_free_rate = 0.01) {
  if (anyNA(returns)) warning("ℹ️ NA values detected in returns. Ignoring them.")
  daily_rfr <- risk_free_rate / 252
  excess_returns <- returns - daily_rfr
  avg_excess <- mean(excess_returns, na.rm = TRUE)
  sd_excess <- sd(excess_returns, na.rm = TRUE)

  if (sd_excess == 0 || is.na(sd_excess)) {
    return(NA)
  }

  return(avg_excess / sd_excess * sqrt(252))
}

# ----------------------------
# Calculate Maximum Drawdown
# ----------------------------
calculate_max_drawdown <- function(returns) {
  if (anyNA(returns)) warning("ℹ️ NA values detected in returns. Ignoring them.")
  curve <- cumprod(1 + returns)
  peak <- cummax(curve)
  drawdown <- 1 - (curve / peak)
  return(max(drawdown, na.rm = TRUE))
}

# ----------------------------
# Calculate RMSE for No-Change Baseline
# ----------------------------
calculate_baseline_rmse <- function(actual_prices) {
  baseline_preds <- c(NA, head(actual_prices, -1))
  rmse <- sqrt(mean((baseline_preds - actual_prices)^2, na.rm = TRUE))
  return(rmse)
}

# ----------------------------
# Directional Accuracy: Custom for strategy
# ----------------------------
calculate_directional_accuracy <- function(predictions, actual_future_prices, current_prices) {
  predicted_dir <- sign(predictions - current_prices)
  actual_dir <- sign(actual_future_prices - current_prices)
  valid <- !is.na(predicted_dir) & !is.na(actual_dir)

  if (sum(valid) == 0) return(NA)
  return(mean(predicted_dir[valid] == actual_dir[valid]))
}

# ----------------------------
# Strategy Evaluation Wrapper
# ----------------------------
evaluate_strategy_metrics <- function(predictions, current_prices, actual_future_prices) {
  # Simulate buy decision
  position <- ifelse(predictions > current_prices, 1, 0)

  # Calculate actual next-day returns
  raw_returns <- c(0, diff(current_prices) / head(current_prices, -1))
  strategy_returns <- position * raw_returns

  return(list(
    Cumulative_Return = calculate_cumulative_return(strategy_returns) %||% NA,
    Sharpe_Ratio = calculate_sharpe_ratio(strategy_returns) %||% NA,
    Max_Drawdown = calculate_max_drawdown(strategy_returns) %||% NA,
    Directional_Accuracy = calculate_directional_accuracy(predictions, actual_future_prices, current_prices) %||% NA
  ))
}
