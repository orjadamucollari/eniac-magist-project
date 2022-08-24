USE magist;
-- ------------------------ DATA EXPLORATION QUESTIONS ------------------------ --
-- 1. How many orders are there in the dataset?
SELECT
    COUNT(*) AS orders_count
FROM
    orders;

-- if you want to count distinct items:
SELECT
	COUNT(DISTINCT order_id) AS orders_count
FROM
	orders;

-- 2. Are orders actually delivered?
SELECT
    order_status, COUNT(*) AS orders
FROM
    orders
GROUP BY order_status;

-- 3. Is Magist having user growth? check for the number of orders grouped by year and month.
-- Tip: you can use the functions YEAR() and MONTH() to separate the year and the month of the order_purchase_timestamp.
-- YES THERE IS GROWTH GIVEN THAT THE NUMBER OF ORDERS INCREASED EACH YEAR
SELECT
    YEAR(order_purchase_timestamp) AS year_,
    MONTH(order_purchase_timestamp) AS month_,
    COUNT(customer_id)
FROM
    orders
GROUP BY year_ , month_
ORDER BY year_ , month_;

# only order by year
SELECT
	YEAR(order_purchase_timestamp) as year,
	COUNT(customer_id)
FROM
	orders
GROUP BY year
ORDER BY year;

-- 4. How many products are there in the products table?
-- (Make sure that there are no duplicate products.) # 32951
SELECT
	COUNT(product_id)
FROM
	products;

-- 5. Which are the categories with most products?
SELECT
	product_category_name,
    COUNT(DISTINCT product_id)
FROM
	products
GROUP BY  product_category_name
ORDER BY COUNT(product_id) DESC;

-- 6. How many of those products were present in actual transactions?
-- The products table is a “reference” of all the available products.
-- Have all these products been involved in orders? Check out the order_items table to find out!
# 32951
SELECT
	COUNT(DISTINCT product_id) AS n_products
FROM
	order_items;

-- 7. What’s the price for the most expensive and cheapest products? Sometimes, having a basing range of prices is informative.
-- Looking for the maximum and minimum values is also a good way to detect extreme outliers).
SELECT
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive
FROM
	order_items;

-- 8. What are the highest and lowest payment values? Some orders contain multiple products.
-- What’s the highest someone has paid for an order? Look at the order_payments table and try to find it out.
SELECT
	MAX(payment_value) as highest,
    MIN(payment_value) as lowest
FROM
	order_payments;

-- ------------------------ BUSINESS QUESTIONS ------------------------ --
# In relation to the products:

-- 1. What categories of tech products does Magist have?
SELECT DISTINCT product_category_name_english FROM product_category_name_translation;
	# portuguese = "audio", "eletronicos", "informatica_acessorios", "pc_gamer", "pcs", "tablets_impressao_imagem, telefonia", "telefonia_fixa"
SELECT
	product_category_name
FROM
	product_category_name_translation
WHERE
	product_category_name_english IN ("audio", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony", "fixed_telephony");


# TO ADD TECH AS A COLUMN TO THE PRODUCTS TABLE
/* ALTER TABLE products ADD tech varchar(300) as
(case
    WHEN product_category_name = 'audio' THEN '1'
    WHEN product_category_name = 'eletronicos' THEN '1'
    WHEN product_category_name = 'informatica_acessorios' THEN '1'
    WHEN product_category_name = 'pc_gamer' THEN '1'
    WHEN product_category_name = 'pcs' THEN '1'
    WHEN product_category_name = 'tablets_impressao_imagem' THEN '1'
    WHEN product_category_name = 'telefonia' THEN '1'
    WHEN product_category_name = 'telefonia_fixa' THEN '1'
    ELSE '0'
  END);
  */

-- 2. HOW MANY OF THESE TECH PRODUCTS HAVE BEEN SOLD (WITHIN THE TIME WINDOW OF THE DATABASE SNAPSHOT)?
# 11371 tech products sold within 25 months
SELECT
	COUNT(*) AS tech_products_sold
FROM
	orders
JOIN
	order_items ON orders.order_id = order_items.order_id
JOIN
	products ON products.product_id = order_items.product_id
WHERE product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
								"pc_gamer", "pcs", "tablets_impressao_imagem",
                                "telefonia", "telefonia_fixa")
							AND order_status != "canceled" AND order_status != "unavailable";

# WHAT PERCENT DOES THAT REPRESENT FROM THE OVERALL NUMBER OF PRODUCTS SOLD?
SELECT ROUND(15981 / COUNT(*) * 100 , 2) AS percent_of_sales
FROM order_items;

-- 3. * What’s the average price of the products being sold?
-- all products - 120
SELECT
     ROUND(AVG(price),2) AS average_price
FROM
    order_items
INNER JOIN
    orders ON order_items.order_id = orders.order_id
    WHERE order_status != "canceled" AND order_status != "unavailable"; # WHERE order_status = "delivered";

-- Avg tech products: 123, Eniac avg = 540
SELECT
	MIN(price), MAX(price), ROUND(AVG(price), 2)
FROM
	order_items
JOIN
    products ON order_items.product_id = products.product_id
WHERE product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
								"pc_gamer", "pcs", "tablets_impressao_imagem",
                                "telefonia", "telefonia_fixa");

-- 4. * Are expensive tech products popular?: NOT REALLY
SELECT
	COUNT(order_item_id), #product_category_name,
CASE
	WHEN price < 500 THEN "cheap"
	WHEN price < 1000 THEN "expensive"
	ELSE "mid-range"
	END AS price_category
FROM
	order_items
