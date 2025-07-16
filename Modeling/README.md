# 🧰 00_modeling_setup.R

This script initializes and defines key feature sets and modeling parameters for NVIDIA stock price prediction.

---

## 📌 Purpose

To organize and centralize all **feature groupings**, **target definitions**, and **results folder setup** to ensure consistent use across the modeling pipeline.

---

## 📁 What it Does

- **Defines feature groups**:
  - `technical_features`: e.g., SMA20, RSI14, MACD, etc.
  - `economic_features`: e.g., CPI, interest rates, unemployment, etc.
  - `all_features`: union of technical and economic indicators.

- **Defines target variables**:
  - `price_targets`: Future numeric prices (5, 10, and 21 days ahead).
  - `direction_targets`: Binary direction of movement for same periods.

- **Creates a results output folder** (`Results/`) if it does not exist.

---

## 🗂️ Output

- Global variables made available to all subsequent scripts:
  - `technical_features`
  - `economic_features`
  - `all_features`
  - `price_targets`
  - `direction_targets`
  - `results_folder`

These are used to streamline feature selection, evaluation, and reporting in the modeling phase.

---

## ▶️ How to Run

From your R console or any script:
```r
source("Modeling/00_modeling_setup.R")

```
## ✂️ 01_data_split.R

### 📌 Purpose
To separate historical data for model training and hold out future data for unbiased testing.

### 📁 What it Does
* Loads cleaned data from `Data_Clean/nvda_data_with_targets.rds`
* Splits by time:
    * **Train set:** 2017-02-03 to 2022-12-31
    * **Test set:** 2023-01-01 to 2025-07-14
* Saves results into `Modeling/Data_Splits/`

### 🗂️ Output
* `train_set.rds`
* `test_set.rds`

### ▶️ How to Run

```R
source("Modeling/01_data_split.R")
```
---
## 🧮 03_modeling_utils.R

This file provides helper functions for evaluating regression models and visualizing predictions.

### 📌 Purpose
To standardize how we **evaluate model performance** and **store results**.

### 📁 What it Does
* `evaluate_regression_model()`: Computes **RMSE** (Root Mean Squared Error), **MAE** (Mean Absolute Error), **MAPE** (Mean Absolute Percentage Error), and **R²** (Coefficient of Determination). These metrics help quantify how well a model's predictions align with actual values.
* `save_metrics()`: Stores the calculated evaluation metrics into a **`.txt` file** for record-keeping and easy access.
* `save_predictions()`: Saves the model's **predictions** and the corresponding **actual values** to a **CSV file**, which is useful for detailed analysis or sharing.
* `plot_predictions()`: Creates **visualizations** comparing predicted price trends against actual price trends, providing a quick visual assessment of model accuracy. 

### ▶️ How to Run

To make these utility functions available in your R script, first **load the file**:

```R
source("Modeling/03_modeling_utils.R")
```
---
## 💰 04_strategy_evaluation_utils.R

This script evaluates financial strategy performance based on predicted prices.

### 📌 Purpose
Its purpose is to **test if a model-based trading strategy would produce acceptable financial returns and risk characteristics**. This helps determine the practical utility and profitability of a predictive model in a financial context.

### 📁 What it Does
* `calculate_cumulative_return()`: Determines the **total growth** an investment would experience over a specified period. This is a fundamental measure of overall profitability.
* `calculate_sharpe_ratio()`: Calculates the **risk-adjusted return**. A higher Sharpe Ratio (with a target of **≥ 0.8**) indicates that an investment is generating more return for each unit of risk taken, which is desirable for investors. 
* `calculate_max_drawdown()`: Identifies the **largest percentage loss** from a previous peak in equity. A lower maximum drawdown (with a target of **≤ 15%**) suggests a more stable strategy with less severe losses. 
* `evaluate_strategy_metrics()`: A **convenience function** that returns all three of the above financial performance metrics, providing a comprehensive overview of the strategys effectiveness.

### ▶️ How to Run
To use these functions for evaluating your trading strategy, simply **source the script**:

```R
source("Modeling/04_strategy_evaluation_utils.R")
```
# 📈 Linear Regression Modeling

This module focuses on building and evaluating **Linear Regression** models for **NVIDIA (NVDA) stock price prediction**. We're targeting different time horizons:

* **1-week ahead price** (`Target_5_Price`)
* **2-weeks ahead price** (`Target_10_Price`)
* **1-month ahead price** (`Target_21_Price`)

## Feature Sets Evaluated

We experiment with three distinct sets of features to see their impact on prediction accuracy:

* **Technical**: Models trained using only **technical indicators** (e.g., Moving Averages (MA), Relative Strength Index (RSI)).
* **Economic**: Models trained using only **macroeconomic factors** (e.g., Consumer Price Index (CPI), Federal Funds Rate (FEDFUNDS)).
* **All**: Models incorporating **both technical and economic indicators**.

## Evaluation Metrics

Each model's performance is comprehensively assessed using two categories of metrics:

### Regression Metrics
These quantify the model's predictive accuracy:
* **RMSE** (Root Mean Squared Error)
* **MAE** (Mean Absolute Error)
* **MAPE** (Mean Absolute Percentage Error)
* **R²** (Coefficient of Determination)

### Strategy Metrics
These evaluate the practical financial viability of a trading strategy based on the model's predictions:
* **Cumulative Return**
* **Sharpe Ratio**
* **Max Drawdown**

## Output and Results

* **Prediction plots** and detailed **CSV logs** of predictions are saved to the `/Results/Linear_Regression/` directory.
* All model evaluation results are automatically appended to a centralized file: `Results/all_model_metrics.csv`. This provides a single, easy-to-compare overview of all model performances.