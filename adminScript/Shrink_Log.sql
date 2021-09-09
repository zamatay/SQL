--ALTER DATABASE TestBase SET RECOVERY SIMPLE
BACKUP LOG TestBase  --WITH TRUNCATE_ONLY

DBCC SHRINKFILE (  xbc_log, 1)

/*
Don't do this on a live environment, but to ensure you shrink your dev db as much as you can:
Right-click the database, choose Properties, then Options.
Make sure "Recovery model" is set to "Simple", not "Full"
Click OK
Right-click the database again, choose Tasks -> Shrink -> Files
Change file type to "Log"
Click OK.
*/