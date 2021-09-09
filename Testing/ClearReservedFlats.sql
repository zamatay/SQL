declare @flatID INT = 147217;
declare @PC_ID INT;
select @PC_ID = id from r_PotentialClients where DigitalNumber = '72222222222'

update r_Flats set IsReserved = 0, ReservedDateTo = null, DateEdit = GETDATE() where id = @flatID
delete from r_FlatReserveHistory where Flat_id=@flatID and PotentialClient_id = @PC_ID

select master.dbo.checkurl('https://www.vkbn.ru/syncronize/syncronize.php?action=flats')

--select * from _RequestHistory order by id desc
--select count(*) from _RequestHistory order by id desc