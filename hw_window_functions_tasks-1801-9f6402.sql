/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29	 | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
set statistics time, io on;

;with cte as (
	select
		i.InvoiceDate
		,year(i.InvoiceDate) as yr
		,month(i.InvoiceDate) as mth
		,sum(il.UnitPrice * il.Quantity) as Value
	from Sales.Invoices as i
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	where year(i.InvoiceDate) = 2015
	group by i.InvoiceDate
)

select
	c1.InvoiceDate
	,sum(c2.Value) as ValueTotal
from cte as c1
	inner join cte as c2 on c2.yr = c1.yr
		and c2.mth <= c1.mth
group by datefromparts(c1.yr, c1.mth, '01')
	,c1.InvoiceDate
order by c1.InvoiceDate


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select distinct vt.InvoiceDate, max(vt.Value) over (partition by vt.mth) as value
from (
	select-- distinct
		i.InvoiceDate
		,month(i.InvoiceDate) as mth
		,sum(il.UnitPrice * il.Quantity) over (order by i.InvoiceDate rows between unbounded preceding and current row) as Value
		--,sum(il.UnitPrice * il.Quantity) over (partition by month(i.InvoiceDate)) as Value
	from Sales.Invoices as i
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	where year(i.InvoiceDate) = 2015
	--order by i.InvoiceDate
) as vt
order by vt.InvoiceDate


set statistics time, io off;
--С оконными функциями меньше чтений, больше процесорного времени

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select *
from (
	select
		month(i.InvoiceDate) as mth
		,il.StockItemID
		,il.Description
		--,sum(il.Quantity) as qnt
		,row_number() over (partition by month(i.InvoiceDate) order by sum(il.Quantity) desc) as rn
	from sales.Invoices as i
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	where year(i.InvoiceDate) = 2016
	group by month(i.InvoiceDate)
		,il.StockItemID
		,il.Description
) as vt
where vt.rn <= 2

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select
	si.StockItemID
	,si.StockItemName
	,si.Brand
	,si.UnitPrice
	,row_number() over (partition by left(si.StockItemName, 1) order by si.StockItemName) as rn
	,count(*) over (partition by null) as cnt
	,count(*) over (partition by left(si.StockItemName, 1)) as cnt_by_first_symbol
	,lead(si.StockItemID) over (partition by null ORDER BY si.StockItemName) as NextID
	,lag(si.StockItemID) over (partition by null ORDER BY si.StockItemName) as NextID
	,lag(si.StockItemName, 2, 'No items') over (partition by null ORDER BY si.StockItemName) as NextID
	,ntile(30) over (order by si.TypicalWeightPerUnit)
from Warehouse.StockItems as si

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select
	InvoiceDate
	,PersonID
	,FullName
	,CustomerID
	,CustomerName
	,Value
from (
	select
		i.InvoiceDate
		,p.PersonID
		,p.FullName
		,c.CustomerID
		,c.CustomerName
		,sum(il.UnitPrice * il.Quantity) over (partition by il.InvoiceID) as Value
		,row_number() over (partition by p.PersonID order by i.InvoiceDate desc) as rn
	from Sales.Invoices as i
		inner join Application.People as p on p.PersonID = i.SalespersonPersonID
		inner join Sales.Customers as c on c.CustomerID = i.CustomerID
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
) as vt
where vt.rn = 1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;with cte as (
	select distinct
		c.CustomerID
		,c.CustomerName
		,il.StockItemID
		,il.UnitPrice
		,max(i.InvoiceDate) over (partition by c.CustomerID, il.StockItemID) as InvoiceDate
	from Sales.Invoices as i
		inner join Sales.Customers as c on c.CustomerID = i.CustomerID
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
)

select
	CustomerID
	,CustomerName
	,StockItemID
	,UnitPrice
	,InvoiceDate
from (
	select
		 c.CustomerID
		,c.CustomerName
		,c.StockItemID
		,c.UnitPrice
		,c.InvoiceDate
		,row_number() over (partition by c.CustomerID order by c.UnitPrice desc) as rn
	from cte as c
) as vt
where vt.rn <= 2

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 