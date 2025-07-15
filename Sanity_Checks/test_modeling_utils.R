# ================================
# Script: test_modeling_utils.R
# Purpose: Sanity check for utility metric functions
# ================================

# Load utility files
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

# Simulate predictions and actuals
set.seed(42)
actuals <- rnorm(100, mean = 100, sd = 10)
preds <- actuals + rnorm(100, sd = 5)  # Add noise

# --- Regression metrics ---
cat("📊 Testing regression metrics:\n")
reg_metrics <- evaluate_regression_model(actuals, preds)
print(reg_metrics)

# --- Directional accuracy & baseline RMSE ---
cat("\n🔁 Testing directional accuracy and baseline RMSE:\n")
cat("Directional Accuracy        :", directional_accuracy(actuals, preds), "\n")
cat("Baseline RMSE               :", baseline_rmse(actuals), "\n")
cat("Improvement over baseline % :", rmse_improvement(actuals, preds), "\n")

# --- Financial strategy metrics ---
daily_returns <- rnorm(126, mean = 0.0006, sd = 0.02)  # Simulated portfolio returns

cat("\n💰 Testing financial strategy metrics:\n")
cat("Cumulative Return:", calculate_cumulative_return(daily_returns), "\n")
cat("Sharpe Ratio     :", calculate_sharpe_ratio(daily_returns), "\n")
cat("Max Drawdown     :", calculate_max_drawdown(daily_returns), "\n")
