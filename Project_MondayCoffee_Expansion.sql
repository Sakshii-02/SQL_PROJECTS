-- Monday Coffee Expansion SQL Project

--CREATING TABLES
DROP TABLE IF EXISTS city;
CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

DROP TABLE IF EXISTS products;
CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

DROP TABLE IF EXISTS customers;
CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Q.1 Coffee Consumers Count: How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	CITY_NAME,
	ROUND(POPULATION*0.25/1000000, 2) AS COFFEE_CONSUMERS_IN_MILLIONS
FROM CITY
ORDER BY 1;

-- Q.2 Sales Count for Each Product: How many units of each coffee product have been sold?
SELECT
	P.PRODUCT_NAME,
	COUNT(S.SALE_ID) AS TOTAL_ORDERS
FROM PRODUCTS AS P
LEFT JOIN SALES AS S
ON P.PRODUCT_ID = S.PRODUCT_ID
GROUP BY 1
ORDER BY 2;

-- Q.3 Total Revenue from Coffee Sales: What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
	SUM(TOTAL) AS TOTAL_REVENUE
FROM SALES
WHERE EXTRACT(YEAR FROM SALE_DATE) = 2023
AND
EXTRACT(QUARTER FROM SALE_DATE) = 4;

-- Q.4 Average Sales Amount per City: What is the average sales amount per customer in each city?
SELECT
	CI.CITY_NAME,
	COUNT(DISTINCT C.CUSTOMER_ID) AS TOTAL_CUSTOMERS,
	SUM(S.TOTAL) AS TOTAL_REV,
	ROUND(
		SUM(S.TOTAL)::NUMERIC/
				COUNT(DISTINCT C.CUSTOMER_ID)::NUMERIC
	, 2) AS AVG_SALES_PER_CITY
FROM CITY AS CI
JOIN CUSTOMERS AS C
ON CI.CITY_ID = C.CITY_ID
JOIN SALES AS S
ON S.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY 1
ORDER BY 4 DESC;

-- Q.5 City Population and Coffee Consumers (25%): Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
WITH CITY_TABLE AS(
	SELECT
		CITY_NAME,
		ROUND((POPULATION*0.25)/1000000, 2) AS COFFEE_CONSUMERS
	FROM CITY
),
CUSTOMERS_TABLE AS(
	SELECT
		CI.CITY_NAME,
		COUNT(DISTINCT C.CUSTOMER_ID) AS UNIQUE_CUST
	FROM SALES AS S
	JOIN CUSTOMERS AS C
	ON C.CUSTOMER_ID = S.CUSTOMER_ID
	JOIN CITY AS CI
	ON CI.CITY_ID = C.CITY_ID
	GROUP BY 1
)
SELECT
	CUSTOMERS_TABLE.CITY_NAME,
	CITY_TABLE.COFFEE_CONSUMERS,
	CUSTOMERS_TABLE.UNIQUE_CUST
FROM CUSTOMERS_TABLE
JOIN CITY_TABLE
ON CITY_TABLE.CITY_NAME = CUSTOMERS_TABLE.CITY_NAME;

-- Q6 Top Selling Products by City: What are the top 3 selling products in each city based on sales volume?
SELECT * FROM 
(
	SELECT
		CI.CITY_NAME,
		P.PRODUCT_NAME,
		COUNT(S.SALE_ID) AS TOTAL_ORDERS,
		DENSE_RANK() OVER (PARTITION BY CI.CITY_NAME ORDER BY COUNT(SALE_ID) DESC) AS RANK
	FROM SALES AS S
	JOIN CUSTOMERS AS C
		ON C.CUSTOMER_ID = S.CUSTOMER_ID
	JOIN CITY AS CI
		ON C.CITY_ID = CI.CITY_ID
	JOIN PRODUCTS AS P
		ON P.PRODUCT_ID = S.PRODUCT_ID	
	GROUP BY 1,2
) AS T1
WHERE RANK<=3;

