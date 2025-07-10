library(dplyr)
library(lubridate)

# Add year and month columns
df <- df %>%
  mutate(year = year(date), month = month(date))

# Step 1: Fill each month using the value from the first day of the month
fill_by_first_day <- function(df, col) {
  first_vals <- df %>%
    group_by(year, month) %>%
    arrange(date) %>%
    slice(1) %>%
    select(year, month, first_val = {{ col }})
  
  df %>%
    left_join(first_vals, by = c("year", "month")) %>%
    mutate({{ col }} := first_val) %>%
    select(-first_val)
}

df <- df %>% fill_by_first_day(cpiaucns)
df <- df %>% fill_by_first_day(unrate)
df <- df %>% fill_by_first_day(fedfunds)

set.seed(180) 
# Step 2: Fill any remaining NA using normal distribution by year
fill_na_by_normal <- function(df, col) {
  global_mean <- mean(df[[col]], na.rm = TRUE)
  global_sd <- sd(df[[col]], na.rm = TRUE)
  
  df %>%
    group_by(year) %>%
    mutate({{ col }} := ifelse(
      is.na({{ col }}),
      rnorm(n(), mean = ifelse(all(is.na({{ col }})), global_mean, mean({{ col }}, na.rm = TRUE)),
            sd   = ifelse(all(is.na({{ col }})) || is.na(sd({{ col }}, na.rm = TRUE)) || sd({{ col }}, na.rm = TRUE) == 0,
                          global_sd,
                          sd({{ col }}, na.rm = TRUE))
      ),
      {{ col }}
    )) %>%
    ungroup()
}

df <- df %>% fill_na_by_normal("cpiaucns")
df <- df %>% fill_na_by_normal("unrate")
df <- df %>% fill_na_by_normal("fedfunds")

# Final cleanup
df <- df %>% select(-year, -month)
df

write.csv(df, "full_cleaned_dataset.csv", row.names = FALSE)
