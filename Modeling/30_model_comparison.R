# ============================================
# Script: 30_model_comparison.R
# Purpose: Compare models and select the best based on metrics
# ============================================

library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)
library(forcats)

results_folder <- "Results"
metrics_path <- file.path(results_folder, "all_model_metrics.csv")
plot_output_folder <- file.path(results_folder, "Comparison_Plots")

if (!dir.exists(plot_output_folder)) {
  dir.create(plot_output_folder, recursive = TRUE)
}

if (!file.exists(metrics_path)) {
  stop("Error: 'all_model_metrics.csv' not found.")
}
metrics_df <- read_csv(metrics_path, show_col_types = FALSE)

metrics_df <- metrics_df %>%
  mutate(
    RMSE = as.numeric(RMSE),
    MAE = as.numeric(MAE),
    MAPE = as.numeric(MAPE),
    R2 = as.numeric(R2),
    Accuracy = as.numeric(Accuracy),
    Cumulative_Return = as.numeric(Cumulative_Return),
    Sharpe_Ratio = as.numeric(Sharpe_Ratio),
    Max_Drawdown = as.numeric(Max_Drawdown),
    Directional_Accuracy = as.numeric(Directional_Accuracy)
  )

filtered_df <- metrics_df %>%
  filter(!is.na(RMSE) | !is.na(Accuracy)) %>%
  group_by(Model, Target) %>%
  filter(Timestamp == max(Timestamp)) %>%
  ungroup() %>%
  mutate(
    Model = fct_inorder(Model),
    Target = fct_inorder(Target)
  )

regression_df <- filtered_df %>%
  filter(!is.na(RMSE) & is.na(Accuracy))

classification_df <- filtered_df %>%
  filter(!is.na(Accuracy) & is.na(RMSE))

regression_sorted <- regression_df %>%
  arrange(Target, RMSE, desc(R2))

classification_sorted <- classification_df %>%
  arrange(Target, desc(Sharpe_Ratio), desc(Cumulative_Return), desc(Accuracy))

cat("🏆 Top Regression Models by Target:
")
print(regression_sorted %>% group_by(Target) %>% slice(1) %>% select(Model, Target, RMSE, R2, Cumulative_Return, Sharpe_Ratio, Max_Drawdown))

cat("
🏆 Top Classification Models by Target:
")
print(classification_sorted %>% group_by(Target) %>% slice(1) %>% select(Model, Target, Accuracy, Directional_Accuracy, Cumulative_Return, Sharpe_Ratio, Max_Drawdown))

write_csv(regression_sorted, file.path(results_folder, "sorted_regression_models.csv"))
write_csv(classification_sorted, file.path(results_folder, "sorted_classification_models.csv"))

df_financial_metrics <- filtered_df %>%
  select(Model, Target, Cumulative_Return, Sharpe_Ratio, Max_Drawdown) %>%
  filter(!is.na(Cumulative_Return) | !is.na(Sharpe_Ratio) | !is.na(Max_Drawdown)) %>%
  gather(key = "Metric", value = "Value", -Model, -Target) %>%
  mutate(Metric = factor(Metric, levels = c("Cumulative_Return", "Sharpe_Ratio", "Max_Drawdown")))

p_financial_combined <- ggplot(df_financial_metrics, aes(x = Model, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_grid(Metric ~ Target, scales = "free_y") +
  labs(title = "Financial Performance Comparison Across Models and Targets", y = "Value", x = "Model") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "none", plot.title = element_text(hjust = 0.5, face = "bold"), strip.text.y = element_text(angle = 0))

ggsave(file.path(plot_output_folder, "Financial_Performance_Combined.png"), p_financial_combined, width = 14, height = 10, dpi = 300)

df_clf_financial <- classification_df %>%
  select(Model, Target, Cumulative_Return, Sharpe_Ratio, Max_Drawdown) %>%
  gather(key = "Metric", value = "Value", -Model, -Target) %>%
  mutate(Metric = factor(Metric, levels = c("Cumulative_Return", "Sharpe_Ratio", "Max_Drawdown")))

p_clf_financial <- ggplot(df_clf_financial, aes(x = Model, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_grid(Metric ~ Target, scales = "free_y") +
  labs(title = "Financial Performance - Classification Models", y = "Value", x = "Model") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "none", plot.title = element_text(hjust = 0.5, face = "bold"), strip.text.y = element_text(angle = 0))

ggsave(file.path(plot_output_folder, "Financial_Performance_Classifiers.png"), p_clf_financial, width = 12, height = 8, dpi = 300)

df_reg_financial <- regression_df %>%
  select(Model, Target, Cumulative_Return, Sharpe_Ratio, Max_Drawdown) %>%
  gather(key = "Metric", value = "Value", -Model, -Target) %>%
  mutate(Metric = factor(Metric, levels = c("Cumulative_Return", "Sharpe_Ratio", "Max_Drawdown")))

p_reg_financial <- ggplot(df_reg_financial, aes(x = Model, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_grid(Metric ~ Target, scales = "free_y") +
  labs(title = "Financial Performance - Regression Models", y = "Value", x = "Model") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "none", plot.title = element_text(hjust = 0.5, face = "bold"), strip.text.y = element_text(angle = 0))

ggsave(file.path(plot_output_folder, "Financial_Performance_Regression.png"), p_reg_financial, width = 12, height = 8, dpi = 300)

cat("✅ Comparison script complete. Visualizations saved to 'Results/Comparison_Plots'.
")