library(quantmod)
library(TTR)
library(ggplot2)

getSymbols("NVDA", src = "yahoo")
nvda <- na.omit(NVDA)

df <- data.frame(
  Date = index(nvda),
  Close = as.numeric(Cl(nvda)),                
  Volume = as.numeric(Vo(nvda)),            
  RSI = as.numeric(RSI(Cl(nvda), n = 14)),
  MACD = as.numeric(MACD(Cl(nvda))$macd),
  Volatility = as.numeric(runSD(Cl(nvda), 20)),
  Return = as.numeric(dailyReturn(Cl(nvda), type = "log")),
  Lag_1 = as.numeric(lag(Cl(nvda), k = 1))     
)
df <- na.omit(df)

colnames(df)

ggplot(df, aes(x = RSI, y = Close)) +
  geom_point(color = "steelblue", alpha = 0.6) +
  labs(title = "RSI vs Close Price", x = "RSI (14-day)", y = "Closing Price") +
  theme_minimal()

ggplot(df, aes(x = Volatility, y = Return)) +
  geom_point(color = "darkred", alpha = 0.6) +
  labs(title = "Volatility vs Log Return", x = "20-Day Rolling Volatility", y = "Log Return") +
  theme_minimal()

ggplot(df, aes(x = MACD, y = Lag_1)) +
  geom_point(color = "darkgreen", alpha = 0.6) +
  labs(title = "MACD vs Lagged Price", x = "MACD", y = "Lag-1 Close") +
  theme_minimal()

ggplot(df, aes(x = Volume, y = Close)) +
  geom_point(color = "purple", alpha = 0.6) +
  labs(title = "Volume vs Closing Price", x = "Volume", y = "Close") +
  theme_minimal()

