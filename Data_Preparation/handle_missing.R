# Load macroeconomic data
source("Data_Preparation/import_data.R", encoding = "UTF-8")

# Load required library for forward fill
library(zoo)

# Create list of macroeconomic series
macro_vars <- list(CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM)

# Forward-fill missing values
macro_filled <- lapply(macro_vars, function(x) na.locf(na.locf(x, fromLast = TRUE)))

# Reassign back to variables
CPIAUCNS <- macro_filled[[1]]
FEDFUNDS <- macro_filled[[2]]
DGS10    <- macro_filled[[3]]
UNRATE   <- macro_filled[[4]]
GDP      <- macro_filled[[5]]
DTWEXM   <- macro_filled[[6]]

# Optional: Print confirmation
print("✅ Missing values handled using na.locf")
print(sapply(macro_filled, function(x) sum(is.na(x))))
