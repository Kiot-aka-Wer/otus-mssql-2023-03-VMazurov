set statistics io, time on;

--Добавляем недостающий индекс
drop index if exists FK_Sales_Invoices_OrderID_TEST on Sales.Invoices;
create index FK_Sales_Invoices_OrderID_TEST on Sales.Invoices(OrderID) include (CustomerID, BillToCustomerID, InvoiceDate);

Select     ord.CustomerID
    , det.StockItemID
    , SUM(det.UnitPrice)
    , SUM(det.Quantity)
    , COUNT(ord.OrderID)
FROM
    Sales.Orders AS ord
    JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
    JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
    JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
    JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
WHERE
    Inv.BillToCustomerID != ord.CustomerID
    AND (Select
            SupplierId
        FROM Warehouse.StockItems AS It
        Where It.StockItemID = det.StockItemID) = 12
    AND (SELECT
            SUM(Total.UnitPrice*Total.Quantity)
        FROM Sales.OrderLines AS Total
            Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
        WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
    AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY
    ord.CustomerID
    , det.StockItemID
ORDER BY
    ord.CustomerID
    , det.StockItemID;

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 137 ms, elapsed time = 137 ms.

(3619 rows affected)
Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 29, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 331, lob physical reads 0, lob read-ahead reads 0.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 883, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 224, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 907 ms,  elapsed time = 1264 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/

with cte as (
    select distinct
        o.CustomerID
    from Sales.Orders as o
        inner join Sales.OrderLines as ol on ol.OrderID = o.OrderID
    group by o.CustomerID
    having sum(ol.UnitPrice * ol.Quantity)> 250000
)

select
    ord.CustomerID
    ,det.StockItemID
    ,sum(det.UnitPrice)
    ,sum(det.Quantity)
    ,count(ord.OrderID)
FROM Sales.Orders as ord
    inner join Sales.OrderLines as det on det.OrderID = ord.OrderID
    inner join Warehouse.StockItems as si on si.StockItemID = det.StockItemID
        and si.SupplierId = 12
    inner join Sales.Invoices as Inv on Inv.OrderID = ord.OrderID
    inner join cte as c on c.CustomerID = Inv.CustomerID
    inner join Sales.CustomerTransactions as Trans on Trans.InvoiceID = Inv.InvoiceID
    inner hash join Warehouse.StockItemTransactions as ItemTrans on ItemTrans.StockItemID = det.StockItemID
where Inv.BillToCustomerID != ord.CustomerID
    and datediff(dd, Inv.InvoiceDate, ord.OrderDate) = 0
group by ord.CustomerID
	,det.StockItemID;

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
Warning: The join order has been enforced because a local join hint is used.
SQL Server parse and compile time: 
   CPU time = 60 ms, elapsed time = 60 ms.

(3619 rows affected)
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItemTransactions'. Scan count 8, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 58, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'OrderLines'. Scan count 32, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 662, lob physical reads 0, lob read-ahead reads 0.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'CustomerTransactions'. Scan count 11, logical reads 696, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 18, logical reads 1293, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 9, logical reads 668, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 1110 ms,  elapsed time = 1084 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/