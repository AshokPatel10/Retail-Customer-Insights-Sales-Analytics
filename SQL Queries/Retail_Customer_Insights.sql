-- Check the list of all the tables pre
--SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

ALTER TABLE "Customer" RENAME TO customer;

SELECT * FROM customer LIMIT 10;

----------🔹 Customer Demographics Analysis----------
-- Q1. Which gender spends more on average?
SELECT gender, round(AVG(purchase_amount),2) AS avg_spending
FROM customer
GROUP BY gender;
-- Q2. Which age group generates the highest revenue?
SELECT age, SUM(purchase_amount) AS total_sales
FROM customer
GROUP BY age
ORDER BY total_sales DESC;
-- Q3. Which locations have the highest number of customers?
SELECT location, COUNT(*) AS total_customers
FROM customer
GROUP BY location
ORDER BY total_customers DESC;

----------🔹 Product & Category Analysis----------
-- Q4. Most purchased category
SELECT category, COUNT(*) AS total_orders
FROM customer
GROUP BY category
ORDER BY total_orders DESC;
-- Q5. Highest revenue generating category
SELECT category, SUM(purchase_amount) AS total_revenue_category
FROM customer
GROUP BY category
ORDER BY total_revenue_category DESC;
-- Q6. Top purchased items
SELECT item_purchased, COUNT(*) AS purchase_count
FROM customer
GROUP BY item_purchased
ORDER BY purchase_count DESC, item_purchased ASC;

----------🔹 Customer Spending Behavior----------
-- Q7. Top 10 highest spending customers
SELECT customer_id, SUM(purchase_amount) AS total_spending
FROM customer
GROUP BY customer_id
ORDER BY total_spending DESC
LIMIT 10;
-- Q8. Average purchase amount by season
SELECT season, round(AVG(purchase_amount),2) AS avg_purchase_amount
FROM customer
GROUP BY season
ORDER BY avg_purchase_amount DESC;
-- Q9. Does discount increase purchases?
SELECT discount_applied, round(AVG(purchase_amount),2) AS avg_sales
FROM customer
GROUP BY discount_applied
ORDER BY avg_sales DESC;

----------🔹 Subscription & Loyalty Analysis----------
-- Q10. Subscription vs non-subscription spending
SELECT subscription_status, SUM(purchase_amount) AS total_spendings
FROM customer
GROUP BY subscription_status
ORDER BY total_spendings DESC;
-- Q11. Customers with highest previous purchases
SELECT customer_id, previous_purchases
FROM customer
ORDER BY previous_purchases DESC
LIMIT 10;

----------🔹 Payment & Shipping Analysis----------
-- Q12. Most preferred payment method
SELECT payment_method, COUNT(*) AS preferred_method
FROM customer
GROUP BY payment_method
ORDER BY preferred_method DESC;
-- Q13. Which shipping type is most used?
SELECT shipping_type, COUNT(*) AS preferred_type
FROM customer
GROUP BY shipping_type
ORDER BY preferred_type DESC;

----------🔹 Review & Satisfaction Analysis----------
-- Q14. Which category gets the best reviews?
SELECT category, ROUND(AVG(review_rating) :: NUMERIC,2) AS best_reviews
FROM customer
GROUP BY category
ORDER BY best_reviews DESC;
-- Q15. Does higher spending mean better reviews?
SELECT 
	CASE
		WHEN purchase_amount > 70 THEN 'High Spending'
		ELSE 'Low Spending'
	END AS spending_group,
	ROUND(AVG(review_rating)::numeric,2) AS avg_review_rating
FROM customer
GROUP BY spending_group;

----------🔹 Seasonal Trends (Very Good for Dashboard)----------
-- Q16. Which season generates maximum sales?
SELECT season, SUM(purchase_amount) AS maximum_sales
FROM customer
GROUP BY season
ORDER BY maximum_sales DESC;
-- Q17. Most purchased category in each season
SELECT season, category, COUNT(*) AS purchased_category
FROM customer
GROUP BY season, category
ORDER BY purchased_category DESC;
-- Q18. top purchased category in each season
WITH cte as (
select season, category, count(*) as total_orders,
RANK() OVER(
PARTITION BY season
ORDER BY COUNT(*) DESC
) AS rnk
FROM customer
GROUP BY season, category
)
SELECT season, category, total_orders
FROM cte
WHERE rnk = 1
ORDER BY season;
-- Q19. Which customers are likely loyal customers?
SELECT customer_id,
		CASE WHEN previous_purchases >=40
				AND purchase_frequency_days IN (1,14)
				AND subscription_status = 'Yes'
			THEN 'HIGH LOYALTY'
			WHEN previous_purchases >=20
			THEN 'MEDIUM LOYALTY'
			ELSE 'LOW LOYALTY'
		END AS loyalty_segment
