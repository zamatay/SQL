declare @s varchar(max) = '';
select @s + 'c_' + name + '=' + cast(id as varchar) + ';
' from _Objects where del = 0 and ObjectsTypes_id in (1,4) and LEFT(name, 1) != '#' and name not like '%$%' and name not like '%.%'
print @s