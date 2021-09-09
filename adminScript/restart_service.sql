-- включить
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 1
RECONFIGURE
--отключить
EXEC sp_configure 'xp_cmdshell', 0
RECONFIGURE
EXEC sp_configure 'show advanced options', 0
RECONFIGURE

-- перезапуск сервиса
EXEC master..xp_cmdshell 'net.exe stop Apache2.2'
EXEC master..xp_cmdshell 'net.exe start Apache2.2'
EXEC master..xp_cmdshell 'net.exe stop Apache2.2 && net.exe start Apache2.2'
EXEC master..xp_cmdshell '"C:\Program Files (x86)\Apache Software Foundation\Apache2.2\bin\httpd.exe" -k restart'
-- копирование файла
EXEC master..xp_cmdshell 'copy "C:\Program Files (x86)\Apache Software Foundation\Apache2.2\modules\VKB_CLR.dll" "c:\Windows\System32\" /Y'
EXEC master..xp_cmdshell 'copy "C:\Program Files (x86)\Apache Software Foundation\Apache2.2\modules\Newtonsoft.Json.dll" "c:\Windows\System32\" /Y'
-- директории
EXEC master..xp_cmdshell 'dir "c:\Program Files\Microsoft SQL Server\"'
