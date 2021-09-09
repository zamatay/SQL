ALTER DATABASE TestBase SET offline
GO
ALTER DATABASE TestBase MODIFY FILE (NAME = xbc_log, FILENAME = "E:\Data\TestBase_log.ldf")
GO
ALTER DATABASE TestBase SET online
GO