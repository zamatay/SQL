DECLARE
	@BeginDate	DateTime,
	@EndDate	DateTime
SELECT @BeginDate = '20160101', @EndDate = '20161231';
with cte as 
(select 1 id, @BeginDate beginDate, DATEADD(MILLISECOND,24*60*60*1000-3,DATEADD(dd, 9, @BeginDate)) endDate
  UNION ALL
select 
	case when id = 3 then 1 else id+1 end, 
	case when id = 3 then dbo.BeginOfMonth(DATEADD(dd, 10, endDate)) else dateadd(dd, 10, beginDate) end, 
	case when id = 2 then DATEADD(MILLISECOND,24*60*60*1000-3,dbo.EndOfMonth(endDate)) else DATEADD(dd, 10, endDate) end from cte
WHERE endDate < @EndDate
)
select * from cte