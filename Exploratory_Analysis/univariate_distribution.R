# ============================================
# Author: Hyunsung Ha
# Script: univariate_distribution.R
# Purpose:
#   Generate a summary statistics table for raw NVDA stock data,
#   including mean and standard deviation of Open, Close, Volume,
#   and Adjusted prices. The output is saved as a styled PNG table.
#
# Output:
#   • Figures/raw_data_summary_table.png — Table of summary statistics
#
# Libraries Used: readr, dplyr, gridExtra, ggplot2, grid, quantmod
# Data Source: nvda_data_raw.rds (raw price data in xts format)
# ============================================


library(readr)
library(dplyr)
library(gridExtra)
library(ggplot2)
library(grid)
library(quantmod)

# Load raw data
nvda_raw_xts <- readRDS("Data/nvda_data_raw.rds")

# Convert to data.frame
nvda_raw <- data.frame(Date = index(nvda_raw_xts), coredata(nvda_raw_xts))

# Calculate mean and sd for selected columns
summary_df_raw <- data.frame(
  Metric = c("Open_mean", "Open_sd", "Close_mean", "Close_sd",
             "Volume_mean", "Volume_sd", "Adjusted_mean", "Adjusted_sd"),
  Value = c(
    mean(nvda_raw$NVDA.Open, na.rm = TRUE), sd(nvda_raw$NVDA.Open, na.rm = TRUE),
    mean(nvda_raw$NVDA.Close, na.rm = TRUE), sd(nvda_raw$NVDA.Close, na.rm = TRUE),
    mean(nvda_raw$NVDA.Volume, na.rm = TRUE), sd(nvda_raw$NVDA.Volume, na.rm = TRUE),
    mean(nvda_raw$NVDA.Adjusted, na.rm = TRUE), sd(nvda_raw$NVDA.Adjusted, na.rm = TRUE)
  )
) %>%
  # Format values for readability
  mutate(Value = formatC(Value, format = "f", big.mark = ",", digits = 2))

# Create table grob
table_grob_raw <- tableGrob(summary_df_raw, rows = NULL,
                             theme = ttheme_default(
                               core = list(fg_params = list(fontsize = 10)),
                               colhead = list(fg_params = list(fontsize = 10)),
                               rowhead = list(fg_params = list(fontsize = 10))
                             ))

# Add background color for alternate rows
table_grob_raw$grobs[which(grepl("background", table_grob_raw$layout$name))] <-
  Map(function(grob, i) {
    rectGrob(gp = gpar(fill = ifelse(i %% 2 == 0, "#f0f0f0", "white"), col = NA))
  }, table_grob_raw$grobs[which(grepl("background", table_grob_raw$layout$name))],
     seq_along(table_grob_raw$grobs[which(grepl("background", table_grob_raw$layout$name))]))

# Save as PNG
png("Figures/raw_data_summary_table.png", width = 800, height = 400, res = 150)
grid.draw(table_grob_raw)
dev.off()


message("✅ Raw data summary table generated and saved to Figures/raw_data_summary_table.png.")
