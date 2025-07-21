# ============================================
# Script: 05_baseline_classifier_model.R
# Purpose: Baseline model for directional classification using majority class
# ============================================

# Load setup and utility scripts
source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")

# Load training and testing datasets
train <- readRDS("Modeling/Data_Splits/train_set.rds")
test  <- readRDS("Modeling/Data_Splits/test_set.rds")

# Define model name
model_name <- "Baseline_Classifier"

# Loop through each directional target variable
for (target_var in direction_targets) {
  
  # Extract relevant columns
  actual_direction <- test[[target_var]]
  dates <- test$date
  current_prices <- test$NVDA.Close
  
  # Predict the most common class from the training set
  most_common <- as.integer(
    names(sort(table(train[[target_var]]), decreasing = TRUE)[1])
  )
  if (is.na(most_common)) most_common <- 1  # Fallback in case of NA
  preds <- rep(most_common, length(actual_direction))  # Repeat baseline prediction
  
  # Calculate classification accuracy
  accuracy <- mean(preds == actual_direction, na.rm = TRUE)
  
  # Evaluate trading strategy metrics
  strategy_metrics <- evaluate_strategy_metrics(
    predictions = preds,
    actuals = actual_direction,
    current_prices = current_prices,
    test_dates = dates,
    direction_target = TRUE
  )
  
  # Create folder for saving results
  results_path <- file.path(results_folder, model_name)
  dir.create(results_path, showWarnings = FALSE)
  
  # Save predictions to CSV
  save_predictions(
    actual = actual_direction,
    predicted = preds,
    dates = dates,
    filepath = file.path(results_path, paste0(target_var, "_predictions.csv"))
  )
  
  # Generate and save prediction plot
  plot_df <- na.omit(data.frame(Date = dates, Actual = actual_direction, Predicted = preds))
  plot <- plot_predictions(
    actual = plot_df$Actual,
    predicted = plot_df$Predicted,
    dates = plot_df$Date,
    title = paste("Baseline Classifier:", target_var)
  )
  ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)
  
  # Append results to the central model metrics file
  append_model_results(
    model_name = model_name,
    target_var = target_var,
    metrics = list(Accuracy = accuracy),
    strategy_metrics = strategy_metrics,
    filepath = file.path(results_folder, "all_model_metrics.csv")
  )
}

cat("✅ Baseline classifier complete.\n")
