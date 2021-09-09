-- запросы с высокими издержками на ввод-вывод
SELECT TOP 10
       [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count,
       [Total IO] = (total_logical_reads + total_logical_writes),
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, (CASE
                                                                               WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
                                                                               ELSE qs.statement_end_offset
                                                                             END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average IO] DESC

  -- нагрузку на подсистему ввода-вывода
select top 5 
    (total_logical_reads/execution_count) as avg_logical_reads,
    (total_logical_writes/execution_count) as avg_logical_writes,
    (total_physical_reads/execution_count) as avg_phys_reads,
     Execution_count, 
    statement_start_offset as stmt_start_offset, 
    plan_handle,
    qt.text
  from sys.dm_exec_query_stats  qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  order by  (total_logical_reads + total_logical_writes) Desc

-- i/o-нагрузка на файлы баз
SELECT DB_NAME(saf.dbid) AS [База данных],
       saf.name AS [Логическое имя],
       vfs.BytesRead/1048576 AS [Прочитано (Мб)],
       vfs.BytesWritten/1048576 AS [Записано (Мб)],
       saf.filename AS [Путь к файлу]

  FROM master..sysaltfiles AS saf
  JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
                                                  vfs.fileid = saf.fileid-- AND
                                                  --saf.dbid NOT IN (1,3,4)
  where vfs.BytesRead/1048576 <> 0 or
        vfs.BytesWritten/1048576 <> 0
  ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC



-- i/o-нагрузка на диски
SELECT SUBSTRING(saf.physical_name, 1, 1)    AS [Диск],
       SUM(vfs.num_of_bytes_read/1048576)    AS [Прочитано (Мб)],
       SUM(vfs.num_of_bytes_written/1048576) AS [Записано (Мб)]
  FROM sys.master_files AS saf
  JOIN sys.dm_io_virtual_file_stats(NULL,NULL) AS vfs ON vfs.database_id = saf.database_id AND
                                                         vfs.file_id = saf.file_id AND
                                                         saf.database_id NOT IN (1,3,4) AND
                                                         saf.type < 2
  GROUP BY SUBSTRING(saf.physical_name, 1, 1)
  ORDER BY [Диск]