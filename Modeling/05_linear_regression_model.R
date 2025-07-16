# ============================================
# Script: 05_linear_regression_model.R
# Purpose: Build and evaluate linear regression models with different feature sets and targets
# ============================================

# --- Load setup and utility functions ---
source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

# --- Load train and test sets ---
df_train <- readRDS("Modeling/Data_Splits/train_set.rds")
df_test  <- readRDS("Modeling/Data_Splits/test_set.rds")

# --- Define modeling options ---
feature_configs <- list(
  Technical = technical_features,
  Economic  = economic_features,
  All       = all_features
)

# --- Loop through feature sets and targets ---
for (config in names(feature_configs)) {
  feature_set <- feature_configs[[config]]

  for (target_var in price_targets) {

    cat("\n\n\U0001F4C8 Modeling for:", config, "-", target_var, "\n")

    # Build formula
    formula <- as.formula(paste(target_var, "~", paste(feature_set, collapse = "+")))

    # Train model
    model <- lm(formula, data = df_train)

    # Predict on test set
    preds <- predict(model, newdata = df_test)
    actuals <- df_test[[target_var]]
    dates <- df_test$date

    # Evaluate metrics
    metrics <- evaluate_regression_model(actuals, preds)

    # Evaluate strategy metrics
    strategy_metrics <- evaluate_strategy_metrics(preds, df_test$NVDA.Close)

    # Save predictions and plot
    results_path <- file.path(results_folder, paste0("LinearRegression_", config))
    dir.create(results_path, showWarnings = FALSE)
    save_predictions(actuals, preds, dates, file.path(results_path, paste0(target_var, "_predictions.csv")))

    plot_df <- na.omit(data.frame(Date = as.Date(dates), Actual = actuals, Predicted = preds))
    plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                             title = paste("Linear Regression:", config, target_var))
    ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)

    # Append to central results file
    append_model_results(
      model_name = paste0("LinearRegression_", config),
      target_var = target_var,
      metrics = metrics,
      strategy_metrics = strategy_metrics,
      filepath = file.path(results_folder, "all_model_metrics.csv")
    )
  }
}

cat("\n\u2705 All linear regression modeling complete.\n")
