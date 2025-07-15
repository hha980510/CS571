# NVIDIA Stock Price Project

This project predicts NVIDIA (NVDA) stock prices. It uses a "walk-forward validation" method. This method helps predict future stock prices and if the price will go up or down for different time periods.

---

## Project Files

Here are the main files in this project:

* `Data_Clean/cleaned_nvda_data.rds`: This file has the **prepared and clean stock data**. It must be ready before running any models. Another script (not in this project) creates this file.
* `Modeling/`: This folder holds all R scripts for setting up, running, and checking models.
    * `00_model_setup.R`: This is the **main setup script**. It loads the cleaned data. It also creates the target (what we want to predict, like future prices or direction). It sets up the features (the data used for prediction) that all models will use.
    * `05_evaluation_metrics.R`: This file has **R functions to calculate results**. It includes ways to measure how well the model predicts (like RMSE, MAPE, accuracy) and how much money the strategy might make (like cumulative return, Sharpe Ratio, Max Drawdown). All model scripts will use these functions.
    * `01_linear_regression_model.R`: This script uses the **Linear Regression model**. It runs the walk-forward validation, trains the model, makes predictions, and shows how well it performed.
    * `02_xgboost_model.R` (Example): This would be the file for the next model, like XGBoost. It will be set up like `01_linear_regression_model.R`.
    * `03_neural_network_model.R` (Example): And so on for any other models.
* `Results/`: This folder saves the results. It has detailed predictions and a table that summarizes how well each model worked.

---

## How Files Work Together

The project has a clear way for files to work:

1.  **`Data_Clean/cleaned_nvda_data.rds`**: This is the basic data. It must be ready before any model starts.
2.  **`00_model_setup.R`**: This script prepares data for all models.
    * It loads `cleaned_nvda_data.rds`.
    * It makes "Target_Price" and "Target_Direction" for different time periods (like 1 week, 2 weeks, 1 month).
    * It finds the `feature_cols` (the input data) that **all** models will use.
    * **Every script for a model (like `01_linear_regression_model.R`, `02_xgboost_model.R`) MUST run `source("Modeling/00_model_setup.R")` at the beginning.** This makes sure all models use the same data, targets, and features.
3.  **`05_evaluation_metrics.R`**: This file has the math functions to check results.
    * It is just a set of functions, not a script to run by itself.
    * **Every model script also MUST run `source("Modeling/05_evaluation_metrics.R")`** to use its functions.
4.  **Each Model Script (e.g., `01_linear_regression_model.R`)**:
    * Each script sets a `model_name` (like "Linear_Regression").
    * It chooses the `current_horizon` (like "1W").
    * It loads any special libraries needed for that model (e.g., `xgboost` library for an XGBoost model).
    * It runs the **walk-forward validation loop**. This means it trains and tests the model many times on different parts of the data.
    * Inside the loop, it uses the `feature_cols` and `target_col` (which come from `00_model_setup.R`) to train its specific model (e.g., `lm()` for linear regression).
    * Then, it uses the functions from `05_evaluation_metrics.R` to get and show its performance numbers.
    * Finally, it saves the results in the `Results/` folder.

---

## How to Run the Models

Follow these steps to run the stock prediction models and get results.

### Step 1: Get Ready

1.  **Check for Clean Data:**
    * Make sure `Data_Clean/cleaned_nvda_data.rds` is in the project. This file is made by earlier data work.
2.  **Start RStudio or R:**
3.  **Set Project Folder:**
    * Tell R where the main project folder is. This helps R find all files.
    ```R
    # Example: Change this path to the project's main folder
    setwd("/Users/YourUsername/PathToCS571Project")
    ```

### Step 2: Run a Model (Example: Linear Regression)

To run a model for a certain time period, you will change and run its script.

#### Model: Linear Regression (`01_linear_regression_model.R`)

This script runs the linear regression model inside the walk-forward test.

1.  **Open `Modeling/01_linear_regression_model.R`** in a text editor (like RStudio).
2.  **Find `current_horizon`:**
    ```R
    current_horizon <- "1W" # Change this for "1W", "2W", or "1M" for each run
    ```
3.  **Change its value** to what is needed: `"1W"`, `"2W"`, or `"1M"`.
    * **For 1-Week:** `current_horizon <- "1W"`
    * **For 2-Weeks:** `current_horizon <- "2W"`
    * **For 1-Month:** `current_horizon <- "1M"`
