/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

----TODO: напишите здесь свое решение
select
	si.StockItemID
	,si.StockItemName
from  Warehouse.StockItems as si
where (si.StockItemName like '%urgent%'
	or si.StockItemName like 'Animal%')

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

----TODO: напишите здесь свое решение
select
	s.SupplierID
	,s.SupplierName
from Purchasing.Suppliers as s
	left join Purchasing.PurchaseOrders as po on po.SupplierID = s.SupplierID
where po.SupplierID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

--TODO: напишите здесь свое решение

select distinct
	o.OrderID
	,convert(date, o.OrderDate, 104) as OrderDate
	,datename(month, o.OrderDate) as [MonthName]
	,datepart(quarter, o.OrderDate) as [quarter]
	,case 
		when month(o.OrderDate) between 1 and 4 then 1
		when month(o.OrderDate) between 5 and 8 then 2
		when month(o.OrderDate) between 9 and 12 then 3
	 end as ThirdOfYearNo
	,c.CustomerName
from Sales.Orders as o
	inner join Sales.OrderLines as ol on ol.OrderID = o.OrderID
		and (ol.UnitPrice >= 100.00 or (ol.Quantity > 20 and o.PickingCompletedWhen is not null))
	inner join Sales.Customers as c on c.CustomerID = o.CustomerID
order by o.OrderDate

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

--TODO: напишите здесь свое решение

select
	dm.DeliveryMethodName
	,po.ExpectedDeliveryDate
	,s.SupplierName
	,p.FullName
from Purchasing.Suppliers as s
	inner join Purchasing.PurchaseOrders as po on po.SupplierID = s.SupplierID
		--and convert(varchar(6), po.ExpectedDeliveryDate, 112) = '201301'
		and po.IsOrderFinalized = 1
	inner join Application.DeliveryMethods as dm on dm.DeliveryMethodID = po.DeliveryMethodID
		--and dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
	inner join Application.People as p on p.PersonID = po.ContactPersonID

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

--TODO: напишите здесь свое решение

select top 10 so.*, sc.CustomerName, ap.FullName
from sales.Orders as so
inner join sales.Customers as sc on sc.CustomerID = so.CustomerID
inner join Application.People as ap on ap.PersonID = so.SalespersonPersonID
order by so.OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

--TODO: напишите здесь свое решение
select distinct sc.CustomerID, sc.CustomerName, sc.PhoneNumber
from sales.Orders as so
	inner join sales.OrderLines as ol on ol.OrderID = so.OrderID
		and ol.Description = 'Chocolate frogs 250g'
	inner join sales.Customers as sc on sc.CustomerID = so.CustomerID
order by sc.CustomerID

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--TODO: напишите здесь свое решение

select
	year(i.InvoiceDate) as Year
	,month(i.invoiceDate) as Month
	,avg(il.UnitPrice) as AvgUnitPrice
	,sum(il.ExtendedPrice) as SalesValue
from Sales.Invoices as i
	inner join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by
	year(i.InvoiceDate)
	,month(i.invoiceDate)

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--TODO: напишите здесь свое решение
select
	year(i.InvoiceDate) as Year
	,month(i.invoiceDate) as Month
	,sum(il.ExtendedPrice) as SalesValue
from Sales.Invoices as i
	inner join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by year(i.InvoiceDate), month(i.invoiceDate)
having sum(il.ExtendedPrice) > 10000

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--TODO: напишите здесь свое решение
select
	year(i.InvoiceDate) as Year
	,month(i.invoiceDate) as Month
	,il.Description as ProductName
	,sum(il.ExtendedPrice) as SalesValue
	,min(i.InvoiceDate) as FirstSalesDAte
	,sum(il.Quantity) as Qty
from Sales.Invoices as i
	inner join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by
	year(i.InvoiceDate)
	,month(i.invoiceDate)
	,il.Description
having sum(il.Quantity) < 50

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
