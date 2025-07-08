library(quantmod)
library(ggplot2)
library(dplyr)
library(tidyr)

getSymbols("NVDA", src = "yahoo")
nvda <- na.omit(NVDA)

df <- data.frame(
  Date = index(nvda),
  Close = as.numeric(Cl(nvda)),
  Volume = as.numeric(Vo(nvda)),
  RSI = as.numeric(RSI(Cl(nvda), n = 14)),
  MACD = as.numeric(MACD(Cl(nvda))$macd),
  Volatility = as.numeric(runSD(Cl(nvda), n = 20)),
  Return = as.numeric(dailyReturn(Cl(nvda), type = "log"))
)
df <- na.omit(df)

dist_df <- df %>% 
  select(RSI, MACD, Volatility, Return, Volume) %>%
  pivot_longer(cols = everything(), names_to = "Feature", values_to = "Value")

ggplot(dist_df, aes(x = Value)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "lightblue", color = "black", alpha = 0.6) +
  geom_density(color = "darkblue", size = 1) +
  facet_wrap(~ Feature, scales = "free", ncol = 2) +
  labs(title = "Univariate Distribution of Technical Indicators",
       x = "Value", y = "Density") +
  theme_minimal()
