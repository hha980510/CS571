# ============================================
# Script: 13_xgboost_regressor_model.R
# Purpose: Build and evaluate XGBoost regression models
# ============================================

library(xgboost)
library(dplyr)
library(ggplot2)
library(scales)

source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

train <- readRDS("Modeling/Data_Splits/train_set.rds")
test  <- readRDS("Modeling/Data_Splits/test_set.rds")

feature_configs <- list(
  Technical = technical_features,
  Economic  = economic_features,
  All       = all_features
)

for (config in names(feature_configs)) {
  features <- feature_configs[[config]]
  model_name <- paste0("XGBoost_Regression_", config)

  for (target_var in price_targets) {
    cat("\n\n📈 XGBoost Regression:", config, "-", target_var, "\n")

    y_train <- train[[target_var]]
    y_test  <- test[[target_var]]
    dates   <- test$date
    current_prices <- test$NVDA.Close

    X_train <- train[, features]
    X_test  <- test[, features]

    train_matrix <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)
    test_matrix  <- xgb.DMatrix(data = as.matrix(X_test), label = y_test)

    params <- list(objective = "reg:squarederror", eval_metric = "rmse")
    xgb_model <- xgb.train(params = params, data = train_matrix, nrounds = 100, verbose = 0)

    preds <- predict(xgb_model, newdata = test_matrix)

    min_len <- min(length(preds), length(y_test), length(dates))
    preds <- preds[1:min_len]
    y_test <- y_test[1:min_len]
    dates <- dates[1:min_len]
    current_prices <- current_prices[1:min_len]

    metrics <- evaluate_regression_model(y_test, preds)
    strategy_metrics <- evaluate_strategy_metrics(
      predictions = preds,
      actuals = y_test,
      current_prices = current_prices,
      test_dates = dates,
      direction_target = FALSE
    )

    results_path <- file.path(results_folder, model_name)
    dir.create(results_path, showWarnings = FALSE)

    save_predictions(y_test, preds, dates, file.path(results_path, paste0(target_var, "_predictions.csv")))

    plot_df <- na.omit(data.frame(Date = as.Date(dates), Actual = y_test, Predicted = preds))
    plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                             title = paste("XGBoost Regressor:", config, target_var))
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

cat("\n✅ All XGBoost regression modeling complete.\n")