create database nft;


use nft;


SELECT 
    *
FROM
    pricedata;

-- 1. How many sales occurred during this time period? ( January 1st, 2018 to December 31st, 2021)

SELECT 
    COUNT(*) AS Total_sales
FROM
    pricedata
WHERE
    event_date >= '2018-01-01'
        AND event_date <= '2021-12-31';
        
 -- 2. Return the top 5 most expensive transactions (by USD price) for this data set. Return the name, ETH price, and USD price, as well as the date.
 
SELECT 
    name, eth_price, usd_price, event_date
FROM
    pricedata
ORDER BY usd_price DESC
LIMIT 5;


-- 3. Return a table with a row for each transaction with an event column, a USD price column, and a moving average of USD price that averages the last 50 transactions.

SELECT CAST(event_date AS DATE) AS Date,
usd_price,
AVG(USD_PRICE) OVER(ORDER BY transaction_hash ROWS BETWEEN 49
PRECEDING AND CURRENT ROW)AS moving_average
FROM pricedata
ORDER BY transaction_hash;


-- 4. Return all the NFT names and their average sale price in USD. Sort descending. Name the average column as average_price.

SELECT 
   name,
    AVG(USD_price) AS average_price
FROM 
    pricedata
GROUP BY 
    name
ORDER BY 
    average_price DESC;
    
    
-- 5. Return each day of the week and the number of sales that occurred on that day of the week, as well as the average price in ETH. Order by the count of transactions in ascending order.
    
  select DATE(event_date), count(*)AS no_of_sales_ontheday,avg(eth_price)
from pricedata
group by event_date
order by count(*);      

-- 6.Construct a column that describes each sale and is called summary. The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date, and what price it was sold for in USD rounded to the nearest thousandth.

SELECT 
    CONCAT(
        name, ' was sold for $', ROUND(USD_PRICE, -3),
        ' to ', buyer_address,
        ' from ', seller_address,
        ' on ', event_date
    ) AS summary
FROM 
    pricedata;
    
    
 -- 7. Create a view called “1919_purchases” and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.

CREATE VIEW 1919_purchases AS
    SELECT 
        *
    FROM
        pricedata
    WHERE
        buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';
        
 -- 8.Create a histogram of ETH price ranges. Round to the nearest hundred value. 
       
SELECT 
    ROUND(eth_price, - 2) AS ETH,
    COUNT(*) AS Count,
    RPAD('', COUNT(*), '*') AS Bar
FROM
    pricedata
GROUP BY ETH
ORDER BY ETH;


-- 9. Return a unioned query that contains the highest price each NFT was bought for and a new column called status saying “highest” with a query that has the lowest price each NFT was bought for and the status column saying “lowest”. The table should have a name column, a price column called price, and a status column. Order the result set by the name of the NFT, and the status, in ascending order. 

SELECT 
    name, MIN(usd_price) AS price, 'lowest' AS status
FROM
    pricedata
GROUP BY name 
UNION ALL SELECT 
    name, MIN(usd_price) AS price, 'lowest' AS STATUS
FROM
    pricedata
GROUP BY name;


-- 10. What NFT sold the most each month / year combination? Also, what was the name and the price in USD? Order in chronological format. 

SELECT 
    YEAR(event_date) AS year,
    MONTH(event_date) AS month,
    name,
    MAX(USD_price) AS max_price_in_usd
FROM
    pricedata
GROUP BY YEAR(event_date) , MONTH(event_date)
ORDER BY year ASC , month ASC;



-- 11 .Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year).

SELECT 
    DATE_FORMAT(event_date, '%Y-%m') AS month_year,
    ROUND(SUM(USD_price), -2) AS total_volume
FROM 
    pricedata
GROUP BY 
    DATE_FORMAT(event_date, '%Y-%m')
ORDER BY 
    month_year ASC;
    
-- 12 Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period.

SELECT 
    COUNT(*) AS total_transaction_count
FROM
    pricedata
WHERE
    buyer_address = '0x1919db36ca2fa2e159000fd9cdc2edcf863e685'
        OR seller_address = '0x1919db36ca2fa2e159000fd9cdc2edcf863e685'
        AND event_date >= '2018-01-01'
        AND event_date <= '2021-12-31';
        
-- 13 Create an “estimated average value calculator” that has a representative price of the collection every day based off of these criteria:
 -- Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
 -- Take the daily average of remaining transactions
 -- a) First create a query that will be used as a subquery. Select the event date, the USD price, and the average USD price for each day using a window function. Save it as a temporary table.
 -- b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of the daily average and return a new estimated value which is just the daily average of the filtered data.
 
 WITH DailyAverage As
(SELECT event_date, usd_price,
AVG(usd_price) OVER (PARTITION BY event_date) AS daily_avg_price
FROM pricedata),

FilteredData AS
(SELECT event_date,usd_price,daily_avg_price
FROM DailyAverage
WHERE usd_price>=0.1 * daily_avg_price)

SELECT event_date,
AVG(usd_price)AS estimated_valve
FROM FilteredData
GROUP BY event_date
ORDER BY event_date;


CREATE TEMPORARY TABLE buying_price
SELECT buyer_address,sum(usd_price) AS buying_price FROM pricedata
GROUP BY buyer_address;

CREATE TEMPORARY TABLE selling_price
SELECT seller_address,sum(usd_price) AS selling_price FROM pricedata
GROUP BY seller_address;

CREATE TEMPORARY TABLE profit
SELECT * FROM buying_price INNER JOIN selling_price ON
buying_price.buyer_address = selling_price.seller_address;

SELECT selling_price,buying_price,buyer_address,(selling_price-buying_price)
AS profitability F

