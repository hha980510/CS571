# ============================
# Script: handle_missing.R
# Purpose: Handle missing values and align macroeconomic data frequencies
# Input: Global macroeconomic variables (CPIAUCNS, FEDFUNDS, etc.)
# Output: Global daily-aligned macroeconomic variables (e.g., CPIAUCNS_daily)
# ============================

library(xts)     
library(zoo)    
library(lubridate) 

# Confirm original macro data exists
if (!exists("CPIAUCNS") || !exists("FEDFUNDS")) { # Check a few representative ones
  stop("❌ Macroeconomic data not found. Please run import_data.R first.")
}

# --- 1. Define Universal Daily Time Index ---

start_date_overall <- min(index(nvda_data)[1], index(CPIAUCNS)[1]) # Use earliest start date
end_date_overall   <- max(index(nvda_data)[NROW(nvda_data)], index(CPIAUCNS)[NROW(CPIAUCNS)]) # Use latest end date

all_daily_dates <- seq(start_date_overall, end_date_overall, by = "day")
daily_template <- xts(order.by = all_daily_dates)

# --- 2. Process Each Macro Variable Individually for Daily Alignment ---

#### 2.1. CPIAUCNS (Monthly, Released Mid-Next Month)
# FRED's CPIAUCNS is typically indexed by the first day of the reference month (e.g., 2024-01-01 for January 2024 CPI).
cpi_release_dates <- index(CPIAUCNS) + months(1) + days(14) # Approx 15th of next month
CPIAUCNS_on_release_date <- xts(coredata(CPIAUCNS), order.by = cpi_release_dates)

# Merge with daily template, then forward-fill based on release.
CPIAUCNS_daily <- merge(daily_template, CPIAUCNS_on_release_date)
CPIAUCNS_daily <- na.locf(CPIAUCNS_daily, na.rm = FALSE) # Forward fill from release date
# Fill any leading NAs if daily_template starts before the very first CPI release
CPIAUCNS_daily <- na.locf(CPIAUCNS_daily, fromLast = TRUE, na.rm = FALSE)
colnames(CPIAUCNS_daily) <- "CPIAUCNS" # Maintain original column name

#### 2.2. UNRATE (Monthly, Released First Friday of Next Month)

unrate_release_dates <- index(UNRATE) + months(1)
UNRATE_on_release_date <- xts(coredata(UNRATE), order.by = unrate_release_dates)

UNRATE_daily <- merge(daily_template, UNRATE_on_release_date)
UNRATE_daily <- na.locf(UNRATE_daily, na.rm = FALSE)
UNRATE_daily <- na.locf(UNRATE_daily, fromLast = TRUE, na.rm = FALSE)
colnames(UNRATE_daily) <- "UNRATE"

#### 2.3. GDP (Quarterly, Released First Month of Next Quarter)
gdp_release_dates <- index(GDP) + months(3) - days(1) # End of the quarter month
GDP_on_release_date <- xts(coredata(GDP), order.by = gdp_release_dates)

GDP_daily <- merge(daily_template, GDP_on_release_date)
GDP_daily <- na.locf(GDP_daily, na.rm = FALSE)
GDP_daily <- na.locf(GDP_daily, fromLast = TRUE, na.rm = FALSE)
colnames(GDP_daily) <- "GDP"

#### 2.4. FEDFUNDS, DGS10, DTWEXM (Daily or Business Daily)


FEDFUNDS_daily <- merge(daily_template, FEDFUNDS)
FEDFUNDS_daily <- na.locf(na.locf(FEDFUNDS_daily, fromLast = TRUE))
colnames(FEDFUNDS_daily) <- "FEDFUNDS"

DGS10_daily <- merge(daily_template, DGS10)
DGS10_daily <- na.locf(na.locf(DGS10_daily, fromLast = TRUE))
colnames(DGS10_daily) <- "DGS10"

DTWEXM_daily <- merge(daily_template, DTWEXM)
DTWEXM_daily <- na.locf(na.locf(DTWEXM_daily, fromLast = TRUE))
colnames(DTWEXM_daily) <- "DTWEXM"

# ---3. Consolidate Processed Macro Data into a single object ---

macro_data_combined_daily <- merge(
    CPIAUCNS_daily,
    FEDFUNDS_daily,
    DGS10_daily,
    UNRATE_daily,
    GDP_daily,
    DTWEXM_daily
)


# `macro_data_combined_daily` is now available globally
assign("macro_data_combined_daily", macro_data_combined_daily, envir = globalenv())


# Print confirmation and check for any remaining NAs
print("✅ Macroeconomic data processed and aligned to daily frequency, respecting release dates.")
print("Summary of NAs in `macro_data_combined_daily` (before final trim):")
print(sapply(macro_data_combined_daily, function(x) sum(is.na(x))))

# Remove the original high-frequency macro variables from the global environment
# to avoid confusion, keeping only the daily aligned ones if you prefer.
rm(CPIAUCNS, FEDFUNDS, DGS10, UNRATE, GDP, DTWEXM, envir = globalenv())