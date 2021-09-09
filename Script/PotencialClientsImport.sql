--SELECT '+7 (' + substring([5# Контактный телефон], 2, 3) + ') ' + substring([5# Контактный телефон], 5, 3) + '-'+ substring([5# Контактный телефон], 8, 2) + '-' + substring([5# Контактный телефон], 10, 2) MainPhone, * INTO #t FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;IMEX=1;Database=c:\work\import.xlsx;',[СВОД$]) 
--DROP TABLE #t

DECLARE @USERID INT
SET @USERID = 2734;
INSERT INTO VKBS2.vkb.dbo.r_PotentialClients (Date, Staff_id, FIO, MainPhone, ClientSource_id, BuildingZone_id, AdvertisingSource_id, Info, RoomsCount, MonthsCount, PaymentMethod_id, Editor, Creator, DateEdit, DateCreate)
SELECT 
	cast(substring([1# Дата], 1, 10) as DATETIME) Date, 
	--(select id from OurFirms where Name = [2# Компания]) Firm_id,
	(select top 1 id from VKBS2.vkb.dbo.ok_staff where  Family + ' ' + Name + ' ' + Patronymic = [3# Менеджер-продавец]) Staff_id, 
	[4# Ф#И#О#  Клиента  (Имя)] FIO,--+7 (928) 328-41-62
	MainPhone, 
	(SELECT top 1 id FROM VKBS2.vkb.dbo.Clients WHERE Name = [6# ПОСТАВЩИК_(Указать того, кто направил покупателя к Вам, инфор]) ClientSource_id,
	(SELECT top 1 id from VKBS2.vkb.dbo.BuildingZones where Name = [7# Рассматриваемый для сделки район] AND del = 0) BuildZone_id, 
	(SELECT id FROM VKBS2.vkb.dbo.r_AdvertisingSource where Name = [8# Источник рекламы]) AdvertisingSource_id, 
	[10# Комментарий] Info,
	[12#Желаемое Кол-во комнат] RoomsCount,
	substring([13# Предполагаемый срок приобритения], 1, 1) MonthsCount,
	(SELECT id from VKBS2.vkb.dbo.r_PaymentMethod where del = 0 AND name = [14# Предполагаемый способ оплаты]) PaymentMethod_id,
	@USERID, @USERID, getdate(), getdate()
FROM #t t
where [5# Контактный телефон] IS NOT null AND NOT EXISTS (select 1 from VKBS2.vkb.dbo.r_PotentialClients where mainPhone = t.MainPhone)
