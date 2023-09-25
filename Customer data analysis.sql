CREATE DATABASE projects;

USE projects;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM dbo.sales s
INNER JOIN dbo.menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant??

SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS days_visited
FROM dbo.sales s
GROUP BY s.customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH first_time_purchases  AS(
  Select s.customer_id, MIN(s.order_date) AS first_joining_date
  from projects.sales s
  GROUP BY s.customer_id)
  
  Select cfp.customer_id, cfp.first_joining_date, m.product_name
  from first_time_purchases cfp
  INNER JOIN projects.sales s
  ON cfp.customer_id = s.customer_id
  AND cfp.first_joining_date = s.order_date
  INNER JOIN projects.menu m
  ON s.product_id = m.product_id;
  
  
  -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
  Select s.customer_id, COUNT
  Select m.product_name, COUNT(s.product_id) AS number_of_times
  from projects.menu m 
  INNER JOIN projects.sales s 
  ON m.product_id = s.product_id
  GROUP BY m.product_name
  ORDER BY number_of_times DESC LIMIT 1 ;
  
  -- 5. Which item was the most popular for each customer?

WITH customer_popularity AS (
Select s.customer_id, m.product_name, COUNT(*) AS purchase_count, 
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS position
FROM projects.sales s
inner join
projects.menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name )

Select customer_id, product_name, purchase_count
from customer_popularity 
where position = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase_after_membership AS (

Select s.customer_id , MIN(s.order_date) AS first_purchase 
from projects.sales s 
INNER JOIN projects.members e
ON s.customer_id = e.customer_id
WHERE s.order_date >= e.join_date
GROUP BY s.customer_id)

Select fpm.customer_id, m.product_name
from first_purchase_after_membership fpm
INNER JOIN projects.sales s
ON fpm.customer_id = s.customer_id 
AND fpm.first_purchase = s.order_date
INNER JOIN projects.menu as m 
ON s.product_id = m.product_id;


-- 7. Which item was purchased just before the customer became a member?

WITH last_purchase_membership AS(
Select s.customer_id, MAX(s.order_date) AS last_order
from projects.sales s 
INNER JOIN 
projects.members e
ON s.customer_id = e.customer_id
WHERE s.order_date < e.join_date
GROUP BY s.customer_id)

Select lpm.customer_id, m.product_name
from last_purchase_membership lpm
INNER JOIN projects.sales s 
ON s.customer_id = lpm.customer_id
AND s.order_date = lpm.last_order
INNER JOIN menu m
ON s.product_id = m.product_id;

-- 8. What is the total items and amount spent for each member before they became a member?
Select s.customer_id, COUNT(*) as total_items, SUM(m.price) AS Amount
from projects.sales s 
INNER JOIN projects.menu m 
ON s.product_id = m.product_id
INNER JOIN projects.members e 
ON s.customer_id = e.customer_id
WHERE s.order_date < e.join_date
GROUP BY s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

Select s.customer_id, SUM(
CASE 
WHEN m.product_name = 'sushi' THEN m.price*20
ELSE m.price*10 END ) AS total_points
from projects.sales s 
INNER JOIN projects.menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id;

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT s.customer_id, SUM(
    CASE 
        WHEN s.order_date BETWEEN e.join_date AND DATEADD (day, 7, e.join_date) THEN m.price*20
        WHEN m.product_name = 'sushi' THEN m.price*20 
        ELSE m.price*10 
    END) AS total_points
FROM projects.sales s
JOIN projects.menu m ON s.product_id = m.product_id
LEFT JOIN projects.members e ON s.customer_id = e.customer_id
-- WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
WHERE s.customer_id = e.customer_id AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

-- 11. Recreate the table output using the available data

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date >= e.join_date THEN 'Y'
ELSE 'N' END AS member
FROM projects.sales s
JOIN projects.menu m ON s.product_id = m.product_id
LEFT JOIN projects.members e ON s.customer_id = e.customer_id
ORDER BY s.customer_id, s.order_date;

-- 12. Rank all the things

Select s.customer_id, s.order_date, m.product_name, m.price, 
CASE 
WHEN s.order_date < e.join_date THEN 'N'
WHEN s.order_date >= e.join_date THEN 'Y'
ELSE 'N' END AS member 
from projects.sales s 
JOIN projects.menu m 
ON s.product_id = m.product_id
LEFT JOIN projects.members e 
ON s.customer_id = e.customer_id
GROUP BY s.customer_id












