library(quantmod)
library(TTR)

# Stock Data
getSymbols("NVDA", src = "yahoo", from = "2005-01-01", env = globalenv())
nvda_data <- NVDA

# Macroeconomic Data - force to global environment
getSymbols(
  c("CPIAUCNS", "FEDFUNDS", "DGS10", "UNRATE", "GDP", "DTWEXM"),
  src = "FRED",
  from = "2017-01-01",
  env = globalenv()
)