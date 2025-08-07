# ------------------------------------------------------------
# Author: Hyunsung Ha
# Description:
#   This script computes the correlation matrix and generates
#   a heatmap of engineered features for NVIDIA stock analysis.
#   Features include technical indicators (RSI, MACD), lagged values,
#   returns, and volatility.
#
# Libraries Used: quantmod, TTR, ggcorrplot, ggplot2
# Data Source: 'nvda_data_fully_engineered.rds' (output from data_pipeline.R)
# Output: 'Figures/correlation_heatmap_nvda.png'
# ------------------------------------------------------------


library(quantmod)
library(TTR)
if (!require("ggcorrplot")) install.packages("ggcorrplot", dependencies = TRUE)
library(ggcorrplot)
70
library(ggplot2)

# Load Full Data Pipeline
nvda_data <- readRDS("Data/nvda_data_fully_engineered.rds")

# Ensure nvda_data exists
if (!exists("nvda_data")) stop("❌ 'nvda_data' is missing. Please run data_pipeline.R first.")

# Select Features for Correlation Analysis
df <- na.omit(nvda_data[, c(
  "scaled_close", "RSI14", "MACD", "Signal",
  "volatility_20", "lag_close_1", "lag_return_1", "log_return", "scaled_rsi"
)])

# Compute Correlation Matrix
corr_matrix <- cor(df)

# Plot Correlation Heatmap
heatmap_plot <- ggcorrplot(corr_matrix,
           method = "square",
           type = "lower",
           lab = TRUE,
           lab_size = 3,
           colors = c("darkblue", "white", "darkred"),
           title = "Correlation Heatmap of Engineered NVDA Features",
           ggtheme = theme_minimal())
ggsave("correlation_heatmap_nvda.png", plot = heatmap_plot, width = 8, height = 6)

# Save to Figures/

ggsave("Figures/correlation_heatmap_nvda.png", plot = heatmap_plot, width = 8, height = 6)
