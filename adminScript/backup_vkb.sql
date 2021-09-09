use master
declare @path varchar(300)
set @path = N'F:\sql_backup\'+convert(varchar,getdate(),12)+'.bak' 

BACKUP DATABASE [VKB] TO  DISK = @path
WITH COMPRESSION, NOFORMAT, INIT,  NAME = N'VKB-Full Database Backup', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10

ALTER DATABASE VKB_test1 SET OFFLINE WITH ROLLBACK IMMEDIATE

RESTORE DATABASE [VKB_test1] FROM  DISK = @path
WITH  FILE = 1,  
MOVE N'xbc_data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Data\VKB_test1.mdf',  
MOVE N'xbc_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Data\VKB_test1_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 10

ALTER DATABASE VKB_test1 SET ONLINE

USE [VKB_test1]
GO

DECLARE @Users TABLE (id INT)
INSERT INTO @Users
SELECT id FROM dbo._Users
where	Login like 'VKBU\Sidorov_PP' or 
		Login like 'VKBU\Zamuraev_AV' or 
		Login like 'VKBU\Leontyev_av' or 
		Login like 'Sidorov_PP' or 
		Login like 'Leontyev_av' or 
		Login like 'Zamuraev_AV' or 
		Login like 'VKBU\Krasnyanskaya_ta' or
		Login like 'VKBU\Esaulov_ea'	 or
		Login like 'Esaulov_ea' or
		Login like 'vkbu\Mihalev_mv'	
update _Users
set IsAdmin = 1
WHERE id IN (SELECT id from @Users)

exec sp_droprolemember 'xbc_user', 'Zamuraev_av'
exec sp_droprolemember 'xbc_user', 'Leontyev_av'

exec sp_droprolemember 'db_denydatareader', 'Zamuraev_av'
exec sp_droprolemember 'db_denydatareader', 'Leontyev_av'
exec sp_droprolemember 'db_denydatawriter', 'Zamuraev_av'
exec sp_droprolemember 'db_denydatawriter', 'Leontyev_av'

insert into _LikeUser(User_id, LikeUser_id)
select u1.id, u.id
from (select id from _Users where IsGroup = 0) u
	cross JOIN @Users u1

update _GlobalOptions set s = 'http://192.168.0.13:8090' where guid='4719920A-4470-4FF1-9832-BB3F7006D2B9'
GO
