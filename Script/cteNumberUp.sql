with cte as (select 0 num
union all
select num + 1 from cte where num < 256
)
select char(num), num from cte
OPTION (MAXRECURSION 500);  