4.  **Save the file** after changing.
5.  **In R, run the script:**
    ```R
    source("Modeling/01_linear_regression_model.R")
    ```
    * **What happens:** This command will first run `00_model_setup.R` and `05_evaluation_metrics.R` (because `01_linear_regression_model.R` asks for them). Then, it runs the linear regression model for the `current_horizon` chosen.
6.  **Run for other periods:** To run for a different time period (e.g., from "1W" to "2W"), do steps 1-5 again: **change `current_horizon` in the file, save, then `source()` again.**

---

### Step 3: Add and Run a New Model (Example: XGBoost)

To add a new model (like XGBoost, Random Forest, or Neural Network), create a new R script like the others.

1.  **Make a new script file:** For example, `Modeling/02_xgboost_model.R`.
2.  **At the start of the new script, add these lines:**
    ```R
    # Modeling/02_xgboost_model.R

    # --- Use setup and evaluation scripts (VERY IMPORTANT for ALL models) ---
    source("Modeling/00_model_setup.R")
    source("Modeling/05_evaluation_metrics.R")

    # --- Model settings ---
    model_name <- "XGBoost" # Name of this model
    current_horizon <- "1W" # Time period for this run

    # --- Add special libraries for this new model ---
    library(xgboost)
    # ... other libraries if XGBoost needs them ...

    # --- Set up target columns (uses variables from 00_model_setup.R) ---
    target_col <- paste0("Target_", current_horizon, "_Price")
    directional_target_col <- paste0("Target_", current_horizon, "_Direction")

    # --- Put new model's walk-forward loop here ---
    # This part will be like `01_linear_regression_model.R`,
    # but with the new model's own training and prediction steps.
    # Make sure to use `train_data`, `test_data`, `feature_cols`, and `target_col`
    # as set up by `00_model_setup.R`.

    # ... XGBoost model training and prediction steps here ...

    # --- Calculate results (using functions from 05_evaluation_metrics.R) ---
    # ... Use calculate_rmse, calculate_sharpe_ratio, etc. ...

    # --- Save results (like in 01_linear_regression_model.R) ---
    # ... Save results and predictions to Results/ ...
    ```
3.  **Write the new model's training and prediction steps** inside the walk-forward loop in this new script. Use the `train_data`, `test_data`, `feature_cols`, `target_col`, and `directional_target_col` variables, which are ready because `00_model_setup.R` was run.
4.  **Run the new model:** Like in Step 2, change `current_horizon` in the new model script, save it, and then `source()` it from R.
    ```R
    # After setting current_horizon in 02_xgboost_model.R
    source("Modeling/02_xgboost_model.R")
    ```

---

## Check Results

After each model runs, the performance numbers will print in R. All results are saved in the `Results/` folder:

* `model_performance_metrics.csv`: This CSV file is a **main log** for all model runs. Each time a model finishes, a new line with its name, time period, and all numbers is added. You can open this file in programs like Excel to compare models.
* `[ModelName]_predictions_[Horizon].rds`: For each model and time period, an `.rds` file is saved (e.g., `Linear_Regression_predictions_1W.rds`). These files have the full prediction data, including `Actual_Price`, `Predicted_Price`, and other details. You can load them back into R for more checks or charts:
    ```R
    # Load predictions for 1-month Linear Regression
    lr_1m_preds <- readRDS("Results/Linear_Regression_predictions_1M.rds")
    head(lr_1m_preds)
    ```

---

## Important Notes

* **Wrong Returns / Data Leakage:** If model returns are extremely high (like 1 with 30 zeroes after it) and drawdowns are very low, this usually means **"data leakage"**. This happens when the model accidentally uses future information it should not have known during prediction. This is a common and serious problem in stock prediction testing. It means checking carefully how features and targets are made, making sure they only use past data.
* **Walk-Forward Validation:** This project uses "walk-forward validation." This is a better way to test trading strategies. It trains the model again and again using more and more past data.
* **Needed Tools:** Make sure all R packages listed at the top of `00_model_setup.R` (common ones) and in each model script (for that model) are installed. Install any missing ones using `install.packages("package_name")`.
* **Restart R:** Always restart R (`q()` then `n`) when doing major runs or if something goes wrong. This helps clear old data and avoid problems.
* **Computer Power:** Running models, especially complex ones or with much data, needs good computer memory and speed.