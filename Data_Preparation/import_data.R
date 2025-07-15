# ============================
# Script: import_data.R
# Purpose: Load stock and macroeconomic data
# Input: None
# Output: Global variables (nvda_data, CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM)
# Save: nvda_data_raw.rds, macro_data_raw.rds
# ============================

library(quantmod)
library(TTR)

# Stock Data
getSymbols("NVDA", src = "yahoo", from = "2017-01-01", env = globalenv())
nvda_data <- NVDA # Renaming for consistency

# Macroeconomic Data
getSymbols(
  c("CPIAUCNS", "FEDFUNDS", "DGS10", "UNRATE", "GDP", "DTWEXM"),
  src = "FRED",
  from = "2017-01-01",
  env = globalenv()
)

# Store raw macro data as a combined object
macro_data_raw <- merge(CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM)
# Remove original single-variable global objects to keep env clean for later steps if sourcing
rm(CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM, envir = globalenv())

# --- Save Raw Data ---
dir.create("Data_Clean", showWarnings = FALSE) # Ensure directory exists
saveRDS(nvda_data, file = "Data_Clean/nvda_data_raw.rds")
saveRDS(macro_data_raw, file = "Data_Clean/macro_data_raw.rds")

print("✅ Data imported and raw versions saved.")