	ALTER TABLE CalcDistribCachePlan drop constraint PK__CalcDist__3214EC072AC4455D
	--DROP INDEX PK__CalcDist__3214EC072AC4455D on CalcDistribCachePlan 
	alter table CalcDistribCachePlan alter column id bigint
	alter table CalcDistribCachePlan add primary key (id)
	--create unique clustered index PK__CalcDist__3214EC072AC4455D on CalcDistribCachePlan(id primary key) 
	sp_help CalcDistribCachePlan
	--truncate table CalcDistribCachePlan
