declare
	@datefrom	DATETIME,
	@DateTO		DATETIME
SELECT @DateFrom = '20310101', @DateTo = '20401231'
;WITH periods as
(
	--месяцы
	select 3 group_id, dbo.BeginOfMonth(@dateFrom) Begin_Data, dbo.EndOfMonth(@DateFrom) End_Data
	UNION All
	--кварталы
	select 2 group_id, dbo.BeginOfMonth(@dateFrom) Begin_Data, dbo.EndOfPeriod(@DateFrom, 'Quarter', 0) End_Data
	UNION ALL
	--года
	select 1 group_id, dbo.BeginOfMonth(@dateFrom) Begin_Data, dbo.EndOfPeriod(@DateFrom, 'Year', 0) End_Data
	UNION All
	SELECT group_id, 
		case group_id 
			-- в зависимости от группы прибавляем нужный период
			when 1 then dateadd(yy, 1, Begin_Data) when 2 then dateadd(q, 1, Begin_Data) when 3 then dateadd(m, 1, Begin_Data)
		end,
		case group_id 
			-- в зависимости от группы прибавляем нужный период и высчитываем его окончание
			when 1 then dbo.EndOfPeriod(dateadd(yy, 1, Begin_Data), 'Year', 0) when 2 then dbo.EndOfPeriod(dateadd(q,1,Begin_Data), 'Quarter', 0) when 3 then dbo.EndOfMonth(dateadd(m, 1, Begin_Data))
		end
	FROM periods where End_Data < @DateTo
), a as (
SELECT 
	case 
		when group_id = 3 then dbo.monthByID(month(begin_data)) + ' ' + STR(year(begin_data), 4) 
		WHEN group_id = 2 THEN STR(ceiling(Month(begin_data)*1.00/3), 1) + N'-й квартал ' + str(year(begin_data), 4)
		ELSE str(year(begin_data), 4) + '-й год'
	end name, *
FROM periods)
--insert into Period(DateCreate, name, group_id, Begin_Data, End_Data, FullName)
select getDate(), name, group_id, Begin_Data, End_Data, format(Begin_Data, 'yyyy.MM ') + name from a order by group_id, Begin_Data
OPTION (MAXRECURSION 0)


select * from Period where Begin_Data >= '20310101' order by id desc


DECLARE 
	@BedinDate	DATETIME,
	@EndDate	DATETIME
SELECT @BedinDate='20300101', @EndDate='20301201';
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