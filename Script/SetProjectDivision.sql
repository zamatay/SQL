/*	
INSERT INTO _DivisionDetail (Division_id, OurFirm_id)
SELECT d.Id, _of1.id
	FROM dbo._Divisions d
	join dbo.OurFirms _of1 ON _of1.Name = d.Name and _of1.del = 0-- AND DivisionType_ID = 50

INSERT INTO _DivisionDetail (Division_id, EndDate)
SELECT d.Id, cast('20111231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты до 2012 года' and DivisionType_ID = 42

INSERT INTO _DivisionDetail (Division_id, BeginDate, EndDate)
SELECT d.Id, cast('20120101' as dateTime), cast('20121231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты 2012 года' and DivisionType_ID = 42

INSERT INTO _DivisionDetail (Division_id, BeginDate, EndDate)
SELECT d.Id, cast('20130101' as dateTime), cast('20131231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты 2013 года' and DivisionType_ID = 42

INSERT INTO _DivisionDetail (Division_id, BeginDate, EndDate)
SELECT d.Id, cast('20140101' as dateTime), cast('20141231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты 2014 года' and DivisionType_ID = 42

INSERT INTO _DivisionDetail (Division_id, BeginDate, EndDate)
SELECT d.Id, cast('20150101' as dateTime), cast('20151231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты 2015 года' and DivisionType_ID = 42

INSERT INTO _DivisionDetail (Division_id, EndDate)
SELECT d.Id, cast('20111231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты со сроком ввода в эксплуатацию до 2012г. (объекты по которым будет реализация в 2012г.)'

INSERT INTO _DivisionDetail (Division_id, BeginDate, EndDate)
SELECT d.Id, cast('20120101' as dateTime), cast('20121231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты со сроком ввода в эксплуатацию в 2012г.'

INSERT INTO _DivisionDetail (Division_id, BeginDate)
SELECT d.Id, cast('20130101' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты со сроком ввода в эксплуатацию после 2012г.'

INSERT INTO _DivisionDetail (Division_id, EndDate)
SELECT d.Id, cast('20130101' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты со сроком ввода в эксплуатацию до 2013 года (объекты, по которым будет реализация в 2013 году)'

INSERT INTO _DivisionDetail (Division_id, BeginDate, EndDate)
SELECT d.Id, cast('20130101' as dateTime), cast('20131231 23:59:59:997' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты со сроком ввода в эксплуатацию в 2013 году'

INSERT INTO _DivisionDetail (Division_id, BeginDate)
SELECT d.Id, cast('20140101' as dateTime)
	FROM dbo._Divisions d
where Name = 'Объекты со сроком ввода в эксплуатацию после 2013 года'

*/ 


	DECLARE
		@Object_ID INT
	SELECT @Object_ID = 1439
		
	DECLARE @ProjectIDS TABLE (id INT)
	insert 	INTO @ProjectIDS (id)
	select id FROM dbo.ObjectsFinance WHERE id IN (1,2)

	DELETE FROM _DivisionRowLink 
	WHERE Division_id IN (SELECT id from dbo._Divisions where del = 0 AND DivisionType_ID IN (50, 43, 42, 38, 39, 45, 44))
		AND object_id = @Object_ID AND Line_id IN (SELECT id from @ProjectIDS)
		
/*
1. Привязываем проект к тому разделу, в котором в доп параметрах СУ = СУ в роле проекта:  поставщик ЖБИ (ID=10) .
Для тех проектов, у которых нет такой роли -привязываем к разделу с ID 1744.
*/
	INSERT INTO _DivisionRowLink(Line_ID, Division_ID, Object_ID)	
	SELECT
		P.ID Line_ID
		, ISNULL(Dd.Division_ID, 1744) Division_ID
		, @Object_ID Object_ID
	FROM
		 ObjectsFinance P
		 LEFT JOIN p_OurFirmProjectRoles PR1 ON PR1.Del = 0 AND PR1.Project_id = P.ID and PR1.ProjectRole_id = 10 
		 LEFT JOIN (SELECT OurFirm_ID, Division_ID FROM dbo._DivisionDetail WHERE del = 0 AND Division_id IN (SELECT id FROM _Divisions d WHERE DivisionType_ID = 50)) dd ON dd.OurFirm_ID = Pr1.OurFirm_ID
	WHERE P.Del = 0 and P.name NOT LIKE '%мкр%' AND P.id IN (SELECT id from @ProjectIDS)

