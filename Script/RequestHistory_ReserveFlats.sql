select dbo.DigitNumber(SUBSTRING(post, CHARINDEX('{"flat_id":', post) + 11, CHARINDEX(',"fio', post)- CHARINDEX('{"flat_id":', post) - 11)),* from _RequestHistory where method='reservedFlats' and DateCreate > '2017-02-02 00:00:00.000'--and post like '%Ильин Денис Александрович%'
select * 
	from (select dbo.DigitNumber(SUBSTRING(post, CHARINDEX('{"flat_id":', post) + 11, CHARINDEX(',"fio', post)- CHARINDEX('{"flat_id":', post) - 11)) flat_id,* from _RequestHistory where method='reservedFlats' and DateCreate > '2017-02-02 00:00:00.000') a 
	left join r_FlatReserveHistory fh on a.flat_id = fh.Flat_id and fh.DateCreate > '20170202'


select dbo.DigitNumber(SUBSTRING(post, charIndex('"MainPhone":', post) + 13, 18)),* from _RequestHistory where method='addExtClients' and dateCreate between '20170821 15:00:00.000' and '20170821 16:28:11.400'