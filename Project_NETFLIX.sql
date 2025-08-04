-- Netflix Data Analysis Project using SQL
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
	show_id	VARCHAR(8),
	type VARCHAR(10),
	title VARCHAR(150),	
	director VARCHAR(210),
	castS VARCHAR(1000),
	country	VARCHAR(150),
	date_added VARCHAR(50),	
	release_year INT,
	rating VARCHAR(10),
	duration VARCHAR(15),
	listed_in VARCHAR(100),
	description VARCHAR(300)
);
SELECT * FROM netflix;

SELECT 
	COUNT(*) as total_content
FROM netflix;

SELECT 
	DISTINCT TYPE
FROM netflix;

-- PROJECT TASKS:
-- 1. Count of Movies VS TV shows
SELECT 
	TYPE,
	COUNT(*) as total_content
FROM netflix
GROUP BY TYPE;

-- 2. Most common rating for movies and tv shows
WITH RatingCounts AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY type, rating
),
RankedRatings AS (
    SELECT 
        type,
        rating,
        rating_count,
        RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS rank
    FROM RatingCounts
)
SELECT 
    type,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rank = 1;
	
-- 3. List all the movies released in 2020
SELECT * FROM netflix
WHERE
	type = 'Movie'
	AND
	release_year = 2020;

-- 4. Find the top 5 countries with most content on Netflix
SELECT * FROM
(
	SELECT 
		UNNEST(STRING_TO_ARRAY(COUNTRY,',')) AS COUNTRY, -- transform elements within an array into individual rows in a table
		COUNT(*) AS TOTAL_CONTENT
	FROM NETFLIX
	GROUP BY 1
) AS T1
WHERE COUNTRY IS NOT NULL
ORDER BY TOTAL_CONTENT DESC
LIMIT 5;

-- 5. Find All Movies/TV Shows by Director 'Rajiv Chilaka'
SELECT * FROM (
	SELECT *, 
	UNNEST(STRING_TO_ARRAY(DIRECTOR,',')) AS DIRECTOR_NAME -- transform elements within an array into individual rows in a table
FROM NETFLIX
) AS T2
WHERE DIRECTOR_NAME = 'Rajiv Chilaka';

-- 6. List All TV Shows with More Than 5 Seasons
SELECT * FROM NETFLIX
WHERE TYPE = 'TV Show' AND SPLIT_PART(DURATION, ' ',1):: INT > 5;

-- 7. Find each year and the average numbers of content release in India on netflix
SELECT 
	RELEASE_YEAR,
	COUNT(SHOW_ID) AS TOTAL_RELEASE,
	ROUND(
		COUNT(SHOW_ID):: NUMERIC/
		(SELECT COUNT(	SHOW_ID) FROM NETFLIX WHERE COUNTRY = 'India'):: NUMERIC *100, 2
	) AS AVG_RELEASE
FROM NETFLIX
WHERE COUNTRY = 'India'
GROUP BY COUNTRY, 1
ORDER BY AVG_RELEASE DESC;

-- 8. List All Movies that are Documentaries
SELECT * FROM NETFLIX
WHERE LISTED_IN LIKE '%Documentaries';

-- 9. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 20 Years
SELECT * FROM NETFLIX
WHERE CASTS LIKE '%Salman Khan%' AND RELEASE_YEAR > EXTRACT(YEAR FROM CURRENT_DATE) - 20; 

-- 10. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
SELECT 
	CATEGORY,
	COUNT(*) AS CONTENT_CNT
FROM (
	SELECT 
		CASE 
			WHEN DESCRIPTION ILIKE '%kill%' OR DESCRIPTION ILIKE '%violence%' THEN 'BAD'
			ELSE 'GOOD'
		END AS CATEGORY
	FROM NETFLIX
) AS CATEGORIZED_CONTENT
GROUP BY 1;
	



