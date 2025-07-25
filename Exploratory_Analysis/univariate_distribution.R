# =====================================================
# Script: univariate_distribution.R
# Purpose: Generate summary statistics table for raw NVDA data
# Output: PNG table saved to Figures/raw_summary_table_pretty.png
# =====================================================

library(readr)
library(dplyr)
library(gridExtra)
library(ggplot2)
library(grid)

# Load raw data
nvda_raw <- readRDS("Data/nvda_data_raw.rds")

# Calculate mean and sd for selected columns
summary_df <- data.frame(
  Metric = c("Open_mean", "Open_sd", "Close_mean", "Close_sd", 
             "Volume_mean", "Volume_sd", "Adjusted_mean", "Adjusted_sd"),
  Value = c(
    mean(Op(nvda_raw)), sd(Op(nvda_raw)),
    mean(Cl(nvda_raw)), sd(Cl(nvda_raw)),
    mean(Vo(nvda_raw)), sd(Vo(nvda_raw)),
    mean(Ad(nvda_raw)), sd(Ad(nvda_raw))
  )
) %>%
  mutate(Value = round(Value, 2))  # Round values

# Create table grob (graphical object)
table_grob <- tableGrob(summary_df, rows = NULL)

# Add background color for alternate rows
table_grob$grobs[which(grepl("background", table_grob$layout$name))] <- 
  Map(function(grob, i) {
    rectGrob(gp = gpar(fill = ifelse(i %% 2 == 0, "#f0f0f0", "white"), col = NA))
  }, table_grob$grobs[which(grepl("background", table_grob$layout$name))], 
     seq_along(table_grob$grobs[which(grepl("background", table_grob$layout$name))]))

# Save as PNG
png("Figures/raw_data_summary_table.png", width = 700, height = 400)
grid.draw(table_grob)
dev.off()
