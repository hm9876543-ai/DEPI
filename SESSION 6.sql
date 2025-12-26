/* =========================
1) Customer Spending
========================= */
DECLARE @CustID INT=1,@TotalSpent DECIMAL(10,2);
SELECT @TotalSpent=SUM(TotalAmount) FROM Orders WHERE CustomerID=@CustID;
PRINT CASE WHEN @TotalSpent>5000 THEN 'VIP Customer' ELSE 'Regular Customer' END;

/* =========================
2) Price Threshold
========================= */
DECLARE @Threshold DECIMAL(10,2)=1500,@ProdCount INT;
SELECT @ProdCount=COUNT(*) FROM Products WHERE ListPrice>@Threshold;
PRINT 'Threshold='+CAST(@Threshold AS VARCHAR)+' Count='+CAST(@ProdCount AS VARCHAR);

/* =========================
3) Staff Performance
========================= */
DECLARE @StaffID INT=2,@Year INT=2017,@Sales DECIMAL(10,2);
SELECT @Sales=SUM(TotalAmount)
FROM Orders WHERE StaffID=@StaffID AND YEAR(OrderDate)=@Year;
PRINT 'Staff='+CAST(@StaffID AS VARCHAR)+' Sales='+CAST(ISNULL(@Sales,0) AS VARCHAR);

/* =========================
4) Global Variables
========================= */
SELECT @@SERVERNAME AS ServerName, @@VERSION AS Version, @@ROWCOUNT AS RowsAffected;

/* =========================
5) Inventory IF
========================= */
DECLARE @Qty INT;
SELECT @Qty=Quantity FROM Inventory WHERE ProductID=1 AND StoreID=1;
IF @Qty>20 PRINT 'Well stocked'
ELSE IF @Qty BETWEEN 10 AND 20 PRINT 'Moderate stock'
ELSE PRINT 'Low stock - reorder needed';

/* =========================
6) WHILE Batch Restock
========================= */
WHILE EXISTS (SELECT 1 FROM Inventory WHERE Quantity<5)
BEGIN
 UPDATE TOP (3) Inventory SET Quantity+=10 WHERE Quantity<5;
 PRINT 'Batch updated: '+CAST(@@ROWCOUNT AS VARCHAR);
END;

/* =========================
7) CASE Categorization
========================= */
SELECT ProductName,ListPrice,
CASE
 WHEN ListPrice<300 THEN 'Budget'
 WHEN ListPrice BETWEEN 300 AND 800 THEN 'Mid-Range'
 WHEN ListPrice BETWEEN 801 AND 2000 THEN 'Premium'
 ELSE 'Luxury' END AS PriceCategory
FROM Products;

/* =========================
8) Customer Validation
========================= */
IF EXISTS (SELECT 1 FROM Customers WHERE CustomerID=5)
 SELECT COUNT(*) AS OrderCount FROM Orders WHERE CustomerID=5;
ELSE PRINT 'Customer not found';

