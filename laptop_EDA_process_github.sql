-- =======================================================================
-- Database Setup
-- =======================================================================

USE data_cleaning;

-- =======================================================================
-- 1. Data Overview
-- =======================================================================

-- Display all records
SELECT * FROM laptop_backup;

-- Head: Display the first 5 records
SELECT * FROM laptop_backup
ORDER BY `sr` LIMIT 5;

-- Tail: Display the last 5 records
SELECT * FROM laptop_backup
ORDER BY `sr` DESC LIMIT 5;

-- Random Sample: Display 5 random records
SELECT * FROM laptop_backup
ORDER BY RAND() LIMIT 5;

-- =======================================================================
-- 2. Univariate Analysis
-- =======================================================================

-- Price Column: Summary statistics (min, max, median, avg, std, count, Q1, Q3)
WITH RankedPrices AS (
    SELECT 
        Price,
        ROW_NUMBER() OVER (ORDER BY Price) AS RowNum,
        COUNT(*) OVER() AS TotalCount
    FROM laptop_backup
)
SELECT 
    COUNT(Price) OVER() AS countprice,
    MIN(Price) OVER() AS minprice,
    MAX(Price) OVER() AS maxprice,
    STD(Price) OVER() AS stdprice,
    AVG(Price) OVER() AS avgprice,
    (SELECT Price 
     FROM RankedPrices 
     WHERE RowNum = FLOOR(TotalCount * 0.25)) AS Q1,
    (SELECT Price 
     FROM RankedPrices 
     WHERE RowNum = FLOOR(TotalCount * 0.5)) AS median,
    (SELECT Price 
     FROM RankedPrices 
     WHERE RowNum = FLOOR(TotalCount * 0.75)) AS Q3
FROM laptop_backup
LIMIT 1;

-- Check for missing values in the Price column
SELECT COUNT(Price) AS MissingValues
FROM laptop_backup
WHERE Price IS NULL;

-- Detect Outliers in Price
WITH RankedPrices AS (
    SELECT 
        Price,
        ROW_NUMBER() OVER (ORDER BY Price) AS RowNum,
        COUNT(*) OVER() AS TotalCount
    FROM laptop_backup
)
SELECT *
FROM (
    SELECT *,
           (SELECT Price FROM RankedPrices WHERE RowNum = FLOOR(TotalCount * 0.25)) AS Q1,
           (SELECT Price FROM RankedPrices WHERE RowNum = FLOOR(TotalCount * 0.75)) AS Q3
    FROM laptop_backup
) t
WHERE t.Price < t.Q1 - (1.5 * (t.Q3 - t.Q1)) OR
      t.Price > t.Q3 + (1.5 * (t.Q3 - t.Q1));

-- Horizontal and Vertical Histograms of Price
SELECT t.buckets, REPEAT('*', COUNT(*) / 5) AS histogram
FROM (
    SELECT Price,
           CASE 
               WHEN Price BETWEEN 0 AND 25000 THEN '0-25k'
               WHEN Price BETWEEN 25001 AND 50000 THEN '25-50K'
               WHEN Price BETWEEN 50001 AND 75000 THEN '50-75k'
               WHEN Price BETWEEN 75001 AND 100000 THEN '75-100k'
               ELSE '>100K'
           END AS buckets
    FROM laptop_backup
) t
GROUP BY t.buckets;

-- Handle Missing Values in the Company Column
SELECT COUNT(Company) AS MissingValues
FROM laptop_backup
WHERE Company IS NULL;

-- =======================================================================
-- 3. Bivariate Analysis
-- =======================================================================

-- Correlation Between cpu_speed and Price
SELECT cpu_speed, Price FROM laptop_backup;

-- Distribution of Touchscreen Laptops by Company
SELECT company,
       SUM(CASE WHEN touchscreen = 1 THEN 1 ELSE 0 END) AS touchscreen_yes,
       SUM(CASE WHEN touchscreen = 0 THEN 1 ELSE 0 END) AS touchscreen_no
FROM laptop_backup
GROUP BY company;

-- Distribution of cpu_brand Across Companies
SELECT company,
       SUM(CASE WHEN cpu_brand = 'Intel' THEN 1 ELSE 0 END) AS Intel,
       SUM(CASE WHEN cpu_brand = 'AMD' THEN 1 ELSE 0 END) AS AMD,
       SUM(CASE WHEN cpu_brand = 'Samsung' THEN 1 ELSE 0 END) AS Samsung
FROM laptop_backup
GROUP BY company;

-- Price Distribution by Company
SELECT company,
       MIN(price) AS min_price,
       MAX(price) AS max_price,
       STD(price) AS std_price,
       AVG(price) AS avg_price
FROM laptop_backup
GROUP BY company;

-- =======================================================================
-- 4. Missing Value Handling
-- =======================================================================

-- Create Missing Values in the Price Column
UPDATE laptop_backup
SET price = NULL
WHERE `sr` IN (200, 11, 145, 777, 714, 786, 404, 421);

-- Replace Missing Values in Price with Mean
SET sql_safe_updates = 0;

CREATE TEMPORARY TABLE temp_avg_price AS
SELECT AVG(price) AS avg_price
FROM laptop_backup;

UPDATE laptop_backup
SET price = (SELECT avg_price FROM temp_avg_price)
WHERE price IS NULL;

-- =======================================================================
-- 5. Feature Engineering
-- =======================================================================

-- Add and Populate ppi Column
ALTER TABLE laptop_backup ADD COLUMN ppi INTEGER;

UPDATE laptop_backup
SET ppi = ROUND(SQRT(resolution_width * resolution_width + resolution_height * resolution_height) / inches);

-- Add and Populate screen_size Column
ALTER TABLE laptop_backup ADD COLUMN screen_size VARCHAR(255) AFTER inches;

UPDATE laptop_backup
SET screen_size =
    CASE
        WHEN inches < 14.0 THEN 'small'
        WHEN inches >= 14.0 AND inches < 17 THEN 'medium'
        ELSE 'large'
    END;

-- One-Hot Encoding for gpu_brand
SELECT gpu_brand,
       CASE WHEN gpu_brand = 'Intel' THEN 1 ELSE 0 END AS intel,
       CASE WHEN gpu_brand = 'AMD' THEN 1 ELSE 0 END AS amd,
       CASE WHEN gpu_brand = 'Nvidia' THEN 1 ELSE 0 END AS nvidia,
       CASE WHEN gpu_brand = 'arm' THEN 1 ELSE 0 END AS arm
FROM laptop_backup;
