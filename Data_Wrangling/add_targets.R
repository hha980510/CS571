# ============================
# Script: add_targets.R
# Purpose: Add supervised learning targets to cleaned NVDA data
# Input: Data_Clean/cleaned_nvda_data.rds
# Output: Data_Clean/nvda_data_with_targets.rds
# ============================

library(dplyr)

# --- Load cleaned data ---
nvda_data <- readRDS("Data_Clean/cleaned_nvda_data.rds")

# Confirm required columns exist
if (!"NVDA.Close" %in% colnames(nvda_data)) {
  stop("❌ 'NVDA.Close' column not found. Please ensure cleaned_nvda_data.rds is correct.")
}

# --- Define helper function to compute targets ---
generate_targets <- function(data, horizon_days, price_col = "NVDA.Close") {
  target_price_col <- paste0("Target_", horizon_days, "_Price")
  direction_col <- paste0("Target_", horizon_days, "_Direction")

  # Use lead() to shift price forward in time
  data[[target_price_col]] <- dplyr::lead(data[[price_col]], horizon_days)

  # Define threshold logic for direction (e.g., 3% gain)
  data[[direction_col]] <- ifelse(
    is.finite(data[[price_col]]) & is.finite(data[[target_price_col]]) & data[[price_col]] > 0,
    ifelse(data[[target_price_col]] > data[[price_col]] * 1.03, 1, 0),
    NA_real_
  )

  return(data)
}

# --- Add targets for 1W (5 days), 2W (10 days), 1M (21 trading days) ---
nvda_data <- generate_targets(nvda_data, 5)
nvda_data <- generate_targets(nvda_data, 10)
nvda_data <- generate_targets(nvda_data, 21)

# --- Drop rows with NA in any of the newly created targets ---
target_cols <- grep("^Target_\\d+[WM]_Price$", names(nvda_data), value = TRUE)
nvda_data <- nvda_data %>% filter(if_all(all_of(target_cols), ~ !is.na(.)))

# --- Save with targets ---
saveRDS(nvda_data, file = "Data_Clean/nvda_data_with_targets.rds")
write.csv(nvda_data, "Data_Clean/nvda_data_with_targets.csv", row.names = FALSE)

print("✅ Target columns added and saved to Data_Clean/nvda_data_with_targets.rds")