FROM customer
ORDER BY
CASE
    WHEN previous_purchases >= 40
         AND purchase_frequency_days IN (1,14)
         AND subscription_status = 'Yes'
    THEN 1
    WHEN previous_purchases >= 20
    THEN 2
    ELSE 3
END,
previous_purchases DESC;
-- Q20. Which category performs best without discounts?
SELECT category, SUM(purchase_amount) AS total_sales
FROM customer
WHERE discount_applied = 'No' 
GROUP BY category
ORDER BY total_sales DESC;
-- Q21. Which payment method is associated with higher spending?
SELECT payment_method, ROUND(AVG(purchase_amount)::numeric, 2) AS avg_spendings
FROM customer
GROUP BY payment_method
Order by avg_spendings DESC;

SELECT * FROM customer LIMIT 10;
----------🔹 Advanced Business Insights----------
--Q1. what is total revenue generated by male vs female customers ?
SELECT gender, SUM(purchase_amount) AS revenue
FROM customer
GROUP BY gender;
--Q2. which customer used discount but still spend more than the avg purchase amount ?
SELECT customer_id, purchase_amount
FROM customer
WHERE discount_applied = 'Yes' 
	AND purchase_amount >(SELECT AVG(purchase_amount) FROM customer);
--Q3. which are the top 5 products with the highest avg review rating ?
SELECT item_purchased, ROUND(AVG(review_rating)::NUMERIC,2) AS avg_review_rating
FROM customer
GROUP BY item_purchased
ORDER BY avg_review_rating DESC
LIMIT 5;
--Q4. compare the avg purchase amounts between standard and express shipping ?
SELECT shipping_type, ROUND(AVG(purchase_amount)::NUMERIC,2) AS avg_purchase_amounts
FROM customer
WHERE shipping_type IN ('Standard','Express')
GROUP BY shipping_type;
--Q5. do subscribed customer spend more ? compare avg spend and total revenue between 
------subscribed and non-subscribers ?
SELECT subscription_status,
COUNT(customer_id) AS total_customers,
ROUND(AVG(purchase_amount)::NUMERIC,2) AS avg_spend,
ROUND(SUM(purchase_amount)::NUMERIC,2) AS total_revenue
FROM customer
GROUP BY subscription_status
ORDER BY total_revenue, avg_spend DESC;
--Q6. which 5 products have the highest percentage of purchases with discount applied ?
SELECT item_purchased,
ROUND(100*SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END)/COUNT(*)::NUMERIC,2) AS purchase_rate
FROM customer
GROUP BY item_purchased
ORDER BY purchase_rate DESC
LIMIT 5;
--Q7. segment customers into new, returning, loyal based on their total number of 
------previous purchases, and show the count of each segment ?
WITH cte AS (
SELECT customer_id, previous_purchases,
CASE WHEN previous_purchases = 1 THEN 'new'
	WHEN previous_purchases BETWEEN 2 AND 10 THEN 'returning'
	ELSE 'loyal'
	END AS segment
FROM customer
)
SELECT segment,
	count(segment)
FROM cte
GROUP BY segment;
--Q8. what are the top 3 most purchased products within each category ?
WITH cte AS (
SELECT category, item_purchased,
COUNT(customer_id) AS total_orders,
ROW_NUMBER() OVER(PARTITION BY category
ORDER BY COUNT(customer_id) DESC)
AS item_rnk
FROM customer
GROUP BY category, item_purchased
)
SELECT item_rnk, category,item_purchased,total_orders
FROM cte
where item_rnk <= 3;
--Q9. are customers who are repeat buyers (more than 5 previous purchases) also 
------likely to subscribe ?
SELECT subscription_status, COUNT(customer_id) AS repeat_buyers
FROM customer
WHERE previous_purchases >5
GROUP BY subscription_status;
--Q10. Which age groups contribute the highest percentage of total revenue?
SELECT age_group, SUM(purchase_amount) AS total_revenue,
		ROUND(
           100 * SUM(purchase_amount)::NUMERIC /
           (SELECT SUM(purchase_amount) FROM customer),
           2
       ) AS revenue_percentage
FROM customer
GROUP BY age_group
ORDER BY revenue_percentage DESC;