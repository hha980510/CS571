# ==========================
# Script: handle_outliers.R
# Purpose: Cap or remove extreme outliers
# ==========================

library(dplyr)

# Load cleaned (but unfiltered) data
df <- readRDS("Data/nvda_data_after_missing_handling.rds")

# Example: Cap volume at 99.5 percentile
vol_cap <- quantile(df$NVDA.Volume, 0.995, na.rm = TRUE)
df$NVDA.Volume <- pmin(df$NVDA.Volume, vol_cap)

# Optional: Do similar for returns or prices if needed
# ret_cap <- quantile(df$NVDA.Return, 0.995, na.rm = TRUE)
# df$NVDA.Return <- pmin(df$NVDA.Return, ret_cap)

# Save
saveRDS(df, "Data/nvda_data_after_outlier_handling.rds")
message("✅ Outliers capped and saved.")