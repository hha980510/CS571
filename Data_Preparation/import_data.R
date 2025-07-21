# ============================================
# Script: import_data.R
# Purpose: Import NVDA stock and macroeconomic data
# Output: Raw RDS files for stock and macro data
# ============================================

library(quantmod)
library(TTR)

# Load NVDA stock data
getSymbols("NVDA", src = "yahoo", from = "2017-01-01", env = globalenv())
nvda_data <- NVDA

# Load macroeconomic indicators from FRED
getSymbols(
  c("CPIAUCNS", "FEDFUNDS", "DGS10", "UNRATE", "GDP", "DTWEXM"),
  src = "FRED",
  from = "2017-01-01",
  env = globalenv()
)

# Combine macro variables and clean global environment
macro_data_raw <- merge(CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM)
rm(CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM, envir = globalenv())

# Save raw data
dir.create("Data_Clean", showWarnings = FALSE)
saveRDS(nvda_data, "Data_Clean/nvda_data_raw.rds")
saveRDS(macro_data_raw, "Data_Clean/macro_data_raw.rds")

message("✅ Data imported and saved.")