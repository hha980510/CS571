# 📦 Load Required Libraries
library(quantmod)
library(TTR)
library(ggplot2)
library(GGally)

# 🔁 Load full data pipeline
source("data_pipeline.R")

# ✅ Ensure required features exist
if (!"log_return" %in% colnames(nvda_data)) stop("❌ 'log_return' not found. Run data_pipeline.R first.")

# 🧹 Prepare dataframe
df <- na.omit(data.frame(
  Date        = index(nvda_data),
  RSI         = nvda_data$RSI14,
  MACD        = nvda_data$MACD,
  Volatility  = nvda_data$volatility_20,
  Lag_Return  = stats::lag(nvda_data$log_return, 1),
  Next_Return = stats::lag(nvda_data$log_return, -1)
))

# 📈 Plot: RSI vs Next Day Return
ggplot(df, aes(x = RSI, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "loess", color = "black") +
  labs(title = "RSI vs Next Day Return", x = "RSI", y = "Next Log Return") +
  theme_minimal()

# 📈 Plot: MACD vs Next Day Return
ggplot(df, aes(x = MACD, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  geom_smooth(method = "lm", se = FALSE, color = "black") +
  labs(title = "MACD vs Next Day Return", x = "MACD", y = "Next Log Return") +
  theme_minimal()

# 📈 Plot: Volatility vs Next Day Return
ggplot(df, aes(x = Volatility, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "tomato") +
  geom_smooth(method = "loess", color = "black") +
  labs(title = "Volatility vs Next Day Return", x = "Volatility", y = "Next Log Return") +
  theme_minimal()

# 📊 Correlation Output
cat("\n--- Correlation with Next Day Return ---\n")
print(cor(df[, c("RSI", "MACD", "Volatility", "Lag_Return")], df$Next_Return))

# 🔗 GGally Pairwise Plot
GGally::ggpairs(df[, c("RSI", "MACD", "Volatility", "Lag_Return", "Next_Return")])