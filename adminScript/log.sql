create table #log
( logdate datetime,
 processinfo char(15),
 text nvarchar(max)
)

insert into #log
exec xp_ReadErrorLog

select * from #log where text like'%������%'  order by logdate desc
--drop table #log
