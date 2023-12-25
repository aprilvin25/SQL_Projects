-- Creating the database 
CREATE SCHEMA restaurant_orders;
USE restaurant_orders;

-- Creating menu_items table
CREATE TABLE menu_items (
menu_item_id BIGINT NOT NULL PRIMARY KEY,
item_name VARCHAR(30) NOT NULL,
category VARCHAR(30) NOT NULL,
price DECIMAL(4,2) NOT NULL
);
-- Creating order_details table
CREATE TABLE order_details (
order_details_id BIGINT NOT NULL PRIMARY KEY,
order_id BIGINT NOT NULL,
order_date DATE NOT NULL,
order_time TIME NOT NULL,
item_id BIGINT NOT NULL,
FOREIGN KEY (item_id) REFERENCES menu_items (menu_item_id)
);

-- Importing the two csv files by utilizing Table Data Import Wizard

-- Viewing the data for menu_items table
SELECT * FROM restaurant_orders.menu_items;

-- Viewing the data for order_details table
SELECT * FROM restaurant_orders.order_details;

-- --------------------------------------------------------------------------------------
-- --------------------------- FEATURE ENGINEERING --------------------------------------
-- ---------------------------------------------------------------------------------------

-- adding a month column 
SELECT MONTHNAME(order_date) AS month
FROM order_details;

ALTER TABLE order_details
ADD COLUMN month VARCHAR(20);

UPDATE order_details
SET month = MONTHNAME(order_date);

SELECT * FROM order_details;

-- adding day of the week column 
SELECT DAYNAME(order_date)
FROM order_details;

ALTER TABLE order_details
ADD COLUMN day_name VARCHAR(20);

UPDATE order_details
SET day_name = DAYNAME(order_date);

-- adding time of day column                                                                      
SELECT CASE 
	WHEN order_time BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
	WHEN order_time BETWEEN "12:00:01" AND "16:00:00" THEN "Afternoon"
		ELSE "Evening" END AS "time_of_day"
FROM order_details;

ALTER TABLE order_details
ADD COLUMN time_of_day VARCHAR(30);

UPDATE order_details
SET time_of_day = (SELECT CASE 
	WHEN order_time BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
	WHEN order_time BETWEEN "12:00:01" AND "16:00:00" THEN "Afternoon"
		ELSE "Evening" END AS "time_of_day");

-- --------------------------------------------------------------------------------------
-- ------------------------- EXPLORATORY DATA ANALYSIS (EDA) ----------------------------
-- ---------------------------------------------------------------------------------------

-- How many months we are looking at
SELECT DISTINCT month
FROM order_details;

-- Exploring descriptive statistics

-- Finding the average price for each category (type of cuisine)
SELECT ROUND(AVG(price),2) AS average_price, category
FROM menu_items
GROUP BY category
ORDER BY average_price DESC;



-- Finding the average amount of customers who come in for each day of the week, for the three months of data

/* Step 1) Find the total number of customers per month and day of the week; 
this will be the inner query of a subquery */
SELECT COUNT(DISTINCT order_id) AS total_customers, month, day_name
FROM order_details
GROUP BY month, day_name ORDER BY total_customers DESC;

/* Step 2) The average was rounded to the nearest whole integer, as you can't have a fraction of a person.
Here, about 294 customers come in on average every Monday and about 236 customers come in on Saturday, on average*/

SELECT ROUND(AVG(total_customers),0) AS average_total_customer, day_name
FROM (
	SELECT COUNT(DISTINCT order_id) AS total_customers, month, day_name
	FROM order_details
	GROUP BY month, day_name ORDER BY total_customers DESC
    ) AS total_customers_count -- This is the inner query
GROUP BY day_name;


-- ---------------------------------------------------------------------------------------
-- --------------------------- Customer QUESTIONS -----------------------------------------

/* How many order items (order_details_id) did each customer order (order_id)? 
What was the least amount of items ordered and the greatest amount? */
SELECT order_id AS customer, 
	COUNT(order_details_id) AS number_of_items_ordered
FROM order_details
GROUP BY order_id 
ORDER BY number_of_items_ordered DESC;

-- What time of day is the busiest, on average?
/* S1) making the inner query to find the total number of customers 
per time_of_day in each day of the week and month */
SELECT COUNT(DISTINCT order_id) AS number_of_customers, time_of_day, month, day_name
FROM order_details
GROUP BY time_of_day, month, day_name 
ORDER BY number_of_customers DESC;

/* S2) creating a subquery to find the average number of customers that order during each time
of the day */
SELECT ROUND(AVG(number_of_customers),0) AS avg_number_of_customers, time_of_day 
FROM (
	SELECT COUNT(DISTINCT order_id) AS number_of_customers, time_of_day, month, day_name
	FROM order_details
	GROUP BY time_of_day, month, day_name 
	ORDER BY number_of_customers DESC
    ) AS total_customers_per_time_of_day
GROUP BY time_of_day;


-- What is the total amount of customers that have come in each day of the week?
SELECT COUNT(order_id) AS number_of_customers, day_name
FROM order_details
GROUP BY day_name ORDER BY number_of_customers DESC;


