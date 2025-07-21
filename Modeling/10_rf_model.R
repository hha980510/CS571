# ============================================
# Script: 10_rf_model.R
# Purpose: Build and evaluate a random forest model with all, technical, and economic features
# ============================================

library(randomForest)

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

# --- Loop over feature sets ---
for (config in names(feature_configs)) {
  features <- feature_configs[[config]]
  model_name <- paste0("RandomForest_Regression_", config)
  
  # --- Loop over price target variables ---
  for (target_var in price_targets) {
    cat("\n🌲 Training Random Forest:", config, "-", target_var, "\n")
    
    y_train <- df_train[[target_var]]
    y_test  <- df_test[[target_var]]
    dates   <- df_test$date
    current_prices <- df_test$NVDA.Close
    
    X_train <- df_train[, features]
    X_test  <- df_test[, features]
    
    # --- Train the Random Forest model ---
    rf_model <- randomForest(x = X_train, y = y_train, ntree = 500)
    
    # --- Generate predictions ---
    preds <- predict(rf_model, newdata = X_test)
    
    # --- Trim data to matching lengths ---
    min_len <- min(length(preds), length(y_test), length(dates))
    preds <- preds[1:min_len]
    y_test <- y_test[1:min_len]
    dates <- dates[1:min_len]
    current_prices <- current_prices[1:min_len]
    
    # --- Evaluate model ---
    metrics <- evaluate_regression_model(y_test, preds)
    strategy_metrics <- evaluate_strategy_metrics(
      predictions = preds,
      actuals = y_test,
      current_prices = current_prices,
      test_dates = dates,
      direction_target = FALSE
    )
    
    # --- Save results ---
    results_path <- file.path(results_folder, model_name)
    dir.create(results_path, showWarnings = FALSE)
    
    save_predictions(y_test, preds, dates,
                     file.path(results_path, paste0(target_var, "_predictions.csv")))
    
    plot_df <- na.omit(data.frame(Date = as.Date(dates), Actual = y_test, Predicted = preds))
    plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                             title = paste("Random Forest:", config, target_var))
    ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)
    
    append_model_results(
      model_name = model_name,
      target_var = target_var,
      metrics = metrics,
      strategy_metrics = strategy_metrics,
      filepath = file.path(results_folder, "all_model_metrics.csv")
    )
  }
}

cat("\n✅ All Random Forest regression modeling complete.\n")
