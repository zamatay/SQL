-- проверка базы
DBCC CHECKDB WITH NO_INFOMSGS;

-- размер файлов логов
DBCC SQLPERF (Logspace) 

-- исправляет неточности в подсчете страниц для всех баз
exec sp_msforeachdb 'USE ?; DBCC UPDATEUSAGE(?)'

-- чистим tempdb без перезапуска сервера
DBCC FREESYSTEMCACHE ('ALL')
DBCC SHRINKFILE (N'XBC_data' , 0, TRUNCATEONLY)

-- ставим "контрольную точку" для всех баз
exec sp_msforeachdb 'USE ?; CHECKPOINT'