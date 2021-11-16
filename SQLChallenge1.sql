/*
8 Week SQL Challenges 
CASE STUDY 1 - Danny's Dinner DATA WITH DANNY
*/

Create Table Sales
(
customer_id varchar(1),
order_date Date,
product_id int
)

Select * from Sales

Insert into Sales Values
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3')

 CREATE TABLE menu 
(
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
)

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12')
  

CREATE TABLE members 
(
  "customer_id" VARCHAR(1),
  "join_date" DATE
)

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09')

  Select * from Sales
  Select * from menu
  Select * from members

  -- Q1) What is the total amount each customer spent at the restaurant?

  Select customer_id, sum(price) as Total_amount
  from Sales INNER JOIN menu
  ON Sales.product_id = menu.product_id
  Group BY customer_id

  -- Q2) How many days has each customer visited the restaurant?

  Select customer_id, COUNT(distinct order_date)
  from Sales
  Group by customer_id

  -- Q3) What was the first item from the menu purchased by each customer?

  WITH CTE_Table AS (Select customer_id, product_name, order_date from Sales Inner Join menu on Sales.product_id = menu.product_id) 
Select customer_id, product_name from (Select customer_id, product_name , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as RK
from CTE_Table) NT
Where NT.RK = 1

-- Q4) What is the most purchased item on the menu and how many times was it purchased by all customers?

Select product_name, count(*) as Total_Sales
from menu join Sales on 
menu.product_id = Sales.product_id
Group by product_name
order by Total_Sales DESC

-- Q5) Which item was the most popular for each customer?

WITH CTE_MOST_POPULAR AS 
(
Select customer_id, product_name, count(*) as ProductSale, DENSE_RANK() OVER (PARTITION BY customer_id Order by Count(*) DESC) AS RK
FROM Sales JOIN menu on Sales.product_id = menu.product_id 
Group by customer_id, product_name
)

Select customer_id, product_name from CTE_MOST_POPULAR
Where RK = 1


--Q6) Which item was purchased first by the customer after they became a member?

WITH CTE_ITEM_FIRST_CUSTOMER AS
(
Select 
  RANK() OVER (Partition by members.customer_id order by order_date) as ranked,
  members.customer_id, menu.product_name
  from Sales
  LEFT JOIN members ON sales.customer_id = members.customer_id
  LEFT JOIN menu ON menu.product_id = Sales.product_id
  Where order_date >= join_date
  )
Select * from CTE_ITEM_FIRST_CUSTOMER Where ranked = 1

--Q7) Which item was purchased just before the customer became a member?

WITH CTE_ITEM_FIRST_CUSTOMER_BEFORE AS
(
Select 
  RANK() OVER (Partition by members.customer_id order by order_date) as ranked,
  members.customer_id, menu.product_name
  from Sales
  LEFT JOIN members ON sales.customer_id = members.customer_id
  LEFT JOIN menu ON menu.product_id = Sales.product_id
  Where order_date < join_date
  )
Select * from CTE_ITEM_FIRST_CUSTOMER_BEFORE Where ranked = 1

--Q8) What is the total items and amount spent for each member before they became a member?

Select Sales.customer_id, COUNT(DISTINCT menu.product_id) as Total_items, SUM(menu.price) as Total_Amount from Sales
LEFT JOIN members ON Sales.customer_id = members.customer_id
INNER JOIN menu ON Sales.product_id = menu.product_id
Where order_date < join_date
Group by Sales.customer_id
Order by Sales.customer_id

--Q9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

Select Sales.customer_id,
SUM(
    CASE
       When product_name = 'sushi' Then 20 * price
	   ELSE 10 * price
	   END
) AS Total_Points
from Sales
LEFT JOIN menu ON Sales.product_id = menu.product_id
Group By Sales.customer_id
Order by Total_Points DESC;

--Q10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

With Valid_date_CTE as
(
Select *,
DATEADD(DAY,6,join_date) as valid_date,
EOMONTH('2021-01-31') as last_date
from members
)
Select Valid_date_CTE.customer_id, join_date, valid_date, last_date, order_date, product_name, menu.product_id,
SUM(
   CASE
      WHEN order_date >= join_date AND order_date < valid_date THEN 2 * 10 * price
	  WHEN product_name = 'sushi' THEN 2 * 10 * price
	  ELSE 10 * price
	  END) as Points
From Valid_date_CTE INNER JOIN Sales ON Valid_date_CTE.customer_id = Sales.customer_id
INNER JOIN menu ON Sales.product_id = menu.product_id
Where order_date < last_date
GROUP BY Valid_date_CTE.customer_id, join_date, valid_date, last_date, order_date, product_name, menu.product_id
Order by Points DESC

--- BONUS QUESTION

--Join All The Things

Select sales.customer_id, order_date, product_name, price,
CASE
WHEN join_date > order_date THEN 'N'
WHEN join_date <= order_date THEN 'Y'
ELSE 'N'
END as Valid_Members
from Sales LEFT JOIN menu on Sales.product_id = menu.product_id
LEFT JOIN members ON members.customer_id = Sales.customer_id


--Rank All The Things

WITH overall_rank_cte as
(
Select sales.customer_id, order_date, product_name, price,
CASE
WHEN join_date > order_date THEN 'N'
WHEN join_date <= order_date THEN 'Y'
ELSE 'N'
END as Valid_Members
from Sales LEFT JOIN menu on Sales.product_id = menu.product_id
LEFT JOIN members ON members.customer_id = Sales.customer_id
)
Select *,
CASE
WHEN Valid_Members = 'N' Then NULL
ELSE
RANK() OVER (Partition by customer_id, valid_members order by order_date)
END AS Member_Ranking
from overall_rank_cte
