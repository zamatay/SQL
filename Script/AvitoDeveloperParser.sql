declare @xml xml

SELECT @xml = CONVERT(xml, BulkColumn, 2) 
FROM OPENROWSET(BULK 'D:\New_developments.xml', SINGLE_BLOB) as x

select 
	housing.item.value('@name', 'varchar(max)') as name,
	housing.item.value('../@name', 'varchar(max)') as name,
	housing.item.value('@id', 'int') as id,
	housing.item.value('@address', 'varchar(max)') as address,
	Developer.item.value('@id', 'int') as bz_id,
	Developer.item.value('@name', 'varchar(max)') as bz,
	Developer.item.value('@developer', 'varchar(max)') as developer,
	Region.item.value('@name', 'varchar(max)') as regionName,
	Region.item.value('City[1]/@name', 'varchar(max)') as regionName,
	City.item.value('@name', 'varchar(max)') as cityName
from @xml.nodes('Developments/Region') Region(Item)
	outer apply Region.Item.nodes('City') City(Item)
	outer apply City.Item.nodes('Object') Developer(item)
	outer apply Developer.item.nodes('Housing') housing(item)
where Region.item.value('@name', 'varchar(max)') in ('Краснодарский край', 'Адыгея', 'Ростовская область')
--where Region.item.exist('.[@name="Краснодарский край"]')=1 --in ('Краснодарский край', 'Адыгея', 'Ростовская область')
