DECLARE @TableInfo TABLE (
    table_name sysname,
    row_count int,
    reserved_size_kb nvarchar(50),
    data_size_kb nvarchar(50),
    index_size_kb nvarchar(50),
    unused_size_kb nvarchar(50)
)
 
INSERT INTO @TableInfo
EXEC sp_MSforeachtable 'sp_spaceused ''?'''
 
UPDATE @TableInfo 
SET 
    data_size_kb     = replace(data_size_kb, 'KB', ''),
    reserved_size_kb = replace(reserved_size_kb, 'KB', ''),
    index_size_kb    = replace(index_size_kb, 'KB', ''),
    unused_size_kb   = replace(unused_size_kb, 'KB', '')
 
SELECT *, 
    reserved_size_kb/1024 AS reserved_size_mb, 
    data_size_kb/1024 AS data_size_mb, 
    index_size_kb/1024 AS index_size_mb, 
    unused_size_kb/1024 AS unused_size_mb 
FROM @TableInfo 
ORDER BY convert(int, reserved_size_kb) DESC

-- занимаемое на диске место
SELECT TOP 1000
       (row_number() over(order by (a1.reserved + ISNULL(a4.reserved,0)) desc))%2 as l1,
       a3.name AS [schemaname],
       a2.name AS [tablename],
       a1.rows as row_count,
      (a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved,
       a1.data * 8 AS data,
      (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS index_size,
      (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS unused,
      'ALTER TABLE [' + a2.name  + '] REBUILD' as [sql]
  FROM (SELECT ps.object_id,
               SUM(CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows],
               SUM(ps.reserved_page_count) AS reserved,
               SUM(CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END) AS data,
               SUM(ps.used_page_count) AS used
          FROM sys.dm_db_partition_stats ps
          GROUP BY ps.object_id
       ) AS a1
  LEFT JOIN (SELECT it.parent_id,
                    SUM(ps.reserved_page_count) AS reserved,
                    SUM(ps.used_page_count) AS used
               FROM sys.dm_db_partition_stats ps
               INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
               WHERE it.internal_type IN (202,204)
               GROUP BY it.parent_id
            ) AS a4 ON (a4.parent_id = a1.object_id)
  INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )
  INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
  WHERE a2.type <> N'S' and a2.type <> N'IT'
  ORDER BY 8 DESC

