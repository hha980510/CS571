# ============================
# Script: import_data.R
# Purpose: Load stock and macroeconomic data
# Input: None
# Output: Global variables (NVDA, CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM)
# ============================

library(quantmod)
library(TTR) # TTR is needed for some indicators later, good to load early

# Stock Data
# Ensure it's explicitly assigned to nvda_data and not just NVDA from getSymbols
getSymbols("NVDA", src = "yahoo", from = "2005-01-01", env = globalenv())
nvda_data <- NVDA # Renaming for consistency

# Macroeconomic Data - force to global environment
getSymbols(
  c("CPIAUCNS", "FEDFUNDS", "DGS10", "UNRATE", "GDP", "DTWEXM"),
  src = "FRED",
  from = "2017-01-01", # You can align this start date with your NVDA data if needed
  env = globalenv()
)

print("✅ Data imported successfully.")