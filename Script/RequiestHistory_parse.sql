declare @searchWord varchar(max)='"BaitProgram_id":';
with a as (
select CHARINDEX(@searchWord, post) startIndex, post from _RequestHistory where post LIKE '%BaitProgram_id%'
), b as (select CHARINDEX(',"', post, startIndex) finishIndex, post, startIndex from a),
c as (select REPLACE(SUBSTRING(post, startIndex + len(@searchWord), finishIndex - startIndex - len(@searchWord)), '\', '') result, dbo.DigitNumber(SUBSTRING(post, 15, 18)) phone from b),
d as (select SUBSTRING(result, 2, len(result) - 2) result, phone from c where result <> 'null'), 
itog as (select d.*, p.id p_id, pc.id pc_id
			from d
			left join r_Promotions p on p.Name=d.result
			left join r_PotentialClients pc on pc.DigitalNumber=d.phone)
select * from itog
--UPDATE pc SET Promotion_id=p_id
--	from r_PotentialClients pc
--	join itog on itog.pc_id=pc.Id
--where itog.p_id is not null and pc.Promotion_id is null
