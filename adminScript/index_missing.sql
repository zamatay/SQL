SELECT  @@ServerName AS ServerName ,
        DB_NAME() AS DBName ,
        t.name AS 'Affected_table' ,
        ( LEN(ISNULL(ddmid.equality_columns, N'')
              + CASE WHEN ddmid.equality_columns IS NOT NULL
                          AND ddmid.inequality_columns IS NOT NULL THEN ','
                     ELSE ''
                END) - LEN(REPLACE(ISNULL(ddmid.equality_columns, N'')
                                   + CASE WHEN ddmid.equality_columns
                                                             IS NOT NULL
                                               AND ddmid.inequality_columns
                                                             IS NOT NULL
                                          THEN ','
                                          ELSE ''
                                     END, ',', '')) ) + 1 AS K ,
        COALESCE(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
                    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + COALESCE(ddmid.inequality_columns, '') AS Keys ,
        COALESCE(ddmid.included_columns, '') AS [include] ,
        replace('Create NonClustered Index IDX_' + t.name + '_' + replace(replace(replace(replace(replace(ddmid.equality_columns, '],','_'), '[', ''), ']', ''), '__', '_'), ' ', ''), '__', '_') +
        + ' On ' + ddmid.[statement] COLLATE database_default
        + ' (' + ISNULL(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
                    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + ISNULL(ddmid.inequality_columns, '') + ')'
        + ISNULL(' Include (' + ddmid.included_columns + ');', ';')
                                                  AS sql_statement ,
        ddmigs.user_seeks ,
        ddmigs.user_scans ,
        CAST(( ddmigs.user_seeks + ddmigs.user_scans )
        * ddmigs.avg_user_impact AS BIGINT) AS 'est_impact' ,
        avg_user_impact ,
        ddmigs.last_user_seek ,
        ( SELECT    DATEDIFF(Second, create_date, GETDATE()) Seconds
          FROM      sys.databases
          WHERE     name = 'tempdb'
        ) SecondsUptime 
FROM    sys.dm_db_missing_index_groups ddmig
        INNER JOIN sys.dm_db_missing_index_group_stats ddmigs
               ON ddmigs.group_handle = ddmig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details ddmid
               ON ddmig.index_handle = ddmid.index_handle
        INNER JOIN sys.tables t ON ddmid.OBJECT_ID = t.OBJECT_ID
WHERE   ddmid.database_id = DB_ID()
ORDER BY est_impact DESC

with xmlnamespaces (default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'), p as
(
 select
  quotename(object_schema_name(t.objectid, t.dbid)) + N'.' + quotename(object_name(t.objectid, t.dbid)) as [object_name],
  p.query_plan,
  a.sql_text,
  n.value('@Impact', 'numeric(18,4)') as [query_impact, %],
  n.value('MissingIndex[1]/@Database', 'sysname') + N'.' +
  n.value('MissingIndex[1]/@Schema', 'sysname') + N'.' +
  n.value('MissingIndex[1]/@Table', 'sysname') as table_name,
  n.query('for $c in MissingIndex/ColumnGroup[@Usage="EQUALITY"]/Column order by xs:integer($c/@ColumnId) return concat($c/@Name, ",")').value('.', 'nvarchar(4000)') as equality_columns,
  n.query('for $c in MissingIndex/ColumnGroup[@Usage="INEQUALITY"]/Column order by xs:integer($c/@ColumnId) return concat($c/@Name, ",")').value('.', 'nvarchar(4000)') as inequality_columns,
  n.query('for $c in MissingIndex/ColumnGroup[@Usage="INCLUDE"]/Column order by xs:integer($c/@ColumnId) return concat($c/@Name, ",")').value('.', 'nvarchar(4000)') as included_columns
 from
  sys.dm_exec_query_stats qs cross apply
  sys.dm_exec_query_plan(qs.plan_handle) p cross apply
  p.query_plan.nodes('//MissingIndexes/MissingIndexGroup') px(n) cross apply
  sys.dm_exec_sql_text(qs.plan_handle) t cross apply
  (select substring(t.text, (qs.statement_start_offset / 2) + 1, (case qs.statement_end_offset when -1 then datalength(t.text) else qs.statement_end_offset end - qs.statement_start_offset) / 2 + 1)) a(sql_text)
 where
  n.value('../../..[1]/@QueryHash', 'nvarchar(max)') = cast(qs.query_hash as varchar(max))
)
select
 mid.[statement], mid.equality_columns, mid.inequality_columns, mid.included_columns,
 p.[query_impact, %], p.object_name, p.sql_text, p.query_plan
from
 sys.dm_db_missing_index_details mid join
 p on p.table_name = mid.statement and
      p.equality_columns = isnull(mid.equality_columns + ',', '') and
      p.inequality_columns = isnull(mid.inequality_columns + ',', '') and
      p.included_columns = isnull(mid.included_columns + ',', '');

SELECT  @@ServerName AS ServerName ,
        DB_NAME() AS DBName ,
        t.name AS 'Affected_table' ,
        ( LEN(ISNULL(ddmid.equality_columns, N'')
              + CASE WHEN ddmid.equality_columns IS NOT NULL
                          AND ddmid.inequality_columns IS NOT NULL THEN ','
                     ELSE ''
                END) - LEN(REPLACE(ISNULL(ddmid.equality_columns, N'')
                                   + CASE WHEN ddmid.equality_columns
                                                             IS NOT NULL
                                               AND ddmid.inequality_columns
                                                             IS NOT NULL
                                          THEN ','
                                          ELSE ''
                                     END, ',', '')) ) + 1 AS K ,
        COALESCE(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
                    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + COALESCE(ddmid.inequality_columns, '') AS Keys ,
        COALESCE(ddmid.included_columns, '') AS [include] ,
        'Create NonClustered Index IDX_' + t.name + '_missing_'
        + CAST(ddmid.index_handle AS VARCHAR(20)) + 
        + ' On ' + ddmid.[statement] COLLATE database_default
        + ' (' + ISNULL(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
                    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + ISNULL(ddmid.inequality_columns, '') + ')'
        + ISNULL(' Include (' + ddmid.included_columns + ');', ';')
                                                  AS sql_statement ,
        ddmigs.user_seeks ,
        ddmigs.user_scans ,
        CAST(( ddmigs.user_seeks + ddmigs.user_scans )
        * ddmigs.avg_user_impact AS BIGINT) AS 'est_impact' ,
        avg_user_impact ,
        ddmigs.last_user_seek ,
        ( SELECT    DATEDIFF(Second, create_date, GETDATE()) Seconds
          FROM      sys.databases
          WHERE     name = 'tempdb'
        ) SecondsUptime 
FROM    sys.dm_db_missing_index_groups ddmig
        INNER JOIN sys.dm_db_missing_index_group_stats ddmigs
               ON ddmigs.group_handle = ddmig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details ddmid
               ON ddmig.index_handle = ddmid.index_handle
        INNER JOIN sys.tables t ON ddmid.OBJECT_ID = t.OBJECT_ID
WHERE   ddmid.database_id = DB_ID()
ORDER BY est_impact DESC;



-- итоговое число отсутствующих индексов для каждой базы данных
SELECT [DatabaseName] = DB_NAME(database_id),
       [Number Indexes Missing] = count(*) 
  FROM sys.dm_db_missing_index_details
  GROUP BY DB_NAME(database_id)
  ORDER BY 2 DESC




-- отсутствующие индексы, вызывающие издержки
SELECT TOP 10 
       [Total Cost] = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0),
       avg_user_impact,
       TableName = statement,
       [EqualityUsage] = equality_columns,
       [InequalityUsage] = inequality_columns,
       [Include Cloumns] = included_columns
  FROM sys.dm_db_missing_index_groups g 
  INNER JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle 
  INNER JOIN sys.dm_db_missing_index_details d ON d.index_handle = g.index_handle
  WHERE database_id = DB_ID()
  ORDER BY [Total Cost] DESC;


/*
CREATE index IDX_ObjectsFinance_OurFirm_id_20170123 on ObjectsFinance(OurFirm_id) include([id], [Parent_ID], [Name], [CostInProject]) where del = 0
CREATE index IDX_ObjectsFinance_CostInProject on ObjectsFinance(CostInProject) where del = 0 
*/
