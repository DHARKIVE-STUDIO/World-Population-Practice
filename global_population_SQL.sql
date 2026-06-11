-- ============================================================
-- Global Population Analysis - SQL Queries
-- Dataset: world_population.csv (234 countries)
-- Columns: Rank, CCA3, Country/Territory, Capital, Continent,
--          2022/2020/2015/2010/2000/1990/1980/1970 Population,
--          Area (km²), Density (per km²), Growth Rate,
--          World Population Percentage
-- ============================================================
-- Load population_long_format.csv (exported from Python notebook)
-- Table: population (country, cca3, continent, year, population,
--                    growth_rate, world_pct, area_km2, density)
-- ============================================================


-- SETUP: Create table (PostgreSQL syntax)
CREATE TABLE IF NOT EXISTS population (
    country       VARCHAR(100),
    cca3          VARCHAR(5),
    continent     VARCHAR(50),
    capital       VARCHAR(100),
    year          INT,
    pop_value     BIGINT,
    growth_rate   NUMERIC(8,4),
    world_pct     NUMERIC(6,2),
    area_km2      BIGINT,
    density       NUMERIC(10,4)
);
-- Load: \COPY population FROM 'population_long_format.csv' CSV HEADER;


-- ============================================================
-- QUERY 1: Top 10 most populous countries in 2022
-- ============================================================
SELECT
    country,
    continent,
    pop_value,
    world_pct,
    RANK() OVER (ORDER BY pop_value DESC) AS global_rank
FROM population
WHERE year = 2022
ORDER BY pop_value DESC
LIMIT 10;


-- ============================================================
-- QUERY 2: Total population by continent in 2022
-- ============================================================
SELECT
    continent,
    SUM(pop_value)                                    AS total_population,
    ROUND(SUM(pop_value) * 100.0 / SUM(SUM(pop_value)) OVER (), 2) AS pct_of_world
FROM population
WHERE year = 2022
GROUP BY continent
ORDER BY total_population DESC;


-- ============================================================
-- QUERY 3: Decade-over-decade growth rate per country
-- ============================================================
WITH snapshots AS (
    SELECT
        country,
        continent,
        MAX(CASE WHEN year = 1990 THEN pop_value END) AS pop_1990,
        MAX(CASE WHEN year = 2000 THEN pop_value END) AS pop_2000,
        MAX(CASE WHEN year = 2010 THEN pop_value END) AS pop_2010,
        MAX(CASE WHEN year = 2022 THEN pop_value END) AS pop_2022
    FROM population
    GROUP BY country, continent
)
SELECT
    country,
    continent,
    pop_1990,
    pop_2000,
    pop_2010,
    pop_2022,
    ROUND((pop_2000 - pop_1990) * 100.0 / NULLIF(pop_1990, 0), 2) AS growth_1990_2000_pct,
    ROUND((pop_2010 - pop_2000) * 100.0 / NULLIF(pop_2000, 0), 2) AS growth_2000_2010_pct,
    ROUND((pop_2022 - pop_2010) * 100.0 / NULLIF(pop_2010, 0), 2) AS growth_2010_2022_pct
FROM snapshots
WHERE pop_2022 IS NOT NULL
ORDER BY pop_2022 DESC
LIMIT 20;


-- ============================================================
-- QUERY 4: Countries that doubled their population since 1990
-- ============================================================
WITH base AS (
    SELECT
        country,
        continent,
        MAX(CASE WHEN year = 1990 THEN pop_value END) AS pop_1990,
        MAX(CASE WHEN year = 2022 THEN pop_value END) AS pop_2022
    FROM population
    GROUP BY country, continent
)
SELECT
    country,
    continent,
    pop_1990,
    pop_2022,
    ROUND(pop_2022 * 1.0 / NULLIF(pop_1990, 0), 2) AS growth_multiplier
FROM base
WHERE pop_1990  > 1000000
  AND pop_2022 >= pop_1990 * 2
ORDER BY growth_multiplier DESC;


-- ============================================================
-- QUERY 5: Countries where population DECLINED since 2000
-- ============================================================
WITH base AS (
    SELECT
        country,
        continent,
        MAX(CASE WHEN year = 2000 THEN pop_value END) AS pop_2000,
        MAX(CASE WHEN year = 2022 THEN pop_value END) AS pop_2022
    FROM population
    GROUP BY country, continent
)
SELECT
    country,
    continent,
    pop_2000,
    pop_2022,
    ROUND((pop_2022 - pop_2000) * 100.0 / NULLIF(pop_2000, 0), 2) AS change_pct
FROM base
WHERE pop_2022 < pop_2000
  AND pop_2000  > 500000
ORDER BY change_pct ASC;


-- ============================================================
-- QUERY 6: Rank countries by population within each continent (2022)
-- ============================================================
SELECT
    country,
    continent,
    pop_value,
    RANK()       OVER (PARTITION BY continent ORDER BY pop_value DESC) AS rank_in_continent,
    DENSE_RANK() OVER (ORDER BY pop_value DESC)                        AS global_dense_rank
FROM population
WHERE year = 2022
ORDER BY continent, rank_in_continent;


-- ============================================================
-- QUERY 7: Population growth index (base year 1970 = 100) per continent
-- ============================================================
WITH base AS (
    SELECT continent, SUM(pop_value) AS base_pop
    FROM population
    WHERE year = 1970
    GROUP BY continent
),
yearly AS (
    SELECT continent, year, SUM(pop_value) AS yearly_pop
    FROM population
    GROUP BY continent, year
)
SELECT
    y.continent,
    y.year,
    y.yearly_pop,
    ROUND(y.yearly_pop * 100.0 / b.base_pop, 2) AS pop_index_1970_base
FROM yearly y
JOIN base b ON y.continent = b.continent
ORDER BY y.continent, y.year;
