# 📦 필요한 패키지
library(quantmod)
library(ggplot2)
if (!require(forecast)) install.packages("forecast")
library(forecast)

# ✅ Load cleaned and engineered data
nvda_data <- readRDS("Data/nvda_data_after_outlier_handling.rds")

# ✅ Extract and clean log returns
nvda_ret <- na.omit(diff(log(nvda_data$NVDA.Close)))

# ACF,B
acf_plot <- ggAcf(as.numeric(nvda_ret)) +
  ggtitle("ACF of NVIDIA Log Returns") +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(color = "navy", face = "bold", size = 18),
    axis.title.x = element_text(color = "gray20", size = 14),
    axis.title.y = element_text(color = "gray20", size = 14)
  ) +
  scale_y_continuous(limits = c(-0.1, 0.1)) +  # 확대해서 보기 좋게
  geom_hline(yintercept = 0, color = "steelblue", linetype = "dashed", linewidth = 0.8)


# PACF,R
pacf_plot <- ggPacf(as.numeric(nvda_ret)) +
  ggtitle("PACF of NVIDIA Log Returns") +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(color = "darkred", face = "bold", size = 18),
    axis.title.x = element_text(color = "gray20", size = 14),
    axis.title.y = element_text(color = "gray20", size = 14)
  ) +
  scale_y_continuous(limits = c(-0.1, 0.1)) +  # 좁은 범위로 확대
  geom_hline(yintercept = 0, color = "firebrick", linetype = "dashed", linewidth = 0.8)

#  Save both

ggsave("Figures/acf_nvda_log_returns.png", acf_plot, width = 7, height = 5)
ggsave("Figures/pacf_nvda_log_returns.png", pacf_plot, width = 7, height = 5)
