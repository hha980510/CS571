# ============================================
# Script: 06_linear_regression_model.R
# Purpose: Train and evaluate linear regression models
# ============================================

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
  feature_set <- feature_configs[[config]]

  for (target_var in price_targets) {
    formula <- as.formula(paste(target_var, "~", paste(feature_set, collapse = "+")))
    model <- lm(formula, data = df_train)

    preds <- predict(model, newdata = df_test)
    actuals <- df_test[[target_var]]
    dates <- df_test$date

    min_len <- min(length(preds), length(actuals), length(dates))
    preds <- preds[1:min_len]
    actuals <- actuals[1:min_len]
    dates <- dates[1:min_len]
    current_prices <- df_test$NVDA.Close[1:min_len]

    metrics <- evaluate_regression_model(actuals, preds)
    strategy_metrics <- evaluate_strategy_metrics(
      predictions = preds,
      actuals = actuals,
      current_prices = current_prices,
      test_dates = dates,
      direction_target = FALSE
    )

    results_path <- file.path(results_folder, paste0("LinearRegression_", config))
    dir.create(results_path, showWarnings = FALSE)

    save_predictions(actuals, preds, dates, file.path(results_path, paste0(target_var, "_predictions.csv")))

    plot_df <- na.omit(data.frame(Date = as.Date(dates), Actual = actuals, Predicted = preds))
    plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                             title = paste("Linear Regression:", config, target_var))
    ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)

    append_model_results(
      model_name = paste0("LinearRegression_", config),
      target_var = target_var,
      metrics = metrics,
      strategy_metrics = strategy_metrics,
      filepath = file.path(results_folder, "all_model_metrics.csv")
    )
  }
}

cat("✅ Linear regression modeling complete.\n")