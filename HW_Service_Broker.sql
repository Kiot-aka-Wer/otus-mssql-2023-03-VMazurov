create table Sales.InvoicesReport(
	InvoicesReportID int identity(1,1) not null,
	CustomerID int not null,
	OrdersCount int not null,
	ReportDateTime datetime2(7) not null default (sysdatetime()),
constraint PK_Sales_InvoicesReport primary key clustered
(
	InvoicesReportID
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
go

alter table Sales.InvoicesReport with check add constraint FK_Sales_InvoicesReport_CustomerID_Sales_Customers foreign key(CustomerID)
references Sales.Customers (CustomerID)
go

alter table Sales.InvoicesReport check constraint FK_Sales_InvoicesReport_CustomerID_Sales_Customers
go

--Таблица с ответами
create table Sales.InvoicesReport_Reply(
	InvoicesReport_ReplyID int identity(1,1) not null,
	ReplyText nvarchar(255) not null,
	ReplyTime datetime2(7) not null default (sysdatetime()),
constraint PK_Sales_InvoicesReport_Reply primary key clustered 
(
	InvoicesReport_ReplyID
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
go

--Хранимка формирования и отправки запроса
create procedure Sales.SendInvoicesReport
	@CustomerID INT
	,@Datebegin date
	,@Dateend date
as
begin
	set nocount on;

    --Sending a Request Message to the Target	
	declare @InitDlgHandle uniqueidentifier --open init dialog
		,@RequestMessage nvarchar(4000); --сообщение, которое будем отправлять
	
	begin tran
		--Prepare the Message  !!!auto generate XML
		select @RequestMessage = (select 
									CustomerID
									,@Datebegin as Datebegin
									,@Dateend as Dateend
								  from Sales.Customers AS Cu
								  where CustomerID = @CustomerID
								  for xml auto, root('RequestMessage')); 
	
		--Determine the Initiator Service, Target Service and the Contract 
		begin DIALOG @InitDlgHandle
		from service
		[//WWI/SB/InitiatorService]
		to service
		'//WWI/SB/TargetService'
		on contract
		[//WWI/SB/Contract]
		with encryption=off;

		--Send the Message
		send on conversation @InitDlgHandle 
		message type
		[//WWI/SB/RequestMessage]
		(@RequestMessage);
	commit tran 
end
go

--Процедура обработки запроса
create procedure Sales.GetInvoicesReport
as
begin

	declare @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@CustomerID INT,
			@Datebegin date,
			@Dateend   date,
			@InvoicesReportID int,
			@xml XML; 
	
	begin tran;
		receive top(1)
			@TargetDlgHandle = Conversation_Handle,
			@Message = Message_Body,
			@MessageType = Message_Type_Name
		FROM dbo.TargetQueueWWI;

		SET @xml = CAST(@Message AS XML);

		--получаем InvoiceID из xml
		select
			@CustomerID = R.Cu.value('@CustomerID','INT')
			,@Datebegin = R.Cu.value('@Datebegin','date')
			,@Dateend = R.Cu.value('@Dateend','date')
		from @xml.nodes('/RequestMessage/Cu') as R(Cu);

		IF @MessageType=N'//WWI/SB/RequestMessage'
		begin
			insert into Sales.InvoicesReport (CustomerId,OrdersCount)
			select 
				cu.CustomerID
				,isnull(count(o.OrderID),0) as OrdersCount
			from
				Sales.Customers AS Cu
				left join Sales.Invoices i on cu.CustomerID = i.CustomerID
				left join Sales.Orders o on i.OrderID = o.OrderID and o.OrderDate between @Datebegin and @Dateend
			where cu.CustomerID = @CustomerID
			group by cu.CustomerID

			SET @ReplyMessage =N'<ReplyMessage> Message received. InvoicesReport='+cast(SCOPE_IDENTITY() as varchar(10))+'</ReplyMessage>'; 
	
			Send ON CONVERSATION @TargetDlgHandle
			message type
			[//WWI/SB/ReplyMessage]
			(@ReplyMessage);
			end conversation @TargetDlgHandle;--закроем диалог со стороны таргета
		end
	commit tran;
end
go

--ХП обработки ответа
create procedure Sales.ConfirmInvoicesReport
as
begin
	declare @InitiatorReplyDlgHandle uniqueidentifier,
			@ReplyReceivedMessage nvarchar(1000)
	
	begin tran;
		receive top(1)
			@InitiatorReplyDlgHandle = Conversation_Handle
			,@ReplyReceivedMessage = Message_Body
		from dbo.InitiatorQueueWWI;
		
		end conversation @InitiatorReplyDlgHandle;
		
		insert into Sales.InvoicesReport_Reply (ReplyText)
		select @ReplyReceivedMessage AS ReceivedRepliedMessage;
	commit tran; 
end
go

alter queue dbo.InitiatorQueueWWI with status = on, retention = off, poison_message_handling (status = off), activation (status = on, procedure_name = Sales.ConfirmInvoicesReport, max_queue_readers = 100, execute as owner);
go

alter queue dbo.TargetQueueWWI with status = on, retention = off , poison_message_handling (status = off), activation(status = on,procedure_name = Sales.GetInvoicesReport, max_queue_readers = 100, execute as owner);
go

exec Sales.SendInvoicesReport 1, '2016-01-02', '2016-03-02'

select * from dbo.InitiatorQueueWWI;

select * from dbo.TargetQueueWWI;

select * from Sales.InvoicesReport

select * from Sales.InvoicesReport_Reply