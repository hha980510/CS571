# ===========================================================
# Author: Hyunsung Ha
# Script: stationarity_tests.R
# Purpose:
#   Conduct stationarity analysis on NVDA log returns using
#   Augmented Dickey-Fuller (ADF) and KPSS tests, and visualize
#   the time series of log returns.
#
# Output:
#   • Stationarity test summary saved to: Figures/stationarity_tests.txt
#   • Time series plot of log returns saved to: Figures/log_return_plot.png
#
# Libraries Used: quantmod, tseries, urca, ggplot2
# Data Source: nvda_data_fully_engineered.rds
# ===========================================================


library(quantmod)
library(tseries)
library(urca)
library(ggplot2)

# Ensure output folder exists
if (!dir.exists("Figures")) dir.create("Figures")

# Load cleaned and enriched dataset
nvda_data <- readRDS("Data/nvda_data_fully_engineered.rds")

# Extract log returns
log_return <- nvda_data$log_return
log_return_ts <- na.omit(ts(log_return))

# Save ADF and KPSS Test Results
sink("Figures/stationarity_tests.txt")

cat("=== Stationarity Tests for Log Returns ===\n\n")

# ADF Test
cat("\n--- ADF Test Result ---\n")
adf_result <- adf.test(log_return_ts)
print(adf_result)

# KPSS Test
cat("\n--- KPSS Test Result ---\n")
kpss_result <- ur.kpss(log_return_ts)
print(summary(kpss_result))

sink()  # End capturing output

# Save Log Return Plot
log_return_df <- data.frame(
  Date = index(nvda_data),
  LogReturn = as.numeric(nvda_data$log_return)
)

# Remove NA values
log_return_df <- na.omit(log_return_df)

p <- ggplot(log_return_df, aes(x = Date, y = LogReturn)) +
  geom_line(color = "steelblue") +
  labs(title = "Log Returns of NVDA", x = "Date", y = "Log Return") +
  theme_minimal()

ggsave("Figures/log_return_plot.png", plot = p, width = 8, height = 4)


message("✅ Stationarity analysis complete: plot and test results saved.")
