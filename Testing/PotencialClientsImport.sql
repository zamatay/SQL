--SELECT '+7 (' + substring([5# ���������� �������], 2, 3) + ') ' + substring([5# ���������� �������], 5, 3) + '-'+ substring([5# ���������� �������], 8, 2) + '-' + substring([5# ���������� �������], 10, 2) MainPhone, * INTO #t FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;IMEX=1;Database=c:\work\import.xlsx;',[����$]) 
--DROP TABLE #t

DECLARE @USERID INT
SET @USERID = 2734;
INSERT INTO VKBS2.vkb.dbo.r_PotentialClients (Date, Staff_id, FIO, MainPhone, ClientSource_id, BuildingZone_id, AdvertisingSource_id, Info, RoomsCount, MonthsCount, PaymentMethod_id, Editor, Creator, DateEdit, DateCreate)
SELECT 
	cast(substring([1# ����], 1, 10) as DATETIME) Date, 
	--(select id from OurFirms where Name = [2# ��������]) Firm_id,
	(select top 1 id from VKBS2.vkb.dbo.ok_staff where  Family + ' ' + Name + ' ' + Patronymic = [3# ��������-��������]) Staff_id, 
	[4# �#�#�#  �������  (���)] FIO,--+7 (928) 328-41-62
	MainPhone, 
	(SELECT top 1 id FROM VKBS2.vkb.dbo.Clients WHERE Name = [6# ���������_(������� ����, ��� �������� ���������� � ���, �����]) ClientSource_id,
	(SELECT top 1 id from VKBS2.vkb.dbo.BuildingZones where Name = [7# ��������������� ��� ������ �����] AND del = 0) BuildZone_id, 
	(SELECT id FROM VKBS2.vkb.dbo.r_AdvertisingSource where Name = [8# �������� �������]) AdvertisingSource_id, 
	[10# �����������] Info,
	[12#�������� ���-�� ������] RoomsCount,
	substring([13# �������������� ���� ������������], 1, 1) MonthsCount,
	(SELECT id from VKBS2.vkb.dbo.r_PaymentMethod where del = 0 AND name = [14# �������������� ������ ������]) PaymentMethod_id,
	@USERID, @USERID, getdate(), getdate()
FROM #t t
where [5# ���������� �������] IS NOT null AND NOT EXISTS (select 1 from VKBS2.vkb.dbo.r_PotentialClients where mainPhone = t.MainPhone)
