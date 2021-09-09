declare @db_name sysname = 'vkb_test1'
declare @db_id int = db_id(@db_name)
select count(spid), stuff((select ' GO kill ' + cast(spid as varchar) from sysprocesses p  where dbid = @db_id for xml path('')), 1, 3, ' GO') a from sysprocesses where dbid = @db_id

declare @t table (spid smallint, ecid smallint, status nchar(30), loginame nvarchar(128), hostname nchar(128), blk char(5), dbname nvarchar(128), cmd nchar(16), request_id int)
insert into @t
exec sp_who
select * from @t where dbname='vkb_test1'

DECLARE cur CURSOR FOR 
select
	spid
from
	master.dbo.sysprocesses p
where dbid = 6 and spid <> @@spid

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

select * from _Objects where name = 'r_RealtyObjects'
select RealtyObject_id, * from r_Flats where id=168880

select * from _Files where table_id = 899  and line_id = 45392 order by id desc

ALTER DATABASE vkb_test1
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;

ALTER DATABASE vkb_test1
SET MULTI_USER;
GO
select * from vkb_test1..valuta
select * from s_post_log where ext_id is not null order by id desc

