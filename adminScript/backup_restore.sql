declare @path varchar(max)
set @path = N'F:\191128.bak'; --'D:\Backup\xbc.bak'--'F:\sql_backup\vkb.bak'
ALTER DATABASE TestBase_1 SET OFFLINE WITH ROLLBACK IMMEDIATE

/*
BACKUP DATABASE [XBC] TO  DISK = @path
WITH NOFORMAT, INIT, COMPRESSION, NAME = N'XBC-Full Database Backup', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10
*/

RESTORE DATABASE TestBase_1 FROM  DISK = @path
WITH  FILE = 1,  
MOVE N'xbc_data' TO N'E:\Backup\S2017\TestBase_1.mdf',  
MOVE N'xbc_log' TO N'E:\Backup\S2017\TestBase_1.ldf',  NOUNLOAD,  REPLACE,  STATS = 10

ALTER DATABASE TestBase_1 SET ONLINE

ALTER DATABASE TestBase
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;

declare @path varchar(max)
set @path = N'F:\200730.bak'; --'D:\Backup\xbc.bak'--'F:\sql_backup\vkb.bak'
--ALTER DATABASE TestBase SET OFFLINE WITH ROLLBACK IMMEDIATE
RESTORE DATABASE TestBase FROM  DISK = @path
WITH  FILE = 1,  
MOVE N'xbc_data' TO N'E:\Backup\S2017\TestBase.mdf',  
MOVE N'xbc_log' TO N'E:\Backup\S2017\TestBase.ldf',  NOUNLOAD,  REPLACE,  STATS = 10
--ALTER DATABASE TestBase SET ONLINE
ALTER DATABASE TestBase
SET MULTI_USER;

GO