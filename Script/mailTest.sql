--select * from _RequestHistory where post like '%korona%'
--select * from r_Promotions order by id desc
--{"ClientAttach_id":"_ОТСУТСТВУЕТ","ClientSource_id":"_ОТСУТСТВУЕТ","FIO":"Надежда","MainPhone":"+7 (918) 145-77-83","Info":"ЗАЯВКА НА ПОДБОР КВАРТИРЫ     ROISTAT: 311231","Date":"20200327","AdvertisingSource_id":"Интернет","MethodCall_id":"Самообращение","SaleRegion_id":"КРАСНОДАР Краснодарский край","promotion_id":"korona_online","roistat_id":"311231","Ident":"form_korona_online"}

declare 
	@isAgency			bit=0,
	@TypeEvent			int=1,
	@Promotion_id		int,
	@BuildingZone_id	int,
	@City_id			int,
	@ident				varchar(256) = 'form_korona_online'

SELECT mso.id, replace(replace(cast(cast(t.p as xml).query('/a/email') as varchar(max)), '<email>',''), '</email>','') email, b.FileName, mso.Subject, replace(replace(cast(cast(t.p as xml).query('/a/id') as varchar(max)), '<id>',''), '</id>','') ids
from s_MailSendOptions mso
outer apply (select s.email + ',' email, cast(s.id as varchar) + ',' id
				FROM s_MailSendOptionDetail msod
				JOIN OK_Staff s on s.id = msod.Staff_id and s.del = 0 and s.ReleaseDate is NULL and s.email is not NULL
				where msod.del = 0 and msod.MailSendOption_id = mso.Id FOR XML path('a')) as t(p)
outer apply (select top 1 FileName from _Files where del = 0 and table_id = 53009 and line_id = mso.id and FileType_id = 5) b
where 
	mso.del = 0 and isAgency = @isAgency 
	and (TypeEvent = @TypeEvent or isnull(TypeEvent, 0) = 0) 
	and (Promotion_id = @Promotion_id or BuildingZone_id = @BuildingZone_id or City_id = @City_id or ident = @ident
		or (Promotion_id is null and BuildingZone_id is null and ident is null and city_id is null))
order by ident desc, isnull(promotion_id, 0) desc, isnull(BuildingZone_id, 0) desc, isnull(City_id, 0) desc

