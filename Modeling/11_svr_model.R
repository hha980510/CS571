# ============================================
# Script: 11_scr_model.R
# Purpose: Build and evaluate a support vector regression model with all, technical, and economic features
# ============================================

# --- Load setup and utility functions ---
source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

# --- Load train and test sets ---
df_train <- readRDS("Modeling/Data_Splits/train_set.rds")
df_test  <- readRDS("Modeling/Data_Splits/test_set.rds")

# --- Define feature configurations ---
feature_configs <- list(
  Technical = technical_features,
  Economic  = economic_features,
  All       = all_features
)

# --- Loop through feature sets and target variables ---
for (config in names(feature_configs)) {
  feature_set <- feature_configs[[config]]
  
  for (target_var in price_targets) {
    
    # Define formula
    formula <- as.formula(paste(target_var, "~", paste(feature_set, collapse = "+")))
    
    # Train Support Vector Regression model
    library(e1071)
    model <- svm(formula, data = df_train)
    
    # Make predictions
    preds <- predict(model, newdata = df_test)
    actuals <- df_test[[target_var]]
    dates <- df_test$date
    
    # Align prediction and actual lengths
    min_len <- min(length(preds), length(actuals), length(dates))
    preds <- preds[1:min_len]
    actuals <- actuals[1:min_len]
    dates <- dates[1:min_len]
    current_prices <- df_test$NVDA.Close[1:min_len]
    
    # Evaluate model performance
    metrics <- evaluate_regression_model(actuals, preds)
    strategy_metrics <- evaluate_strategy_metrics(
      predictions = preds,
      actuals = actuals,
      current_prices = current_prices,
      test_dates = dates,
      direction_target = FALSE
    )
    
    # Define and create results path
    results_path <- file.path(results_folder, paste0("SVR_", config))
    dir.create(results_path, showWarnings = FALSE)
    
    # Save predictions
    save_predictions(actuals, preds, dates, file.path(results_path, paste0(target_var, "_predictions.csv")))
    
    # Save prediction plot
    plot_df <- na.omit(data.frame(Date = as.Date(dates), Actual = actuals, Predicted = preds))
    plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                             title = paste("SVR:", config, target_var))
    ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)
    
    # Append results to master metrics file
    append_model_results(
      model_name = paste0("SVR_", config),
      target_var = target_var,
      metrics = metrics,
      strategy_metrics = strategy_metrics,
      filepath = file.path(results_folder, "all_model_metrics.csv")
    )
  }
}

cat("✅ Support Vector Regression modeling complete.\n")
