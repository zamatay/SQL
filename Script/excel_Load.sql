-- ������� �������� ������������ �����
select *
  from opendatasource('Microsoft.ACE.OLEDB.12.0','Data Source="D:\0_������_11.07.xlsx";User ID=Admin;Password=;Extended properties="Excel 8.0;IMEX=1"')...[����1$]

select *
  from opendatasource('Microsoft.ACE.OLEDB.12.0','Data Source="D:\0_Domclick-1.xlsx";User ID=Admin;Password=;Extended properties="Excel 8.0;IMEX=1"')...[�������$]

EXEC master..xp_enum_oledb_providers

EXEC sp_configure 'Ad hoc dis'
EXEC sp_configure 'Show Advanced', 1
reconfigure
EXEC sp_configure 'Ad hoc dis', 1
reconfigure

select * from openrowset('Microsoft.ACE.OLEDB.12.0', 'Database=D:\0_������_11.07.xlsx;User ID=Admin;Password=;Extended properties="Excel 8.0;IMEX=1"', [����1$])