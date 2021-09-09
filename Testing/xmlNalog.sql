select cast(BulkColumn as xml) 
FROM OPENROWSET(BULK 'D:\VO_OTKRDAN1_9965_9965_20180930_440e6e7c-3546-4490-9b81-d747689fc178.xml', SINGLE_BLOB) x
	Union All
select cast(BulkColumn as xml) 
FROM OPENROWSET(BULK 'D:\VO_OTKRDAN1_9965_9965_20180930_440e6e7c-3546-4490-9b81-d747689fc178.xml', SINGLE_BLOB) x

declare @xml xml
select @xml = cast(BulkColumn as xml) 
FROM OPENROWSET(BULK 'D:\VO_OTKRDAN1_9965_9965_20180930_440e6e7c-3546-4490-9b81-d747689fc178.xml', SINGLE_BLOB) x

;with a as (
select 
	c.value('@�����', 'uniqueidentifier') as guid,
	c.value('@�������', 'DateTime') as Date,
	q.value('@�������', 'varchar(512)') as Name,
	q.value('@�����', 'varchar(12)') as INN,
	w.value('@���������', 'BIT') as ESHN,
	w.value('@��������', 'BIT') as USN,
	w.value('@���������', 'BIT') as ENVD,
	w.value('@��������', 'BIT') as SRP
from @xml.nodes('����/��������') t(c)
outer apply c.nodes('������') a(q)
outer apply c.nodes('�������') b(w)
)
--insert into tax_clients(guid, Date, name, INN, ESHN, USN, ENVD, SRP)
select a.* 
	from a
	left join tax_clients t on t.inn = a.inn
where t.id is null

select * from tax_clients
go

declare @xml xml
select @xml = cast(BulkColumn as xml) 
	FROM OPENROWSET(BULK 'F:\���������\paytax_data-10012018-structure-10012018\VO_OTKRDAN4_9965_9965_20180930_e24e38c1-956e-42f0-8503-44bf79a4a5e5.xml', SINGLE_BLOB) x

;with a as (
select 
	c.value('@�����', 'uniqueidentifier') as guid,
	c.value('@�������', 'DateTime') as Date,
	q.value('@�������', 'varchar(512)') as Name,
	q.value('@�����', 'varchar(12)') as INN
from @xml.nodes('����/��������') t(c)
outer apply c.nodes('������') a(q)
)
insert into tax_clients(guid, Date, name, INN)
select a.* 
	from a
	left join tax_clients t on t.inn = a.inn
where t.id is null

declare @a table(INN varchar(10), name varchar(max), Summa money, client_id int)
insert into @a
select 
	q.value('@�����', 'varchar(12)') as INN,
	w.value('@���������', 'varchar(max)') as name,
	w.value('@���������', 'Money') as Summa,
	c.id
from @xml.nodes('����/��������') t(c)
	outer apply c.nodes('������') a(q)
	outer apply c.nodes('�����������') b(w)
	join tax_clients c on c.inn = q.value('@�����', 'varchar(12)')

delete from tax_paid where client_id in (select client_id from @a)

insert into tax_paid (client_id, Date, name, Summa)
select client_id, getDate(), name, Summa from @a

go
declare @xml xml
select @xml = cast(BulkColumn as xml) 
FROM OPENROWSET(BULK 'D:\VO_OTKRDAN5_9965_9965_20180930_fffff047-81d8-405e-ad81-b2897cc54c91.xml', SINGLE_BLOB) x
;with a as (
select 
	q.value('@�����', 'varchar(12)') as INN,
	w.value('@��������', 'Money') as Profit,
	w.value('@���������', 'Money') as Expense
from @xml.nodes('����/��������') t(c)
outer apply c.nodes('������') a(q)
outer apply c.nodes('�����������') b(w)
)
update b set  Profit = a.Profit, Expense = a.Expense
from tax_clients b
	join a on b.INN = a.INN

select * from tax_paid
go
declare @xml xml
select @xml = cast(BulkColumn as xml) 
FROM OPENROWSET(BULK 'D:\VO_OTKRDAN3_9965_9965_20180930_fffce9db-e830-4538-9c0b-04ccb4cdeb36.xml', SINGLE_BLOB) x
;with a as (
select 
	q.value('@�����', 'varchar(12)') as INN,
	w.value('@������', 'Int') as WorkerCount
from @xml.nodes('����/��������') t(c)
outer apply c.nodes('������') a(q)
outer apply c.nodes('��������') b(w)
)
update b set  WorkerCount = a.WorkerCount
from tax_clients b
	join a on b.INN = a.INN

select * from tax_paid

