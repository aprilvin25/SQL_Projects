-- Project based on Alex the Analyst on Youtube

-- Create a database
CREATE SCHEMA nashville_housing_data_cleaning;

-- Select database
USE nashville_housing_data_cleaning;

-- Next, change date format in excel to YYYY-MM-DD
-- Find blank values in Excel and replace with "NULL"
-- Next, import data

-- view all columns and rows
SELECT * 
FROM housing_data;

-- check field and type
SHOW columns
FROM housing_data;

-- ---------------------- standardize date format ----------------------------------
-- view the sale_date column
SELECT sale_date
FROM housing_data;

-- use the DATE() function
SELECT DATE(sale_date) AS sale_date
FROM housing_data;

-- adding a new column sale_date converted column
ALTER TABLE housing_data
ADD sale_date_converted DATE; 

UPDATE housing_data
SET sale_date_converted = DATE(sale_date);

-- deleting the old sale_date column
ALTER TABLE housing_data
DROP COLUMN sale_date;

-- renaming column 
ALTER TABLE housing_data
RENAME COLUMN sale_date_converted TO sale_date;

-- verify the data is correct
SELECT sale_date 
FROM housing_Data;

-- ------------ Populate Property Address Data -----------------------
-- looking for NULL values in property_address column
SELECT *
FROM housing_data
WHERE property_address IS NULL;

/* if parcel_id has an address and the same parcel_id on a different row
does NOT have an address, populate it with the same address, as they're 
going to be the same. */

-- first step is to do a self join to see if the parcel_id on different rows match each other
SELECT A.parcel_id, A.property_address, B.parcel_id, B.property_address
FROM housing_data A
	INNER JOIN housing_data B
		ON A.parcel_id = B.parcel_id        -- same parcel_id
		AND A.unique_id <> B. unique_id;    -- different unique_id

-- next filter to where property_address IS NULL
SELECT A.parcel_id, A.property_address, B.parcel_id, B.property_address
FROM housing_data A
	INNER JOIN housing_data B
		ON A.parcel_id = B.parcel_id
		AND A.unique_id <> B. unique_id
WHERE A.property_address IS NULL;

-- use COALESCE to populate these blank property addresses
-- SYNTAX: COALESCE(column1, default_value)
SELECT A.parcel_id, A.property_address, B.parcel_id, B.property_address,
	COALESCE(A.property_address, B.property_address)
FROM housing_data A
	INNER JOIN housing_data B
		ON A.parcel_id = B.parcel_id
		AND A.unique_id <> B. unique_id
WHERE A.property_address IS NULL;

-- let's update the table
-- (make sure to use alias table name)
UPDATE housing_data A  
INNER JOIN housing_data B
		ON A.parcel_id = B.parcel_id
		AND A.unique_id <> B. unique_id   
SET A.property_address = COALESCE(A.property_address, B.property_address)
WHERE A.property_address IS NULL;
-- 29 rows affected

-- ------- Breaking out Address into individual columns (Address, City, State) -------
SELECT property_address
FROM housing_data;

/*
S1) notice a pattern: there is a comma that is the delimeter (separates values)
S2) use SUBSTRING() and LOCATE() function. 
SUBSTRING() extracts a substring from a string--> SUBSTRING(string, start_position, length)
LOCATE() function in MySQL is used to find the position of 
the first occurrence of a substring within a string.  --> LOCATE(substring, string, start_position)
*/

-- S3) TO FIND ADDRESS:
-- SUBSTRING(COLUMN, START_POS, LENGTH) --> inside length use the LOCATE() function
-- SUBSTRING(COLUMN, START_POS, LOCATE('SUBSTRING', COLUMN)
-- Then subtract 1 in the LOCATE function to delete the comma

SELECT SUBSTRING(property_address, 1, LOCATE(',', property_address)-1) AS street_address
FROM housing_data;   

-- S4) To find the city:
-- Not starting at 1st position anymore. So start at the comma.
-- Use +1 at LOCATE() to start substring after comma.
/*  Need to find where it needs to finish. Use LENGTH() function to ensure 
the rest of the string is included, up to its end. */

SELECT 
	SUBSTRING(property_address, 1, LOCATE(',', property_address) - 1) AS street_address,
	SUBSTRING(property_address, LOCATE(',', property_address) + 1, LENGTH(property_address)) AS city 
FROM housing_data;  

-- Let's update table and add 2 new columns for the street address and city

ALTER TABLE housing_data
ADD street_address VARCHAR(255);

UPDATE housing_data
SET street_address = 
	SUBSTRING(property_address, 1, LOCATE(',', property_address) - 1);
    
ALTER TABLE housing_data
ADD city VARCHAR(255);

UPDATE housing_data
SET city = SUBSTRING(property_address, LOCATE(',', property_address) + 1, LENGTH(property_address));
-- view your new columns at the end
SELECT *
FROM housing_data;

-- ---------------- CHange Y and N to YES and No in "Sold as Vacant" field -----------------------
-- S1) find out the different unique resposnes and a count for each 
SELECT DISTINCT(sold_as_vacant), COUNT(sold_as_vacant) AS total_count
FROM housing_data
GROUP BY sold_as_vacant
ORDER BY COUNT(sold_as_vacant);

-- S2) Use CASE statements
SELECT sold_as_vacant,
	CASE WHEN sold_as_vacant = "Y" THEN "YES"
		 WHEN sold_as_vacant = "N" THEN "NO"
         ELSE sold_as_vacant
         END AS final_sold_as_vacant
FROM housing_data;

-- S3) update the table using UPDATE statement
UPDATE housing_data
SET sold_as_vacant = 
	CASE WHEN sold_as_vacant = "Y" THEN "YES"
		 WHEN sold_as_vacant = "N" THEN "NO"
         ELSE sold_as_vacant
         END;
         
-- S4) go to Step 1 to make sure all the rows have been affected 
    
-- ----------------- Remove Duplicates ----------------------------------------
-- S1) write a CTE and find where there are duplicate values using a windows function. 
/* Need a way to identify duplicate rows. Use ROW_NUMBER(). we need to partition it
on things that should be unique to each row. then use ORDER BY. then name it row_num. 
*/

WITH row_num_CTE AS(
SELECT *, 
	ROW_NUMBER() OVER(
    PARTITION BY Parcel_id,
		 Property_address,
		 sale_price,
                 sale_date,
                 legal_reference
                 ORDER BY unique_id) row_num
FROM housing_data
-- ORDER BY parcel_id
)
SELECT * 
FROM row_num_CTE
WHERE row_num > 1
ORDER BY property_address;

