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