/*
2. тип раздела «Застройщики (Без дат)»(43)
OurFirm_id в доп параметрах раздела =  СУ в ролях проекта:Застройщик/Заказчик(1),Генподрядчик(2),Инвестор(8)

*/

	INSERT INTO _DivisionRowLink(Line_ID, Division_ID, Object_ID)	
	SELECT
		P.ID Line_ID
		, ISNULL(Dd.Division_ID, 1744)
		, @Object_ID
	FROM
		 ObjectsFinance P
		 LEFT JOIN p_OurFirmProjectRoles pr ON pr.id = (SELECT TOP 1 ID FROM p_OurFirmProjectRoles WHERE del = 0 AND Project_id = p.ID and ProjectRole_id IN (1,2,8) ORDER BY ProjectRole_id)
		 LEFT JOIN dbo._DivisionDetail dd ON dd.OurFirm_id = pr.OurFirm_id AND dd.Del = 0
		 JOIN dbo._Divisions d ON d.Id = dd.Division_id AND D.DivisionType_ID = 43
	WHERE P.Del = 0 AND dd.Division_ID IS NOT NULL AND P.id IN (SELECT id from @ProjectIDS)

/*
3.
привязываем к разделам 4-го уровня дерева по условиям:
2-й уровень (СУ доп параметров =  название СУ в ролях:Застройщик/Заказчик(1),Генподрядчик(2),Инвестор(8)

3-й уровень по дате из показателя проекта "23. Планируемая дата ввода в эксплуатацию" (14)
к разделам с Доп параметрами BeginDate and EndDate
если дата пустая или больше 31.12.2015г. то к 
"Дата ввода не определена"

4-уровень по полю "тип проекта" из проекта
тип "Жилое здание" (1) к разделу с наименованием "Жилые здания"
остальные типы к разделу с наименованием "Прочие объекты"


*/


	declare @division table (id INT, Firm_id INT, Ident INT, BeginDate DateTime, EndDate DateTime)

	INSERT INTO @division
	select d4.Id, dd2.OurFirm_id, case WHEN d4.Name = 'Жилые здания' THEN 1 ELSE NULL END, dd1.BeginDate, dd1.EndDate
	FROM dbo._Divisions d4
		LEFT JOIN dbo._Divisions d3 ON d3.Id = d4.Parent_ID
		LEFT JOIN dbo._DivisionDetail dd1 ON dd1.Division_id=d3.id
		LEFT JOIN dbo._Divisions d2 ON d2.Id = d3.Parent_ID
		LEFT JOIN dbo._DivisionDetail dd2 ON dd2.Division_id=d2.id
	where NOT EXISTS (SELECT 1 from _Divisions where del = 0 AND Parent_ID = d4.id) AND d4.DivisionType_ID = 42 AND d4.del = 0

	INSERT INTO _DivisionRowLink(Line_ID, Division_ID, Object_ID)	
	SELECT 
		P.ID Line_ID
		, D.id Division_ID
		, @Object_ID Object_ID
	FROM 
		 ObjectsFinance P
		 JOIN p_OurFirmProjectRoles pr ON pr.id = (SELECT TOP 1 ID FROM p_OurFirmProjectRoles WHERE del = 0 AND Project_id = p.ID and ProjectRole_id IN (1,2,8) ORDER BY ProjectRole_id)
		 join (select ObjectFinance_id, CASE WHEN [Date] > '20150101' THEN NULL ELSE [Date] END [Date] from ProjectRateValues where del = 0 and ProjectRate_id = 14 AND ObjectFinance_id IS NOT null) prv on prv.ObjectFinance_id = p.id
		 JOIN @division d on d.Firm_id = pr.OurFirm_id 
			and ((prv.Date between ISNULL(d.BeginDate, 0) and isnull(d.EndDate, '99991212') AND isnull(d.BeginDate, d.EndDate) IS NOT null) OR COALESCE(prv.Date, d.BeginDate, d.EndDate, 0) = 0)
			and p.ObjectFinanceType_id = ISNULL(d.Ident, nullIF(p.ObjectFinanceType_id, 1))
		LEFT join dbo._Divisions d1 ON d1.Id = d.id
	WHERE P.Del = 0 AND P.id IN (SELECT id from @ProjectIDS)


/*
4. тип раздела «План 2012 (отчет по недвижимости)» (38)

по показателю проекта "23. Планируемая дата ввода в эксплуатацию" (14)
к разделам с Доп параметрами BeginDate and EndDate

*/

	INSERT INTO _DivisionRowLink(Line_ID, Division_ID, Object_ID)	
	SELECT 
		P.ID Line_ID
		, D.id Division_ID
		, @Object_ID Object_ID
	FROM 
		 ObjectsFinance P
		 JOIN (select ObjectFinance_id, [Date] from ProjectRateValues where del = 0 and ProjectRate_id = 14) prv on prv.ObjectFinance_id = p.id
		 LEFT JOIN dbo._DivisionDetail dd ON prv.[Date] BETWEEN ISNULL(dd.BeginDate, 0) AND ISNULL(dd.EndDate, '99991212') AND isnull(dd.BeginDate, dd.EndDate) IS NOT null
		 JOIN dbo._Divisions d on d.id = dd.Division_id AND d.DivisionType_ID = 38
	WHERE P.Del = 0 AND P.id IN (SELECT id from @ProjectIDS)

