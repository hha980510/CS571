library(quantmod)
library(TTR)
library(ggplot2)
library(tidyr)
library(dplyr)

getSymbols("NVDA", src = "yahoo")
nvda <- na.omit(NVDA)

df <- data.frame(
  Date = index(nvda),
  Close = as.numeric(Cl(nvda)),
  Volume = as.numeric(Vo(nvda)),
  RSI = as.numeric(RSI(Cl(nvda), n = 14)),
  MACD = as.numeric(MACD(Cl(nvda))$macd),
  Volatility = as.numeric(runSD(Cl(nvda), 20)),
  Return = as.numeric(dailyReturn(Cl(nvda), type = "log"))
)
df <- na.omit(df)

box_df <- df %>%
  select(RSI, MACD, Volatility, Return, Volume) %>%
  pivot_longer(cols = everything(), names_to = "Feature", values_to = "Value")

ggplot(box_df, aes(x = Feature, y = Value, fill = Feature)) +
  geom_boxplot(alpha = 0.7, outlier.color = "red", outlier.alpha = 0.5) +
  labs(title = "Boxplot of Technical Indicators", x = "", y = "Value") +
  theme_minimal() +
  theme(legend.position = "none")


log_df <- df %>%
  select(RSI, MACD, Volatility, Return, Volume) %>%
  mutate(across(everything(), log1p)) %>%
  pivot_longer(cols = everything(), names_to = "Feature", values_to = "Log_Value")

ggplot(log_df, aes(x = Feature, y = Log_Value, fill = Feature)) +
  geom_boxplot(alpha = 0.7, outlier.color = "red", outlier.alpha = 0.5) +
  labs(title = "Boxplot of Technical Indicators (Log Scaled)", y = "log(1 + x) Value") +
  theme_minimal() +
  theme(legend.position = "none")
