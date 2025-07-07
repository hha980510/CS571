library(quantmod)
library(TTR)
library(ggplot2)
library(dplyr)

# Load full cleaned and enriched dataset
source("data_pipeline.R")

df <- data.frame(
  Date = index(nvda_data),
  Close = Cl(nvda_data),
  Volume = Vo(nvda_data),
  SMA_10 = SMA(Cl(nvda_data), 10),
  RSI_14 = RSI(Cl(nvda_data), 14),
  MACD = MACD(Cl(nvda_data))$macd,
  Signal = MACD(Cl(nvda_data))$signal,
  Volatility = runSD(Cl(nvda_data), n = 20)
)

df <- na.omit(df)


ggplot(df, aes(x = Date, y = Close)) +
  geom_line(color = "steelblue", linewidth = 1) +
  labs(title = "NVDA Closing Price Over Time", x = "Date", y = "Close") +
  theme_minimal()

#RSI
ggplot(df, aes(x = Date, y = RSI_14)) +
  geom_line(color = "darkorange", linewidth = 1) +
  labs(title = "RSI(14) of NVDA", x = "Date", y = "RSI") +
  theme_minimal()


ggplot(df, aes(x = Date)) +
  geom_line(aes(y = MACD, color = "MACD"), linewidth = 1) +
  geom_line(aes(y = Signal, color = "Signal"), linewidth = 1) +
  labs(title = "MACD and Signal Line", y = "Value", x = "Date") +
  scale_color_manual(values = c("MACD" = "darkred", "Signal" = "darkgreen")) +
  theme_minimal()

#Volatility
ggplot(df, aes(x = Date, y = Volatility)) +
  geom_line(color = "purple", linewidth = 1) +
  labs(title = "Rolling 20-Day Volatility", x = "Date", y = "Volatility") +
  theme_minimal()
