-- „тение/запись таблицы
--  учи не рассматриваютс€, у них нет индексов
-- “олько те таблицы, к которым обращались после запуска SQL Server

dbcc show_statistics(_ConfirmVisa, [IDX_ConfirmVisa_Coordination_id]) WITH histogram
dbcc show_statistics(_ConfirmVisa, [IDX_ConfirmVisa_Coordination_id]) WITH density_vector

SELECT  @@ServerName AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_NAME(ddius.object_id) AS TableName ,
        SUM(ddius.user_seeks + ddius.user_scans + ddius.user_lookups)
                                                               AS  Reads ,
        SUM(ddius.user_updates) AS Writes ,
        SUM(ddius.user_seeks + ddius.user_scans + ddius.user_lookups
            + ddius.user_updates) AS [Reads&Writes],
		avg(i.RowCnt) row_count
FROM    sys.dm_db_index_usage_stats ddius
        cross apply (SELECT cast(rowcnt as int) RowCnt FROM dbo.sysindexes WHERE indid = 1 and ddius.object_id = id) i
WHERE    OBJECTPROPERTY(ddius.object_id, 'IsUserTable') = 1
        AND ddius.database_id = DB_ID()
GROUP BY OBJECT_NAME(ddius.object_id)
ORDER BY [Reads&Writes] DESC;
--колонки
SELECT  @@Servername AS Server ,
        DB_NAME() AS DBName ,
        isc.Table_Name AS TableName ,
        isc.Table_Schema AS SchemaName ,
        Ordinal_Position AS  Ord ,
        Column_Name ,
        Data_Type ,
        Numeric_Precision AS  Prec ,
        Numeric_Scale AS  Scale ,
        Character_Maximum_Length AS LEN , -- -1 means MAX like Varchar(MAX) 
        Is_Nullable ,
        Column_Default ,
        Table_Type
FROM     INFORMATION_SCHEMA.COLUMNS isc
        INNER JOIN  information_schema.tables ist
              ON isc.table_name = ist.table_name 
--      WHERE Table_Type = 'BASE TABLE' -- 'Base Table' or 'View' 
ORDER BY DBName ,
        TableName ,
        SchemaName ,
        Ordinal_position;  


-- дата обновлени€ статистики
SELECT STATS_DATE(t1.object_id, stats_id),
      'UPDATE STATISTICS ['+ OBJECT_SCHEMA_NAME(t1.object_id, DB_ID()) + '].[' + object_name(t1.object_id) + ']([' + t1.name + ']) WITH FULLSCAN',
       t4.rows
  FROM sys.stats as t1
  inner join sys.objects as t2 on t1.object_id = t2.object_id
  left join sys.indexes  as t3 on t3.object_id = t1.object_id and
                                  t3.name = t1.name
  left join (select object_id, index_id, sum(rows) as rows
               from sys.partitions 
               group by object_id, index_id
            ) as t4 on t4.object_id = t3.object_id and
                       t4.index_id  = t3.index_id
  where STATS_DATE(t1.object_id, stats_id) < GETDATE()-5 and
        -- не учитываем отключенные индексы
        t3.is_disabled = 0 and
        -- исключаем автостатистику, по идее, в нормально спроектированной системе
        -- она создана по редким ad-hoc запросам, поэтому не €вл€етс€ об€зательной
        -- дл€ принудительного обновлени€
        t1.auto_created = 0 and
        -- исключаем служебные объекты 
        t2.is_ms_shipped = 0
  order by t4.rows