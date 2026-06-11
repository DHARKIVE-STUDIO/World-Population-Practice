# Global Population Trends & Forecasting
### Tools: Python | R | SQL
### Dataset: world_population.csv — 234 countries, 1970–2022

---

## Project Summary
Analyzed population data across 234 countries spanning 50+ years to identify
growth patterns, regional disparities, and forecast future population to 2040
using ARIMA time series modeling. Delivered findings via a 4-page Power BI dashboard.

---

## Files
| File | Purpose |
|------|---------|
| global_population_analysis.ipynb | Python: EDA, cleaning, ARIMA forecast, export |
| global_population_R.R | R: Regional analysis, growth stats, auto ARIMA |
| global_population_SQL.sql | 7 analytical SQL queries |

---

## Dataset Columns
Rank, CCA3, Country/Territory, Capital, Continent,
2022/2020/2015/2010/2000/1990/1980/1970 Population,
Area (km²), Density (per km²), Growth Rate, World Population Percentage

**Place `world_population.csv` in the same folder before running.**

---

## How to Run

### Python
```bash
pip install pandas numpy matplotlib seaborn statsmodels scikit-learn
# Open global_population_analysis.ipynb in Jupyter and run all cells
```

### R
```r
install.packages(c("tidyverse","forecast","scales","ggthemes"))
source("global_population_R.R")
```

### SQL
Load `population_long_format.csv` into PostgreSQL/MySQL/SQLite,
then run queries from `global_population_SQL.sql`

---

## Key Findings
1. World population reached ~8B by 2022, up from ~3.7B in 1970
2. Asia holds ~59% of world population; Africa is fastest growing
3. Africa is the only continent with an accelerating growth rate
4. 10+ countries showed population decline since 2000 (mostly Eastern Europe)
5. India surpassed China as most populous country around 2023
6. ARIMA forecast: India projected to reach ~1.6B by 2040, China declining to ~1.3B

---

## Model Performance (ARIMA)
- Countries modeled: India and China
- MAPE: under 2% on 2015–2022 test period
