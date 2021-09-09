DECLARE @params table (name varchar(max), value varchar(max), id int)
insert into @params
EXEC [_Today_GetParams] null

;with countClick as (
	select Line_ID, e.user_id , count(*) cnt
		from _Events e WITH (INDEX([IDX__Events__EventType_ID]))
	where EventType_ID = (select top 1 id from _EventTypes where GUID='0FDB943C-AE7A-408E-B441-F58089FF1F8C') --and e.User_ID=2379
	GROUP BY Line_ID, e.user_id
),
params  as (select * from @params where name='action')
select  top 10
	[Table_0].name,
	TRV.value,
	(useCount.cnt) AS [c_CountUse]
 from 
/*Join_b*/
[_TodayElements] [Table_0] /*MainTable*/
left join params TRV on TRV.id = table_0.id
LEFT JOIN countClick useCount on useCount.Line_id = Table_0.id
 where Table_0.type_id=4
 order by c_CountUse desc

