-- 1
SELECT * FROM products WHERE list_price > 1000;

-- 2
SELECT * FROM customers WHERE state IN ('CA','NY');

-- 3
SELECT * FROM orders WHERE YEAR(order_date)=2023;

-- 4
SELECT * FROM customers WHERE email LIKE '%@gmail.com';

-- 5
SELECT * FROM staff WHERE active=0;

-- 6
SELECT * FROM products ORDER BY list_price DESC LIMIT 5;

-- 7
SELECT * FROM orders ORDER BY order_date DESC LIMIT 10;

-- 8
SELECT * FROM customers ORDER BY last_name LIMIT 3;

-- 9
SELECT * FROM customers WHERE phone IS NULL;

-- 10
SELECT * FROM staff WHERE manager_id IS NOT NULL;

-- 11
SELECT category_id, COUNT(*) FROM products GROUP BY category_id;

-- 12
SELECT state, COUNT(*) FROM customers GROUP BY state;

-- 13
SELECT brand_id, AVG(list_price) FROM products GROUP BY brand_id;

-- 14
SELECT staff_id, COUNT(*) FROM orders GROUP BY staff_id;

-- 15
SELECT customer_id FROM orders GROUP BY customer_id HAVING COUNT(*)>2;

-- 16
SELECT * FROM products WHERE list_price BETWEEN 500 AND 1500;

-- 17
SELECT * FROM customers WHERE city LIKE 'S%';

-- 18
SELECT * FROM orders WHERE order_status IN (2,4);

-- 19
SELECT * FROM products WHERE category_id IN (1,2,3);

-- 20
SELECT * FROM staff WHERE store_id=1 OR phone IS NULL;
