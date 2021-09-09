declare 
	@frh_id		int = 134498,
	@flat_id	int = 106451,
	@pc_id		int

--select top 1 @frh_id = id from r_FlatReserveHistory where flat_id =@flat_id order by date desc

select top 1 @frh_id = id,  @flat_id  = Flat_id from r_FlatReserveHistory where DigitalNumber = '79286691921' order by date desc
select * from r_FlatReserveHistory where flat_id =@flat_id order by date desc
select @frh_id
--select * from r_FlatReserveHistory where flat_id =70284 order by date desc
--select @flat_id = flat_id, @pc_id = PotentialClient_id from r_FlatReserveHistory where id =@frh_id
--delete from r_PotentialClients where id=$pc_id
delete from r_FlatReserveHistory where id = @frh_id
update r_Flats set IsReserved = 0 where id = @flat_id

--select master.dbo.checkURL('https://www.vkbn.ru/syncronize/syncronize.php?action=flats')

select * from r_MortgageRequests where 


--select * from r_FlatObjects where isSales = 0 and IsReserved = 0 and DisableForSite = 0 order by id desc

select * from r_Petitions where flat_id = 168588 order by id desc
select * from r_Petitions order by id desc

delete from r_Petitions where id = 14011
select * from s_post_log order by id desc

select * from r_Petitions where SberBankOrder_uid is not null

delete from r_FlatReserveHistory where dbo.DigitNumber(MainPhone)='79181792619'
delete from r_FlatReserveHistory where dbo.DigitNumber(MainPhone)='73434343434'

select * from r_PetitionOrder

select * from qe_Questions