-- ----------------------------------------------------------------------------------------
-- --------------------------- MENU ITEM QUESTIONS ----------------------------------------

-- How many unique food menu items does this restaurant have?
SELECT COUNT(DISTINCT menu_item_id) AS number_of_menu_items
FROM menu_items;

-- What categories (cuisine) does this restaurant have to offer?
SELECT DISTINCT category 
FROM menu_items;
-- ---------------------------------------------------------------------------------------
-- --------------------------- SALES QUESTIONS -------------------------------------------
 
 /* What were the least and most ordered items?
 What categories were they in? */
 SELECT COUNT(order_details.order_details_id) AS number_of_items_ordered, 
menu_items.menu_item_id, menu_items.item_name, menu_items.category
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY menu_item_id, item_name;
 
 /* What do the highest spend orders look like?
 Which items did they buy and how much did they spend? */ 
 /* S1) Firstly, I will find the total amount that each person ordered. */ 
SELECT order_details.order_id, SUM(menu_items.price) AS total_amount_each_person_spent
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY order_details.order_id
ORDER BY totaL_amount_each_person_spent DESC
LIMIT 3;

-- Next, to find what items each customer (order_id) they bought:
SELECT order_details.order_id,  
menu_items.item_name, menu_items.category
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
WHERE order_id IN (440, 2075,1957);

 
/* What are the total gross sales revenue for each category (cuisine) in total? 
How about for each month? Each day of the week? */

-- Gross sales for each cuisine:
SELECT menu_items.category AS cuisine_type, SUM(menu_items.price) AS gross_sales_revenue
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY category
ORDER BY gross_sales_revenue DESC;

-- For each month:
SELECT menu_items.category AS cuisine_type, 
SUM(menu_items.price) AS gross_sales_revenue, order_details.month
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY menu_items.category, order_details.month 
ORDER BY gross_sales_revenue DESC;

-- Each day of the week:
SELECT menu_items.category AS cuisine_type, 
SUM(menu_items.price) AS gross_sales_revenue, order_details.day_name
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY menu_items.category, order_details.day_name 
ORDER BY gross_sales_revenue DESC;
        
/* Which cuisines should we focus on developming more menu items for
based on the data? */

SELECT * FROM menu_items;
SELECT COUNT(item_name) AS number_of_items, category
FROM menu_items
GROUP BY category 
ORDER BY number_of_items DESC;


/* What were the number of sales made in each time of the day per weekday? */ 
SELECT COUNT(DISTINCT order_details.order_id) AS count_sales,
 order_details.time_of_day, order_details.day_name, order_details.month
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY order_details.month,
order_details.day_name, order_details.time_of_day
ORDER BY count_sales DESC;

/*  Next to the order_date, add a column showing "Good," "Bad," and "Average". Mark "Good" if it's 
greater than the cost of average sales per day and "Bad" if it's lower than the cost of average sales per day.*/
-- S1) Find the cost of sales per day:
SELECT order_date, order_details.day_name, SUM(menu_items.price) AS gross_sales
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY order_details.day_name, order_date;

-- S2) Now to find the AVERAGE cost of sales per day: ANS: $1769.09
SELECT ROUND(AVG(gross_sales),2) AS average_cost_of_sales_per_day
FROM (
	SELECT order_date, order_details.day_name, SUM(menu_items.price) AS gross_sales
	FROM order_details
		LEFT JOIN menu_items
			ON menu_items.menu_item_id = order_details.item_id
	GROUP BY order_details.day_name, order_date
    ) AS cost_of_sales_per_day;

-- S3) Using the CASE statement
SELECT order_date, SUM(menu_items.price) AS gross_sales,
	CASE 
		WHEN SUM(menu_items.price) > 
        (SELECT ROUND(AVG(gross_sales),2) AS average_cost_of_sales_per_day
			FROM (
				SELECT order_date, order_details.day_name, SUM(menu_items.price) AS gross_sales
				FROM order_details
					LEFT JOIN menu_items
						ON menu_items.menu_item_id = order_details.item_id
				GROUP BY order_details.day_name, order_date
				) AS cost_of_sales_per_day
		) -- LINES 261 THRU 269 THIS IS FROM STEP 2 IN FINDING THE AVG COST OF SALES PER DAY
			THEN "Good"
        WHEN SUM(menu_items.price) = 
        (SELECT ROUND(AVG(gross_sales),2) AS average_cost_of_sales_per_day
			FROM (
				SELECT order_date, order_details.day_name, SUM(menu_items.price) AS gross_sales
				FROM order_details
					LEFT JOIN menu_items
						ON menu_items.menu_item_id = order_details.item_id
				GROUP BY order_details.day_name, order_date
				) AS cost_of_sales_per_day
		)  THEN "Average"
        ELSE "Bad"
		END AS "Type_of_day"
FROM order_details
	LEFT JOIN menu_items
		ON menu_items.menu_item_id = order_details.item_id
GROUP BY order_date;
