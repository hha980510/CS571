# ============================
# Script: data_pipeline.R
# Purpose: Run entire data pipeline end-to-end
# ============================

source("Data_Preparation/import_data.R")
source("Data_Preparation/handle_missing.R")
source("Data_Preparation/feature_engineering.R")
source("Data_Wrangling/clean_column_structure.R")
source("Data_Wrangling/data_quality_checks.R")
source("Data_Wrangling/add_targets.R")
