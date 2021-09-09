select name, clr_name from sys.assemblies 

select * from sys.dm_clr_properties
select * from sys.dm_clr_appdomains

/*
// для работы zip необходимо зарегистрировать библиотеку
CREATE ASSEMBLY [System.IO.Compression] AUTHORIZATION dbo 
FROM 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.IO.Compression.dll'
WITH PERMISSION_SET = unsafe

CREATE ASSEMBLY [system.runtime.serialization] AUTHORIZATION dbo 
FROM 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Runtime.Serialization.dll'
WITH PERMISSION_SET = unsafe

CREATE ASSEMBLY [newtonsoft.json] AUTHORIZATION dbo 
FROM 'c:\Windows\System32\Newtonsoft.Json.dll'
WITH PERMISSION_SET = unsafe
*/

sp_configure 'clr enabled', 1;
GO
reconfigure
go

alter database master set trustworthy on
go

drop function unzip
go
drop function zip
go
drop function getJSONValue
go
drop assembly VKB_CLR
go


create assembly VKB_CLR
from 'C:\Windows\System32\VKB_CLR.dll'
with permission_set = unsafe
go


create function unzip(@data varbinary(max))
returns nvarchar(max)
as
	external name VKB_CLR.[VKB_CLR.VKB].[UnZip]
go
GRANT EXECUTE on dbo.unzip TO public
go

create function zip(@data nvarchar(max))
returns varbinary(max)
as
	external name VKB_CLR.[VKB_CLR.VKB].[Zip]
go
GRANT EXECUTE on dbo.zip TO public
go

create function getJSONValue(@Text nvarchar(max), @Method nvarchar(max))
returns nvarchar(max)
as
	external name VKB_CLR.[VKB_CLR.VKB].[getJSONValue]
go
GRANT EXECUTE on dbo.getJSONValue TO public
go


create function checkUrl(@Text nvarchar(max))
returns Bit
as
	external name VKB_CLR.[VKB_CLR.VKB].[checkUrl]
go
GRANT EXECUTE on dbo.checkUrl TO public
go

select top 1000 id, master.dbo.unzip(data) from _RegisterView

select top 1 master.dbo.unzip(data), master.dbo.zip(master.dbo.unzip(data)), data from _RegisterView where id=383

select id, post, master.dbo.getJSONValue(POST, 'tel') from _RequestHistory where substring(master.dbo.getJSONValue(POST, 'tel'), 1,1) != '+' order by id desc