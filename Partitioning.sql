-- “аблица будет хранить большие объЄмы данных, обновление которых будет происходить за последние 2 мес€ца, дл€ этого таблица партицируетс€ по полю с ID мес€ца.

create partition function pfnPartYearMonth (int) as range right
for values ()

create partition scheme psnPartYearMonth as partition pfnPartYearMonth to ([PRIMARY])

create table fact.Sales (
	ID int identity(1,1) not null
	,nPartYearMonth int not null
	,ID_Date int not null
	,ID_Customer int not null
	,ID_VendingMachine int not null
	,ID_Planogramm int not null
	,UsingQty int not null
,CONSTRAINT [PKC_fact_Sales] PRIMARY KEY CLUSTERED
(
	nPartYearMonth, ID
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = ON, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) on psnPartYearMonth(nPartYearMonth)
) on psnPartYearMonth(nPartYearMonth)