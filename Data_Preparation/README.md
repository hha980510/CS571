# 📊 My Stock Price Prediction Data Pipeline

This document details my robust data pipeline, meticulously crafted in R, to prepare historical NVIDIA (NVDA) stock data and relevant macroeconomic indicators for a stock price prediction model. My primary goal is to ensure the data is clean, consistent, and free from look-ahead bias, providing a reliable foundation for machine learning.

---

## 🚀 Pipeline Orchestration: `data_pipeline.R`

This file serves as the **master script** for the entire data preparation process. I structured it this way to ensure **reproducibility** and **automation**. By simply running `source("data_pipeline.R")`, I can execute the full sequence of data import, cleaning, feature engineering, and quality checks in the correct order. This is a critical design choice for an analytical project, allowing me to easily re-run the pipeline when new data is available or if I modify any of the underlying processing steps.

**Orchestrates Generation of the following data files in the `Data_Clean` folder:**
* **`nvda_data_raw.rds`**: Stores the **raw, unaligned daily NVIDIA stock prices** (`xts` object) directly from Yahoo Finance, representing the initial, unprocessed stock data.
* **`macro_data_raw.rds`**: Contains all **raw, unaligned macroeconomic indicators** as a combined `xts` object, exactly as retrieved from the FRED database.
* **`nvda_data_after_missing_handling.rds`**: The NVIDIA stock data, now **aligned to a daily frequency** with basic NA handling (e.g., forward-filled for non-trading days), providing a continuous daily stock view.
* **`macro_data_combined_daily.rds`**: All macroeconomic indicators, **aligned to a daily frequency and with missing values intelligently handled** to respect their actual release lags, creating a unified daily economic context.
* **`nvda_data_fully_engineered.rds`**: The NVIDIA dataset, **enriched with all derived technical indicators, return calculations, lagged features, scaled features, and merged macroeconomic data**. This is a comprehensive feature set before final NA removal.
* **`nvda_data_structured_clean.rds`**: The `nvda_data_fully_engineered.rds` dataset **after the removal of any constant (zero-variance) columns**. It's more efficient but still retains initial `NA` values from indicator calculations and differing data start dates.
* **`cleaned_nvda_data.csv`**: The **final, complete-case, fully cleaned dataset** in CSV format. All rows containing `NA` values have been removed, making it ready for direct use in various modeling environments or for easy viewing.
* **`cleaned_nvda_data.rds`**: The **final, complete-case, fully cleaned dataset** in R data serialization format. This is highly efficient for loading back into R, preserving all data types and structure, ideal for subsequent R-based modeling.

---

## 📥 Stage 1: Data Acquisition (`Data_Preparation/import_data.R`)

This is where I first acquire the raw ingredients for my analysis.

* **What it does:**
    * I use `quantmod::getSymbols()` to download **historical daily NVIDIA (NVDA) stock prices** (Open, High, Low, Close, Volume, Adjusted Close) directly from Yahoo Finance, starting from **January 1, 2005**. This is my primary time series and the asset I aim to predict.
    * Simultaneously, I fetch **macroeconomic indicators** from the Federal Reserve Economic Data (FRED) database, starting from **January 1, 2017**. These include:
        * **CPIAUCNS:** Consumer Price Index (All Urban Consumers).
        * **FEDFUNDS:** Federal Funds Effective Rate.
        * **DGS10:** 10-Year Treasury Constant Maturity Rate.
        * **UNRATE:** Unemployment Rate.
        * **GDP:** Gross Domestic Product.
        * **DTWEXM:** Nominal Major Currencies U.S. Dollar Index.
* **Period Taken:** NVIDIA data from 2005-01-01; Macroeconomic data from 2017-01-01.
* **Why this period:** The **NVIDIA** data provides a long history for technical analysis. The macroeconomic data's start date (2017) is a constraint based on the availability of these specific **FRED** series, which will become a key challenge later in the pipeline.
* **Challenge & Decision:** The main challenge here is dealing with **disparate start dates** and **differing frequencies** of the raw data. My decision is to import everything available, then handle the alignment and missingness in the subsequent `handle_missing.R` script. I opt for `xts` objects from `quantmod` as they are highly efficient for time series operations in R.

