# ============================================
# Script: 14_xgboost_classifier_tuning.R
# Purpose: Tune and evaluate XGBoost classifiers using caret
# ============================================

library(xgboost)
library(caret)
library(dplyr)
library(ggplot2)

source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

df_train <- readRDS("Modeling/Data_Splits/train_set.rds")
df_test  <- readRDS("Modeling/Data_Splits/test_set.rds")

feature_configs <- list(
  Technical = technical_features,
  Economic  = economic_features,
  All       = all_features
)

for (config in names(feature_configs)) {
  features <- feature_configs[[config]]
  model_base_name <- paste0("XGBoost_Classifier_Tuned_", config)

  for (target_var in direction_targets) {
    cat("\n📈 Tuning:", config, "-", target_var, "\n")

    y_train <- as.factor(df_train[[target_var]])
    y_test  <- as.factor(df_test[[target_var]])
    X_train <- df_train[, features]
    X_test  <- df_test[, features]
    test_dates <- df_test$date
    current_prices <- df_test$NVDA.Close

    train_df <- data.frame(X_train, Target = y_train)

    control <- trainControl(method = "cv", number = 5)
    tune_grid <- expand.grid(
      nrounds = c(50, 100),
      max_depth = c(3, 6),
      eta = c(0.01, 0.1),
      gamma = c(0, 1),
      colsample_bytree = 0.7,
      min_child_weight = 1,
      subsample = 0.7
    )

    set.seed(42)
    xgb_tuned <- train(
      Target ~ .,
      data = train_df,
      method = "xgbTree",
      trControl = control,
      tuneGrid = tune_grid,
      metric = "Accuracy"
    )

    preds <- predict(xgb_tuned, newdata = X_test, type = "raw")
    probs <- predict(xgb_tuned, newdata = X_test, type = "prob")[, "1"]

    min_len <- min(length(preds), length(y_test), length(test_dates))
    preds <- preds[1:min_len]
    probs <- probs[1:min_len]
    y_test <- y_test[1:min_len]
    test_dates <- test_dates[1:min_len]
    current_prices <- current_prices[1:min_len]

    accuracy <- mean(preds == y_test, na.rm = TRUE)
    strategy_metrics <- evaluate_strategy_metrics(
      predictions = preds,
      actuals = y_test,
      current_prices = current_prices,
      test_dates = test_dates,
      probabilities = probs,
      direction_target = TRUE
    )

    results_path <- file.path(results_folder, model_base_name)
    dir.create(results_path, showWarnings = FALSE)

    save_predictions(y_test, preds, test_dates, file.path(results_path, paste0(target_var, "_predictions.csv")))

    plot_df <- na.omit(data.frame(Date = as.Date(test_dates), Actual = y_test, Predicted = preds))
    plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                             title = paste("XGBoost Tuned:", config, target_var))
    ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)

    append_model_results(
      model_name = model_base_name,
      target_var = target_var,
      metrics = list(Accuracy = accuracy),
      strategy_metrics = strategy_metrics,
      filepath = file.path(results_folder, "all_model_metrics.csv")
    )
  }
}

cat("\n✅ All tuned XGBoost classifier models complete.\n")