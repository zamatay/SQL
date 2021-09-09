declare @Object_Name varchar(max) = 'payments';

select	OBJECT_NAME(S.[OBJECT_ID]),
		I.[NAME] AS [INDEX NAME], 
        sum(USER_SEEKS) USER_SEEKS, 
        sum(USER_SCANS) USER_SCANS, 
        sum(USER_LOOKUPS) USER_LOOKUPS, 
        sum(USER_UPDATES) USER_UPDATES, 'drop index ' + OBJECT_NAME(S.[OBJECT_ID]) + '.' + I.[NAME]
FROM SYS.DM_DB_INDEX_USAGE_STATS AS S 
	JOIN SYS.INDEXES AS I on i.index_id = s.index_id and I.[OBJECT_ID] = S.[OBJECT_ID] and s.object_id > 0
where OBJECT_NAME(S.[OBJECT_ID]) = isnull(@Object_Name, OBJECT_NAME(S.[OBJECT_ID])) and I.[NAME] not like '%pk_%' -- and OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
GROUP by I.[NAME], OBJECT_NAME(S.[OBJECT_ID])
--HAVING sum(USER_SEEKS) + sum(USER_SCANS) + sum(USER_LOOKUPS)=0
order by 3 asc

select	*
FROM SYS.DM_DB_INDEX_USAGE_STATS AS S 
	JOIN SYS.INDEXES AS I on i.index_id = s.index_id and I.[OBJECT_ID] = S.[OBJECT_ID] and s.object_id > 0
where OBJECT_NAME(S.[OBJECT_ID]) = isnull(@Object_Name, OBJECT_NAME(S.[OBJECT_ID])) and I.[NAME] not like '%pk_%' and database_id = db_id() -- and OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
--HAVING sum(USER_SEEKS) + sum(USER_SCANS) + sum(USER_LOOKUPS)=0

--exec sp_mshelpindex IDX_Payments_x_Contracts_id_CreditDebitInternal
--drop index Payments._dta_index_Payments_6_1939089635__K7_K33_K18_K15_K2_K32_K38_K9_K8_K11_10_12_23_24_25_26_36_48_56