if object_id('tempdb..#t') is not null drop table #t
create table #t (spid int, ecid int, status sysname, loginame sysname, hostname sysname, blk int, dbname sysname null, cmd varchar(max), request_id int)
insert into #t exec sp_who
select * from #t where loginame = 'service'
