declare
	@datefrom	DATETIME,
	@DateTO		DATETIME
SELECT @DateFrom = '20100101', @DateTo = '20201231'
;WITH periods as
(
	select 3 group_id, dbo.BeginOfMonth(@dateFrom) Begin_Data, dbo.EndOfMonth(@DateFrom) End_Data
	UNION All
	select 2 group_id, dbo.BeginOfMonth(@dateFrom) Begin_Data, dbo.EndOfPeriod(@DateFrom, 'Quarter', 0) End_Data
	UNION ALL
	select 1 group_id, dbo.BeginOfMonth(@dateFrom) Begin_Data, dbo.EndOfPeriod(@DateFrom, 'Year', 0) End_Data
	UNION All
	SELECT group_id, dateadd(yy, 1, Begin_Data), dbo.EndOfPeriod(dateadd(yy, 1, Begin_Data), 'Year', 0) FROM
	periods where End_Data < @DateTo AND group_id=1
	UNION All
	SELECT group_id, dateadd(q, 1, Begin_Data), dbo.EndOfPeriod(dateadd(q,1,Begin_Data), 'Quarter', 0) FROM
	periods where End_Data < @DateTo AND group_id=2
	UNION All
	SELECT group_id, dateadd(m, 1, Begin_Data), dbo.EndOfMonth(dateadd(m, 1, Begin_Data)) FROM
	periods where End_Data < @DateTo AND group_id=3
)
SELECT 
	case 
		when group_id = 3 then dbo.monthByID(month(begin_data)) + ' ' + STR(year(begin_data), 4) 
		WHEN group_id = 2 THEN case ceiling(Month(begin_data)*1.00/3) 
									when 2 THEN STR(ceiling(Month(begin_data)*1.00/3), 1) + N'-ой квартал'
									when 3THEN STR(ceiling(Month(begin_data)*1.00/3), 1) + N'-ий квартал'
									else STR(ceiling(Month(begin_data)*1.00/3), 1) + N'-ый квартал'
								end
		ELSE str(year(begin_data), 4) + ' год'
	end, * 
FROM periods order by group_id desc, begin_data OPTION (MAXRECURSION 0)

DECLARE 
	@BedinDate	DATETIME,
	@EndDate	DATETIME
SELECT @BedinDate='20160101', @EndDate='20200101';
with cte as 
(select 1 id, 0 a, cast(@BedinDate as datetime) beginDate, DATEADD(dd, 9, @BedinDate) endDate
  UNION ALL
select 
	case when id = 3 then 1 else id+1 end, 
	id,  
	case when id = 3 then dbo.BeginOfMonth(DATEADD(dd, 9, enddate)) else dateadd(dd, 1, endDate) end, 
	case when id = 2 then dbo.EndOfMonth(endDate) else DATEADD(dd, 10, endDate) end from cte
where endDate <= @EndDate
)
select id, beginDate, endDate from cte
OPTION (MAXRECURSION 1000)