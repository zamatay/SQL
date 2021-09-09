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

SELECT
    @sql = @sql + 
	'
     UPDATE '+sTable+' 
        SET '+sColumn+' = 
            ''+7 ('' + 
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 2, 3) + '') ''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 4, 3) + ''-''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 7, 2) + ''-''+
            RIGHT(dbo.DigitNumber('+sColumn+'), 2)
    FROM '+sTable+'
    WHERE LEN(dbo.DigitNumber('+sColumn+')) = 11

     UPDATE '+sTable+' 
        SET '+sColumn+' = 
            ''+7 (861) '' + 
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 1, 3) + ''-''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 4, 2) + ''-''+
            RIGHT(dbo.DigitNumber('+sColumn+'), 2)
    FROM '+sTable+'
    WHERE LEN(dbo.DigitNumber('+sColumn+')) = 7

    UPDATE '+sTable+' 
        SET '+sColumn+' = 
            ''+7 ('' + 
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 1, 3) + '') ''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 3, 3) + ''-''+
            SUBSTRING(dbo.DigitNumber('+sColumn+'), 6, 2) + ''-''+
            RIGHT(dbo.DigitNumber('+sColumn+'), 2)
    FROM '+sTable+'
    WHERE LEN(dbo.DigitNumber('+sColumn+')) = 10 '
FROM @t


    exec (@sql)

select * from OK_Staff where 
phonework not like '+7 ([0-9][0-9][0-9]) [0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' or phonecontact not like '+7 ([0-9][0-9][0-9]) [0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' or phonehome not like '+7 ([0-9][0-9][0-9]) [0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
