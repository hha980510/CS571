# 📊 NVIDIA Stock Price Prediction Pipeline

This repository contains a robust, end-to-end pipeline for predicting the short- to medium-term (1 week to 1 month) price movement of NVIDIA (NVDA) stock using technical indicators and macroeconomic variables.

---

## 🚀 Project Overview

This project combines **data preparation**, **feature engineering**, **target generation**, and a suite of **regression** and **classification models**. It evaluates models using both traditional accuracy metrics and financial strategy metrics to determine their practical profitability.

---

## 🧱 Pipeline Structure

The pipeline is modular and controlled through a single master script: `data_pipeline.R`.

### 🗂️ Modules Included

- **Data Clean**
  - `import_data.R`: Pulls stock and macroeconomic data.
  - `handle_missing.R`: Cleans and fills missing values using time-series forward fill.
  
- **Data preparation**
  - `feature_engineering.R`: Builds technical and macro features.
  - `clean_column_structure.R`: Cleans and aligns column names and structures.
  - `data_quality_checks.R`: Checks consistency, types, NAs, etc.
  - `add_targets.R`: Generates price and direction targets.

- **Exploratory Data Analysis**

 - `univariate_distribution.R`: Plots histograms and density plots of technical indicators (RSI, MACD, Volatility, Volume, Return).
 - `Time-series_plots.R`: Generates time series plots for key indicators (Close price, RSI, MACD, Volatility).
 - `Stationarity_Test.R`: Performs ADF and KPSS tests on log returns; saves results and plots.
 - `ACF_PACF_plots.R`: Plots ACF and PACF of log returns to explore autocorrelation structure.
 - `Scatter_plots.R`: Shows scatter plots of each feature against target variables to assess linear relationships.
 - `feature_response_relationship.R`: Visualizes how selected features relate to price or directional targets using smoothed plots.
 - `technical_indicator_boxplots.R`: Creates boxplots grouped by direction target to compare feature distributions across classes.
 - `Correlation_Heatmap.R`: Displays a correlation heatmap across all numeric predictors and targets.

- **Modeling Setup**
  - `00_modeling_setup.R`: Defines feature sets, target variables, and output folders.
  - `01_data_split.R`: Performs time-based split into train/test sets.
  - `03_modeling_utils.R`: Evaluation and plotting functions for regression models.
  - `04_strategy_evaluation_utils.R`: Trading strategy metrics (returns, Sharpe, drawdown).

- **Models Implemented**
  - Baseline
  - Linear Regression
  - Lasso Regression
  - Ridge Regression
  - XGBoost Regressor
  - XGBoost Classifier (standard + tuned)
  - Random Forest
  - Support Vector Regression (SVR)
  - Random Forest Tuned

---

## ▶️ Running the Pipeline

To run the full pipeline from start to finish, including data loading, cleaning, modeling, and evaluation:

```r
source("data_pipeline.R")
```

You can control which models to run by toggling the following flags inside data_pipeline.R:

```r
run_linear <- TRUE
run_lasso <- TRUE
run_ridge <- TRUE
run_xgboost <- TRUE
run_xgboost_tuning <- TRUE
```
## 🧮 Model Evaluation

Each model is evaluated using:

### 📉 Regression Metrics

- **RMSE** (Root Mean Squared Error)  
- **MAE** (Mean Absolute Error)  
- **MAPE** (Mean Absolute Percentage Error)  
- **R²** (Coefficient of Determination)  

### 💰 Strategy Metrics

- **Cumulative Return**: Total profit/loss from trading  
- **Sharpe Ratio**: Risk-adjusted return (target ≥ 0.8)  
- **Max Drawdown**: Worst loss from peak (target ≤ 15%)  
- **Directional Accuracy**: Percent of times model predicted the right direction  

---

## 📁 Output Structure

All outputs are stored under the `/Results/` directory:

### 🔹 Model-specific folders:

- `/Results/LinearRegression_*`  
- `/Results/XGBoost_Regression_*`  
- `/Results/XGBoost_Classifier_Tuned_*`  

### 📄 Files inside each model folder:

- `*_predictions.csv`: Actual vs. predicted values  
- `*_plot.png`: Time-series plot of predictions  

### 📊 Centralized log:

- `Results/all_model_metrics.csv`: Combined metrics across all models  

---

## 📌 Technologies Used

- **Language**: R  
- **Libraries**:  
  `xgboost`, `caret`, `dplyr`, `quantmod`, `TTR`, `zoo`, `ggplot2`, `scales`  
- **Data Sources**:  
  - Yahoo Finance (via `quantmod`)  
  - FRED (Federal Reserve Economic Data)