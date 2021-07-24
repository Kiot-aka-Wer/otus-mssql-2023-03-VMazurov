/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select
	p.PersonID
	,p.FullName
from Application.People as p
	left join Sales.Invoices as i on i.SalespersonPersonID = p.PersonID
		and i.InvoiceDate = '20150704'
where p.IsSalesPerson = 1
	and i.InvoiceID is null


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

--Надеюсь правильно понял задание, что имелась ввиду цена в заказе
	--select distinct
	--	il.Description
	--	--,il.UnitPrice
	--	,min(il.UnitPrice)
	--from sales.InvoiceLines as il
	--order by il.Description, il.UnitPrice asc

--select distinct
--	ac.CityID
--	,ac.CityName
--	,p.FullName
--from sales.Invoices as i
--	inner join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
--	inner join cte as c on c.Description = il.Description

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

select distinct vt.*
from (
	select top 5 p.*
	from Sales.CustomerTransactions as ct
		inner join sales.Invoices as i on i.InvoiceID = ct.InvoiceID
		inner join Application.People as p on p.PersonID = i.AccountsPersonID
	order by ct.TransactionAmount desc
) as vt


;with cte as (
	select top 5 p.*
	from Sales.CustomerTransactions as ct
		inner join sales.Invoices as i on i.InvoiceID = ct.InvoiceID
		inner join Application.People as p on p.PersonID = i.AccountsPersonID
	order by ct.TransactionAmount desc
)
select distinct c.*
from cte as c


;with cte as (
	select top 5 i.AccountsPersonID
	from Sales.CustomerTransactions as ct
		inner join sales.Invoices as i on i.InvoiceID = ct.InvoiceID
	order by ct.TransactionAmount desc
)
select distinct p.*
from cte as c
	inner join Application.People as p on p.PersonID = c.AccountsPersonID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

with cte as (
	select distinct top 3
		il.Description
		,il.UnitPrice
	from sales.InvoiceLines as il
	order by il.UnitPrice desc
)

select distinct
	ac.CityID
	,ac.CityName
	,p.FullName
from sales.Invoices as i
	inner join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	inner join cte as c on c.Description = il.Description
	inner join Application.People as p on p.PersonID = i.PackedByPersonID
	inner join sales.Customers as sc on sc.CustomerID = i.CustomerID
	inner join Application.Cities as ac on ac.CityID = sc.DeliveryCityID

/*
*/


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

-- --

with cte as (
	select
		InvoiceId
		,sum(il.Quantity * il.UnitPrice) as TotalSumm
	from Sales.InvoiceLines as il
	group by InvoiceId
	having sum(il.Quantity * il.UnitPrice) > 27000
)

select 
	i.InvoiceID
	,i.InvoiceDate
	,p.FullName as SalesPersonName
	,SalesTotals.TotalSumm as TotalSummByInvoice
	,sum(ol.PickedQuantity * ol.UnitPrice) as TotalSummForPickedItems
from Sales.Invoices as i
	inner join cte as SalesTotals ON SalesTotals.InvoiceID = i.InvoiceID
	left join Sales.Orders as o on o.OrderId = i.OrderId
		and o.PickingCompletedWhen is not null
	left join Sales.OrderLines as ol on ol.OrderID = o.OrderId
	left join Application.People as p on p.PersonID = i.SalespersonPersonID
group by
	i.InvoiceID
	,i.InvoiceDate
	,p.FullName
	,SalesTotals.TotalSumm
order by TotalSumm desc

