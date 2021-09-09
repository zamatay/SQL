	declare @IDs xml
	SELECT @IDs = (SELECT id flat_id from r_Flats for xml path('row'))
	exec r_checkFlats @IDs
