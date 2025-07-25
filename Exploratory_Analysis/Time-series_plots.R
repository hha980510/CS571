# ============================================================
# Script: time_series_indicators.R
# Purpose: Visualize NVDA technical indicators over time
# Output: Line plots saved to Figures/
# ============================================================

# 📦 Load Required Libraries
library(quantmod)
library(TTR)
library(ggplot2)
library(dplyr)

# 📂 Ensure output folder exists
if (!dir.exists("Figures")) dir.create("Figures")

# 📄 Load cleaned and enriched NVDA dataset
nvda_data <- readRDS("Data/nvda_data_fully_engineered.rds")

# 🧹 Prepare DataFrame for Visualization
macd_vals <- MACD(Cl(nvda_data))  # compute once

df <- data.frame(
  Date       = index(nvda_data),
  Close      = as.numeric(Cl(nvda_data)),
  Volume     = as.numeric(Vo(nvda_data)),
  SMA_10     = as.numeric(SMA(Cl(nvda_data), 10)),
  RSI_14     = as.numeric(RSI(Cl(nvda_data), 14)),
  MACD       = as.numeric(macd_vals$macd),
  Signal     = as.numeric(macd_vals$signal),
  Volatility = as.numeric(runSD(Cl(nvda_data), n = 20))
) %>% na.omit()

# 📈 Plot 1: Closing Price
p1 <- ggplot(df, aes(x = Date, y = Close)) +
  geom_line(color = "steelblue", linewidth = 1) +
  labs(title = "NVDA Closing Price Over Time", x = "Date", y = "Close Price") +
  theme_minimal()
ggsave("Figures/close_price.png", p1, width = 8, height = 4)

# 📈 Plot 2: RSI(14)
p2 <- ggplot(df, aes(x = Date, y = RSI_14)) +
  geom_line(color = "darkorange", linewidth = 1) +
  labs(title = "RSI(14) of NVDA", x = "Date", y = "RSI") +
  theme_minimal()
ggsave("Figures/rsi_14.png", p2, width = 8, height = 4)

# 📈 Plot 3: MACD & Signal Line
p3 <- ggplot(df, aes(x = Date)) +
  geom_line(aes(y = MACD, color = "MACD"), linewidth = 1) +
  geom_line(aes(y = Signal, color = "Signal"), linewidth = 1) +
  scale_color_manual(values = c("MACD" = "darkred", "Signal" = "darkgreen")) +
  labs(title = "MACD and Signal Line", x = "Date", y = "Value", color = "") +
  theme_minimal()
ggsave("Figures/macd_signal.png", p3, width = 8, height = 4)

# 📈 Plot 4: Rolling Volatility
p4 <- ggplot(df, aes(x = Date, y = Volatility)) +
  geom_line(color = "purple", linewidth = 1) +
  labs(title = "20-Day Rolling Volatility of NVDA", x = "Date", y = "Volatility") +
  theme_minimal()
ggsave("Figures/volatility.png", p4, width = 8, height = 4)

cat("✅ All indicator plots saved to Figures/\n")