**Files Generated in `Data_Clean` folder:**
* **`nvda_data_raw.rds`**: The raw, unaligned NVIDIA stock data as an `xts` object.
* **`macro_data_raw.rds`**: A combined `xts` object containing all raw, unaligned macroeconomic indicators.

---

## 🧼 Stage 2: Temporal Alignment & Missing Value Handling (`Data_Preparation/handle_missing.R`)

This is arguably the most critical and complex stage, where I confront the business-specific challenge of data availability lags for economic indicators. My overarching goal is to avoid **look-ahead bias**, meaning my model must *only* use information that was genuinely public and available at the time of a given prediction.

* **What it does:**
    * **Universal Daily Template:** I first establish a complete `daily_template` covering every single day within the combined range of my stock and macro data. This template serves as the foundation for aligning all series.
    * **Indicator-Specific Cleaning:**
        * **CPIAUCNS (Consumer Price Index)** 📈
            * **Specification:** Monthly inflation data. FRED typically indexes it to the first day of the reference month (e.g., May's CPI is 2025-05-01).
            * **Business Specificity/Challenge:** The CPI for month 'X' isn't released until around the **middle of month 'X+1'**. If I were to use the CPI on its reference date, my model would be "seeing into the future." This is a classic source of look-ahead bias in financial modeling.
            * **Decision/Technique:** I apply a **date shift**: `index(CPIAUCNS) + months(1) + days(14)`. This approximates the actual release date. Then, I `merge` this onto the `daily_template` and apply `na.locf()` (Last Observation Carried Forward). This means the last publicly announced CPI value is held constant until the next release, accurately reflecting market information.
        * **UNRATE (Unemployment Rate)** 🧑‍💼
            * **Specification:** Monthly measure of labor market health. FRED indexes it to the first day of the reference month.
            * **Business Specificity/Challenge:** Similar to CPI, the Unemployment Rate for month 'X' is released on the **first Friday of month 'X+1'**. Again, look-ahead bias is a risk.
            * **Decision/Technique:** I apply a **date shift**: `index(UNRATE) + months(1)`. While not precisely the first Friday, it's a close approximation that captures the monthly lag effectively. I then `merge` and apply `na.locf()`, ensuring only the latest *released* unemployment data is used.
        * **GDP (Gross Domestic Product)** 📊
            * **Specification:** Quarterly measure of economic output. FRED indexes it to the first day of the quarter.
            * **Business Specificity/Challenge:** GDP data for quarter 'Q' is typically released in the **first month of quarter 'Q+1'**. This is a longer lag than monthly indicators.
            * **Decision/Technique:** I apply a **date shift**: `index(GDP) + months(3) - days(1)` (approximating the end of the first month of the next quarter). After merging, `na.locf()` fills the daily gaps with the last known quarterly GDP figure.
        * **FEDFUNDS (Federal Funds Effective Rate), DGS10 (10-Year Treasury Rate), DTWEXM (U.S. Dollar Index)** 🏦
            * **Specification:** These are largely **daily** (business day) indicators reflecting short-term interest rates, long-term bond yields, and currency strength.
            * **Business Specificity/Challenge:** While daily, they are not reported on weekends or holidays, creating small gaps.
            * **Decision/Technique:** I directly `merge` these with the `daily_template`. The resulting NAs for non-business days are then filled using `na.locf(..., fromLast = TRUE)`. This ensures that on any given day, the last available rate or index value is carried forward until a new one is published, which is the standard market practice.
    * All individual daily macro series are then combined into a single `macro_data_combined_daily` `xts` object.
* **Challenge Addressed:** **Look-ahead bias** and **frequency mismatch** are the core challenges tackled by this script. My decisions to shift dates to release dates and use `na.locf()` are fundamental to creating a realistic information environment for the model.

**Files Generated in `Data_Clean` folder:**
* **`nvda_data_after_missing_handling.rds`**: NVIDIA stock data aligned to a daily frequency with basic NA handling (e.g., forward-filled for non-trading days).
* **`macro_data_combined_daily.rds`**: All macroeconomic indicators, aligned to a daily frequency, with missing values handled respecting their release lags.

---

## 🛠️ Stage 3: Feature Engineering (`Data_Preparation/feature_engineering.R`)

In this script, I enrich my core `nvda_data` with features that capture market dynamics and integrate broader economic context.

* **What it does:**
    * **Technical Indicators:** I calculate commonly used technical indicators:
        * **RSI (Relative Strength Index, 14-period):** A momentum oscillator to gauge overbought or oversold conditions.
        * **MACD (Moving Average Convergence Divergence) & Signal Line:** A trend-following momentum indicator.
        * **20-day Volatility:** The standard deviation of 20-day log returns, measuring price fluctuation.
    * **Return Features:** I calculate **daily logarithmic returns**, which are preferred for their additive properties and more symmetrical distribution.
    * **Lag Features:** I create lagged versions of the closing price (`lag_close_1`) and log return (`lag_return_1`). These are vital as past values are often strong predictors of future values in time series.
    * **Scaled Features:** I **standardize** the closing price and RSI (`scale(Cl(nvda_data))` and `scale(nvda_data$RSI14)`). This transforms them to have a mean of 0 and a standard deviation of 1.
    * **Outlier Detection:** I derive a `z_return` (scaled log return) and create an `outlier` flag for extreme price movements (e.g., `abs(z_return) > 3`). This allows for potential special handling or analysis of significant events.
    * **Macroeconomic Integration:** Finally, I perform a `merge` of the `macro_data_combined_daily` (from the previous step) with `nvda_data` based on their shared daily index. Column names are then cleaned for consistency (e.g., `cpi`, `fed_funds`).
* **Period Taken:** This script operates on the combined `nvda_data` and `macro_data_combined_daily`. The effective start date for fully populated features will be constrained by the availability of all required past data for indicator calculation (e.g., 20 days for volatility) and the macro data's start (2017).
* **Business Specificity:** Technical indicators are widely used by traders to identify trends, momentum, and potential reversal points. Lag features are a direct application of the time-series nature of stock data. Macroeconomic factors provide a top-down view that can influence market sentiment and valuations.
* **Challenge & Decision:**
    * **Challenge:** The main challenge is the initial NA values generated by technical indicator calculations (e.g., the first 19 days of a 20-day SMA are NA). Also, merging stock data from 2005 with macro data from 2017 means all pre-2017 stock data will have NAs for macro features.
    * **Decision:** I consciously accept these initial NAs here, knowing they will be systematically handled in the final data quality check. The scaling decision is crucial for many ML models which perform poorly or converge slowly with unscaled data.

**Files Generated in `Data_Clean` folder:**
* **`nvda_data_fully_engineered.rds`**: The NVIDIA dataset enriched with all derived technical, return, lagged, scaled, outlier, and merged macroeconomic features. This is a comprehensive feature set before final NA removal.

---

## 🧹 Stage 4: Column Structure Cleanup (`Data_Wrangling/clean_column_structure.R`)

This stage focuses on refining the structure of the dataset.

* **What it does:**
    * I identify and remove any columns that have zero (or near-zero) variance. This means columns where all values are identical or almost identical.
* **Period Taken:** Operates on the full `nvda_data` object at this point.
* **Business Specificity:** In a dynamic financial environment, features should provide discriminative information.
* **Challenge & Decision:**
    * **Challenge:** Sometimes, after merging or specific calculations, columns might inadvertently end up with constant values (e.g., if a data source consistently reported '0' for a period, or a feature was always 'TRUE' within a subset). Such columns provide no predictive power.
    * **Decision:** My decision is to remove these constant columns. They add computational overhead without contributing to model learning. It's a form of dimensionality reduction and noise removal.

**Files Generated in `Data_Clean` folder:**
* **`nvda_data_structured_clean.rds`**: The `nvda_data_fully_engineered.rds` dataset after the removal of any constant columns. This dataset is now more efficient and relevant for modeling, but still retains `NA` values resulting from initial indicator calculations and the differential start dates of data sources.

---

## 🔍 Stage 5: Data Quality Checks (`Data_Wrangling/data_quality_checks.R`)

This is my final gate, ensuring the dataset is pristine and ready for modeling.

* **What it does:**
    * I verify that there are no duplicate timestamps in the `nvda_data` index. While `xts` largely handles this, an explicit check confirms data integrity.
    * **Critical Cleaning: NA Removal** 🗑️
        * I explicitly run `nvda_data <- na.omit(nvda_data)`. This command removes any row from the `xts` object where *any* column contains an `NA` value.
    * **Saving Cleaned Data:** The final, processed `nvda_data` `xts` object is converted into a standard `data.frame` for broader compatibility. This `data.frame` is then saved in two formats:
        * `Data_Clean/cleaned_nvda_data.csv`: A widely readable format for persistence and sharing.
        * `Data_Clean/cleaned_nvda_data.rds`: An R-native binary format that is faster to load back into R and preserves object structure.
    * The `nvda_data` object also remains available in the R session's memory.
* **Period Taken:** After `na.omit()`, the effective start date of my cleaned dataset is **constrained by the latest start date of a non-NA feature**. Given that macroeconomic data starts in 2017, and technical indicators have a burn-in period, my final cleaned data set will likely begin sometime in **early 2017** (e.g., after the first few weeks of January 2017 to allow for 20-day lookbacks on daily macro data that started then).
* **Business Specificity:** A model trained on incomplete or inconsistent data will perform poorly and give unreliable predictions.
* **Challenge & Decision:**
    * **Challenge:** The most significant challenge addressed here is the **presence of `NA`s** that are inherent from:
        1.  **Indicator "Burn-in":** Technical indicators require historical data (e.g., 20 days for volatility) to compute their first valid value. The initial rows for these columns will be `NA`.
        2.  **Macro Data Start Date:** My NVIDIA data starts in 2005, but macroeconomic data only begins in 2017. Any NVIDIA data rows before 2017 will have `NA`s for all macroeconomic features.
    * **Decision:** I make the crucial decision to **remove all rows containing `NA`s using `na.omit()`**.
        * **Why Delete?** Many machine learning models simply **cannot handle `NA` values**; they will either crash, produce errors, or yield biased results. While imputation is an alternative, for this specific context (initial `NA`s due to data availability or calculation necessity), **deleting is the most robust and honest approach**. It ensures that every observation my model learns from is a **complete case**, reflecting a moment in time where all chosen features were genuinely available. This avoids introducing arbitrary values that might skew the model's understanding of real-world relationships. My model will thus operate on the period where it has the full, consistent informational context.

**Files Generated in `Data_Clean` folder:**
* **`cleaned_nvda_data.csv`**: The final, complete-case, cleaned dataset in CSV format. This is ready for direct use in various modeling environments or for quick viewing.
* **`cleaned_nvda_data.rds`**: The final, complete-case, cleaned dataset in R data serialization format. This is highly efficient for loading back into R while preserving all data types and `data.frame` structure, ideal for subsequent R-based modeling.

## 🎯 Stage 6: Target Variable Creation (`Data_Wrangling/add_targets.R`)

This crucial step transforms the cleaned dataset into a supervised learning format by adding **future target values** for model training and evaluation.

### 🔧 What it does:
- For each date in the dataset, the script calculates:
  - **Target_5_Price / Target_10_Price / Target_21_Price**: The actual NVDA closing price after 5, 10, and 21 trading days respectively.
  - **Target_5_Direction / Target_10_Direction / Target_21_Direction**: A binary classification label:
    - `1` if the price increases
    - `0` if the price decreases or stays the same  
    Computed as:  
    ```r
    Direction = ifelse(Future_Price > Current_Close, 1, 0)
    ```

### 📈 Business Specificity:
- These targets align with **1-week**, **2-week**, and **1-month** investment/trading windows.
- They enable evaluation of both **regression (price forecasting)** and **classification (directional movement)** models.

### ⚠️ Challenges & Decisions:
- The final 5/10/21 rows naturally lack future data, so the corresponding target columns contain `NA`. These are retained but will be excluded from model training.
- Targets are calculated using actual future prices, ensuring objective and unbiased ground truth.

### 📁 Output:
- **`nvda_data_with_targets.rds`**: Final cleaned dataset with all engineered features **plus target values**, saved in the `Data_Clean` folder.

---

## 🔍 Additional Sanity Checks (`Sanity_Checks/check_cleaned_data.R`)

After all features and targets are added, this step validates the data to ensure it's ready for modeling.

### ✅ Key Validations:
- No unexpected `NA` values (aside from trailing rows with unavailable future targets).
- All expected target columns are present and correctly typed.
- Direction labels (`0`/`1`) are reasonably distributed.
- Future price targets are **highly but naturally correlated** with the current NVDA.Close price, confirming correctness.

This step gives full confidence before modeling begins and avoids hidden data quality issues downstream.
