# =============================================
# Script: technical_indicator_boxplots.R
# Purpose: Boxplots of raw and log-scaled features
# Output: Saved plots in Figures/
# =============================================

library(quantmod)
library(TTR)
library(ggplot2)
library(dplyr)
library(tidyr)
library(xts)

# 📁 Ensure Figures folder exists
if (!dir.exists("Figures")) dir.create("Figures")

# ✅ Load data (must be an xts object)
nvda_data <- readRDS("Data/nvda_data_after_outlier_handling.rds")

# ✅ Compute technical indicators on xts object
rsi_vals <- RSI(nvda_xts$NVDA.Close, n = 14)
macd_vals <- MACD(nvda_xts$NVDA.Close)
vol_vals <- runSD(nvda_xts$NVDA.Close, n = 20)
ret_vals <- dailyReturn(nvda_xts$NVDA.Close, type = "log")

# ✅ Combine all indicators into a single xts object
indicators_xts <- merge(rsi_vals, macd_vals[, "macd"], vol_vals, ret_vals, nvda_xts$NVDA.Volume)
colnames(indicators_xts) <- c("RSI", "MACD", "Volatility", "Return", "Volume")

# ✅ Convert to data.frame for ggplot
df <- na.omit(data.frame(Date = index(indicators_xts), coredata(indicators_xts)))

# ✅ Raw boxplot
box_df <- df %>%
  pivot_longer(cols = -Date, names_to = "Feature", values_to = "Value")

raw_plot <- ggplot(box_df, aes(x = Feature, y = Value, fill = Feature)) +
  geom_boxplot(alpha = 0.7, outlier.color = "red", outlier.alpha = 0.5) +
  labs(title = "Boxplot of Technical Indicators", x = "", y = "Value") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("Figures/boxplot_raw_indicators.png", raw_plot, width = 8, height = 6)

# ✅ Log-scaled boxplot (handle negatives safely)
log_df <- df %>%
  mutate(across(-Date, ~ log1p(pmax(.x, -0.999)))) %>%
  pivot_longer(cols = -Date, names_to = "Feature", values_to = "Log_Value")

log_plot <- ggplot(log_df, aes(x = Feature, y = Log_Value, fill = Feature)) +
  geom_boxplot(alpha = 0.7, outlier.color = "red", outlier.alpha = 0.5) +
  labs(title = "Boxplot of Technical Indicators (Log Scaled)", y = "log(1 + x) Value") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("Figures/boxplot_log_indicators.png", log_plot, width = 8, height = 6)

message("✅ Boxplots saved to Figures/")