-- прописываем необходимые таблицы и колонки для приведения к маске
DECLARE @t TABLE(sTable sysname, sColumn sysname)
    INSERT INTO @t
    SELECT 'OK_Staff', 'PhoneContact'
        UNION
    SELECT 'OK_Staff', 'PhoneHome'
        UNION
    SELECT 'OK_Staff', 'PhoneWork'
        UNION
    SELECT 'Clients', 'PhoneHome'
        UNION
    SELECT 'Clients', 'PhoneWork'
        UNION
    SELECT 'c_Contacts', 'PhoneHome'
        UNION
    SELECT 'c_Contacts', 'PhoneMobile'
        UNION
    SELECT 'c_Contacts', 'PhoneWork'

DECLARE @sql VARCHAR(max)
SET @sql = ''

-- отключаем тригеры
select distinct 
    @sql = @sql + 'DISABLE TRIGGER ' + so.name + ' ON ' + t.sTable + '
	'
from sysobjects so
	join @t t on object_id(t.sTable) = so.parent_obj
where type = 'TR'
exec (@sql)

SET @sql = '';

-- обновляем данные при необходимости включаем транзакцию
--BEGIN TRAN
SELECT
    @sql = @sql + 
    '
     UPDATE '+sTable+' 
        SET '+sColumn+' = 
            ''+7 ('' + 
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 2, 3) + '') ''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 5, 3) + ''-''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 8, 2) + ''-''+
            RIGHT(dbo.DigitNumber('+sColumn+'), 2) output inserted.id, inserted.' + sColumn + ', deleted.'+sColumn+'
    FROM '+sTable+'
    WHERE LEN(dbo.DigitNumber('+sColumn+')) = 11

     UPDATE '+sTable+' 
        SET '+sColumn+' = 
            ''+7 (861) '' + 
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 1, 3) + ''-''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 4, 2) + ''-''+
            RIGHT(dbo.DigitNumber('+sColumn+'), 2) output inserted.id, inserted.' + sColumn + ', deleted.'+sColumn+'
    FROM '+sTable+'
    WHERE LEN(dbo.DigitNumber('+sColumn+')) = 7

    UPDATE '+sTable+' 
        SET '+sColumn+' = 
            ''+7 ('' + 
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 1, 3) + '') ''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 4, 3) + ''-''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 7, 2) + ''-''+
            RIGHT(dbo.DigitNumber('+sColumn+'), 2) output inserted.id, inserted.' + sColumn + ', deleted.'+sColumn+'
    FROM '+sTable+'
    WHERE LEN(dbo.DigitNumber('+sColumn+')) = 10 '
FROM @t

exec (@sql)

-- откатываем или закрываем транзакцию при необходимости
--ROLLBACK TRAN
--COMMIT TRAN


-- включаем тригеры
SET @sql = '';
select distinct 
    @sql = @sql + 'ENABLE TRIGGER ' + so.name + ' ON ' + t.sTable + '
	'
from sysobjects so
	join @t t on object_id(t.sTable) = so.parent_obj
where type = 'TR'
exec (@sql)


declare @s varchar(20) = '440-82-74'

	SELECT '+7 (861) ' + 
			SUBSTRING(dbo.DigitNumber(@s), 1, 3) + '-'+
            SUBSTRING(dbo.DigitNumber(@s), 4, 2) + '-'+
            RIGHT(dbo.DigitNumber(@s), 2)
