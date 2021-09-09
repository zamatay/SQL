--select * from r_FlatReserveHistory where flat_id =144152
declare 
	@frh_id int = 249770,
	@flat_id	int,
	@pc_id		int
select @flat_id = flat_id, @pc_id = PotentialClient_id from r_FlatReserveHistory where id =@frh_id
--delete from r_PotentialClients where id=$pc_id
delete from r_FlatReserveHistory where id =@frh_id
update r_Flats set IsReserved = 0 where id = @flat_id

select master.dbo.checkURL('https://www.vkbn.ru/syncronize/syncronize.php?action=flats')