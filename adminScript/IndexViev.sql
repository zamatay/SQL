SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF

IF object_id('dbo.viewName', 'V') IS NOT NULL
	DROP VIEW dbo.viewName
GO

CREATE VIEW dbo.viewName
WITH SCHEMABINDING AS
	select id, 911 object_id, cast(dbo.DigitNumber(PhoneHome) as varchar(30)) phone_1, cast(dbo.DigitNumber(PhoneWork) as varchar(30)) phone_2
	from dbo.Clients 
	where del = 0 and (PhoneHome is not null or PhoneWork is not null)

GO
CREATE UNIQUE CLUSTERED INDEX IDX_viewName
ON dbo.viewName(id)
-- может ли вьюха быть индексированной
SELECT objectproperty(object_id('viewName'), 'IsIndexable');
-- занимаемое место
sp_spaceused 'viewName'