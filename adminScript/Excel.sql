-- 'Microsoft.ACE.OLEDB.12.0'
-- �������������� ������������� �� ������ ����������� ������ 32/64
-- https://www.microsoft.com/en-us/download/details.aspx?id=13255

sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1

insert into VKBS2.vkb_test1.test()
SELECT top 7050 [� �/�], [����� ��������], [���� ��������], [���], [����������], [���� ��������], [���� ����� �� ����������� � ���], [���� ��������� ����� ���-��], [������� ������������ ����������� � ���], [���� ����������� (����� � ���#)], [����������� ���� ��������� �� ����������], [�����������] 
	FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0','Excel 12.0;Database=D:\work\Mikhalev\����� !!! ����������� � ����!!!!!!!!.xlsx','SELECT * FROM [����$]')
WHERE [� �/�] is not null-- for xml  path('a')

GO
