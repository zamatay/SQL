declare @path varchar(300)
set @path = N'c:\backup\vkb'+convert(varchar,getdate(),12)+'.bak' 

BACKUP DATABASE [VKB] TO  DISK = @path
WITH NOFORMAT, INIT,  NAME = N'VKB-Full Database Backup', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10

DECLARE cur CURSOR FOR 
select
	spid
from
	master.dbo.sysprocesses p
where dbid = 7 and spid <> @@spid

declare @SQL varchar(100)

open cur
declare @spid int

FETCH NEXT FROM cur 
INTO @spid
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'kill ' + cast(@spid as varchar)
	exec(@SQL)
	FETCH NEXT FROM cur 
	INTO @spid
END

close cur
deallocate CUR

ALTER DATABASE VKB_test1 SET OFFLINE WITH ROLLBACK IMMEDIATE

RESTORE DATABASE [VKB_test1] FROM  DISK = @path
WITH  FILE = 1,  
MOVE N'xbc_data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Data\VKB_test1.mdf',  
MOVE N'xbc_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Data\VKB_test1_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 10

ALTER DATABASE VKB_test1 SET ONLINE
