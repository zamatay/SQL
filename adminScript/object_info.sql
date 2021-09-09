select * 
	from sys.objects o
	LEFT JOIN sys.sql_modules m on m.object_id = o.object_id
where uses_ansi_nulls = 0 or uses_quoted_identifier = 0

select * from sys.syscomments
select * from sys.sql_modules