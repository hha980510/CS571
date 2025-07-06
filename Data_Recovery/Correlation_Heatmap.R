library(quantmod)
library(TTR)
library(ggplot2)
library(ggcorrplot)

# 1. Load stock data
getSymbols("NVDA", src = "yahoo")
nvda <- na.omit(NVDA)  # Remove NAs

# 2. Feature engineering
df <- data.frame(
  Close = Cl(nvda),
  Volume = Vo(nvda),
  SMA_5 = SMA(Cl(nvda), n = 5),
  SMA_10 = SMA(Cl(nvda), n = 10),
  RSI_14 = RSI(Cl(nvda), n = 14),
  MACD = MACD(Cl(nvda))$macd,
  Signal = MACD(Cl(nvda))$signal,
  Volatility = runSD(Cl(nvda), n = 20),
  Lag_1 = lag(Cl(nvda), k = 1)
)

df <- na.omit(df)  # 필수: NA 제거

# Correlation matrix
corr_matrix <- cor(df)

# Heatmap 시각화 (ggplot 기반)
ggcorrplot(corr_matrix,
           method = "square", 
           type = "lower", 
           lab = TRUE, 
           lab_size = 3, 
           colors = c("darkblue", "white", "darkred"),
           title = "Correlation Heatmap of NVDA Features",
           ggtheme = theme_minimal())