-- Q7. Average Sale vs Rent: Find each city and their average sale per customer and avg rent per customer
WITH CITY_TABLE
AS
(
	SELECT 
		CI.CITY_NAME,
		SUM(S.TOTAL) as TOTAL_REVENUE,
		COUNT(DISTINCT S.CUSTOMER_ID) as TOTAL_CX,
		ROUND(
				SUM(S.TOTAL)::numeric/
					COUNT(DISTINCT S.CUSTOMER_ID)::numeric
				,2) as AVG_SALE_PER_CX
		
	FROM SALES as S
	JOIN CUSTOMERS as C
	ON S.CUSTOMER_ID = C.CUSTOMER_ID
	JOIN CITY as CI
	ON CI.CITY_ID = C.CITY_ID
	GROUP BY 1
	ORDER BY 2 DESC
),
CITY_RENT
AS
(SELECT 
	CITY_NAME, 
	ESTIMATED_RENT
FROM CITY
)
SELECT 
	CR.CITY_NAME,
	CR.ESTIMATED_RENT,
	CT.TOTAL_CX,
	CT.AVG_SALE_PER_CX,
	ROUND(
		CR.ESTIMATED_RENT::numeric/
									CT.TOTAL_CX::numeric
		, 2) as AVG_RENT_PER_CX 
FROM CITY_RENT as CR
JOIN CITY_TABLE as CT
ON CR.CITY_NAME = CT.CITY_NAME
ORDER BY 4 DESC;

-- Q8. Monthly Sales Growth Rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city
WITH
MONTHLY_SALES
AS
(
	SELECT 
		CI.CITY_NAME,
		EXTRACT(MONTH FROM SALE_DATE) AS MONTH,
		EXTRACT(YEAR FROM SALE_DATE) AS YEAR,
		SUM(S.TOTAL) AS TOTAL_SALE
	FROM SALES AS S
	JOIN CUSTOMERS AS C
	ON C.CUSTOMER_ID = S.CUSTOMER_ID
	JOIN CITY AS CI
	ON CI.CITY_ID = C.CITY_ID
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),

GROWTH_RATIO
AS
(
		SELECT
			CITY_NAME,
			MONTH,
			YEAR,
			TOTAL_SALE AS CR_MONTH_SALE,
			LAG(TOTAL_SALE, 1) OVER(PARTITION BY CITY_NAME ORDER BY YEAR, MONTH) AS LAST_MONTH_SALE
		FROM MONTHLY_SALES
)

SELECT
	CITY_NAME,
	MONTH,
	YEAR,
	CR_MONTH_SALE,
	LAST_MONTH_SALE,
	ROUND(
		(CR_MONTH_SALE-LAST_MONTH_SALE)::numeric/LAST_MONTH_SALE::numeric * 100
		, 2
		) AS GROWTH_RATIO

FROM GROWTH_RATIO
WHERE 
	LAST_MONTH_SALE IS NOT NULL;	

-- Q9. Market Potential Analysis: Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH CITY_TABLE
AS
(
	SELECT 
		CI.CITY_NAME,
		SUM(S.TOTAL) AS TOTAL_REVENUE,
		COUNT(DISTINCT S.CUSTOMER_ID) AS TOTAL_CX,
		ROUND(
				SUM(S.TOTAL)::numeric/
					COUNT(DISTINCT S.CUSTOMER_ID)::numeric
				,2) AS AVG_SALE_PER_CX
		
	FROM SALES AS S
	JOIN CUSTOMERS AS C
	ON S.CUSTOMER_ID = C.CUSTOMER_ID
	JOIN CITY AS CI
	ON CI.CITY_ID = C.CITY_ID
	GROUP BY 1
	ORDER BY 2 DESC
),
CITY_RENT
AS
(
	SELECT 
		CITY_NAME, 
		ESTIMATED_RENT,
		ROUND((POPULATION * 0.25)/1000000, 3) as ESTIMATED_COFFEE_CONSUMERS_IN_MILLIONS
	FROM CITY
)
SELECT 
	CR.CITY_NAME,
	TOTAL_REVENUE,
	CR.ESTIMATED_RENT AS TOTAL_RENT,
	CT.TOTAL_CX,
	ESTIMATED_COFFEE_CONSUMERS_IN_MILLIONS,
	CT.AVG_SALE_PER_CX,
	ROUND(
		CR.ESTIMATED_RENT::numeric/
									CT.TOTAL_CX::numeric
		, 2) AS AVG_RENT_PER_CX
FROM CITY_RENT AS CR
JOIN CITY_TABLE AS CT
ON CR.CITY_NAME = CT.CITY_NAME
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.