/* =========================
9) Shipping Function
========================= */
CREATE FUNCTION CalculateShipping(@Total DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS BEGIN
 RETURN CASE
  WHEN @Total>100 THEN 0
  WHEN @Total BETWEEN 50 AND 99 THEN 5.99
  ELSE 12.99 END
END;

/* =========================
10) Inline TVF
========================= */
CREATE FUNCTION GetProductsByPriceRange(@Min DECIMAL(10,2),@Max DECIMAL(10,2))
RETURNS TABLE
AS RETURN
SELECT p.ProductName,p.ListPrice,b.BrandName,c.CategoryName
FROM Products p
JOIN Brands b ON p.BrandID=b.BrandID
JOIN Categories c ON p.CategoryID=c.CategoryID
WHERE p.ListPrice BETWEEN @Min AND @Max;

/* =========================
11) Multi-Statement Function
========================= */
CREATE FUNCTION GetCustomerYearlySummary(@CID INT)
RETURNS @R TABLE(Year INT,TotalOrders INT,TotalSpent DECIMAL(10,2),AvgOrder DECIMAL(10,2))
AS BEGIN
 INSERT INTO @R
 SELECT YEAR(OrderDate),COUNT(*),SUM(TotalAmount),AVG(TotalAmount)
 FROM Orders WHERE CustomerID=@CID
 GROUP BY YEAR(OrderDate);
 RETURN;
END;

/* =========================
12) Discount Function
========================= */
CREATE FUNCTION CalculateBulkDiscount(@Q INT)
RETURNS INT
AS BEGIN
 RETURN CASE
  WHEN @Q BETWEEN 1 AND 2 THEN 0
  WHEN @Q BETWEEN 3 AND 5 THEN 5
  WHEN @Q BETWEEN 6 AND 9 THEN 10
  ELSE 15 END
END;

/* =========================
13) Order History Proc
========================= */
CREATE PROC sp_GetCustomerOrderHistory
@CID INT,@Start DATE=NULL,@End DATE=NULL
AS
SELECT o.OrderID,o.OrderDate,
SUM(oi.Quantity*oi.UnitPrice) AS OrderTotal
FROM Orders o JOIN OrderItems oi ON o.OrderID=oi.OrderID
WHERE o.CustomerID=@CID
AND (@Start IS NULL OR o.OrderDate>=@Start)
AND (@End IS NULL OR o.OrderDate<=@End)
GROUP BY o.OrderID,o.OrderDate;

/* =========================
14) Restock Proc
========================= */
CREATE PROC sp_RestockProduct
@StoreID INT,@ProductID INT,@Qty INT,
@OldQty INT OUTPUT,@NewQty INT OUTPUT,@Success BIT OUTPUT
AS
SELECT @OldQty=Quantity FROM Inventory WHERE StoreID=@StoreID AND ProductID=@ProductID;
UPDATE Inventory SET Quantity+=@Qty WHERE StoreID=@StoreID AND ProductID=@ProductID;
SELECT @NewQty=Quantity FROM Inventory WHERE StoreID=@StoreID AND ProductID=@ProductID;
SET @Success=1;

/* =========================
15) Process Order (Transaction)
========================= */
CREATE PROC sp_ProcessNewOrder
@CID INT,@PID INT,@Qty INT,@Store INT
AS BEGIN TRY
 BEGIN TRAN
 INSERT INTO Orders(CustomerID,OrderDate) VALUES(@CID,GETDATE());
 DECLARE @OID INT=SCOPE_IDENTITY();
 INSERT INTO OrderItems(OrderID,ProductID,Quantity) VALUES(@OID,@PID,@Qty);
 UPDATE Inventory SET Quantity-=@Qty WHERE ProductID=@PID AND StoreID=@Store;
 COMMIT
END TRY
BEGIN CATCH
 ROLLBACK
 THROW
END CATCH;

/* =========================
16) Dynamic Search
========================= */
CREATE PROC sp_SearchProducts
@Name NVARCHAR(50)=NULL,@Cat INT=NULL,@Min DECIMAL(10,2)=NULL,@Max DECIMAL(10,2)=NULL,@Sort NVARCHAR(50)='ListPrice'
AS
DECLARE @SQL NVARCHAR(MAX)='SELECT * FROM Products WHERE 1=1';
IF @Name IS NOT NULL SET @SQL+=' AND ProductName LIKE ''%'+@Name+'%''';
IF @Cat IS NOT NULL SET @SQL+=' AND CategoryID='+CAST(@Cat AS VARCHAR);
IF @Min IS NOT NULL SET @SQL+=' AND ListPrice>='+CAST(@Min AS VARCHAR);
IF @Max IS NOT NULL SET @SQL+=' AND ListPrice<='+CAST(@Max AS VARCHAR);
SET @SQL+=' ORDER BY '+@Sort;
EXEC(@SQL);

/* =========================
17) Staff Bonus System
========================= */
DECLARE @Start DATE='2017-01-01',@End DATE='2017-03-31';
SELECT StaffID,SUM(TotalAmount) Sales,
CASE
 WHEN SUM(TotalAmount)>50000 THEN SUM(TotalAmount)*0.10
 WHEN SUM(TotalAmount)>20000 THEN SUM(TotalAmount)*0.05
 ELSE SUM(TotalAmount)*0.02 END AS Bonus
FROM Orders WHERE OrderDate BETWEEN @Start AND @End
GROUP BY StaffID;

/* =========================
18) Smart Inventory
========================= */
DECLARE @CatID INT;
SELECT @Qty=Quantity,@CatID=CategoryID
FROM Inventory i JOIN Products p ON i.ProductID=p.ProductID
WHERE i.ProductID=1;
IF @Qty<5
 IF @CatID=1 UPDATE Inventory SET Quantity+=50 WHERE ProductID=1
 ELSE UPDATE Inventory SET Quantity+=20 WHERE ProductID=1;

/* =========================
19) Loyalty Tier
========================= */
SELECT c.CustomerID,
CASE
 WHEN SUM(o.TotalAmount) IS NULL THEN 'No Orders'
 WHEN SUM(o.TotalAmount)>10000 THEN 'Platinum'
 WHEN SUM(o.TotalAmount)>5000 THEN 'Gold'
 ELSE 'Silver' END AS LoyaltyTier
FROM Customers c LEFT JOIN Orders o ON c.CustomerID=o.CustomerID
GROUP BY c.CustomerID;

/* =========================
20) Product Lifecycle
========================= */
CREATE PROC sp_DiscontinueProduct @PID INT
AS
IF EXISTS (SELECT 1 FROM OrderItems WHERE ProductID=@PID)
 PRINT 'Pending orders exist'
ELSE
BEGIN
 DELETE FROM Inventory WHERE ProductID=@PID;
 UPDATE Products SET IsDiscontinued=1 WHERE ProductID=@PID;
 PRINT 'Product discontinued'
END;

/* =========================
21) Advanced Analytics
========================= */
SELECT YEAR(o.OrderDate) Y,MONTH(o.OrderDate) M,
s.StaffID,c.CategoryName,
SUM(oi.Quantity*oi.UnitPrice) Sales
FROM Orders o
JOIN OrderItems oi ON o.OrderID=oi.OrderID
JOIN Products p ON oi.ProductID=p.ProductID
JOIN Categories c ON p.CategoryID=c.CategoryID
JOIN Staff s ON o.StaffID=s.StaffID
GROUP BY YEAR(o.OrderDate),MONTH(o.OrderDate),s.StaffID,c.CategoryName;

/* =========================
22) Data Validation
========================= */
CREATE PROC sp_ValidateInsertOrder
@CID INT,@PID INT,@Qty INT
AS
IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID=@CID)
 THROW 50000,'Invalid Customer',1;
IF NOT EXISTS (SELECT 1 FROM Inventory WHERE ProductID=@PID AND Quantity>=@Qty)
 THROW 50001,'Insufficient Stock',1;
INSERT INTO Orders(CustomerID,OrderDate) VALUES(@CID,GETDATE());
