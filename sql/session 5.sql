

/* 1)  */
SELECT product_name,
CASE
  WHEN list_price < 300 THEN 'Economy'
  WHEN list_price BETWEEN 300 AND 999 THEN 'Standard'
  WHEN list_price BETWEEN 1000 AND 2499 THEN 'Premium'
  ELSE 'Luxury'
END AS price_category
FROM products;

/* 2)  */
SELECT order_id,
CASE order_status
  WHEN 1 THEN 'Order Received'
  WHEN 2 THEN 'In Preparation'
  WHEN 3 THEN 'Order Cancelled'
  WHEN 4 THEN 'Order Delivered'
END AS status_desc,
CASE
  WHEN order_status = 1 AND DATEDIFF(CURDATE(), order_date) > 5 THEN 'URGENT'
  WHEN order_status = 2 AND DATEDIFF(CURDATE(), order_date) > 3 THEN 'HIGH'
  ELSE 'NORMAL'
END AS priority
FROM orders;

/* 3)  */
SELECT s.staff_id,
CASE
  WHEN COUNT(o.order_id) = 0 THEN 'New Staff'
  WHEN COUNT(o.order_id) BETWEEN 1 AND 10 THEN 'Junior Staff'
  WHEN COUNT(o.order_id) BETWEEN 11 AND 25 THEN 'Senior Staff'
  ELSE 'Expert Staff'
END AS staff_level
FROM staff s
LEFT JOIN orders o ON s.staff_id = o.staff_id
GROUP BY s.staff_id;

/* 4)  */
SELECT *,
ISNULL(phone, 'Phone Not Available') AS phone_fixed,
COALESCE(phone, email, 'No Contact Method') AS preferred_contact
FROM customers;

/* 5)  */
SELECT p.product_name,
ISNULL(p.list_price / NULLIF(s.quantity,0),0) AS price_per_unit,
CASE
  WHEN s.quantity IS NULL OR s.quantity = 0 THEN 'Out of Stock'
  ELSE 'In Stock'
END AS stock_status
FROM stocks s
JOIN products p ON s.product_id = p.product_id
WHERE s.store_id = 1;

/* 6)  */
SELECT customer_id,
CONCAT(
 COALESCE(street,''),
 ', ', COALESCE(city,''),
 ', ', COALESCE(state,''),
 ' ', COALESCE(zip_code,'')
) AS formatted_address
FROM customers;
