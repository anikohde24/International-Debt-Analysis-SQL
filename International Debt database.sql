CREATE DATABASE international_debt;

USE international_debt;

-- Short-term debt staging
CREATE TABLE short_term_debt (
    country_name VARCHAR(100),
    iso3 CHAR(3),
    year INT,
    debt_usd BIGINT
);

-- Long-term debt staging
CREATE TABLE long_term_debt (
    country_name VARCHAR(100),
    iso3 CHAR(3),
    year INT,
    debt_usd BIGINT
);

-- Total debt staging
CREATE TABLE total_external_debt (
    country_name VARCHAR(100),
    iso3 CHAR(3),
    year INT,
    debt_usd BIGINT
);

SELECT * FROM short_term_debt;

SELECT * FROM long_term_debt;

SELECT * FROM total_external_debt;


SELECT * FROM short_term_debt
WHERE debt_usd IS NULL OR iso3 IS NULL;

-- If missing values come then
-- UPDATE staging_short_term_debt
-- SET debt_usd = 0
-- WHERE debt_usd IS NULL;

UPDATE short_term_debt
SET country_name = UPPER(TRIM(country_name));

-- Clean short-term debt table
CREATE TABLE short_term_debt_clean AS
SELECT s.country_name, s.iso3, s.year, s.debt_usd,
       (s.debt_usd / t.debt_usd) * 100 AS pct_of_total
FROM short_term_debt s
JOIN total_external_debt t
  ON s.iso3 = t.iso3 AND s.year = t.year;

-- Clean long-term debt table
CREATE TABLE long_term_debt_clean AS
SELECT country_name, iso3, year, debt_usd
FROM long_term_debt;

-- Clean total debt table
CREATE TABLE total_external_debt_clean AS
SELECT country_name, iso3, year, debt_usd
FROM total_external_debt;

-- 1️ . View first few rows
SELECT * FROM short_term_debt_clean LIMIT 10;

-- 2️ . Count total rows per table
SELECT COUNT(*) AS total_rows FROM total_external_debt_clean;

-- 3 . List all distinct countries
SELECT DISTINCT country_name FROM total_external_debt_clean;

-- 4 . Find all records for 2023
SELECT * FROM total_external_debt_clean WHERE year = 2023;

-- 5 . Get countries with missing or zero debt
SELECT * FROM total_external_debt_clean WHERE debt_usd = 0 OR debt_usd IS NULL;


-- 6️ . Compare short vs long term debt for 2023
SELECT 
    s.country_name,
    s.debt_usd AS short_term,
    l.debt_usd AS long_term,
    t.debt_usd AS total
FROM short_term_debt_clean s
JOIN long_term_debt_clean l USING (iso3, year)
JOIN total_external_debt_clean t USING (iso3, year)
WHERE s.year = 2023;


-- 7 . ️Find top 5 countries by total debt in 2024
SELECT country_name, debt_usd
FROM total_external_debt_clean
WHERE year = 2024
ORDER BY debt_usd DESC
LIMIT 5;


-- 8 . ️Calculate total world debt for each year
SELECT year, SUM(debt_usd) AS global_debt
FROM total_external_debt_clean
GROUP BY year
ORDER BY year;


-- 9 . ️Find average short-term debt per country
SELECT country_name, AVG(debt_usd) AS avg_short_term
FROM short_term_debt_clean
GROUP BY country_name
ORDER BY avg_short_term DESC;

-- 10 . Countries where short-term > long-term debt
SELECT s.country_name, s.year, s.debt_usd AS short_term, l.debt_usd AS long_term
FROM short_term_debt_clean s
JOIN long_term_debt_clean l USING (iso3, year)
WHERE s.debt_usd > l.debt_usd;

-- 11️ . Find difference between total and (short+long)
SELECT 
    s.country_name, s.year,
    (t.debt_usd - (s.debt_usd + l.debt_usd)) AS diff
FROM total_external_debt_clean t
JOIN short_term_debt_clean s USING (iso3, year)
JOIN long_term_debt_clean l USING (iso3, year)
HAVING diff <> 0;

-- 12 . Total debt percentage share per country (2024)
SELECT 
    country_name,
    ROUND((debt_usd / (SELECT SUM(debt_usd) FROM total_external_debt_clean WHERE year=2024)) * 100, 2) AS pct_share
FROM total_external_debt_clean
WHERE year = 2024
ORDER BY pct_share DESC;

-- 13️ . Find countries with debt increasing from 2023 → 2024
SELECT 
    a.country_name,
    a.debt_usd AS debt_2023,
    b.debt_usd AS debt_2024,
    (b.debt_usd - a.debt_usd) AS growth
FROM total_external_debt_clean a
JOIN total_external_debt_clean b 
    ON a.iso3 = b.iso3 AND a.year = 2023 AND b.year = 2024
WHERE b.debt_usd > a.debt_usd;

-- 14️ . Top 3 countries by highest short-term % of total debt
SELECT country_name, ROUND(pct_of_total, 2) AS short_term_pct
FROM short_term_debt_clean
WHERE year = 2024
ORDER BY pct_of_total DESC
LIMIT 3;

-- 15️ . Create a view for quick comparison
CREATE VIEW debt_summary AS
SELECT 
    s.country_name,
    s.year,
    s.debt_usd AS short_term,
    l.debt_usd AS long_term,
    t.debt_usd AS total,
    ROUND((s.debt_usd / t.debt_usd) * 100, 2) AS short_pct,
    ROUND((l.debt_usd / t.debt_usd) * 100, 2) AS long_pct
FROM short_term_debt_clean s
JOIN long_term_debt_clean l USING (iso3, year)
JOIN total_external_debt_clean t USING (iso3, year);

SELECT * FROM debt_summary;

-- 16️ . Use the view to find high short-term dependency countries
SELECT * FROM debt_summary
WHERE short_pct > 60
ORDER BY short_pct DESC;

-- 17️ . Categorize countries based on total debt
SELECT 
    country_name,
    year,
    debt_usd,
    CASE
        WHEN debt_usd > 1000000000000 THEN 'Very High'
        WHEN debt_usd BETWEEN 500000000000 AND 1000000000000 THEN 'High'
        WHEN debt_usd BETWEEN 100000000000 AND 500000000000 THEN 'Moderate'
        ELSE 'Low'
    END AS debt_category
FROM total_external_debt_clean
ORDER BY debt_usd DESC;

-- 18️ . Subquery: Countries with debt > average global debt (2024)
SELECT country_name, debt_usd
FROM total_external_debt_clean
WHERE year = 2024
AND debt_usd > (SELECT AVG(debt_usd) FROM total_external_debt_clean WHERE year = 2024);

-- 19️ . Combine all debt tables into a unified dataset
SELECT 
    t.country_name,
    t.year,
    t.debt_usd AS total,
    s.debt_usd AS short_term,
    l.debt_usd AS long_term,
    ROUND((s.debt_usd / t.debt_usd) * 100, 2) AS short_pct,
    ROUND((l.debt_usd / t.debt_usd) * 100, 2) AS long_pct
FROM total_external_debt_clean t
JOIN short_term_debt_clean s USING (iso3, year)
JOIN long_term_debt_clean l USING (iso3, year);

-- 20️ . Delete duplicate records (if any)
DELETE FROM total_external_debt_clean
WHERE (country_name, iso3, year) IN (
    SELECT country_name, iso3, year
    FROM total_external_debt_clean
    GROUP BY country_name, iso3, year
    HAVING COUNT(*) > 1
);
