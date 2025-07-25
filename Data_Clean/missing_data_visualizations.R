# ============================================
# Script: missing_data_summary_table.R
# Purpose: Generate a styled summary table of missing values
# Output: PNG image of table saved in Figures folder
# ============================================

# Load libraries
library(quantmod)
library(tidyr)
library(dplyr)
library(gt)
library(webshot2)

# Load raw data
df_raw_xts <- readRDS("Data/nvda_data_raw.rds")

# Convert xts to data.frame
df_raw <- data.frame(Date = index(df_raw_xts), coredata(df_raw_xts))

# Summarize missing values
missing_summary <- df_raw %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Missing_Count") %>%
  mutate(
    Total_Observations = nrow(df_raw),
    Missing_Percentage = round((Missing_Count / Total_Observations) * 100, 2)
  )

# Create styled gt table
table_plot <- missing_summary %>%
  gt() %>%
  tab_header(
    title = "Missing Data Summary Table"
  ) %>%
  cols_label(
    Variable = "Variable",
    Missing_Count = "Missing Values",
    Total_Observations = "Total Observations",
    Missing_Percentage = "Missing (%)"
  ) %>%
  fmt_percent(
    columns = vars(Missing_Percentage),
    scale_values = FALSE,
    decimals = 2
  ) %>%
  data_color(
    columns = vars(Missing_Percentage),
    colors = scales::col_numeric(palette = "Reds", domain = c(0, 100))
  ) %>%
  tab_options(
    table.font.size = 12,
    heading.title.font.size = 16
  )

# Save table as PNG in Figures folder
gtsave(table_plot, "Figures/missing_data_summary_table.png", expand = 10)
