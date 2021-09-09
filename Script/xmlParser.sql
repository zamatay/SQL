declare @xml xml =
'<p>1</p><p>2</p><p>3</p><p>4</p><p>5</p><p>6</p>'

select @xml.query(N'p[last()]')


WITH temp as (
	select id, cast('<a>' + replace(replace(replace(replace(replace(info, ' ', '</a><a>'), ',', '</a><a>'), '\', '</a><a>'), ' ', '</a><a>'), char(13)+char(10), '</a><a>') + '</a>' AS XML) info
	from r_PotentialClients a 
	where Info LIKE '%@%'
), temp_1 as
(
	SELECT temp.id, p.value('.', 'VARCHAR(max)') words
	FROM temp
		cross apply temp.Info.nodes('/a') as t(p)
)
, result AS (SELECT id, words email FROM temp_1 WHERE Words LIKE '%@%')

SELECT * FROM result

UPDATE c SET email = a.email
FROM dbo.r_PotentialClients c
	JOIN result a ON a.id = c.id 


SELECT * FROM dbo.r_PotentialClients where email IS NOT null

SELECT Id, Name FROM k_PowerBuyerTypes where del = 0

-- парсер строки с запятыми
select @xml = '<a>' + REPLACE(@DocIDs, ',', '</a><a>') + '</a>'
INSERT INTO @IDs
select  p.value('.', 'VARCHAR(max)') from @xml.nodes('/a') as t(p)


/*
WITH temp as (
	select id, cast('<a>' + replace(replace(replace(replace(replace(info, ' ', '</a><a>'), ',', '</a><a>'), '\', '</a><a>'), ' ', '</a><a>'), char(13)+char(10), '</a><a>') + '</a>' AS XML) info
	from r_PotentialClients a 
	where Info LIKE '%@%'
)
--select * from temp
select Info.query('/a').value('.', 'varchar(max)') from temp

select Info.query('
   for $step in /a
   return string($step)
')--.nodes('/a') --as t(p)
	from temp
	
, temp_1 as
(
	SELECT a.id, p.value('.', 'VARCHAR(max)') words
	FROM temp a
		cross apply a.Info.nodes('/a') as t(p)
)
, result AS (SELECT id, words email FROM temp_1 WHERE Words LIKE '%@%')

SELECT * FROM result

with cte as (
select cast(t AS XML).query('/a').value('.', 'varchar(max)') readed,  d.id--, Right(cast(t AS xml).query('/a').value('.', 'varchar(max)'), len(cast(t AS xml).query('/a').value('.', 'varchar(max)'))-1) --d.id, t.query('/a').value('.', 'varchar(max)')
FROM DS_Disposals  d
	CROSS APPLY (SELECT ',' + Family
					FROM DS_Readed r
					left join OK_Staff s on r.Personal=s.id					
				where r.del = 0 AND r.Disposal=d.id
				FOR XML path('a') ) r(t)
where d.del = 0)
SELECT id, right(readed, len(readed)-1) 
FROM cte

select * FROM (
SELECT ',' + Family
	FROM DS_Readed r
	left join OK_Staff s on r.Personal=s.id					
where r.del = 0 
FOR XML path('a')).nodes('/a') t(p)
*/

DECLARE @xml XML = N'
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <dict_CitiesResponse xmlns="http://ltl-ws.major-express.ru/edclients/">
      <dict_CitiesResult>
        <EDCity>
          <Code>73</Code>
          <Name>Архангельск</Name>
          <EngName>ARKHANGELSK</EngName>
          <IsShipper>true</IsShipper>
        </EDCity>
        <EDCity>
          <Code>74</Code>
          <Name>Астрахань</Name>
          <EngName>ASTRAKHAN</EngName>
          <IsShipper>true</IsShipper>
        </EDCity>
        <EDCity>
          <Code>75</Code>
          <Name>Барнаул(Алтайский край)</Name>
          <EngName>BARNAUL</EngName>
          <IsShipper>true</IsShipper>
        </EDCity>
        <EDCity>
          <Code>76</Code>
          <Name>Белгород</Name>
          <EngName>BELGOROD</EngName>
          <IsShipper>true</IsShipper>
        </EDCity>
      </dict_CitiesResult>
    </dict_CitiesResponse>
  </soap:Body>
</soap:Envelope>'

SELECT b.n.value('(*:Code/text())[1]', 'INT') AS CodeCity
     , b.n.value('(*:Name/text())[1]', 'NVARCHAR(200)') AS NameCity
     , b.n.value('(*:EngName/text())[1]', 'NVARCHAR(200)') AS EngName
     , b.n.value('(*:IsShipper/text())[1]', 'VARCHAR(10)') AS IsShipper
FROM @xml.nodes('//*:EDCity') b(n)

;WITH XMLNAMESPACES(DEFAULT 'http://ltl-ws.major-express.ru/edclients/')
SELECT b.n.value('(Code/text())[1]', 'INT') AS CodeCity
     , b.n.value('(Name/text())[1]', 'NVARCHAR(200)') AS NameCity
     , b.n.value('(EngName/text())[1]', 'NVARCHAR(200)') AS EngName
     , b.n.value('(IsShipper/text())[1]', 'VARCHAR(10)') AS IsShipper
FROM @xml.nodes('//EDCity') b(n)