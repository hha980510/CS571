library(quantmod)
library(tseries)
library(urca)
library(ggplot2)

getSymbols("NVDA", src = "yahoo")          
nvda <- na.omit(NVDA)                      

log_return <- dailyReturn(Cl(nvda), type = "log")  
log_return <- na.omit(log_return)                  

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
