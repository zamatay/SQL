-- ”становить Microsoft Access Database Engine 2010 Redistributable
--http://www.microsoft.com/en-us/download/details.aspx?id=13255

--–азрешени€ дл€ драйвера
USE master
GO
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 
 
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

EXEC sp_addlinkedserver
   @server = 'dbf',
   @srvproduct=N'OLE DB Provider for ACE', 
   @provider = 'Microsoft.ACE.OLEDB.12.0',
   @datasrc = 'C:\MyFolder\MVK\tables',
   @provstr = 'DBASE IV'

/*
1.Open the Management Studio and navigate to Server Objects and then to Linked Server.
2.Right click on your Linked Server Name, and click on Properties.
3.Go to Security Page. Now for solving above problem you have 2 option, you can try any of the below 2 option.
*/

use vkb_test1
-- сливаем на другой сервер
go
create table socrbase(scname nvarchar(10), socrName nvarchar(29), Level nvarchar(5))
create table street(name nvarchar(40), socr nvarchar(10), Code nvarchar(15), [index] nvarchar(6))
create table kladr(name nvarchar(40), socr nvarchar(10), Code nvarchar(11), [index] nvarchar(6))
go

-- переливаем в временную таблицу что бы работать уже с ней
select [name], RTRIM(LTRIM(socr)) socr, Left(code, 11) Code, [index] --INTO ##kladr 
FROM OPENDATASOURCE('Microsoft.ACE.OLEDB.12.0', 'Data Source=d:\0_Base\;Extended Properties=DBASE IV;')...KLADR
WHERE RIGHT(code, 2) = '00'

select [name], RTRIM(LTRIM(socr)) socr, LEFT(code, 15) Code, [index] INTO ##street
FROM OPENDATASOURCE('Microsoft.ACE.OLEDB.12.0', 'Data Source=d:\0_Base\;Extended Properties=DBASE IV;')...street
WHERE RIGHT(code, 2) = '00'

SELECT DISTINCT RTRIM(LTRIM(scname)) scname, RTRIM(LTRIM(socrName)) socrName, Level INTO ##socrbase
FROM OPENDATASOURCE('Microsoft.ACE.OLEDB.12.0', 'Data Source=d:\0_Base\;Extended Properties=DBASE IV;')...socrbase

insert into vkbs2.vkb_test1.dbo.kladr
select * from ##kladr where name='ѕашковский'

insert into vkbs2.vkb_test1.dbo.socrbase
select * from ##socrbase

insert into vkbs2.vkb_test1.dbo.street
select * from ##street

/*
EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE
*/

-- копирование в xml не прошло
/*
EXEC xp_cmdshell 'bcp "select * from ##kladr for xml path(''''), ROOT(''ROOT'')" queryout "d:\kladr.xml" -S TEST3\S2017 -U sa -P 123 -T -c -t'
EXEC xp_cmdshell 'bcp "select * from ##street for xml path(''''), ROOT(''ROOT'')" queryout "d:\street.xml" -S TEST3\S2017 -U sa -P 123 -T -c -t'
EXEC xp_cmdshell 'bcp "select * from ##socrbase for xml path(''a''), ROOT(''ROOT'')" queryout "d:\socrbase.xml" -S TEST3\S2017 -U sa -P 123 -T -c -t | "C:\Program Files (x86)\GnuWin32\bin\iconv.exe" -f CP866 -t UTF-8 d:\socrbase.xml'
declare @t table (s varchar(max))
insert into @t
EXEC xp_cmdshell 'bcp "select * from ##socrbase for xml path(''''), ROOT(''ROOT'')" queryout "d:\socrbase.xml" -S TEST3\S2017 -U sa -P 123 -T -c -t | "C:\Program Files (x86)\GnuWin32\bin\iconv.exe" -f CP866 -t UTF-8 d:\socrbase.xml'
select s + '' from @t for xml path('')
--  | "C:\Program Files (x86)\GnuWin32\bin\iconv.exe" -f UCS-2 -t UTF-8 d:\socrbase.xml
*/

-- сводим с боевой 

-- заливаем те которых нет
	INSERT INTO dbo.RegionAlias(ShortName, FullName)
	SELECT DISTINCT a.scname, a.socrName
	FROM vkb_test1..socrBase a
	left join RegionAlias ra on ra.ShortName = a.scname
	WHERE ra.id IS NULL

	-- заливаем уровни объектов
	INSERT INTO dbo.RegionAliasLevel([Level], RegionAlias_id)
	SELECT a.LEVEL, ra.id FROM vkb_test1..socrbase a
	left join RegionAlias ra on ra.ShortName = a.scname
	LEFT JOIN dbo.RegionAliasLevel AS ral ON ral.RegionAlias_id = ra.id
	WHERE ral.id IS NULL

	-- заливае регионы
	DECLARE
	@s VARCHAR(3),
	@Level INT,
	@cnt INT,
	@StartPos INT
	SELECT @s='00', @level = 1, @cnt = 11, @StartPos = 1

	WHILE @StartPos + LEN(@s) <= 13
	BEGIN
		INSERT INTO Regions(Parent_ID, [Name], Code, [Index], RegionAlias_id, [Level], Country_id) output inserted.*
		SELECT distinct a.id, k.[name], k.code, k.[index], ra.Id, @Level, 1
		FROM vkb_test1..kladr AS k
		LEFT JOIN dbo.RegionAlias AS ra ON ra.ShortName = k.socr
		outer apply (select top 1 id from Regions a where SUBSTRING(a.Code, 1, @StartPos - 1) = SUBSTRING(k.Code, 1, @StartPos - 1)) a
		WHERE not exists (select 1 from Regions a1 where a1.Code = k.Code)
		AND SUBSTRING(k.code, @StartPos, LEN(@s)) <> @s
		AND CAST(SUBSTRING(k.code, @StartPos + LEN(@s), LEN(k.Code) - @StartPos - LEN(@s) + 1) AS INT) = 0

		SET @level = @Level + 1
		SET @StartPos = @StartPos + LEN(@s)
		SET @s = '000'
	END

	-- если изменилось название региона апдейтим его
	UPDATE dbo.Regions SET NAME = k.[Name]
	FROM dbo.Regions r
	JOIN vkb_test1..kladr k ON r.Code = k.Code AND r.NAME <> k.NAME


	-- заливаем улицы
	INSERT INTO dbo.Streets ([Name], Region_id, Code, [Index], RegionAlias_id)
	SELECT st.NAME, a.id, st.Code, st.[Index], ra.id
	FROM vkb_test1..street st
	JOIN Regions a ON a.Code = SUBSTRING(st.Code, 1, 11) -- определ€ем ссылку региона
	LEFT JOIN dbo.RegionAlias AS ra ON ra.ShortName = st.socr
	WHERE not exists (select 1 from Streets s where s.code = st.code) 

	-- если изменилось название улицы апдейтим его
	UPDATE dbo.Streets SET NAME = s.[Name]
	FROM dbo.Streets AS s2
	JOIN vkb_test1..street s ON s2.Code = s.Code AND s2.NAME <> s.NAME