JOIN
    orders ON orders.order_id = order_items.order_id
JOIN
    products ON order_items.product_id = products.product_id
WHERE
	products.product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
									   "pc_gamer", "pcs", "tablets_impressao_imagem",
									   "telefonia", "telefonia_fixa")
GROUP BY
	price_category; #,product_category_name


-- 5. * How many moths of data are included in the Magist Database?: # 25 months
SELECT
	TIMESTAMPDIFF(MONTH, MIN(DATE(order_purchase_timestamp)), MAX(DATE(order_purchase_timestamp))) AS number_of_months
FROM
	orders;


# In relation to the sellers:
-- 5. * How many sellers are there?  # 3095
SELECT
	COUNT(DISTINCT(seller_id))
FROM
	sellers;

-- 6. * How many Tech sellers are there? : 463
SELECT
	COUNT(DISTINCT sellers.seller_id)
FROM
	sellers
JOIN
    order_items ON sellers.seller_id = order_items.seller_id
JOIN
    products ON order_items.product_id = products.product_id
WHERE products.product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
									    "pc_gamer", "pcs", "tablets_impressao_imagem",
									    "telefonia", "telefonia_fixa");
# What percent are tech sellers?
SELECT
	ROUND(400 / COUNT(DISTINCT seller_id), 2) AS percent_of_tech_sellers
FROM
	sellers;

-- 7. * What is the total amount earned by all sellers and amount earned by tech sellers?
# all sellers:  13494400
SELECT
	ROUND(SUM(oi.price), 2) AS total_revenue
FROM
	sellers as s
JOIN
	order_items AS oi ON s.seller_id = oi.seller_id
JOIN
	products as p ON oi.product_id = p.product_id
JOIN
	orders as o ON oi.order_id = o.order_id
AND order_status != "canceled" AND order_status != "unavailable";

# TECH SELLERS: 1724035

SELECT
	ROUND(SUM(price),2) AS total_tech_revenue
FROM
	orders as o
JOIN
	order_items as oi ON o.order_id = oi.order_id
JOIN
	products as p ON oi.product_id = p.product_id
WHERE order_status != "canceled" AND order_status != "unavailable" AND p.product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
																									"pc_gamer", "pcs", "tablets_impressao_imagem",
                                                                                                    "telefonia", "telefonia_fixa");

-- 8. * What is the avg monthly income of all sellers and the tech sellers?
-- all sellers: 13494400 / 25 = 539.776
-- tech sellers: 1724035 / 25 = 68.961

# In relation to the delivery time:

-- 9. * How many orders are delivered on time vs orders delivered with a delay?
-- All: 96478
SELECT
	COUNT(*) AS all_delivered
FROM
	orders
WHERE
	order_status = "delivered";

-- On time:  89805, 93% of all
SELECT
	COUNT(*) AS delivered_on_time
FROM
	orders
WHERE
	datediff(order_delivered_customer_date, order_estimated_delivery_date) <= 0 AND order_status = "delivered";

-- Delayed:  6665 7% of all
SELECT
	COUNT(*) AS delivered_late
FROM
	orders
WHERE
	datediff(order_delivered_customer_date, order_estimated_delivery_date) > 0 AND order_status = "delivered";

-- 10. * Is there any pattern for delayed orders, e.g. big products being delayed more often? : No pattern based on weight
SELECT
	*
FROM
	orders
WHERE datediff(order_delivered_customer_date, order_estimated_delivery_date) > 0 AND order_status = "delivered";

# add a new column for delivery time status
ALTER TABLE orders ADD deliv_time_status varchar(300) as
(CASE
    WHEN datediff(order_delivered_customer_date, order_estimated_delivery_date) <= 0 THEN 'on_time'
    WHEN datediff(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN 'delayed'
    ELSE '0'
  END);

  # calculate avg product weight, length, height and widht based on delivery time status for all products
SELECT
	AVG(p.product_weight_g), AVG(p.product_length_cm), AVG(p.product_height_cm), AVG(p.product_width_cm)
FROM
	products as p
INNER JOIN
	order_items as oi ON p.product_id = oi.product_id
INNER JOIN
	orders as o ON o.order_id = oi.order_id
WHERE order_status != "canceled" AND order_status != "unavailable"
AND p.product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
								"pc_gamer", "pcs", "tablets_impressao_imagem",
								"telefonia", "telefonia_fixa");

# delayed
SELECT
	AVG(p.product_weight_g), AVG(p.product_length_cm), AVG(p.product_height_cm), AVG(p.product_width_cm)
FROM
	products as p
INNER JOIN
	order_items as oi ON p.product_id = oi.product_id
INNER JOIN
	orders as o ON o.order_id = oi.order_id
WHERE order_status != "canceled" AND order_status != "unavailable"
AND p.product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
								"pc_gamer", "pcs", "tablets_impressao_imagem",
								"telefonia", "telefonia_fixa")
AND o.deliv_time_status = "delayed";

# on time
SELECT
	AVG(p.product_weight_g), AVG(p.product_length_cm), AVG(p.product_height_cm), AVG(p.product_width_cm)
FROM
	products as p
INNER JOIN
	order_items as oi ON p.product_id = oi.product_id
INNER JOIN
	orders as o ON o.order_id = oi.order_id
WHERE order_status != "canceled" AND order_status != "unavailable"
AND p.product_category_name IN ("audio", "eletronicos", "informatica_acessorios",
								"pc_gamer", "pcs", "tablets_impressao_imagem",
								"telefonia", "telefonia_fixa")
AND o.deliv_time_status = "on_time";
