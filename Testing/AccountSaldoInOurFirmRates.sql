
	declare @t table (id int identity, Firm_id int, Date datetime, Value money)
	declare @find_ids table (id int, frv_id int)
	-- месяные периоды за два года
	declare @periods table (id int, begin_Data datetime, end_data datetime)
	insert into @periods
	select id, Begin_Data, End_Data from Period where del = 0 and Group_id=3 and end_data >= Dateadd(year, -2, GETDATE()) and begin_data <= GETDATE()

--#region Остатки на считах СУ
	declare 
		@minDate	DateTime,
		@maxDate	DateTime
	
	select @minDate = min(begin_data), @maxDate = max(end_data) from @periods

	;with 
	-- входящий остаток по счетам и датам
	temp as (
	select 
		Account_ID,
		AccountType,
		SaldoIn,
		date
	from 
		PaymentsSummary ps
	where del = 0 and SaldoIn is not null and (AccountType=1161 or AccountType=26022) and date >= Dateadd(year, -2, GETDATE())
	)
	-- входящий остаток с датами начала и окончания
	,SaldoIn as (
	select temp.*, LEAD(date, 1, @maxDate) OVER(PARTITION BY Account_ID order by Account_ID,date) AS NextDate from temp 
	)
	-- сальдо по периодам
	, summary as (
	select Account_ID, AccountType, s_in.SaldoIn +  a.Summa summa, p.Begin_Data date
		from SaldoIn s_in
		left join @periods p on s_in.Date <= p.End_Data and s_in.NextDate >= p.End_Data
		outer apply (select sum(Income) - sum(outCome) Summa from PaymentsSummary where Account_ID = s_in.Account_ID and date between s_in.date and p.End_Data and del = 0) a
	)
	-- по счетам определяем СУ и считаем сумму по датам
	insert into @t(Firm_id, Date, Value)
	select isnull(sb.client_id, sp.Firm_id), ps.date, sum(Summa)
		from summary ps
			left join AccountsBank sb on sb.id = ps.account_id and sb.del = 0 and ps.AccountType=1161
			left join AccountsPaper sp on sp.id = ps.account_id and sp.del = 0 and ps.AccountType=26022
	where isnull(sb.client_id, sp.Firm_id) is not null and date is not null
	group by isnull(sb.client_id, sp.Firm_id), ps.date

	-- проверяем какие существуют
	insert into @find_ids
	select t.id, frv.id
		from @t t
		join OurFirmRateValues frv on t.Firm_id = frv.OurFirm_id and t.Date=frv.Date and OurFirmRate_id=857

	-- вставляем каких нет
	insert into OurFirmRateValues(Creator, DateCreate, OurFirm_id, OurFirmRate_id, Date, PeriodGroup_id, Value)
	select -1, getDate(), t.Firm_id, 857, t.Date, 3, t.Value
		from @t t
	where t.id not in (select id from @find_ids)

	-- апдейтим которые есть
	update frv set 
		Editor=-1, 
		DateEdit = GetDate(), 
		Value = t.Value
	FROM OurFirmRateValues frv
		join @find_ids f on f.frv_id = frv.id
		join @t t on t.id = f.id
--#endregion

--#region Кредиты Кубань кредит
	delete from @t
	delete from @find_ids
	;with 
	temp as (
	select 
		OurFirm_id,
		SaldoInKK,
		date
	from 
		CreditSummary ps
	where del = 0 and SaldoIn is not null and date >= Dateadd(year, -2, GETDATE())
	)
	,SaldoIn as (select temp.*, LEAD(date, 1, @maxDate) OVER(PARTITION BY OurFirm_id order by OurFirm_id,date) AS NextDate from temp)
	, summary as (
	select OurFirm_id, s_in.SaldoInKK +  a.Summa summa, p.Begin_Data date
		from SaldoIn s_in
		left join @periods p on s_in.Date <= p.End_Data and s_in.NextDate >= p.End_Data
		outer apply (select sum(IncomeKK) - sum(outComeKK) Summa from CreditSummary where OurFirm_id = s_in.OurFirm_id and date between s_in.date and p.End_Data and del = 0) a
	)
	insert into @t(Firm_id, Date, Value)
	select OurFirm_id, ps.date, sum(Summa)
		from summary ps
	where OurFirm_id is not null and date is not null
	group by OurFirm_id, ps.date
	having sum(Summa) is not null

	insert into @find_ids
	select t.id, frv.id
		from @t t
		join OurFirmRateValues frv on t.Firm_id = frv.OurFirm_id and t.Date=frv.Date and OurFirmRate_id=856

	insert into OurFirmRateValues(Creator, DateCreate, OurFirm_id, OurFirmRate_id, Date, PeriodGroup_id, Value)
	select -1, getDate(), t.Firm_id, 856, t.Date, 3, t.Value
		from @t t
	where t.id not in (select id from @find_ids)

	update frv set 
		Editor=-1, 
		DateEdit = GetDate(), 
		Value = t.Value
	FROM OurFirmRateValues frv
		join @find_ids f on f.frv_id = frv.id
		join @t t on t.id = f.id
--#endregion Кредиты Кубань кредит