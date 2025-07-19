# ============================================
# Script: 08_ridge_regression_model.R
# Purpose: Build and evaluate a Ridge regression model with all, technical, and economic features
# ============================================

# --- Load setup and utility functions ---
source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

# --- Load train and test sets ---
df_train <- readRDS("Modeling/Data_Splits/train_set.rds")
df_test  <- readRDS("Modeling/Data_Splits/test_set.rds")

# --- Define feature set types ---
feature_configs <- list(
  Technical = technical_features,
  Economic  = economic_features,
  All       = all_features
)

# --- Loop through feature sets and targets ---
for (config in names(feature_configs)) {
  feature_set <- feature_configs[[config]]
  model_name <- paste0("RidgeRegression_", config)

  for (target_var in price_targets) {

    cat("\n\n\U0001F4C8 Modeling for:", model_name, "-", target_var, "\n")

    # --- Select features ---
    x_train <- model.matrix(as.formula(paste(target_var, "~", paste(feature_set, collapse = "+"))), data = df_train)[, -1]
    x_test  <- model.matrix(as.formula(paste(target_var, "~", paste(feature_set, collapse = "+"))), data = df_test)[, -1]
    y_train <- df_train[[target_var]]
    y_test  <- df_test[[target_var]]
    dates   <- df_test$date

    # --- Actual future prices for strategy evaluation ---
    actual_future_prices <- y_test

    # --- Train Ridge regression with cross-validation ---
    ridge_cv <- glmnet::cv.glmnet(x_train, y_train, alpha = 0)
    best_lambda <- ridge_cv$lambda.min
    model <- glmnet::glmnet(x_train, y_train, alpha = 0, lambda = best_lambda)

    # --- Predict ---
    preds <- predict(model, s = best_lambda, newx = x_test)
    preds <- as.numeric(preds)

    # --- Align lengths safely ---
    min_len <- min(length(preds), length(y_test), length(dates))
    preds <- preds[1:min_len]
    y_test <- y_test[1:min_len]
    dates <- dates[1:min_len]
    actual_future_prices <- actual_future_prices[1:min_len]
    current_prices <- df_test$NVDA.Close[1:min_len]

    # --- Evaluate metrics ---
    metrics <- evaluate_regression_model(y_test, preds)
    strategy_metrics <- evaluate_strategy_metrics(
      predictions = preds,
      current_prices = current_prices,
      actual_future_prices = actual_future_prices
    )

    # --- Save predictions and plot ---
    results_path <- file.path(results_folder, paste0("RidgeRegression_", config))
    dir.create(results_path, showWarnings = FALSE)
    save_predictions(y_test, preds, dates, file.path(results_path, paste0(target_var, "_predictions.csv")))

    plot_df <- na.omit(data.frame(Date = as.Date(dates), Actual = y_test, Predicted = preds))
    plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                             title = paste("Ridge Regression:", config, target_var))
    ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)

    # --- Append to central results file ---
    append_model_results(
      model_name = model_name,
      target_var = target_var,
      metrics = metrics,
      strategy_metrics = strategy_metrics,
      filepath = file.path(results_folder, "all_model_metrics.csv")
    )
  }
}

cat("\n\u2705 All Ridge regression modeling complete.\n")

