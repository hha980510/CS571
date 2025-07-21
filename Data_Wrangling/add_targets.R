# ============================
# Script: add_targets.R
# Purpose: Add price and direction targets for 1W, 2W, and 1M
# Output: nvda_data_with_targets.rds
# ============================

library(dplyr)

# Load data
nvda_data <- readRDS("Data_Clean/cleaned_nvda_data.rds")

if (!"NVDA.Close" %in% colnames(nvda_data)) {
  stop("❌ 'NVDA.Close' column not found.")
}

# Function to add target price and direction
generate_targets <- function(data, horizon_days, price_col = "NVDA.Close") {
  target_price_col <- paste0("Target_", horizon_days, "_Price")
  direction_col <- paste0("Target_", horizon_days, "_Direction")

  data[[target_price_col]] <- dplyr::lead(data[[price_col]], horizon_days)
  data[[direction_col]] <- ifelse(
    is.finite(data[[price_col]]) & is.finite(data[[target_price_col]]) & data[[price_col]] > 0,
    ifelse(data[[target_price_col]] > data[[price_col]] * 1.03, 1, 0),
    NA_real_
  )
  return(data)
}

# Add targets
nvda_data <- generate_targets(nvda_data, 5)
nvda_data <- generate_targets(nvda_data, 10)
nvda_data <- generate_targets(nvda_data, 21)

# Remove rows with NA in any price targets
target_cols <- grep("^Target_\\d+[WM]_Price$", names(nvda_data), value = TRUE)
nvda_data <- nvda_data %>% filter(if_all(all_of(target_cols), ~ !is.na(.)))

# Save output
saveRDS(nvda_data, file = "Data_Clean/nvda_data_with_targets.rds")
write.csv(nvda_data, "Data_Clean/nvda_data_with_targets.csv", row.names = FALSE)

message("✅ Targets added and saved.")