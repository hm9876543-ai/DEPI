/* =====================================================
INDEXES
===================================================== */

/* 1) Non-Clustered Index on customers.email */
CREATE NONCLUSTERED INDEX IX_Customers_Email
ON sales.customers(email);

/* 2) Composite Index on products (category_id, brand_id) */
CREATE NONCLUSTERED INDEX IX_Products_Category_Brand
ON production.products(category_id, brand_id);

/* 3) Index on orders.order_date with INCLUDED columns */
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
ON sales.orders(order_date)
INCLUDE (customer_id, store_id, order_status);


/* =====================================================
REQUIRED TABLES FOR TRIGGERS
===================================================== */

/* Customer activity log */
CREATE TABLE sales.customer_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    action VARCHAR(50),
    log_date DATETIME DEFAULT GETDATE()
);

/* Price history tracking */
CREATE TABLE production.price_history (
    history_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    change_date DATETIME DEFAULT GETDATE(),
    changed_by VARCHAR(100)
);

/* Order audit trail */
CREATE TABLE sales.order_audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    customer_id INT,
    store_id INT,
    staff_id INT,
    order_date DATE,
    audit_timestamp DATETIME DEFAULT GETDATE()
);


/* =====================================================
TRIGGERS
===================================================== */

/* 4) Welcome log after inserting new customer */
CREATE TRIGGER trg_NewCustomer_Log
ON sales.customers
AFTER INSERT
AS
INSERT INTO sales.customer_log (customer_id, action)
SELECT customer_id, 'WELCOME'
FROM inserted;

/* 5) Track product price changes */
CREATE TRIGGER trg_ProductPrice_Change
ON production.products
AFTER UPDATE
AS
IF UPDATE(list_price)
BEGIN
    INSERT INTO production.price_history
    (product_id, old_price, new_price, changed_by)
    SELECT i.product_id, d.list_price, i.list_price, SYSTEM_USER
    FROM inserted i
    JOIN deleted d ON i.product_id = d.product_id
    WHERE i.list_price <> d.list_price;
END;

/* 6) INSTEAD OF DELETE – prevent deleting categories with products */
CREATE TRIGGER trg_PreventCategoryDelete
ON production.categories
INSTEAD OF DELETE
AS
IF EXISTS (
    SELECT 1
    FROM production.products p
    JOIN deleted d ON p.category_id = d.category_id
)
BEGIN
    RAISERROR ('Cannot delete category with existing products',16,1);
END
ELSE
BEGIN
    DELETE FROM production.categories
    WHERE category_id IN (SELECT category_id FROM deleted);
END;

/* 7) Reduce stock when order item inserted */
CREATE TRIGGER trg_OrderItem_UpdateStock
ON sales.order_items
AFTER INSERT
AS
UPDATE s
SET s.quantity = s.quantity - i.quantity
FROM production.stocks s
JOIN inserted i ON s.product_id = i.product_id
AND s.store_id = i.store_id;

/* 8) Audit new orders */
CREATE TRIGGER trg_NewOrder_Audit
ON sales.orders
AFTER INSERT
AS
INSERT INTO sales.order_audit
(order_id, customer_id, store_id, staff_id, order_date)
SELECT order_id, customer_id, store_id, staff_id, order_date
FROM inserted;
