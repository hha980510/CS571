# ============================
# Script: handle_missing.R
# Purpose: Handle missing values and align macroeconomic data frequencies
# Input: Data_Clean/nvda_data_raw.rds, Data_Clean/macro_data_raw.rds
# Output: Global daily-aligned macroeconomic variables (e.g., CPIAUCNS_daily)
# Save: nvda_data_after_missing_handling.rds, macro_data_combined_daily.rds
# ============================

library(xts)     
library(zoo)    
library(lubridate) 

# --- Load raw data ---
nvda_data <- readRDS("Data_Clean/nvda_data_raw.rds")
macro_data_raw <- readRDS("Data_Clean/macro_data_raw.rds")

# Confirm original macro data exists in combined object
if (!exists("macro_data_raw") || NCOL(macro_data_raw) < 6) {
  stop("❌ Raw macroeconomic data not found or incomplete. Please run import_data.R first.")
}

# Extract individual components from the combined raw macro data for processing
CPIAUCNS <- macro_data_raw$CPIAUCNS
FEDFUNDS <- macro_data_raw$FEDFUNDS
DGS10    <- macro_data_raw$DGS10
UNRATE   <- macro_data_raw$UNRATE
GDP      <- macro_data_raw$GDP
DTWEXM   <- macro_data_raw$DTWEXM

# --- 1. Define Universal Daily Time Index ---
start_date_nvda <- index(nvda_data)[!is.na(index(nvda_data))][1]
start_date_macro <- index(macro_data_raw)[!is.na(index(macro_data_raw))][1]

start_date_overall <- min(start_date_nvda, start_date_macro)
end_date_overall   <- max(index(nvda_data)[NROW(nvda_data)], index(macro_data_raw)[NROW(macro_data_raw)])

all_daily_dates <- seq(start_date_overall, end_date_overall, by = "day")
daily_template <- xts(order.by = all_daily_dates)

# --- 2. Process Each Macro Variable Individually for Daily Alignment ---

#### 2.1. CPIAUCNS (Monthly, Released Mid-Next Month)
cpi_release_dates <- index(CPIAUCNS) + months(1) + days(14)

# --- FIX: Filter out NA/NaN/Inf from cpi_release_dates ---
valid_indices_cpi <- !is.na(cpi_release_dates) & !is.infinite(cpi_release_dates) & !is.nan(cpi_release_dates)

# Apply filter to both coredata and the calculated dates
CPIAUCNS_filtered_coredata <- coredata(CPIAUCNS)[valid_indices_cpi]
cpi_release_dates_filtered <- cpi_release_dates[valid_indices_cpi]

# Now create xts object with guaranteed valid dates
CPIAUCNS_on_release_date <- xts(CPIAUCNS_filtered_coredata, order.by = cpi_release_dates_filtered)

# Merge with daily template, then forward-fill based on release.
CPIAUCNS_daily <- merge(daily_template, CPIAUCNS_on_release_date)
CPIAUCNS_daily <- na.locf(CPIAUCNS_daily, na.rm = FALSE)
CPIAUCNS_daily <- na.locf(CPIAUCNS_daily, fromLast = TRUE, na.rm = FALSE)
colnames(CPIAUCNS_daily) <- "CPIAUCNS"

#### 2.2. UNRATE (Monthly, Released First Friday of Next Month)
unrate_release_dates <- index(UNRATE) + months(1)

# --- FIX: Filter out NA/NaN/Inf from unrate_release_dates ---
valid_indices_unrate <- !is.na(unrate_release_dates) & !is.infinite(unrate_release_dates) & !is.nan(unrate_release_dates)

UNRATE_filtered_coredata <- coredata(UNRATE)[valid_indices_unrate]
unrate_release_dates_filtered <- unrate_release_dates[valid_indices_unrate]

UNRATE_on_release_date <- xts(UNRATE_filtered_coredata, order.by = unrate_release_dates_filtered)

UNRATE_daily <- merge(daily_template, UNRATE_on_release_date)
UNRATE_daily <- na.locf(UNRATE_daily, na.rm = FALSE)
UNRATE_daily <- na.locf(UNRATE_daily, fromLast = TRUE, na.rm = FALSE)
colnames(UNRATE_daily) <- "UNRATE"

#### 2.3. GDP (Quarterly, Released First Month of Next Quarter)
gdp_release_dates <- index(GDP) + months(3) - days(1)

# --- FIX: Filter out NA/NaN/Inf from gdp_release_dates ---
valid_indices_gdp <- !is.na(gdp_release_dates) & !is.infinite(gdp_release_dates) & !is.nan(gdp_release_dates)

GDP_filtered_coredata <- coredata(GDP)[valid_indices_gdp]
gdp_release_dates_filtered <- gdp_release_dates[valid_indices_gdp]

GDP_on_release_date <- xts(GDP_filtered_coredata, order.by = gdp_release_dates_filtered)

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

# Assign to global environment for subsequent sourcing (though saving is better)
assign("macro_data_combined_daily", macro_data_combined_daily, envir = globalenv())


# --- Prepare nvda_data for basic handling (merging with daily template) ---
# This merges NVDA daily data with the full daily calendar, filling non-trading days
nvda_data_daily_template <- merge(daily_template, nvda_data, join = "left")
# Forward-fill prices/volume for non-trading days (typical for stock data)
nvda_data_daily_template$NVDA.Open <- na.locf(nvda_data_daily_template$NVDA.Open, na.rm = FALSE)
nvda_data_daily_template$NVDA.High <- na.locf(nvda_data_daily_template$NVDA.High, na.rm = FALSE)
nvda_data_daily_template$NVDA.Low <- na.locf(nvda_data_daily_template$NVDA.Low, na.rm = FALSE)
nvda_data_daily_template$NVDA.Close <- na.locf(nvda_data_daily_template$NVDA.Close, na.rm = FALSE)
nvda_data_daily_template$NVDA.Volume <- na.locf(nvda_data_daily_template$NVDA.Volume, na.rm = FALSE)
nvda_data_daily_template$NVDA.Adjusted <- na.locf(nvda_data_daily_template$NVDA.Adjusted, na.rm = FALSE)
# Fill leading NAs for NVDA data if daily_template starts before its first date
nvda_data_daily_template <- na.locf(nvda_data_daily_template, fromLast = TRUE, na.rm = FALSE)

# Rename the NVDA data object to reflect this stage
nvda_data_after_missing_handling <- nvda_data_daily_template

# --- Save Data After Basic Handling ---
saveRDS(nvda_data_after_missing_handling, file = "Data_Clean/nvda_data_after_missing_handling.rds")
saveRDS(macro_data_combined_daily, file = "Data_Clean/macro_data_combined_daily.rds")

print("✅ Macroeconomic data processed and aligned to daily frequency, respecting release dates.")
print("✅ NVDA data aligned to daily frequency with basic NA handling.")