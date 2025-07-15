# 06_feature_grouping.R

# --- Grouping Feature Columns for Experimental Design ---

# This script defines subsets of features based on domain context:
# 1. Technical Indicators: Derived from price/volume data (e.g., moving averages, volatility)
# 2. Economic Indicators: External macroeconomic signals (e.g., interest rates, inflation)
# 3. Combined Features: All available features excluding targets and date

# These subsets support comparative analysis of feature impact on prediction performance
# and enable structured experimentation aligned with defined research questions.

# --- Define Technical Indicators ---
technical_features <- c(
  "SMA_10", "SMA_50", "SMA_200",        # Simple moving averages
  "EMA_12", "EMA_26",                   # Exponential moving averages
  "MACD", "MACD_Signal",                # Moving Average Convergence Divergence
  "RSI_14",                             # Relative Strength Index
  "ATR_14",                             # Average True Range (volatility)
  "NVDA.Volume",                        # Trading volume
  "Price_Range", "Daily_Return"        # Price-based features
)

# --- Define Economic Indicators ---
economic_features <- c(
  "CPIAUCNS",     # Consumer Price Index
  "FEDFUNDS",     # Federal Funds Rate
  "DGS10",        # 10-Year Treasury Yield
  "UNRATE",       # Unemployment Rate
  "GDP",          # Gross Domestic Product
  "DTWEXM"        # U.S. Dollar Index
)

# --- Validate Existence in Dataset ---
available_technical_features <- technical_features[technical_features %in% names(nvda_data_cleaned)]
available_economic_features  <- economic_features[economic_features %in% names(nvda_data_cleaned)]

# --- Define Combined Feature Set ---
combined_features <- names(nvda_data_cleaned)[
  !names(nvda_data_cleaned) %in% c(
    "Date",
    "Target_1W_Price", "Target_2W_Price", "Target_1M_Price",
    "Target_1W_Direction", "Target_2W_Direction", "Target_1M_Direction"
  )
]

# --- Output Confirmation Messages ---
message(paste0("✅ Technical features: ", length(available_technical_features)))
message(paste0("✅ Economic features: ", length(available_economic_features)))
message(paste0("✅ Combined features (all predictors): ", length(combined_features)))
