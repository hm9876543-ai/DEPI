-- 1
SELECT COUNT(*) FROM products;

-- 2
SELECT AVG(list_price), MIN(list_price), MAX(list_price) FROM products;

-- 3
SELECT category_id, COUNT(*) FROM products GROUP BY category_id;

-- 4
SELECT store_id, COUNT(*) FROM orders GROUP BY store_id;

-- 5
SELECT UPPER(first_name), LOWER(last_name)
FROM customers LIMIT 10;

-- 6
SELECT product_name, LENGTH(product_name)
FROM products LIMIT 10;

-- 7
SELECT SUBSTRING(phone,1,3) AS area_code
FROM customers LIMIT 15;

-- 8
SELECT CURDATE(), YEAR(order_date), MONTH(order_date)
FROM orders LIMIT 10;

-- 9
SELECT p.product_name, c.category_name
FROM products p
JOIN categories c ON p.category_id=c.category_id
LIMIT 10;

-- 10
SELECT c.first_name, o.order_date
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
LIMIT 10;

-- 11
SELECT p.product_name, IFNULL(b.brand_name,'No Brand')
FROM products p
LEFT JOIN brands b ON p.brand_id=b.brand_id;

-- 12
SELECT product_name, list_price
FROM products
WHERE list_price > (SELECT AVG(list_price) FROM products);

-- 13
SELECT customer_id
FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- 14
SELECT c.first_name,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id=c.customer_id)
FROM customers c;

-- 15
CREATE VIEW easy_product_list AS
SELECT p.product_name, c.category_name, p.list_price
FROM products p
JOIN categories c ON p.category_id=c.category_id;

SELECT * FROM easy_product_list WHERE list_price > 100;

-- 16
CREATE VIEW customer_info AS
SELECT customer_id,
       CONCAT(first_name,' ',last_name) AS full_name,
       email,
       CONCAT(city,' , ',state) AS location
FROM customers;

SELECT * FROM customer_info WHERE location LIKE '%CA';

-- 17
SELECT product_name, list_price
FROM products
WHERE list_price BETWEEN 50 AND 200
ORDER BY list_price;

-- 18
SELECT state, COUNT(*) 
FROM customers
GROUP BY state
ORDER BY COUNT(*) DESC;

-- 19
SELECT c.category_name, p.product_name, p.list_price
FROM products p
JOIN categories c ON p.category_id=c.category_id
WHERE p.list_price = (
  SELECT MAX(list_price)
  FROM products
  WHERE category_id=p.category_id
);

-- 20
SELECT s.store_name, s.city, COUNT(o.order_id)
FROM stores s
LEFT JOIN orders o ON s.store_id=o.store_id
GROUP BY s.store_id;
