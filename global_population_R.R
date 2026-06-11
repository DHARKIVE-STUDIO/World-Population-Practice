# ============================================================
# Global Population Analysis in R
# Dataset: world_population.csv (234 countries)
# Tools: tidyverse, forecast, ggthemes, scales
# ============================================================

install.packages(c("tidyverse","forecast","scales","ggthemes"))

library(tidyverse)
library(forecast)
library(scales)
library(ggthemes)

# ============================================================
# STEP 1: LOAD DATA
# ============================================================
df <- read.csv("world_population.csv", stringsAsFactors = FALSE, check.names = FALSE)

cat("Shape:", nrow(df), "rows x", ncol(df), "columns\n")
cat("Columns:", names(df), "\n")
str(df)
summary(df)

# ============================================================
# STEP 2: RESHAPE TO LONG FORMAT
# ============================================================
year_cols <- c("1970 Population","1980 Population","1990 Population",
               "2000 Population","2010 Population","2015 Population",
               "2020 Population","2022 Population")

df_long <- df %>%
  pivot_longer(cols = all_of(year_cols),
               names_to  = "Year_Label",
               values_to = "Population") %>%
  mutate(Year = as.integer(str_extract(Year_Label, "\\d{4}"))) %>%
  select(-Year_Label) %>%
  filter(!is.na(Population))

cat("\nLong format shape:", nrow(df_long), "x", ncol(df_long), "\n")
head(df_long)

# ============================================================
# STEP 3: POPULATION BY CONTINENT OVER TIME
# ============================================================
continent_trend <- df_long %>%
  group_by(Continent, Year) %>%
  summarise(Total_Pop = sum(Population, na.rm = TRUE), .groups = "drop")

ggplot(continent_trend, aes(x = Year, y = Total_Pop / 1e9, color = Continent)) +
  geom_line(size = 1.3) +
  geom_point(size = 2) +
  labs(title   = "Population Trends by Continent (1970–2022)",
       x       = "Year",
       y       = "Population (Billions)",
       color   = "Continent") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("continental_trends.png", width = 12, height = 6, dpi = 150)
cat("Saved: continental_trends.png\n")

# ============================================================
# STEP 4: GROWTH RATE DISTRIBUTION BY CONTINENT
# ============================================================
ggplot(df, aes(x = Continent, y = `Growth Rate`, fill = Continent)) +
  geom_boxplot(alpha = 0.7, outlier.colour = "red", outlier.size = 1.5) +
  geom_hline(yintercept = 1.0, linetype = "dashed", color = "black", alpha = 0.5) +
  labs(title    = "Population Growth Rate Distribution by Continent",
       subtitle = "Dashed line = Growth Rate 1.0 (roughly flat)",
       x        = "",
       y        = "Growth Rate") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set2")

ggsave("growth_rate_boxplot.png", width = 11, height = 6, dpi = 150)
cat("Saved: growth_rate_boxplot.png\n")

# ============================================================
# STEP 5: TOP 10 COUNTRIES — POPULATION SHARE
# ============================================================
top10 <- df %>%
  arrange(desc(`2022 Population`)) %>%
  slice(1:10) %>%
  mutate(Share_Pct = round(`World Population Percentage`, 2),
         `Country/Territory` = fct_reorder(`Country/Territory`, Share_Pct))

ggplot(top10, aes(x = `Country/Territory`, y = Share_Pct, fill = Share_Pct)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(title  = "Top 10 Countries: Share of World Population (2022)",
       x      = "",
       y      = "% of World Population",
       fill   = "Share %") +
  theme_minimal(base_size = 13)

ggsave("population_share.png", width = 10, height = 6, dpi = 150)
cat("Saved: population_share.png\n")

# ============================================================
# STEP 6: DECADE GROWTH RATE — TOP 10 COUNTRIES
# ============================================================
top10_names <- as.character(top10$`Country/Territory`)

growth_top10 <- df %>%
  filter(`Country/Territory` %in% top10_names) %>%
  mutate(
    G_1990_2000 = round((`2000 Population` - `1990 Population`) / `1990 Population` * 100, 2),
    G_2000_2010 = round((`2010 Population` - `2000 Population`) / `2000 Population` * 100, 2),
    G_2010_2022 = round((`2022 Population` - `2010 Population`) / `2010 Population` * 100, 2)
  ) %>%
  select(`Country/Territory`, G_1990_2000, G_2000_2010, G_2010_2022) %>%
  pivot_longer(-`Country/Territory`, names_to = "Decade", values_to = "Growth_Pct")

ggplot(growth_top10, aes(x = `Country/Territory`, y = Growth_Pct, fill = Decade)) +
  geom_col(position = "dodge") +
  labs(title  = "Decade Growth Rate (%) — Top 10 Countries",
       x      = "",
       y      = "Growth (%)",
       fill   = "Period") +
  scale_fill_brewer(palette = "Set2",
                    labels  = c("1990–2000","2000–2010","2010–2022")) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("decade_growth_top10.png", width = 13, height = 6, dpi = 150)
cat("Saved: decade_growth_top10.png\n")

# ============================================================
# STEP 7: AUTO ARIMA — INDIA vs CHINA FORECAST TO 2040
# ============================================================
install.packages("tseries")
library(tseries)
library(forecast)

forecast_country <- function(country_name) {
  sub <- df_long %>%
    filter(`Country/Territory` == country_name) %>%
    arrange(Year)
  
  ts_data <- ts(sub$Population, start = min(sub$Year), frequency = 1)
  
  # Auto ARIMA picks best parameters
  model <- auto.arima(ts_data, seasonal = FALSE, stepwise = FALSE)
  cat(sprintf("\n%s - Auto ARIMA model:\n", country_name))
  print(model)
  
  # Forecast to 2040 (18 years from 2022)
  fc <- forecast(model, h = 18)
  return(fc)
}

fc_india <- forecast_country("India")
fc_china <- forecast_country("China")

# Plot side by side
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))

plot(fc_india,
     main  = "India: Population Forecast to 2040",
     xlab  = "Year", ylab = "Population",
     col   = "tomato", fcol = "tomato",
     shadecols = c("mistyrose","lightyellow"))

plot(fc_china,
     main  = "China: Population Forecast to 2040",
     xlab  = "Year", ylab = "Population",
     col   = "steelblue", fcol = "steelblue",
     shadecols = c("lightblue","lightyellow"))

png("r_arima_forecast.png", width = 1400, height = 600, res = 150)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(fc_india, main = "India Forecast to 2040", xlab = "Year",
     col = "tomato", fcol = "tomato")
plot(fc_china, main = "China Forecast to 2040", xlab = "Year",
     col = "steelblue", fcol = "steelblue")
dev.off()
cat("Saved: r_arima_forecast.png\n")

# ============================================================
# STEP 8: STATISTICAL SUMMARY TABLE
# ============================================================
stats_summary <- df_long %>%
  filter(Year %in% c(1970, 1980, 1990, 2000, 2010, 2022)) %>%
  group_by(Year) %>%
  summarise(
    Countries         = n(),
    Total_Pop_B       = round(sum(Population) / 1e9, 2),
    Mean_Country_Pop_M   = round(mean(Population) / 1e6, 2),
    Median_Country_Pop_M = round(median(Population) / 1e6, 2),
    Largest_Country_B    = round(max(Population) / 1e9, 2),
    .groups = "drop"
  )

cat("\nDecadal Statistical Summary:\n")
print(stats_summary)
write.csv(stats_summary, "r_stats_summary.csv", row.names = FALSE)
cat("Saved: r_stats_summary.csv\n")

cat("\nR analysis complete.\n")

