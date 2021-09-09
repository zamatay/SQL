SELECT  @@Servername AS Server ,
        DB_NAME(database_id) AS DatabaseName ,
        COUNT(database_id) AS Connections ,
        Login_name AS  LoginName ,
        MIN(Login_Time) AS Login_Time ,
        MIN(COALESCE(last_request_end_time, last_request_start_time))
                                                         AS  Last_Batch
FROM    sys.dm_exec_sessions
WHERE   database_id > 0
        AND DB_NAME(database_id) NOT IN ( 'master', 'msdb' )
GROUP BY database_id ,
         login_name
ORDER BY DatabaseName;


-- текущая ситуация на сервере (выполняемые запросы)
select *
  from sys.sysprocesses where spid > 50 and spid <> @@spid and status <> 'sleeping'
  order by spid, ecid


-- какой процессор что делает
SELECT DB_NAME(ISNULL(s.dbid,1)) AS [Имя базы данных],
       c.session_id AS [ID сессии],
       t.scheduler_id AS [Номер процессора],
       s.text AS [Текст SQL-запроса]
  FROM sys.dm_exec_connections AS c
  CROSS APPLY master.sys.dm_exec_sql_text(c.most_recent_sql_handle) AS s
  JOIN sys.dm_os_tasks t ON t.session_id = c.session_id AND
                            t.task_state = 'RUNNING'
  ORDER BY c.session_id DESC