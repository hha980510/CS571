# ============================================
# Script: 15_run_all_classifiers.R
# Purpose: Run XGBoost classifier for multiple direction targets and feature sets
# ============================================

source("Modeling/00_modeling_setup.R")
source("Modeling/01_split_train_test.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

library(dplyr)
library(xgboost)
library(caret)
library(scales)

# Define target variables and feature sets
target_vars <- direction_targets
feature_sets <- list(
  Technical = technical_features,
  Economic = economic_features,
  Tech_Econ = all_features
)

# Initialize results file if not present
results_csv <- file.path(results_folder, "all_model_metrics.csv")
if (!file.exists(results_csv)) {
  write.csv(data.frame(), results_csv, row.names = FALSE)
}

# Load train/test data
train <- readRDS("Modeling/Data_Splits/train_set.rds")
test  <- readRDS("Modeling/Data_Splits/test_set.rds")

# Run models
for (target in target_vars) {
  for (fs_name in names(feature_sets)) {

    features <- feature_sets[[fs_name]]
    model_name <- paste0("XGBoost_Classifier_", fs_name)

    train_clean <- train %>%
      filter(!is.na(.data[[target]]) & is.finite(.data[[target]]))
    test_clean <- test %>%
      filter(!is.na(.data[[target]]) & is.finite(.data[[target]]))

    y_train <- train_clean[[target]]
    y_test  <- test_clean[[target]]
    X_train <- train_clean[, features]
    X_test  <- test_clean[, features]

    train_matrix <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)
    test_matrix  <- xgb.DMatrix(data = as.matrix(X_test), label = y_test)

    params <- list(
      objective = "binary:logistic",
      eval_metric = "logloss"
    )

    xgb_model <- xgb.train(
      params = params,
      data = train_matrix,
      nrounds = 100,
      verbose = 0
    )

    preds <- predict(xgb_model, newdata = test_matrix)
    pred_labels <- ifelse(preds > 0.5, 1, 0)
    acc <- mean(pred_labels == y_test)

    strategy_metrics <- tryCatch({
      evaluate_strategy_metrics(
        predictions = pred_labels,
        actuals = y_test,
        current_prices = test_clean$NVDA.Close,
        test_dates = test_clean$date,
        probabilities = preds,
        direction_target = TRUE
      )
    }, error = function(e) {
      return(list(
        Cumulative_Return = NA,
        Sharpe_Ratio = NA,
        Max_Drawdown = NA,
        Directional_Accuracy = NA
      ))
    })

    append_model_results(
      model_name = model_name,
      target_var = target,
      metrics = list(Accuracy = acc),
      strategy_metrics = strategy_metrics,
      filepath = results_csv,
      run_id = Sys.time()
    )
  }
}

message("✅ All XGBoost classifiers completed.")