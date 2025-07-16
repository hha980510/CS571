# ============================
# File: Modeling/04_strategy_evaluation_utils.R
# Purpose: Utility functions for evaluating financial strategy performance
# ============================

# ----------------------------
# Calculate Cumulative Return
# ----------------------------
calculate_cumulative_return <- function(returns) {
  if (any(is.na(returns))) warning("NA values detected in returns. They will be ignored.")
  cumulative_return <- prod(1 + returns, na.rm = TRUE) - 1
  return(cumulative_return)
}

# ----------------------------
# Calculate Sharpe Ratio (annualized)
# ----------------------------
calculate_sharpe_ratio <- function(returns, risk_free_rate = 0.01) {
  if (any(is.na(returns))) warning("NA values detected in returns. They will be ignored.")
  daily_rfr <- risk_free_rate / 252
  excess_returns <- returns - daily_rfr
  avg_excess <- mean(excess_returns, na.rm = TRUE)
  sd_excess <- sd(excess_returns, na.rm = TRUE)
  sharpe <- ifelse(sd_excess == 0, NA, avg_excess / sd_excess * sqrt(252))
  return(sharpe)
}

# ----------------------------
# Calculate Maximum Drawdown
# ----------------------------
calculate_max_drawdown <- function(returns) {
  if (any(is.na(returns))) warning("NA values detected in returns. They will be ignored.")
  cumulative_curve <- cumprod(1 + returns)
  running_max <- cummax(cumulative_curve)
  drawdown <- 1 - (cumulative_curve / running_max)
  max_dd <- max(drawdown, na.rm = TRUE)
  return(max_dd)
}

evaluate_strategy_metrics <- function(predictions, actual_prices) {
  # Signal: buy if prediction > current actual price
  position <- ifelse(predictions > actual_prices, 1, 0)

  # Daily returns (based on actual price movement)
  returns <- c(0, diff(actual_prices) / head(actual_prices, -1))

  # Strategy returns (only earn returns if in the market)
  strategy_returns <- position * returns

  # Calculate all strategy metrics
  cumulative_return <- calculate_cumulative_return(strategy_returns)
  sharpe_ratio <- calculate_sharpe_ratio(strategy_returns)
  max_drawdown <- calculate_max_drawdown(strategy_returns)

  return(list(
    Cumulative_Return = cumulative_return,
    Sharpe_Ratio = sharpe_ratio,
    Max_Drawdown = max_drawdown
  ))
}