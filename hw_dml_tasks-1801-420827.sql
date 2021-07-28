/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
--max id - 1066

insert into Sales.Customers (CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID
	,AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent
	,IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode
	,DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
select top 5
	CustomerName + '_new', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID
	,AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent
	,IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode
	,DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
from Sales.Customers

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from Sales.Customers
where CustomerID = (select max(CustomerID) from Sales.Customers)


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update Sales.Customers
	set CustomerName = CustomerName + '_Updated'
where CustomerID = (select max(CustomerID) from Sales.Customers)

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
merge Sales.Customers as target
using (select
		CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID
		,AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent
		,IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode
		,DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
	from Sales.Customers as c
	where c.CustomerName like '%_New') as source
ON target.CustomerName = source.CustomerName
when not matched by target then 
insert (CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID
		,AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent
		,IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode
		,DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy) 
VALUES (
		source.CustomerName, source.BillToCustomerID, source.CustomerCategoryID, source.BuyingGroupID, source.PrimaryContactPersonID
		,source.AlternateContactPersonID, source.DeliveryMethodID, source.DeliveryCityID, source.PostalCityID, source.CreditLimit, source.AccountOpenedDate, source.StandardDiscountPercentage, source.IsStatementSent
		,source.IsOnCreditHold, source.PaymentDays, source.PhoneNumber, source.FaxNumber, source.DeliveryRun, source.RunPosition, source.WebsiteURL, source.DeliveryAddressLine1, source.DeliveryAddressLine2, source.DeliveryPostalCode
		,source.DeliveryLocation, source.PostalAddressLine1, source.PostalAddressLine2, source.PostalPostalCode, source.LastEditedBy)
when matched then update
set  target.BillToCustomerID			= source.BillToCustomerID
	,target.CustomerCategoryID			= source.CustomerCategoryID
	,target.PrimaryContactPersonID		= source.PrimaryContactPersonID
	,target.DeliveryMethodID			= source.DeliveryMethodID
	,target.DeliveryCityID				= source.DeliveryCityID
	,target.PostalCityID				= source.PostalCityID
	,target.AccountOpenedDate			= source.AccountOpenedDate
	,target.StandardDiscountPercentage	= source.StandardDiscountPercentage
	,target.IsStatementSent				= source.IsStatementSent
	,target.IsOnCreditHold				= source.IsOnCreditHold
	,target.PaymentDays					= source.PaymentDays
	,target.PhoneNumber					= source.PhoneNumber
	,target.FaxNumber					= source.FaxNumber
	,target.WebsiteURL					= source.WebsiteURL
	,target.DeliveryAddressLine1		= source.DeliveryAddressLine1
	,target.DeliveryPostalCode			= source.DeliveryPostalCode
	,target.PostalAddressLine1			= source.PostalAddressLine1
	,target.PostalPostalCode			= source.PostalPostalCode
	,target.LastEditedBy				= source.LastEditedBy;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

exec master.dbo.xp_cmdshell 'bcp "select c.CustomerName,c.BillToCustomerID ,c.CustomerCategoryID,c.PrimaryContactPersonID,c.DeliveryMethodID,c.DeliveryCityID,c.PostalCityID,c.AccountOpenedDate,c.StandardDiscountPercentage,c.IsStatementSent,c.IsOnCreditHold,c.PaymentDays,c.PhoneNumber,c.FaxNumber,c.WebsiteURL,c.DeliveryAddressLine1,c.DeliveryPostalCode,c.PostalAddressLine1,c.PostalPostalCode,c.LastEditedBy from WideWorldImporters.Sales.Customers c where c.customername like ''%[_]New''" queryout  C:\customers.txt -T -c -t ; -S localhost\SQL2017;'

--Загрузка
drop table if exists Sales.Customers_bcp

create table Sales.Customers_bcp(
	CustomerName nvarchar(100) not null,
	BillToCustomerID int not null,
	CustomerCategoryID int not null,
	PrimaryContactPersonID int not null,
	DeliveryMethodID int not null,
	DeliveryCityID int not null,
	PostalCityID int not null,
	AccountOpenedDate date not null,
	StandardDiscountPercentage decimal(18, 3) not null,
	IsStatementSent bit not null,
	IsOnCreditHold bit not null,
	PaymentDays int not null,
	PhoneNumber nvarchar(20) not null,
	FaxNumber nvarchar(20) not null,
	WebsiteURL nvarchar(256) not null,
	DeliveryAddressLine1 nvarchar(60) not null,
	DeliveryPostalCode nvarchar(10) not null,
	PostalAddressLine1 nvarchar(60) not null,
	PostalPostalCode nvarchar(10) not null,
	LastEditedBy int not null,
	CONSTRAINT UQ_Sales_Customers_bcp_CustomerName UNIQUE NONCLUSTERED 
(
	CustomerName ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON userdata,
	
) ON userdata
GO

BULK INSERT WideWorldImporters.Sales.Customers_bcp
	FROM 'C:\customers.txt'
	WITH 
		(
			batchsize = 1000, 
			datafiletype = 'widechar',
			fieldterminator = ';',
			rowterminator ='\n',
			keepnulls,
			tablock
		);