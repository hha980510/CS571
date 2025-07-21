# ============================================
# Script: 05_baseline_regression_model.R
# Purpose: Run a baseline regression using lagged prices as predictors
# ============================================

# Load necessary scripts and utilities
source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

# Load training and testing datasets
train <- readRDS("Modeling/Data_Splits/train_set.rds")
test  <- readRDS("Modeling/Data_Splits/test_set.rds")

# Model identifier
model_name <- "Baseline_Regression"

# Loop through each target price variable
for (target_var in price_targets) {
  
  # Extract relevant data
  actuals <- test[[target_var]]
  dates <- test$date
  current_prices <- test$NVDA.Close
  
  # Generate predictions using 1-day lag
  preds <- dplyr::lag(current_prices, 1)
  preds[is.na(preds)] <- current_prices[1]  # Handle NA at the beginning
  preds <- tail(preds, length(actuals))     # Match length to actuals
  
  # Evaluate regression performance
  metrics <- evaluate_regression_model(actuals, preds)
  
  # Evaluate strategy-related metrics
  strategy_metrics <- evaluate_strategy_metrics(
    predictions = preds,
    actuals = actuals,
    current_prices = current_prices,
    test_dates = dates,
    direction_target = FALSE
  )
  
  # Set up directory for saving results
  results_path <- file.path(results_folder, model_name)
  dir.create(results_path, showWarnings = FALSE)
  
  # Save prediction results to CSV
  save_predictions(
    actuals, preds, dates,
    file.path(results_path, paste0(target_var, "_predictions.csv"))
  )
  
  # Create and save prediction plot
  plot_df <- na.omit(data.frame(Date = dates, Actual = actuals, Predicted = preds))
  plot <- plot_predictions(
    actual = plot_df$Actual,
    predicted = plot_df$Predicted,
    dates = plot_df$Date,
    title = paste("Baseline Regression:", target_var)
  )
  ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)
  
  # Append metrics to the master CSV file
  append_model_results(
    model_name = model_name,
    target_var = target_var,
    metrics = metrics,
    strategy_metrics = strategy_metrics,
    filepath = file.path(results_folder, "all_model_metrics.csv")
  )
}

cat("✅ Baseline regression complete.\n")
