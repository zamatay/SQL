-- русский-21 English -0
EXEC sp_configure 'default language', 21;
GO
RECONFIGURE;

-- сессия
SET LANGUAGE russian

-- поменять всем пользователям
declare @sql nvarchar(max)
set @sql=''
select @sql = @sql + 'alter login ' + quotename(loginname) + ' with default_language = russian;
' 
from sys.syslogins where language is not null and isntGroup=0
exec(@sql)

select * from sys.syslogins where language<>'russian' and isntGroup=0

-- все доступные языки
select * from sys.syslanguages