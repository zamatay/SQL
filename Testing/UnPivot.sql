select * 
	from ProjectRateValues prv
	cross apply (values (cast(Value as varchar), 'Value'), (Description, 'Description')) t2 (value, description)
where prv.value is not null and prv.description is not null

select * 
	from (select id, Cast(Value as varchar(max)) value, cast([Description] as varchar(max)) [Description] from ProjectRateValues where value is not null and description is not null) o
	unpivot ([values] for names IN (Value, [Description])) a

select * 
	from (select * from OurFirmRateValues where ValuePlan is not null) o
	unpivot ([values] for names IN (ValuePlan, Value)) a



select id
		,t.c.value('.', 'FLOAT')
		,t.c.value('local-name(.)', 'sysname')
from
	(select id, x = 
			(select ValuePlan, Value for xml raw('t'), type) from OurFirmRateValues where ValuePlan is not null) p
	cross apply x.nodes('t/@*') t(c)