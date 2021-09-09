DECLARE
      @IsDetailedScan BIT = 0
    , @IsOnline BIT = 0

DECLARE @SQL NVARCHAR(MAX)
SELECT @SQL = (
	SELECT '
	ALTER INDEX [' + i.name + N'] ON [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] ' +
		CASE WHEN s.avg_fragmentation_in_percent > 30
			THEN 'REBUILD WITH (SORT_IN_TEMPDB = ON'
				-- Enterprise, Developer
				+ CASE WHEN SERVERPROPERTY('EditionID') IN (1804890536, -2117995310) AND @IsOnline = 1 THEN ', ONLINE = ON' ELSE '' END + ')'
			ELSE 'REORGANIZE'
		END + ';'
	FROM (
		SELECT s.[object_id], s.index_id, avg_fragmentation_in_percent = MAX(s.avg_fragmentation_in_percent)
		FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, CASE WHEN @IsDetailedScan = 1 THEN 'DETAILED' ELSE 'LIMITED' END) s
		WHERE s.page_count > 128
			AND s.index_id > 0 
			AND s.avg_fragmentation_in_percent > 5
		GROUP BY s.[object_id], s.index_id
	) s
	JOIN sys.indexes i ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
	JOIN sys.objects o ON o.[object_id] = s.[object_id]
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')

exec sp_executesql @SQL

select * FROM
(SELECT 
		s.[object_id]
	, s.index_id
	, avg_fragmentation_in_percent = MAX(s.avg_fragmentation_in_percent)
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, null) s
WHERE s.page_count > 128 -- > 1 MB
	AND s.index_id > 0 -- <> HEAP
	AND s.avg_fragmentation_in_percent > 5
GROUP BY s.[object_id], s.index_id
) s
JOIN sys.indexes i ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
JOIN sys.objects o ON o.[object_id] = s.[object_id]

-- фрагментированные индексы
SELECT TOP 100
       DatbaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       i.type_desc,
       [Fragmentation %] = ROUND(avg_fragmentation_in_percent,2),
       page_count,
       partition_number,
       'alter index [' + i.name + '] on [' + sh.name + '].['+ OBJECT_NAME(s.[object_id]) + '] REBUILD' + case
                                                                                                           when p.data_space_id is not null then ' PARTITION = '+convert(varchar(100),partition_number)
                                                                                                           else ''
                                                                                                         end + ' with(maxdop = 4,  SORT_IN_TEMPDB = on)' [sql]
  FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
  INNER JOIN sys.indexes as i ON s.[object_id] = i.[object_id] AND
                                 s.index_id = i.index_id
  left join sys.partition_schemes as p on i.data_space_id = p.data_space_id
  left join sys.objects o on  s.[object_id] = o.[object_id]
  left join sys.schemas as sh on sh.[schema_id] = o.[schema_id]
  WHERE s.database_id = DB_ID() AND
        i.name IS NOT NULL AND
        OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 and
        page_count > 100 and
        avg_fragmentation_in_percent > 10
  ORDER BY 4, page_count
