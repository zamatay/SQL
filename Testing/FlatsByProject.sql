select * 
	from r_Flats f
	outer apply (select * from r_RealtyObjects ro where ro.id = f.RealtyObject_id) r
where r.FinanceObject_id = 2239 and isSales=0