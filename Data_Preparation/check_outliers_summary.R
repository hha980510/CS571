# ============================================
# Script: check_outliers_summary.R
# Purpose: Generate summary statistics for data AFTER outlier handling.
# Output: PNG table saved to Figures/post_outlier_summary_table.png.
# ============================================

library(readr)
library(dplyr)
library(gridExtra)
library(ggplot2)
library(grid)
library(quantmod)

# Load data AFTER outlier handling
# This script assumes 'nvda_data_after_outlier_handling.rds' is in the top-level 'Data/' folder.
df_post_outlier_xts <- readRDS("Data/nvda_data_after_outlier_handling.rds")

# Convert to data.frame
df_post_outlier <- data.frame(Date = index(df_post_outlier_xts), coredata(df_post_outlier_xts))

# Calculate mean, sd, min, and max for selected columns, focusing on Volume
summary_df_post <- data.frame(
  Metric = c("Open_mean", "Open_sd", "Close_mean", "Close_sd",
             "Volume_mean", "Volume_sd", "Adjusted_mean", "Adjusted_sd",
             "Volume_min_post", "Volume_max_post"), # Include min/max for Volume to see capping effect
  Value = c(
    mean(df_post_outlier$NVDA.Open, na.rm = TRUE), sd(df_post_outlier$NVDA.Open, na.rm = TRUE),
    mean(df_post_outlier$NVDA.Close, na.rm = TRUE), sd(df_post_outlier$NVDA.Close, na.rm = TRUE),
    mean(df_post_outlier$NVDA.Volume, na.rm = TRUE), sd(df_post_outlier$NVDA.Volume, na.rm = TRUE),
    mean(df_post_outlier$NVDA.Adjusted, na.rm = TRUE), sd(df_post_outlier$NVDA.Adjusted, na.rm = TRUE),
    min(df_post_outlier$NVDA.Volume, na.rm = TRUE), max(df_post_outlier$NVDA.Volume, na.rm = TRUE) # Min/Max after capping
  )
) %>%
  # Format values for readability
  mutate(Value = formatC(Value, format = "f", big.mark = ",", digits = 2))

# Create table grob
table_grob_post <- tableGrob(summary_df_post, rows = NULL,
                             theme = ttheme_default(
                               core = list(fg_params = list(fontsize = 10)),
                               colhead = list(fg_params = list(fontsize = 10)),
                               rowhead = list(fg_params = list(fontsize = 10))
                             ))

# Add background color for alternate rows
table_grob_post$grobs[which(grepl("background", table_grob_post$layout$name))] <-
  Map(function(grob, i) {
    rectGrob(gp = gpar(fill = ifelse(i %% 2 == 0, "#f0f0f0", "white"), col = NA))
  }, table_grob_post$grobs[which(grepl("background", table_grob_post$layout$name))],
     seq_along(table_grob_post$grobs[which(grepl("background", table_grob_post$layout$name))]))

# Save as PNG
png("Figures/post_outlier_summary_table.png", width = 800, height = 450, res = 150)
grid.draw(table_grob_post)
dev.off()

message("✅ Post-outlier summary table generated and saved to Figures/post_outlier_summary_table.png.")