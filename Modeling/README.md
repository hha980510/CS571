# 📘 How to Add a New Model to This Project

This guide explains how to add a new model to the stock price prediction project, step by step and explains how strategy metrics are calculated.

---

## 🛠️ What You Need to Do to Add a Model

### 1. Create Your Model Script
- Place your script in the **Modeling/** folder.
- Use one of the existing model scripts (like `06_lasso_model.R`) as a **template**.
- You must include:
  - The name of your model
  - The feature set you're using (technical, economic, or all)
  - The target variable (price or direction)
  - Code to train the model
  - Code to make predictions

---

### 2. Source These Setup Files First

At the top of your script, always add:

```r
source("Modeling/00_modeling_setup.R")
source("Modeling/03_modeling_utils.R")
source("Modeling/04_strategy_evaluation_utils.R")
```
## ✅ Data Preparation and Evaluation Instructions

These setup files load important **features**, **train/test data**, and **functions** used for evaluation.

---

### 📌 No Need to Split the Data Yourself

✅ The dataset has already been split by date using the `01_split_train_test.R` script.  
✅ The output is saved as `.rds` files for reuse in any model.

---

### ✅ What’s Already Done

- The cleaned dataset was filtered to remove rows with invalid or missing target values.
- A **time-based split** was applied:
  - **Training Set**: Data before `2023-01-01`
  - **Testing Set**: Data from `2023-01-01` onward

#### 📁 Saved Files

Modeling/Data_Splits/train_set.rds
Modeling/Data_Splits/test_set.rds


---

### 📂 Load Your Train/Test Data

In any model script, include the following:

```r
train <- readRDS("Modeling/Data_Splits/train_set.rds")
test  <- readRDS("Modeling/Data_Splits/test_set.rds")
```
This gives you consistent and pre-split data used across all models.

## 📈 How to Evaluate Your Model

### 🔹 For Regression Models
```r
metrics <- evaluate_regression_model(actuals, predictions)
```
### 🔹 For Classification Models
```r
accuracy <- mean(predicted_direction == actual_direction)
```
### 🔹 If You Also Want Strategy Metrics (like return, Sharpe, drawdown)
```r
strategy_metrics <- evaluate_strategy_metrics(...)
```
## 💾 How to Save Model Results
To ensure everything stays organized and comparable across models, follow this structure:

### 📍 Step 1: Create Output Folder for the Model

```r
results_path <- file.path(results_folder, model_name)
dir.create(results_path, showWarnings = FALSE)
```

This creates a folder like:

```swift

/Results/XGBoost_Regression_Technical/
```
### 📍 Step 2: Save Predictions to CSV
```r
save_predictions(
  y_test,         # actual values
  preds,          # predicted values
  dates,          # date index
  file.path(results_path, paste0(target_var, "_predictions.csv"))
)
```
This creates a file like:

```swift
/Results/XGBoost_Regression_Technical/Target_5_Price_predictions.csv
```

### 📍 Step 3: Save Time-Series Plot

```r
plot_df <- na.omit(data.frame(Date = as.Date(dates), Actual = y_test, Predicted = preds))
plot <- plot_predictions(plot_df$Actual, plot_df$Predicted, plot_df$Date,
                         title = paste("XGBoost Regressor:", config, target_var))
ggsave(file.path(results_path, paste0(target_var, "_plot.png")), plot)
```
This saves a plot like:

```swift
/Results/XGBoost_Regression_Technical/Target_5_Price_plot.png
```

### 📍 Step 4: Append Metrics to Shared CSV
```r
append_model_results(
  model_name = model_name,
  target_var = target_var,
  metrics = metrics,
  strategy_metrics = strategy_metrics,
  filepath = file.path(results_folder, "all_model_metrics.csv")
)
```
This adds a row to the combined metrics file:

```bash
/Results/all_model_metrics.csv
```
**⚠️ Important:** Always append to this file — do not overwrite or delete it.

------ 


## 📊 How Strategy Metrics Are Calculated

This section explains how the main financial performance metrics are computed inside our `evaluate_strategy_metrics()` function (from `04_strategy_evaluation_utils.R`). These metrics help us evaluate how well the model would perform in a real trading scenario.

---

### 📥 Input Variables

| Variable Name     | Description |
|-------------------|-------------|
| `predictions`     | Model's predicted values (either price or direction). |
| `actuals`         | The actual future prices or directions. |
| `current_prices`  | The current (base) stock prices used to compute returns. |
| `test_dates`      | Dates corresponding to the test set (must align with `current_prices`). |
| `probabilities`   | (Optional) Probabilities from classification models (used for thresholding). |
| `direction_target`| Boolean (`TRUE`/`FALSE`): indicates whether it’s a classification task. |
| `capital_base`    | Starting capital for backtesting (default: `$10,000`). |
| `rf_rate`         | Risk-free rate used in Sharpe ratio (default: `0.01` annual). |

---


# 📊 Strategy Evaluation Logic

This file explains how each performance metric is calculated in the `evaluate_strategy_metrics()` function used for backtesting trading strategies.

---

## 📈 Step-by-Step Logic

### ✅ Step 1: Calculate Returns
We use **daily log returns** based on price movement:

```r
returns <- diff(log(current_prices))
```

This gives us the percentage change in stock price between days on a log scale.

---

### ✅ Step 2: Generate Trade Signals

We compute **trade signals** based on the model's prediction type.

#### 🔹 Classification Models (directional prediction):
- If probability values are available:
  - **Buy**: `prob > 0.6` → signal = 1
  - **Sell**: `prob < 0.4` → signal = -1
  - **Hold**: otherwise → signal = 0
- If no probability, we use:
  - `signal = 1` if predicted direction == actual direction
  - `signal = -1` otherwise

#### 🔹 Regression Models (price prediction):
- Predict future price
- Compare prediction to current price:
  - If predicted price > current price → predicted direction = 1
  - Else → predicted direction = -1
- Then:
  - If predicted direction == actual direction → `signal = 1`
  - Else → `signal = -1`

```r
trade_signal <- ifelse(predicted_direction == actual_direction, 1, -1)
```

---

### ✅ Step 3: Compute Strategy Returns

```r
strategy_returns <- returns * trade_signal
```

- If the model is correct: return stays positive
- If the model is wrong: return becomes negative (bad trade)

---

### ✅ Step 4: Build Equity Curve

```r
equity_curve <- cumprod(1 + strategy_returns)
```

This simulates portfolio growth if $1 was invested and trades were made based on model predictions.

---

## 📏 Metrics Explained

| Metric | Description |
|--------|-------------|
| **Cumulative Return** | Final portfolio value minus 1. Represents total return from the trading strategy. <br>`cumulative_return <- last(equity_curve) - 1` |
| **Sharpe Ratio** | Measures risk-adjusted return. Uses daily returns and assumes 252 trading days/year. Higher is better.<br>```SharpeRatio.annualized(strategy_returns, Rf = 0.01 / 252, scale = 252)``` |
| **Max Drawdown** | Worst loss from a peak in portfolio value.<br>`drawdown <- (equity_curve - cummax(equity_curve)) / cummax(equity_curve)`<br>`max_drawdown <- min(drawdown)` |
| **Directional Accuracy** | Percent of times the predicted direction matched the actual direction.<br>`mean(predicted_direction == actual_direction)` |

---

## 💥 Error Handling

If the function encounters a problem (e.g. input mismatch, NA values), it safely returns default values:

```r
list(
  Cumulative_Return = 0,
  Sharpe_Ratio = NA,
  Max_Drawdown = 0,
  Directional_Accuracy = NA
)
```

---

## 🔁 Why This Matters

A model with high prediction accuracy might still perform poorly in trading. This evaluation shows **how well the model performs as a trading system**, not just how accurately it predicts prices.