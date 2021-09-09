SET STATISTICS PROFILE OFF;
set STATISTICS TIME OFF;
with getSalesFlatsCount as (
	SELECT count(*) [Count]
		FROM r_Flats f
		JOIN r_RealtyObjects ro ON ro.id = f.RealtyObject_id and ro.del = 0
	where f.del = 0 AND IsSales = 1
),  getReservedFlatsCount as (
	SELECT count(*) [Count]
		FROM r_Flats f
		JOIN r_RealtyObjects ro ON ro.id = f.RealtyObject_id and ro.del = 0
	where f.del = 0 AND IsReserved = 1 AND (ReservedDateTo > cast(CONVERT(varchar(max), GetDate(), 112) AS DATETIME))
), getAvailableFlatsCount as (
	SELECT count(*) [Count]
		FROM r_Flats f
		JOIN r_RealtyObjects ro ON ro.id = f.RealtyObject_id and ro.del = 0
		left JOIN ObjectsFinance _of ON ro.FinanceObject_id = _of.id
	where f.del = 0 AND IsSales = 0 AND _of.IsShowOnSite = 1 and (IsReserved = 0 or ReservedDateTo < getdate())
), OurClient as
(
	SELECT c.id FROM OurFirms f
	JOIN Clients c ON f.client_id = c.id
	WHERE f.Del = 0
), getLastSalesDate as (
	SELECT top 1 c.DateCreate [Date]
	FROM x_Contracts c
		JOIN x_Works w on w.del = 0 AND w.Contract_id = c.id
	WHERE c.Del = 0 AND c.FlagInOut = 0 AND isnull(c.IsPledge, 0) = 0 AND c.ContractStatus_id IN (1,2)
	AND c.Client_id NOT IN (SELECT id FROM OurClient) AND c.Contract_id is NULL
	ORDER BY c.DateCreate desc
)
select 
	getLastSalesDate.Date getLastSalesDate, 
	getAvailableFlatsCount.Count getAvailableFlatsCount, 
	getReservedFlatsCount.Count getReservedFlatsCount, 
	getSalesFlatsCount.Count getSalesFlatsCount
from getLastSalesDate
cross join getSalesFlatsCount
cross join getReservedFlatsCount
cross join getAvailableFlatsCount
