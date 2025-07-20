# ============================================
# File: 04_strategy_evaluation_utils.R
# Purpose: Evaluate trading strategy performance
# ============================================

library(PerformanceAnalytics)
library(zoo)
library(xts)

# --- Max Drawdown Calculation ---
calculate_max_drawdown <- function(equity_curve) {
  running_max <- cummax(equity_curve)
  drawdown <- (equity_curve - running_max) / running_max
  return(as.numeric(min(drawdown, na.rm = TRUE)))
}

# --- Strategy Evaluation Function ---
evaluate_strategy_metrics <- function(predictions,
                                      actuals,
                                      current_prices,
                                      test_dates,
                                      probabilities = NULL,
                                      direction_target = FALSE,
                                      capital_base = 10000,
                                      rf_rate = 0.01) {
  tryCatch({
    current_prices <- as.numeric(current_prices)
    predictions <- as.numeric(predictions)
    actuals <- as.numeric(actuals)
    test_dates <- as.Date(test_dates)

    if (length(test_dates) != length(current_prices)) {
      stop("Mismatch in test_dates and current_prices lengths.")
    }

    returns <- diff(log(current_prices))
    trade_signal <- rep(0, length(returns))

    # --- Trade Signal Generation ---
    if (direction_target) {
      if (!is.null(probabilities)) {
        trade_signal <- ifelse(probabilities[-1] > 0.6, 1,
                               ifelse(probabilities[-1] < 0.4, -1, 0))
      } else {
        trade_signal <- ifelse(predictions[-1] == 1, 1, 0)
      }

      predicted_direction <- predictions[-1]
      actual_direction <- actuals[-1]
    } else {
      predicted_direction <- sign(predictions[-1] - current_prices[-length(current_prices)])
      actual_direction <- sign(actuals[-1] - current_prices[-length(current_prices)])
      trade_signal <- ifelse(predicted_direction == actual_direction, 1, -1)
    }

    # --- Strategy Returns ---
    trade_signal <- head(trade_signal, length(returns))
    strategy_returns <- returns * trade_signal
    strategy_returns[is.na(strategy_returns)] <- 0

    aligned_dates <- test_dates[-1]
    strategy_xts <- xts(strategy_returns, order.by = aligned_dates)
    equity_curve <- cumprod(1 + strategy_returns)
    equity_xts <- xts(equity_curve, order.by = aligned_dates)

    # --- Performance Metrics ---
    cumulative_return <- as.numeric(last(equity_xts)) - 1
    sharpe_ratio <- SharpeRatio.annualized(strategy_xts, Rf = rf_rate / 252, scale = 252, geometric = TRUE)
    max_drawdown <- calculate_max_drawdown(as.numeric(equity_xts))
    directional_accuracy <- mean(predicted_direction == actual_direction, na.rm = TRUE)

    return(list(
      Cumulative_Return = cumulative_return,
      Sharpe_Ratio = as.numeric(sharpe_ratio),
      Max_Drawdown = max_drawdown,
      Directional_Accuracy = directional_accuracy
    ))

  }, error = function(e) {
    return(list(
      Cumulative_Return = 0,
      Sharpe_Ratio = NA,
      Max_Drawdown = 0,
      Directional_Accuracy = NA
    ))
  })
}