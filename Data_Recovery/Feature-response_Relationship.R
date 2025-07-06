install.packages("quantmod")
install.packages("TTR")
install.packages("ggplot2")
install.packages("GGally")

library(quantmod)
library(TTR)
library(ggplot2)
library(GGally)

getSymbols("NVDA", src = "yahoo")
nvda <- na.omit(NVDA)

log_return <- dailyReturn(Cl(nvda), type = "log")

df <- data.frame(
  Date = index(nvda),
  Close = as.numeric(Cl(nvda)),
  Volume = as.numeric(Vo(nvda)),
  RSI = as.numeric(RSI(Cl(nvda), n = 14)),
  MACD = as.numeric(MACD(Cl(nvda))$macd),
  Volatility = as.numeric(runSD(Cl(nvda), 20)),
  Lag_Return = as.numeric(log_return),
  Next_Return = as.numeric(lag(log_return, k = -1))
)
df <- na.omit(df)

ggplot(df, aes(x = RSI, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "loess", color = "black") +
  labs(title = "RSI vs Next Day Return", x = "RSI", y = "Next Log Return") +
  theme_minimal()

ggplot(df, aes(x = MACD, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  geom_smooth(method = "lm", se = FALSE, color = "black") +
  labs(title = "MACD vs Next Day Return", x = "MACD", y = "Next Log Return") +
  theme_minimal()

ggplot(df, aes(x = Volatility, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "tomato") +
  geom_smooth(method = "loess", color = "black") +
  labs(title = "Volatility vs Next Day Return", x = "Volatility", y = "Next Log Return") +
  theme_minimal()

cat("\n--- Correlation with Next Day Return ---\n")
print(cor(df[, c("RSI", "MACD", "Volatility", "Lag_Return")], df$Next_Return))

GGally::ggpairs(df[, c("RSI", "MACD", "Volatility", "Lag_Return", "Next_Return")])
