# =====================================================
# Script: scatter_plot.R
# Purpose: Visualize relationships between key indicators and price
# Output: Scatter plots saved in Figures/
# =====================================================

# 📦 Load Required Libraries
library(quantmod)
library(TTR)
library(ggplot2)

# 📂 Ensure Figures directory exists
if (!dir.exists("Figures")) dir.create("Figures")

# 📄 Load engineered data (no need for getSymbols or source)
nvda_data <- readRDS("Data/nvda_data_fully_engineered.rds")

# ✅ Convert xts → data.frame and compute required features
df <- data.frame(
  Date       = index(nvda_data),
  Close      = as.numeric(nvda_data$NVDA.Close),
  Volume     = as.numeric(nvda_data$NVDA.Volume),
  RSI        = as.numeric(nvda_data$RSI14),
  MACD       = as.numeric(nvda_data$MACD),
  Volatility = as.numeric(nvda_data$volatility_20),
  Return     = as.numeric(nvda_data$log_return),
  Lag_1      = dplyr::lag(as.numeric(nvda_data$NVDA.Close), 1)
) |> na.omit()

# 🎯 Plot 1: RSI vs Close Price
p1 <- ggplot(df, aes(x = RSI, y = Close)) +
  geom_point(color = "steelblue", alpha = 0.6) +
  labs(title = "RSI vs Close Price", x = "RSI (14-day)", y = "Closing Price") +
  theme_minimal()
ggsave("Figures/scatter_rsi_vs_close.png", p1, width = 7, height = 5)

# 🎯 Plot 2: Volatility vs Log Return
p2 <- ggplot(df, aes(x = Volatility, y = Return)) +
  geom_point(color = "darkred", alpha = 0.6) +
  labs(title = "Volatility vs Log Return", x = "20-Day Rolling Volatility", y = "Log Return") +
  theme_minimal()
ggsave("Figures/scatter_volatility_vs_return.png", p2, width = 7, height = 5)

# 🎯 Plot 3: MACD vs Lagged Price
p3 <- ggplot(df, aes(x = MACD, y = Lag_1)) +
  geom_point(color = "darkgreen", alpha = 0.6) +
  labs(title = "MACD vs Lagged Price", x = "MACD", y = "Lag-1 Close") +
  theme_minimal()
ggsave("Figures/scatter_macd_vs_lag1.png", p3, width = 7, height = 5)

# 🎯 Plot 4: Volume vs Closing Price
p4 <- ggplot(df, aes(x = Volume, y = Close)) +
  geom_point(color = "purple", alpha = 0.6) +
  labs(title = "Volume vs Closing Price", x = "Volume", y = "Close") +
  theme_minimal()
ggsave("Figures/scatter_volume_vs_close.png", p4, width = 7, height = 5)

message("✅ Scatter plots saved to Figures/")