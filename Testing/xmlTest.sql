/*
<Payments GUID="0B825B42-7C70-4942-85BA-03235C0AF23C" id="2" Editor="2595" Creator="2595" DateEdit="2013-09-05T12:52:57.030" DateCreate="2013-09-05T12:52:40" del="1" ObjectFinance_id="799" state_id="1170" OurFirms_id="30" x_Contracts_id="81296" x_Contracts_summa="1.0000" client_id="1461" Debit_type="1161" Debit_id="60" Credit_type="911" Credit_id="1461" Comment="СМР, взаимозачет Бетонстройиндустрия, письмо 96 от 15 08 13" PAY_NUM="2" DatePay="2013-08-21T00:00:00" CreditDebitInternal="1" Summa="1.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="30" CreditFirm_type="911" CreditFirm_id="1461" IsPlan="1" />
*/
DECLARE @xmlData XML = '<r><id>1</id></r><r><id>2</id></r>'

SELECT 
	p.value('.[1]', 'INT') as ID
FROM @xmlData.nodes('/r/id') t(p)

select d.id, Name, b.ids
	from _Divisions d
	outer apply (select replace(substring(left(drl.id, len(drl.id)-9), 8, 2147483647), '</id></a><a><id>',',') ids from (select Line_id id from _DivisionRowLink where Division_ID = d.id for xml path('a')) drl(id)) b
where del = 0

DECLARE @xml xml
set @xml=(select top 100000 * FROM Payments for xml auto)
SELECT 
	x.value('@GUID', 'uniqueidentifier'),
	x.value('@id', 'INT')
FROM @xml.nodes('Payments') t(x)

SELECT d.*, replace(replace(replace(x, '</a><a>', ','), '<a>', ''), '</a>', '') name
	FROM DS_Disposals d
	outer APPLY (SELECT isnull(s.Family + ' ', '') + isnull(s.Name + ' ', '') + isnull(s.Patronymic, '') 
					FROM DS_Readed a 
					LEFT JOIN OK_Staff s ON s.id=a.Personal
				where d.id = a.Disposal AND a.del = 0 and isnull(s.Family + ' ', '') + isnull(s.Name + ' ', '') + isnull(s.Patronymic + ' ', '') <> '' FOR xml PATH('a')) t(x)
where d.del = 0

DECLARE @xmlData XML =N'
<Shops> 
	<Shop id="1">
		<device vendor="HTC" id="1">Sensation</device>
		<device vendor="Apple" id="2">iPhone</device>
	</Shop>
	<Shop id="2">
		<device vendor="HTC" id="3">Mozart</device>
		<device vendor="Nokia" id="4">Lumia</device>
	</Shop>
</Shops>';

SELECT 
	shop.value('@id', 'int') as Id,
	shop.value('.[1]', 'nvarchar(50)') as CompanyName    
FROM @xmlData.nodes('/Shops/Shop/device') col(shop)

SELECT @xmlData.query('/Shops/Shop/device')

SELECT @xmlData.query('/Shops/Shop/device/.[@vendor cast as xs:string? = "HTC"]') as Data

SELECT shop.query('.') as data FROM @xmlData.nodes('/Shops/Shop') col(shop)

SELECT 
	device.value('@id', 'int') as Id,
	device.value('@vendor', 'nvarchar(50)') as Company,
	device.value('@name', 'nvarchar(50)') as Name,
	shop.value('@id', 'int') as ShopId
FROM 
	@xmlData.nodes('/Shops/Shop') col(shop)
	CROSS APPLY
		shop.nodes('device') tab(device)

SELECT     
	shop.value('@id', 'int') as ShopId
FROM 
	@xmlData.nodes('/Shops/Shop') col(shop)
WHERE shop.exist('device[@vendor cast as xs:string? = "Nokia"]') = 1

declare @xml xml;
set @xml =
'
   <Row>
	<Cell><Data Type="String">Номер договора</Data></Cell>
    <Cell><Data Type="String">Дата регистрации (штамп о рег.)</Data></Cell>
   </Row>
   <Row>
    <Cell Index="2"><Data Type="DateTime">2014-12-07T00:00:00.000</Data></Cell>
   </Row>
   <Row>
    <Cell><Data Type="String">79Ц/215-ЛЗ/5 от 27.10.2015</Data></Cell>
    <Cell><Data Type="DateTime">2015-11-16T00:00:00.000</Data></Cell>
   </Row>'
