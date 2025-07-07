
---

## 🚀 How the Data Pipeline Works

The core pipeline is orchestrated in the `data_pipeline.R` file, which automates the following stages:

### 1. 📥 Data Import
**File:** `Data_Preparation/import_data.R`  
- Loads historical NVIDIA stock prices using `quantmod::getSymbols()`  
- Stores data as `nvda_data`

### 2. 🧼 Handling Missing Values
**File:** `Data_Preparation/handle_missing.R`  
- Fills NA values using `na.locf()`  
- Ensures a continuous time series

### 3. 🛠️ Feature Engineering
**File:** `Data_Preparation/feature_engineering.R`  
- Adds technical indicators:
  - RSI (14)
  - MACD & Signal Line
  - 20-day Volatility
  - Lag features (close and return)
  - Log returns
  - Scaled indicators

### 4. 🧹 Column Structure Cleanup
**File:** `Data_Wrangling/clean_column_structure.R`  
- Resets column names to lower_snake_case  
- Removes redundant or unnamed columns

### 5. 🔍 Data Quality Checks
**File:** `Data_Wrangling/data_quality_checks.R`  
- Verifies no duplicate timestamps  
- Prints structure and NA counts  
- Saves cleaned dataset both as:
  - A CSV file at `/cleaned_data/nvda_cleaned.csv`  
  - An in-memory `nvda_data` dataframe for use in analysis scripts

---

## 💾 Saving Outputs

- Cleaned and processed data is saved as:
  - `nvda_data` (in-memory dataframe)
  - `/cleaned_data/nvda_cleaned.csv` (for persistence and sharing)

---

## 🔁 Re-run Pipeline

To re-run the entire pipeline at once, simply execute:

```r
source("data_pipeline.R")
