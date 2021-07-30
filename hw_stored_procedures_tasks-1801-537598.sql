/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".
Задания выполняются с использованием базы данных WideWorldImporters.
Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak
Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters
go

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

create or alter function Sales.udf_GetCustomerMaxInvoiceSum()
returns int
as
begin
	declare @CustomerId int;

	select top 1 @CustomerId = vt.customerid
	from (
		select
			i.customerid
			,sum(il.extendedprice) as total
		from Sales.Invoices as i
			inner join Sales.InvoiceLines as il on i.invoiceid = il.invoiceid
		group by i.invoiceid
			,i.customerid
	) as vt
	order by total desc

	return @customerid;
end;
go

select Sales.udf_GetCustomerMaxInvoiceSum()
go

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

create or alter procedure Sales.usp_GetCustomerInvoiceSum (@CustomerID int)
as
begin
	--set nocount on;

	select sum(il.extendedprice) as InvoiceSum
	from Sales.Invoices as i
		inner join Sales.InvoiceLines as il on i.invoiceid = il.invoiceid
	where i.CustomerID = @CustomerID
end;
go

exec Sales.usp_GetCustomerInvoiceSum @CustomerID = 834
exec Sales.usp_GetCustomerInvoiceSum @CustomerID = 150
go


/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

create or alter function Sales.udf_GetCustomerInvoiceSum(@CustomerID int)
returns decimal(18,2)
as
begin
	declare @InvoiceSum decimal(18,2);

	select @InvoiceSum = isnull(sum(il.extendedprice),0)
	from Sales.Invoices i
		inner join Sales.InvoiceLines il on i.invoiceid = il.invoiceid
	where i.CustomerID = @CustomerID

	return @InvoiceSum;
end;
go

select [Sales].[udf_GetCustomerInvoiceSum](150)
go

set statistics io, time on;

exec Sales.usp_GetCustomerInvoiceSum 150
select Sales.udf_GetCustomerInvoiceSum(150) as InvoiceSum

set statistics io, time off;

--Функция быстрее. На сколько понимаю в случае с хранимой процедурой проблема в построении планов запроса.

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

create or alter function Sales.udf_GetCustomerInvoicesPiecesCount (@CustomerID int)
returns table
as
return (
	select sum(il.Quantity) as InvoicesPiecesCount
	from Sales.Invoices i
		inner join Sales.InvoiceLines il on i.invoiceid = il.invoiceid
	where i.CustomerID = @CustomerID
)
go

select 
	c.CustomerID
	,c.CustomerName
	,s.InvoicesPiecesCount
from Sales.Customers as c
	cross apply Sales.udf_GetCustomerInvoicesPiecesCount(c.CustomerID) s
go

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/