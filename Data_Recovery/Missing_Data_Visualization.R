library(quantmod)
library(naniar)
library(VIM)
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

library(naniar)
gg_miss_var(df, show_pct = TRUE) +
  labs(title = "Missing Values per Variable") +
  theme_minimal()

library(VIM)
aggr(df, col = c("skyblue", "tomato"), numbers = TRUE, sortVars = TRUE,
     labels = names(df), cex.axis = 0.7, gap = 3,
     main = "Missing Data Pattern")

library(Amelia)

missmap(df, main = "Missing Value Map", col = c("black", "lightgray"), legend = TRUE)

sapply(df, function(x) sum(is.na(x))) 
sapply(df, function(x) mean(is.na(x))) 

