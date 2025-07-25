# ============================
# Script: data_pipeline.R
# Purpose: Run entire data pipeline end-to-end
# ============================

cat("\n🚀 Starting NVIDIA Stock Prediction Data Pipeline...\n")

# --- Utility function to safely source scripts with logging ---
safe_source <- function(script_path) {
  cat(paste0("🔹 Running: ", script_path, "\n"))
  tryCatch({
    source(script_path)
  }, error = function(e) {
    cat(paste0("❌ Error in ", script_path, ": ", e$message, "\n"))
  })
}

# --- Step 1: Data Clean ---
safe_source("Data_Clean/import_data.R")
safe_source("Data_Clean/handle_missing.R")

# --- Step 2: Data Preparation ---
safe_source("Data_Preparation/feature_engineering.R")
safe_source("Data_Preparation/clean_column_structure.R")
safe_source("Data_Preparation/data_quality_checks.R")
safe_source("Data_Preparation/add_targets.R")

# --- Step 3: EDA  ---
safe_source("Exploratory_Analysis/univariate_distribution.R")
safe_source("Exploratory_Analysis/Time-series_plots.R")
safe_source("Exploratory_Analysis/Stationarity_Test.R")
safe_source("Exploratory_Analysis/ACF_PACF_plots.R")
safe_source("Exploratory_Analysis/Scatter_plots.R")
safe_source("Exploratory_Analysis/feature_response_relationship.R")
safe_source("Exploratory_Analysis/technical_indicator_boxplots.R")
safe_source("Exploratory_Analysis/Correlation_Heatmap.R")


# --- Step 4: Modeling Setup ---
safe_source("Modeling/01_split_train_test.R")


# --- Step 4: Control which models to run ---
run_baseline <- TRUE
run_linear <- TRUE
run_lasso <- TRUE
run_ridge <- TRUE
run_xgboost<-TRUE
run_rf <- TRUE
run_svr <- TRUE
run_tunedrf <- TRUE


# --- Step 5: Run Models ---
if (run_baseline) {
  safe_source("Modeling/05_baseline_classifier_model.R")
  safe_source("Modeling/05_baseline_regression_model.R")
}
if (run_linear)   safe_source("Modeling/06_linear_regression_model.R")
if (run_lasso)    safe_source("Modeling/07_lasso_regression_model.R")
if (run_ridge)    safe_source("Modeling/08_ridge_regression_model.R")
if (run_xgboost) {
  safe_source("Modeling/13_xgboost_regressor_model.R")
  safe_source("Modeling/14_xgboost_classifier_tuning.R")
  safe_source("Modeling/15_run_all_classifiers.R")
}
if (run_rf)  safe_source("Modeling/10_rf_model.R")
if (run_svr)  safe_source("Modeling/11_svr_model.R")
if (run_tunedrf)  safe_source("Modeling/12_tunedrf_model.R")



cat("\n✅ Data pipeline complete. All stages executed.\n")