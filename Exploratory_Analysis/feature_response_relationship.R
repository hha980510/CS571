# =====================================================
# Author: Hyunsung Ha
# Script: feature_response_relationship.R
# Purpose:
#   Explore the predictive relationships between selected
#   technical indicators (RSI, MACD, Volatility, Lagged Return)
#   and next-day log returns of NVDA stock.
#
# Output:
#   • Figures/rsi_vs_next_return.png
#   • Figures/macd_vs_next_return.png
#   • Figures/volatility_vs_next_return.png
#   • Console: Correlation table between features and next-day return
#
# Libraries Used: quantmod, TTR, ggplot2, dplyr, GGally
# Data Source: nvda_data_fully_engineered.rds
# =====================================================

# Load Required Libraries
library(quantmod)
library(TTR)
library(ggplot2)
library(GGally)

# Ensure Figures folder exists
if (!dir.exists("Figures")) dir.create("Figures")

# Load engineered data
nvda_data <- readRDS("Data/nvda_data_fully_engineered.rds")

# Ensure required features exist
if (!"log_return" %in% colnames(nvda_data)) stop("❌ 'log_return' not found.")

# Prepare dataframe
df <- data.frame(
  Date       = index(nvda_data),
  RSI        = as.numeric(nvda_data$RSI14),
  MACD       = as.numeric(nvda_data$MACD),
  Volatility = as.numeric(nvda_data$volatility_20),
  LogReturn  = as.numeric(nvda_data$log_return)
)

df <- df %>%
  dplyr::mutate(
    Lag_Return  = dplyr::lag(LogReturn, 1),
    Next_Return = dplyr::lead(LogReturn, 1)
  ) %>%
  dplyr::select(-LogReturn) %>%
  na.omit()

# Plot: RSI vs Next Day Return
p1 <- ggplot(df, aes(x = RSI, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "loess", color = "black") +
  labs(title = "RSI vs Next Day Return", x = "RSI", y = "Next Log Return") +
  theme_minimal()
ggsave("Figures/rsi_vs_next_return.png", p1, width = 7, height = 5)

# Plot: MACD vs Next Day Return
p2 <- ggplot(df, aes(x = MACD, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  geom_smooth(method = "lm", se = FALSE, color = "black") +
  labs(title = "MACD vs Next Day Return", x = "MACD", y = "Next Log Return") +
  theme_minimal()
ggsave("Figures/macd_vs_next_return.png", p2, width = 7, height = 5)

# Plot: Volatility vs Next Day Return
p3 <- ggplot(df, aes(x = Volatility, y = Next_Return)) +
  geom_point(alpha = 0.6, color = "tomato") +
  geom_smooth(method = "loess", color = "black") +
  labs(title = "Volatility vs Next Day Return", x = "Volatility", y = "Next Log Return") +
  theme_minimal()
ggsave("Figures/volatility_vs_next_return.png", p3, width = 7, height = 5)

# Correlation Output
cat("\n--- Correlation with Next Day Return ---\n")
print(cor(df[, c("RSI", "MACD", "Volatility", "Lag_Return")], df$Next_Return))

# GGally Pairwise Plot
pair_plot <- GGally::ggpairs(df[, c("RSI", "MACD", "Volatility", "Lag_Return", "Next_Return")])

ggsave("Figures/indicator_pairwise_plot.png", plot = pair_plot, width = 9, height = 7)
