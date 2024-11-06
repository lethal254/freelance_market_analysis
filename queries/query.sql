-- Create a staging table
CREATE TABLE staging_gigs(
    category VARCHAR(255),
    category_url TEXT,
    subcategory VARCHAR(255),
    subcategory_url TEXT,
    name TEXT,
    stars VARCHAR(255),
    price VARCHAR(255)
)

-- Copy data from the csv file
COPY staging_gigs (category, category_url, subcategory,subcategory_url, name, stars, price)
FROM 'C:\My Files\projects\freelance_challenge\data\fiverr.csv'
DELIMITER ','
CSV HEADER;

-- Clean and formart the data and save in a new table 
CREATE TABLE gigs AS (SELECT 
    category, subcategory,name,
    CASE
        WHEN price IS NOT NULL AND price NOT LIKE '%,%'
            THEN CAST(SPLIT_PART(price, '€', 2)AS DECIMAL)
        ELSE
            CAST(REPLACE(SPLIT_PART(price, '€', 2), ',', '') AS DECIMAL)
    END AS price_in_euros,

    CASE
    WHEN stars IS NULL OR stars LIKE '%null%' THEN NULL
    ELSE CAST(SPLIT_PART(stars, '(', 1) AS DECIMAL)
    END AS rating,

    CASE
        WHEN stars IS NULL OR NOT stars LIKE '%(%' THEN NULL  -- Check if stars is NULL or doesn't contain '('
        ELSE 
            -- Extract the number of reviews
            CASE 
                WHEN stars LIKE '%k%' THEN 
                    CAST(REGEXP_REPLACE(stars, '.*\((\d+).*', '\1') AS INTEGER) * 1000  -- Multiply by 1000 for 'k'
                ELSE 
                    CAST(REGEXP_REPLACE(stars, '.*\((\d+).*', '\1') AS INTEGER)  -- Regular case
            END
    END AS number_of_reviews
FROM staging_gigs);

-- Drop the staging table
DROP TABLE IF EXISTS staging_gigs;

-- Check the categories and subcategories count
SELECT COUNT(DISTINCT category) FROM gigs;
SELECT COUNT(DISTINCT subcategory) FROM gigs;

-- Understanding the price ditribution in the for each category
SELECT category, 
    ROUND(AVG(price_in_euros),2) AS avg_price,
    MIN(price_in_euros) AS min_price,
    MAX(price_in_euros) AS max_price
FROM gigs
GROUP BY category
ORDER BY avg_price DESC;

-- Understanding the price ditribution in the for each subcategory in the programming and tech category
SELECT subcategory, 
    ROUND(AVG(price_in_euros),2) AS avg_price,
    MIN(price_in_euros) AS min_price,
    MAX(price_in_euros) AS max_price
FROM gigs
WHERE category = 'Programming & Tech'
GROUP BY subcategory
ORDER BY avg_price DESC;

-- Finding Highly Rated programming Gigs to Understand Market Expectations

SELECT name, rating, subcategory
FROM gigs
WHERE rating IS NOT NULL AND category = 'Programming & Tech' AND number_of_reviews > 500
ORDER BY rating DESC
LIMIT 10;

-- Analyzing Gigs with a High Number of Reviews to Identify Popular Services

SELECT name, number_of_reviews, subcategory, price_in_euros, rating
FROM gigs
WHERE rating IS NOT NULL AND category = 'Programming & Tech'
ORDER BY number_of_reviews DESC
LIMIT 10;

-- Identifying Opportunities for High-Rating but Low-Priced Gigs
SELECT name, category, subcategory, number_of_reviews, price_in_euros
FROM gigs
WHERE number_of_reviews IS NOT NULL AND category = 'Programming & Tech' AND price_in_euros < 50
ORDER BY number_of_reviews DESC
LIMIT 10
;

-- Identifying Niche Markets with Low Reviews
SELECT name, subcategory,rating, number_of_reviews
FROM gigs
WHERE category = 'Programming & Tech' AND number_of_reviews < 10 AND rating IS NOT NULL
ORDER BY rating DESC;
