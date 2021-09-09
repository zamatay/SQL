-- быстрая загрузка экселевского файла
select *
  from opendatasource('Microsoft.ACE.OLEDB.12.0','Data Source="D:\0_Обзвон_11.07.xlsx";User ID=Admin;Password=;Extended properties="Excel 8.0;IMEX=1"')...[Лист1$]

select *
  from opendatasource('Microsoft.ACE.OLEDB.12.0','Data Source="D:\0_Domclick-1.xlsx";User ID=Admin;Password=;Extended properties="Excel 8.0;IMEX=1"')...[Объекты$]

EXEC master..xp_enum_oledb_providers

EXEC sp_configure 'Ad hoc dis'
EXEC sp_configure 'Show Advanced', 1
reconfigure
EXEC sp_configure 'Ad hoc dis', 1
reconfigure

select * from openrowset('Microsoft.ACE.OLEDB.12.0', 'Database=D:\0_Обзвон_11.07.xlsx;User ID=Admin;Password=;Extended properties="Excel 8.0;IMEX=1"', [Лист1$])