/*
5. тип раздела «План 2012 (свод по проектам)» (39)
привязываем к разделам 3-го уровня дерева по условиям:

2-й уровень дерева по доп показателям =
показателю проекта "23. Планируемая дата ввода в эксплуатацию" (14)

3-й уровень по полю "тип проекта" из проекта
тип "Жилое здание" (1) к разделу с наименованием "Жилые здания"
остальные типы к разделу с наименованием "Прочие объекты"

*/
	DELETE FROM @division
	
	INSERT INTO @division(id, ident, begindate, enddate)
	SELECT DISTINCT d3.Id, case WHEN d3.Name = 'Жилые здания' THEN 1 ELSE NULL END, dd.BeginDate, dd.EndDate
	FROM dbo._Divisions d3
		LEFT JOIN dbo._Divisions d2 ON d2.Id = d3.Parent_ID
		LEFT JOIN dbo._DivisionDetail dd ON dd.Division_id=d2.id
	WHERE NOT EXISTS (SELECT 1 from _Divisions where del = 0 AND Parent_ID = d3.id) AND d3.DivisionType_ID = 39 AND d3.del = 0

	INSERT INTO _DivisionRowLink(Line_ID, Division_ID, Object_ID)	
	SELECT
		P.ID Line_ID
		, D.id Division_ID
		, @Object_ID
	FROM 
		 ObjectsFinance P
		 JOIN (select ObjectFinance_id, [Date] from ProjectRateValues where del = 0 and ProjectRate_id = 14) prv on prv.ObjectFinance_id = p.id
		 JOIN @division d on prv.Date between ISNULL(d.BeginDate, 0) and isnull(d.EndDate, '99991212') AND isnull(d.BeginDate, d.EndDate) IS NOT null
			and p.ObjectFinanceType_id = ISNULL(d.Ident, nullif(p.ObjectFinanceType_id, 1))
	WHERE P.Del = 0 AND P.id IN (SELECT id from @ProjectIDS)

	

/*
6. тип раздела «План 2013 (отчет по недвижимости)» (45)
по показателю проекта "23. Планируемая дата ввода в эксплуатацию" (14)

*/

	INSERT INTO _DivisionRowLink(Line_ID, Division_ID, Object_ID)	
	SELECT
		P.ID Line_ID
		, D.id Division_ID
		, @Object_ID Object_ID
	FROM 
		 ObjectsFinance P
		 JOIN (select ObjectFinance_id, [Date] from ProjectRateValues where del = 0 and ProjectRate_id = 14) prv on prv.ObjectFinance_id = p.id
		 LEFT JOIN dbo._DivisionDetail dd ON prv.[Date] BETWEEN ISNULL(dd.BeginDate, 0) AND ISNULL(dd.EndDate, '99991212') OR COALESCE(prv.Date, dd.BeginDate, dd.EndDate, 0) = 0
		 JOIN dbo._Divisions d on d.id = dd.Division_id AND d.DivisionType_ID = 45
	WHERE P.Del = 0 AND P.id IN (SELECT id from @ProjectIDS)


/*
7. «План 2013 (свод по проектам)» (44)

доп параметр 2-го уровеня дерева 
по показателю проекта "23. Планируемая дата ввода в эксплуатацию" (14)

3-й уровень по полю "тип проекта" из проекта
тип "Жилое здание" (1) к разделу с наименованием "Жилые здания"
остальные типы к разделу с наименованием "Прочие объекты"

*/

	DELETE FROM @division
	
	INSERT INTO @division(id, ident, begindate, enddate)
	select d3.Id, case WHEN d3.Name = 'Жилые здания' THEN 1 ELSE NULL END, dd.BeginDate, dd.EndDate
	FROM dbo._Divisions d3
		LEFT JOIN dbo._Divisions d2 ON d2.Id = d3.Parent_ID
		LEFT JOIN dbo._DivisionDetail dd ON dd.Division_id=d2.id
	WHERE NOT EXISTS (SELECT 1 from _Divisions where del = 0 AND Parent_ID = d3.id) AND d3.DivisionType_ID = 44 AND d3.del = 0

	INSERT INTO _DivisionRowLink(Line_ID, Division_ID, Object_ID)	
	SELECT
		P.ID Line_ID
		, D.id Division_ID
		, @Object_ID Object_ID
	FROM 
		 ObjectsFinance P
		 JOIN (select ObjectFinance_id, [Date] from ProjectRateValues where del = 0 and ProjectRate_id = 14) prv on prv.ObjectFinance_id = p.id
		 JOIN @division d on prv.Date between ISNULL(d.BeginDate, 0) and isnull(d.EndDate, '99991212') AND isnull(d.BeginDate, d.EndDate) IS NOT null
			and p.ObjectFinanceType_id = ISNULL(d.Ident, nullif(p.ObjectFinanceType_id, 1))
	WHERE P.Del = 0 AND P.id IN (SELECT id from @ProjectIDS)