SELECT 
	p.value('.[1]', 'nvarchar(50)') as CompanyName
FROM @xml.nodes('/Row/Cell') t(p)


DECLARE @xmlData XML =N'
<Shops> 
	<Shop id="1">
		<device vendor="HTC" id="1">Sensation</device>
		<device vendor="Apple" id="2">iPhone</device>
	</Shop>
	<Shop id="2">
		<device vendor="HTC" id="3">Mozart</device>
		<device vendor="Nokia" id="4">Lumia</device>
	</Shop>
</Shops>';
select datalength(@xmlData)


insert into alloc(x) values(@xmlData)

select * 
	from  sys.partitions p
	join sys.allocation_units au on au.container_id = p.partition_id
where p.object_id = OBJECT_ID('alloc')

--exec sp_tableoption 'alloc', 'large value types out of row', 1

dbcc ind(vkb_test1, 'dbo.alloc', 1)

dbcc traceon(3604)
dbcc page (vkb_test1, 1, 2336, 3)
dbcc traceon(3606)


DECLARE @xmlData XML =N'
<Shops> 
	<Shop id="1">
		<device vendor="HTC" id="1">Sensation</device>
		<device vendor="Apple" id="2">iPhone</device>
	</Shop>
	<Shop id="2">
		<device vendor="HTC" id="3">Mozart</device>
		<device vendor="Nokia" id="4">Lumia</device>
	</Shop>
</Shops>';

declare @h int;

exec sp_xml_preparedocument @h output, @xmlData;

select
 *
from
 openxml(@h, '/Shops/Shop', 1)
 with
 (
  id int '@id',
  Shop_id int 'device/@id',
  Shop_id_1 int 'device[2]/@id',
  vendor varchar(max)'device/@vendor',
  vendor_1 varchar(max)'device[2]/@vendor',
  device varchar(max)'device',
  device_1 varchar(max)'device[2]'
 );

select
 *
from
 openxml(@h, '/Shops/Shop/device', 1)
 with
 (
  id int,
  Shop_id int '../@id',
  vendor varchar(max),
  device varchar(max) 'text()'
 );

exec sys.sp_xml_removedocument @h;


select top 10000 
	[@id] = id, DatePay d, Summa s, [items/comment] = Comment
from Payments p 
for xml path('r'), root('root')


select name,
		[columns] = (select name from _Objects where Parent_ID = o.id for xml path(''), type)
	from _Objects o
where ObjectsTypes_id = 1
for xml path('table'), root('tables')


select cast('' as xml).query(
'<Table name="{sql:column("name")}"/>'
)
from _Objects Tables
where ObjectsTypes_id = 1 for xml auto

select cast('' as xml).query(
'
<Tables>
	<Table name="{sql:column("name")}"/>
</Tables>
'
)
from _Objects o
where ObjectsTypes_id = 1

declare @xml xml;
set @xml =
'
<a>
	<id val="1"><id1>1</id1></id>
</a>
<a>
	<id val="2">124</id>
</a>
<b>
	<id val="3">abc</id>
</b>
<c>
	<id />
</c>
'

select
	t.c.query('/id[1]'),
	t.c.exist('text()'),
	t.c.value('.', 'varchar(10)'),
	t.c.value('@val', 'varchar(10)')
from @xml.nodes('*/*') t(c)

select
	t.c.query('.'),
	t.c.exist('text()'),
	t.c.value('.', 'varchar(10)'),
	t.c.value('@val', 'varchar(10)')
from @xml.nodes('a/id') t(c)

;with cte as (
	select x = cast(BulkColumn as xml)
	FROM OPENROWSET(BULK 'D:\domclick-rostov.xml', SINGLE_BLOB) x
)
select 
	t.c.value('id[1]', 'INT'),
	t.c.value('name[1]', 'varchar(max)'),
	t.c.value('description_main[1]', 'varchar(max)')
from cte
cross apply x.nodes('complexes/complex') t(c)
-- так быстрее
declare @xml xml
select @xml = BulkColumn FROM OPENROWSET(BULK 'D:\domclick-rostov.xml', SINGLE_BLOB) x
select 
	t.c.value('id[1]', 'INT'),
	t.c.value('name[1]', 'varchar(max)'),
	t.c.value('description_main[1]', 'varchar(max)')
from @xml.nodes('complexes/complex') t(c)

select cast(BulkColumn as xml) FROM OPENROWSET(BULK 'D:\domclick-rostov.xml', SINGLE_BLOB) x