library(quantmod)
library(tseries)
library(urca)
library(ggplot2)

# Load full cleaned and enriched dataset
source("data_pipeline.R")               

plot(log_return,
     main = "Log Returns of NVDA",
     col = "steelblue",
     ylab = "Log Return",
     xlab = "Date")

adf_result <- adf.test(log_return)

cat("\n--- ADF Test Result ---\n")
print(adf_result)

kpss_result <- ur.kpss(log_return)
cat("\n--- KPSS Test Result ---\n")
summary(kpss_result)
