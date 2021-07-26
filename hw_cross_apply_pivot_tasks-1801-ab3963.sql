/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select *
from (
	select
		format(dateadd(day, 1, eomonth(i.InvoiceDate,-1)), 'dd.MM.yyyy') as InvoiceMonth
		,substring(sc.CustomerName, charindex('(', sc.CustomerName) + 1, charindex(')', sc.CustomerName) - charindex('(', sc.CustomerName) - 1) as CustomerName
		,1 as cnt
	from Sales.Invoices as i
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
		inner join Sales.Customers as sc on sc.CustomerID = i.CustomerID
	where i.CustomerID between 2 and 6
) as src
pivot (
	count(cnt) for CustomerName in ([Peeples Valley, AZ], [Sylvanite, MT], [Jessie, ND], [Gasport, NY], [Medicine Lodge, KS])
) as pvt


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select upvt.CustomerName, upvt.AddressLine
from (
	select
		sc.CustomerName
		,sc.PostalAddressLine1
		,sc.PostalAddressLine2
	from Sales.Customers as sc
	where sc.CustomerName like '%Tailspin Toys%'
) as src
unpivot (AddressLine for AddLine in (PostalAddressLine1, PostalAddressLine2)) as upvt


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select upvt.CountryID, upvt.CountryName, Code
from (
	select
		ac.CountryID
		,ac.CountryName
		,cast(ac.IsoAlpha3Code as varchar(max)) as IsoAlpha3Code
		,cast(ac.IsoNumericCode as varchar(max)) as IsoNumericCode
	from Application.Countries as ac
) as src
unpivot (Code for CodeFrom in (IsoAlpha3Code, IsoNumericCode)) as upvt

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select
	c.CustomerID
	,c.CustomerName
	,ca.StockItemID
	,ca.UnitPrice
	,ca.InvoiceDate
from Sales.Customers as c
cross apply (
	select top 2 i.InvoiceDate, il.StockItemID, il.UnitPrice
	from Sales.Invoices as i
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	where i.CustomerID = c.CustomerID
	order by il.UnitPrice desc
) as ca
