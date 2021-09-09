DECLARE @CurrencyID INT
SET @CurrencyID = 31
	SELECT 
		PR.PROJECTID, PER.ID, 
		sum(CASE
		   WHEN CreditDebitInternal = 1 THEN
			   Summa
		   WHEN CreditDebitInternal = 0 THEN
			   -Summa
	   END * pv.curs / nullif(rv.curs, 0)) AS Summa
		 ,
		 -- если расход то просто проект оставляет свой тип если приход или премии то сдвигае тип тоесть приход станет -6 а премии -7
		 CASE
			 WHEN o.CostType = 4 THEN
				 pr.[Type]
			 WHEN o.CostType > 4 THEN
				 o.CostType + 1
		 END
		   , pr.[fDistributedType]
		   , s.CreditDebit_id
		   , s.id
	FROM
		Payments p
		LEFT JOIN Period per ON per.id = (SELECT id FROM Period WHERE p.del = 0 AND p.DatePay BETWEEN Begin_Data AND End_Data AND group_id = 3)
		JOIN states s ON s.id = p.State_id
		JOIN #States o ON o.StateID = s.ParentState_id or o.StateID = s.id -- статьи по операционной деятельности AND o.CostType = pr.[Type]
		LEFT JOIN curs pv ON pv.id = (SELECT TOP 1 id FROM curs WHERE Del = 0 AND Valuta_id = p.Valuta AND Data <= p.DatePay ORDER BY Data DESC)
		LEFT JOIN curs rv ON rv.id = (SELECT TOP 1 id FROM curs WHERE Del = 0 AND Valuta_id = @CurrencyID AND Data <= p.DatePay ORDER BY Data DESC)
		LEFT JOIN (SELECT ProjectID, ParentProjectID, [Type], [fDistributedType] FROM #Projects WHERE [Type] IN (1, 2, 3, 4, 5)) pr
			ON ((pr.ProjectID = p.ObjectFinance_id AND o.CostType IN (4, 5, 6) AND pr.[Type] IN (1, 2, 3)) OR (pr.ProjectID = -p.Departament_id AND (o.CostType = 4 OR (pr.[Type] = 4 AND o.CostType = 5)) AND pr.[Type] IN (4, 5))) AND p.OurFirms_id IN (SELECT FirmID FROM #FirmIDs)
	WHERE
		isnull(Summa, 0) <> 0
		AND p.del = 0
		AND p.DateClose IS NOT NULL
		AND pr.ProjectID IS NOT NULL
		AND isnull(p.Client_id, 0) NOT IN (SELECT clientid FROM #Clients WHERE firmid = p.OurFirms_id)
	GROUP BY
		pr.ProjectID
	  , Per.id
	  , o.DistribType
	  , CASE
			WHEN o.CostType = 4 THEN
				pr.[Type]
			WHEN o.CostType > 4 THEN
				o.CostType + 1
		END
	  , pr.[fDistributedType]
	  , s.CreditDebit_ID
	  , s.id


SELECT * FROM #states




SET STATISTICS TIME OFF
IF OBJECT_ID('tempdb..#FirmIDs') IS NOT NULL
	DROP TABLE #FirmIDs
IF OBJECT_ID('tempdb..#States') IS NOT NULL
	DROP TABLE #States
IF OBJECT_ID('tempdb..#Projects') IS NOT NULL
	DROP TABLE #Projects
IF OBJECT_ID('tempdb..#ProjectFact') IS NOT NULL
	DROP TABLE #ProjectFact
IF OBJECT_ID('tempdb..#ProjectPlan') IS NOT NULL
	DROP TABLE #ProjectPlan
IF OBJECT_ID('tempdb..#Coef') IS NOT NULL
	DROP TABLE #Coef
IF OBJECT_ID('tempdb..#ProjectIDs') IS NOT NULL
	DROP TABLE #ProjectIDs
IF OBJECT_ID('tempdb..#Plan') IS NOT NULL
	DROP TABLE #Plan
IF OBJECT_ID('tempdb..#Fact') IS NOT NULL
	DROP TABLE #Fact
IF OBJECT_ID('tempdb..#BudgetsVersions') IS NOT NULL
	DROP TABLE #BudgetsVersions
IF OBJECT_ID('tempdb..#Clients') IS NOT NULL
	DROP TABLE #Clients
IF OBJECT_ID('tempdb..#TempPlan') IS NOT NULL 
	DROP TABLE #TempPlan
IF OBJECT_ID('tempdb..#TempFact') IS NOT NULL 
	DROP TABLE #TempFact
IF OBJECT_ID('tempdb..#ReadyPlan') IS NOT NULL 
	DROP TABLE #ReadyPlan
IF OBJECT_ID('tempdb..#ReadyFact') IS NOT NULL 
	DROP TABLE #ReadyFact
IF OBJECT_ID('tempdb..#Payments') IS NOT NULL 
	DROP TABLE #Payments
IF OBJECT_ID('tempdb..#f') IS NOT NULL 
	DROP TABLE #f
IF OBJECT_ID('tempdb..#Budgets') IS NOT NULL
	DROP TABLE #Budgets
IF OBJECT_ID('tempdb..#p') IS NOT NULL 
	DROP TABLE #p
IF OBJECT_ID('tempdb..#prj') IS NOT NULL 
	DROP TABLE #prj
IF OBJECT_ID('tempdb..#fTemp') IS NOT NULL  
  DROP TABLE #fTemp
IF OBJECT_ID('tempdb..#pTemp') IS NOT NULL 
  DROP TABLE #pTemp
IF OBJECT_ID('tempdb..#LimitFactor') IS NOT NULL 
  DROP TABLE #LimitFactor

GO

-- определяем начальные данные
-------------------------------------------------------------------------------------------------------
DECLARE
    @StartDate          DateTime,
    @StartPeriod        int,
    @FinishDate         DateTime,
    @FinishPeriod       int,
    @CurrencyID         int,
    @CostTemplateID     int,
    @Level              int,
    @BudgetsGroupID     int,
    @SalesPlanGroupID   int,
    @ExcludeInternal	INT,
    @SalesPlanValuesID  int,
    @GroupPeriodID      INT, 
    @WithProject        BIT,
    @ProjectRate        INT,
    @ConfirmLevel       INT,
    @VersionDate        DATETIME,
    @ProjectEndRates    INT,
    @ByStates			BIT

CREATE TABLE #FirmIDs(FirmID INT)
CREATE TABLE #States(id INT IDENTITY)
CREATE TABLE #Projects(id INT IDENTITY)
CREATE TABLE #ProjectFact(id INT IDENTITY)
CREATE TABLE #ProjectPlan(id INT IDENTITY)
CREATE TABLE #Coef(id INT IDENTITY)
CREATE TABLE #ProjectIDs(ProjectID INT, EndPeriod INT)
CREATE TABLE #Plan(id INT IDENTITY)
CREATE TABLE #Fact(id INT IDENTITY)
CREATE TABLE #BudgetsVersions(id INT IDENTITY)
           
DECLARE @RC BIT
EXECUTE @RC = pd_AddColumnForCalcProject
IF @RC = 0
BEGIN
    DECLARE @Str VARCHAR(128)
    SET @Str = 'Не найдена одна из необходимых таблиц'
    RAISERROR(@Str, 16, 1)
    RETURN
END

SELECT @GroupPeriodID = 3

INSERT INTO #FirmIDs(FirmID)
SELECT id 
FROM OurFirms
WHERE del = 0 and ( id in (12,35,39,40,44,128) )  

SELECT  @StartDate = '20100101', @FinishDate = '20100228 23:59:59', @CurrencyID = 31, 
        @ExcludeInternal = 2, @CostTemplateID = 24, @BudgetsGroupID = 1, 
        @SalesPlanGroupID = 1, @WithProject = 0, @ProjectRate = 1,
        @ConfirmLevel = ISNULL(10, i), @VersionDate = '20140101', @ProjectEndRates = 15
        
FROM _GlobalOptions
WHERE Name = 'BudgetConfirmLevel'

INSERT INTO #ProjectIDs(ProjectID, EndPeriod)
SELECT DISTINCT _of.id, case when isOwner is null then 0 else p.id end 
FROM ObjectsFinance _of
    LEFT JOIN ProjectRateValues prv on prv.ProjectRate_id = @ProjectEndRates and prv.ObjectFinance_id = _of.id and prv.del = 0 
    LEFT JOIN Period p on prv.Date BETWEEN Begin_Data AND End_Data AND group_id = @GroupPeriodID
    JOIN dbo.p_OurFirmProjectRoles ofpr ON _of.id = ofpr.Project_id AND ofpr.del = 0 AND ofpr.OurFirm_id IN (SELECT FirmID FROM #FirmIDs)
    left join (SELECT DISTINCT Project_id, 1 isOwner from p_OurFirmProjectRoles where ProjectRole_id = 1 AND ourFirm_id IN (SELECT FirmID FROM #FirmIDs)) isOwner
        on isOwner.Project_id  = _of.id
WHERE [_of].del = 0 AND  not (_of.id is null )  AND _of.id in (SELECT DISTINCT Project_id FROM dbo.p_OurFirmProjectRoles 
                                                                               WHERE del = 0 AND ISNULL(ProjectRole_id, 0) IN ( ISNULL(ProjectRole_id, 0) )
                                                                                   AND OurFirm_id IN (SELECT FirmID FROM #FirmIDs)
                                                                               )   
-- отбираем действующие версии бюджета
INSERT INTO #BudgetsVersions(BudgetVersion_id, BudgetsGroup_id)
SELECT a.id, a.BudgetsGroup_id 
	FROM dbo.GetBudgetVersion(@ConfirmLevel, @VersionDate) a
	JOIN dbo.BudgetsVersions bv ON bv.Id = a.id AND bv.BudgetsGroup_id = @BudgetsGroupID
WHERE
	bv.OurFirm_id IN (SELECT FirmID from #FirmIDs)


DECLARE 
	@BudgetObject_ID	INT,
	@DistrType			INT
	
SELECT @DistrType = i FROM _GlobalOptions WHERE name = 'AfterLimitFactor'

SELECT @BudgetObject_ID = dbo._GetIDObject(1, 'Budget')

CREATE TABLE #Clients (id INT IDENTITY, ClientID INT, FirmID INT)
INSERT INTO #Clients (ClientID
					, FirmID)
SELECT Client_id
	 , fi.FirmID
FROM
	dbo.OurFirms _of
	JOIN #FirmIDs fi
		ON (@ExcludeInternal = 2 AND _of.id IN (SELECT id
												FROM
													dbo.OurFirms
												WHERE
													isnull(parent_id, id) IN (SELECT isnull(Parent_ID, id)
																			  FROM
																				  dbo.OurFirms
																			  WHERE
																				  id = fi.FirmID
																				  AND id IN (SELECT FirmID
																							 FROM
																								 #FirmIDs)))) OR (@ExcludeInternal = 1 AND _of.id IN (SELECT FirmID
																																					  FROM
																																						  #FirmIDs))
WHERE
	_of.del = 0

-- Статьи участвующие в расчете
-- CostType =x
--1	Затраты по ЦФО
--2	Затраты по родительскому проекту
--3	Затраты по распределяемому проекту
--4	Прямые затраты на проект
--5	Поступления по проекту
---------------------------------------------------------------------------------------------------------------------------------
INSERT #States (StateID
			  , DistribType
			  , CostType
			  , CostDivisionID
			  , checkPeriod)
SELECT ctd.State_id
	 , ctd.DistribType_id
	 , ctd.CostsType_id
	 , ctd.CostDivision_id
	 , dt.CheckPeriod
FROM
	CostTemplatesDetail ctd
	LEFT JOIN dbo.DistribTypes dt
		ON dt.id = ctd.DistribType_id
WHERE
	ctd.del = 0
	AND ctd.CostTemplate_id = @CostTemplateID --AND CostsType_id IN (1,2,3,4,5,6)

-- Заполняем таблицу с проектами
-- Type  = 
-- 1 - Проекты СУ которые выбраны в таблицу #FirmIDs
-- 2 - Распределяемые проекты - Родители нащих проектов с Type = 1
-- 3 - Распределяемый проект - Общий с родительским у которого стоит признак распределять
-- 4 - ОХЗ СУ у которых не стоит признак распределять
-- 5 - ОХЗ СУ у которых стоит признак распределять
---------------------------------------------------------------------------------------------------------------------------------
-- определяем все проекты используемые в расчетах
	-- проекты которые выбрал пользователь и являются конечными расчетными, т.е. не родительский и не распределяемый

PRINT 'pd_GetProjects---------------------------------------------------------------------------------'
SET STATISTICS TIME ON
	
DECLARE 
	@FinishDate_	DateTime 

-- отбираем проекты с Ролей выбранных СУ у которых нет признака распределять с него.
INSERT #Projects (ProjectID, ParentProjectID, Type)
SELECT DISTINCT ofpr.Project_id, of1.Parent_ID, 1
FROM
	dbo.p_OurFirmProjectRoles ofpr
	JOIN dbo.ObjectsFinance of1
		ON of1.id = ofpr.Project_id AND of1.del = 0 AND isnull(CostInProject, 0) <> 1
WHERE
	ofpr.del = 0
	AND ofpr.OurFirm_id IN (SELECT FirmID
							FROM
								#FirmIDs)
	AND NOT EXISTS (SELECT 1
					FROM
						dbo.ObjectsFinance
					WHERE
						parent_id = of1.id
						AND Del = 0) -- не родительский

-- проекты родители отобранных проектов
INSERT #Projects (ProjectID, Type)
SELECT DISTINCT of1.id, 2
FROM
	ObjectsFinance of1
	JOIN #Projects p
		ON of1.id = p.ParentProjectID
WHERE
	of1.DEL = 0

-- проекты у которых есть признак распределять на проекты
INSERT #Projects (ProjectID, ParentProjectID, Type)
SELECT DISTINCT of1.id, of1.Parent_id, 3
FROM
	dbo.ObjectsFinance of1
	JOIN dbo.p_OurFirmProjectRoles pr
		ON pr.Project_id = of1.id AND pr.OurFirm_id IN (SELECT FirmID FROM #FirmIDs)
WHERE
	of1.CostInProject = 1
	AND of1.del = 0
	AND NOT EXISTS (SELECT 1
					FROM
						ObjectsFinance
					WHERE
						del = 0
						AND Parent_id = of1.id)

-- ЦФО у которых не стоит признак распределять
INSERT #Projects (ProjectID, ParentProjectID, Type)
SELECT DISTINCT -Departament_id, NULL, 4
FROM
	Payments p
	JOIN CostCenters cc
		ON cc.id = p.Departament_id AND isnull(cc.CostInProject, 0) = 0
WHERE
	p.DEL = 0
	AND OurFirms_id IN (SELECT FirmID
						FROM
							#FirmIDs)
	AND p.DateClose IS NOT NULL
UNION
SELECT DISTINCT -Departament_id, NULL, 4
FROM
	Budget b
	JOIN CostCenters cc
		ON cc.id = b.Departament_id AND isnull(cc.CostInProject, 0) = 0
WHERE
	b.DEL = 0
	AND b.OurFirm_id IN (SELECT FirmID
						 FROM
							 #FirmIDs)
							 
-- ЦФО у которых стоит признак распределять
INSERT #Projects (ProjectID, ParentProjectID, Type)
SELECT DISTINCT -Departament_id, NULL, 5
FROM
	Payments p
	JOIN CostCenters cc
		ON cc.id = p.Departament_id AND cc.CostInProject = 1
WHERE
	p.DEL = 0
	AND OurFirms_id IN (SELECT FirmID
						FROM
							#FirmIDs)
	AND p.DateClose IS NOT NULL --AND DatePay <= @FinishDate
UNION
SELECT DISTINCT -Departament_id, NULL, 5
FROM
	Budget b
	JOIN CostCenters cc
		ON cc.id = b.Departament_id AND cc.CostInProject = 1
WHERE
	b.DEL = 0
	AND b.OurFirm_id IN (SELECT FirmID
						 FROM
							 #FirmIDs) --AND b.Period_id <= @FinishPeriod


SELECT @FinishDate_ = max(DateTo)
FROM
	p_OurFirmProjectRoles
WHERE
	del = 0
	AND OurFirm_id IN (SELECT FirmID
					   FROM
						   #FirmIDs)

-- определяем плановые сроки проектов, по первому платежу
UPDATE #Projects
SET
	PlanDateFrom = a.Date
FROM
	#Projects p
	LEFT JOIN (SELECT a.ProjectID, min(a.Date) Date
			   FROM
				   (SELECT b.[Object_id] ProjectID, min(p.Begin_Data) [Date]
					FROM
						dbo.Budget b
						JOIN #Projects p1
							ON p1.ProjectID = b.[Object_id]
						LEFT JOIN dbo.Period p
							ON p.id = b.period_id
					WHERE
						b.del = 0
						AND b.OurFirm_id IN (SELECT FirmID
											 FROM
												 #FirmIDs)
					GROUP BY
						b.[Object_id]
					UNION
					SELECT -b.Departament_id, min(p.Begin_Data)
					FROM
						dbo.Budget b
						JOIN #Projects p1
							ON p1.ProjectID = -b.Departament_id
						LEFT JOIN dbo.Period p
							ON p.id = b.period_id
					WHERE
						b.del = 0
						AND b.OurFirm_id IN (SELECT FirmID
											 FROM
												 #FirmIDs)
					GROUP BY
						b.Departament_id) a
			   GROUP BY
				   a.ProjectID) a
		ON a.ProjectID = p.ProjectID
WHERE
	a.ProjectID IS NOT NULL

-- определяем фактические сроки проектов, по первому платежу
UPDATE #Projects
SET
	FactDateFrom = a.Date
FROM
	#Projects p
	LEFT JOIN (SELECT a.ProjectID, min(a.Date) Date
			   FROM
				   (-- проекты
					SELECT p.ObjectFinance_id ProjectID, min(p.DatePay) Date
					FROM
						dbo.Payments p
						JOIN #Projects p1
							ON p1.ProjectID = p.ObjectFinance_id
					WHERE
						p.OurFirms_id IN (SELECT FirmID
										  FROM
											  #FirmIDs)
						AND p.DateClose IS NOT NULL
						AND p.del = 0
					GROUP BY
						p.ObjectFinance_id
					UNION
					-- ЦФО
					SELECT -p.Departament_id ProjectID, min(p.DatePay) Date
					FROM
						dbo.Payments p
						JOIN #Projects p1
							ON p1.ProjectID = -p.Departament_id
					WHERE
						p.OurFirms_id IN (SELECT FirmID
										  FROM
											  #FirmIDs)
						AND p.DateClose IS NOT NULL
						AND p.del = 0
					GROUP BY
						p.Departament_id) a
			   GROUP BY
				   a.ProjectID) a
		ON a.ProjectID = p.ProjectID
WHERE
	a.ProjectID IS NOT NULL

-- здесь сроки по ролям в проетах если не проставлены дату начало берет из расчитанного выше
-- дату окончания или определенную в ролях или выбранную пользоваелем
-- так же если было выбрано брать из бюджетов то планируемые даты будут из бюджетов
UPDATE #Projects
SET
	PlanDateFrom = isnull(a.PlanDateFrom, p.PlanDateFrom), 
	PlanDateTo = isnull(a.PlanDateTo, @FinishDate_), 
	FactDateFrom = isnull(a.FactDateFrom, p.FactDateFrom), 
	FactDateTo = isnull(a.FactDateTo, @FinishDate_)
FROM
	#Projects p
	LEFT JOIN (SELECT p.ProjectID ProjectID
					, min(isnull(b.BeginDistribDate, ofr.DateFrom)) PlanDateFrom
					, max(isnull(b.EndDistribDate, ofr.DateTo)) PlanDateTo
					, min(ofr.DateFromFact) FactDateFrom
					, max(ofr.DateToFact) FactDateTo
			   FROM
				   #Projects p
				   LEFT JOIN p_OurFirmProjectRoles ofr
					   ON ofr.del = 0 AND ofr.Project_id = p.ProjectID AND ofr.OurFirm_id IN (SELECT FirmID
																							  FROM
																								  #FirmIDs)
				   LEFT JOIN (SELECT bv.*
							  FROM
								  dbo.BudgetsVersions bv
								  JOIN #BudgetsVersions a ON a.BudgetVersion_id = bv.id AND a.BudgetsGroup_id = @BudgetsGroupID
							  WHERE
								  ByBudget = 1) b
					   ON b.ObjectFinance_id = p.ProjectID AND b.OurFirm_id = ofr.OurFirm_id
			   WHERE
				   p.Type IN (1, 2, 3, 4)
			   GROUP BY
				   p.ProjectID
				 , p.PlanDateFrom
				 , p.FactDateFrom) a
		ON a.ProjectID = p.ProjectID

-- проставляем периоды дат для более простого использования в дальнейшем и
-- дополнительные параметры проектов
UPDATE #Projects
SET
	PlanPeriodFrom = per1.id, PlanPeriodTo = per2.id, FactPeriodFrom = per3.id, FactPeriodTo = per4.id, 
	[fDistributedType] = CASE
							WHEN isnull(obf.[Distributed], cc.[Distributed]) = 1 AND isnull(obf.costinproject, cc.costinproject) = 1 THEN
								2 -- на него распределяется и с него распределяется
							WHEN coalesce(obf.[Distributed], cc.[Distributed], 0) = 0 AND isnull(cc.costinproject, obf.costinproject) = 1 THEN
								1 -- только с него распределяется по второму заходу
							WHEN isnull(obf.[Distributed], cc.[Distributed]) = 1 THEN
								3 -- на него распределяется
							ELSE
								4 -- на него и с него ничего не распределяется
						END, 
	[pDistributedType] = CASE
							WHEN isnull(obf.[Distributed], cc.[Distributed]) = 1 AND isnull(obf.costinproject, cc.costinproject) = 1 THEN
								2 -- на него распределяется и с него распределяется
							WHEN coalesce(obf.[Distributed], cc.[Distributed], 0) = 0 AND isnull(cc.costinproject, obf.costinproject) = 1 THEN
								1 -- только с него распределяется по второму заходу
							WHEN isnull(obf.[Distributed], cc.[Distributed]) = 1 THEN
								3 -- на него распределяется
							ELSE
								4 -- на него и с него ничего не распределяется
						END, 
						[fDistributed] = coalesce(obf.[Distributed], cc.[Distributed], 0), 
						[fCostInProject] = coalesce(cc.costinproject, obf.costinproject, 0),
						[pDistributed] = coalesce(obf.[Distributed], cc.[Distributed], 0), 
						[pCostInProject] = coalesce(cc.costinproject, obf.costinproject, 0)
FROM
	#Projects p
	LEFT JOIN Period per1
		ON per1.id = (SELECT TOP 1 id
					  FROM
						  Period
					  WHERE
						  PlanDateFrom BETWEEN Begin_Data AND End_Data
						  AND group_id = 3
						  AND del = 0)
	LEFT JOIN Period per2
		ON per2.id = (SELECT TOP 1 id
					  FROM
						  Period
					  WHERE
						  PlanDateTo BETWEEN Begin_Data AND End_Data
						  AND group_id = 3
						  AND del = 0)
	LEFT JOIN Period per3
		ON per3.id = (SELECT TOP 1 id
					  FROM
						  Period
					  WHERE
						  FactDateFrom BETWEEN Begin_Data AND End_Data
						  AND group_id = 3
						  AND del = 0)
	LEFT JOIN Period per4
		ON per4.id = (SELECT TOP 1 id
					  FROM
						  Period
					  WHERE
						  FactDateTo BETWEEN Begin_Data AND End_Data
						  AND group_id = 3
						  AND del = 0)
	LEFT JOIN ObjectsFinance obf
		ON obf.id = p.ProjectID AND p.[Type] NOT IN (4, 5)
	LEFT JOIN CostCenters cc
		ON -cc.id = p.ProjectID AND p.[Type] IN (4, 5)

-- проставляем флаг проектм имеется ли у него бюджет необходимого уровня
UPDATE #Projects
SET
	HaveBudget = cast(a.BudgetVersion_id AS BIT)
FROM
	#Projects pr
	JOIN dbo.BudgetsVersions bv
		ON (bv.ObjectFinance_id = pr.ProjectID OR bv.CostCenter_id = -pr.ProjectID) AND bv.del = 0 AND bv.OurFirm_id IN (SELECT FirmID
																														 FROM
																															 #FirmIDs)
	JOIN #BudgetsVersions a
		ON a.BudgetVersion_id = bv.id

--проставляем плановые настройки проектов из бюджетов где стоит флаг ByBudget
UPDATE #Projects
SET
	[pDistributedType] = CASE
							WHEN isnull(bv.[Distributed], [fDistributed]) = 1 AND isnull(bv.costinproject, fCostinproject) = 1 THEN
								2 -- на него распределяется и с него распределяется
							WHEN coalesce(bv.[Distributed], [fDistributed], 0) = 0 AND isnull(bv.costinproject, fcostinproject) = 1 THEN
								1 -- только с него распределяется по второму заходу
							WHEN isnull(bv.[Distributed], [fDistributed]) = 1 THEN
								3 -- на него распределяется
							ELSE
								4 -- на него и с него ничего не распределяется
						END, 
						[pDistributed] = COALESCE(bv.[Distributed], [fDistributed], 0), 
						[pCostInProject] = COALESCE(bv.costinproject, fCostinproject, 0)
FROM
	#Projects pr
	JOIN dbo.BudgetsVersions bv
		ON (bv.ObjectFinance_id = pr.ProjectID OR bv.CostCenter_id = -pr.ProjectID) AND bv.del = 0 AND bv.OurFirm_id IN (SELECT FirmID
																														 FROM
																															 #FirmIDs)
	JOIN #BudgetsVersions a
		ON a.BudgetVersion_id = bv.id
WHERE bv.ByBudget = 1	
	

	--EXEC pd_GetProjects @BudgetsGroupID
SET STATISTICS TIME OFF


-- Прямые расходы и приходы по проекту
---------------------------------------------------------------------------------------------------------------------------------

-- содержит все как прямые поступления и затраты по проекту 
-- так и на распределяемые проекты и цфо
-- и не распределяемы проекты и ЦФО
-- Все то что необходимо для подсчета коэфициентов
	-- факт
PRINT 'pd_GetProjectCD---------------------------------------------------------------------------------'
SET STATISTICS TIME ON
	EXEC pd_GetProjectCD @BudgetsGroupID, @CurrencyID, @ConfirmLevel
SET STATISTICS TIME OFF

-- Используемые коэфициенты
---------------------------------------------------------------------------------------------------------------------------------
-- таблица с проектами на что распределяем
CREATE TABLE #Prj (ProjectID INT)
-- определяем уровень подсчета если есть 
-- с чего распределять и на что распределять распределяемое то уровень первый
-- иначе сразу уровень 2
IF EXISTS
(SELECT 1
 FROM
	 #Projects
 WHERE
	 ((pCostInProject|fCostInProject)&(pDistributed|fDistributed)) = 1)
	SET @level = 1
ELSE 
	SET @Level = 2


WHILE @Level < 3
BEGIN
	IF OBJECT_ID('tempdb..#ReadyPlan') IS NULL
		CREATE TABLE #ReadyPlan(ProjectID INT, PeriodID INT, Summa float, DistribTypeID INT, CostDivisionID INT, CostTypeID INT, StateID INT)
	IF OBJECT_ID('tempdb..#ReadyFact') IS NULL
		CREATE TABLE #ReadyFact(ProjectID INT, PeriodID INT, Summa float, DistribTypeID INT, CostDivisionID INT, CostTypeID INT, StateID INT)

	PRINT 'pd_FillFactors---------------------------------------------------------------------------------'
	SET STATISTICS TIME ON





IF OBJECT_ID('tempdb..#ProjectPlan_temp') IS NULL
BEGIN
	CREATE TABLE #ProjectPlan_temp (ProjectID INT, PeriodID INT, CostType INT, CreditDebitID INT, Summa FLOAT)
	CREATE NONCLUSTERED INDEX IDX_ProjectPlan_temp_CreditDebitID ON [dbo].#ProjectPlan_temp (CreditDebitID)
	CREATE NONCLUSTERED INDEX IDX_ProjectPlan_temp_CostType ON [dbo].#ProjectPlan_temp (CostType)
END ELSE
	TRUNCATE TABLE #ProjectPlan_temp
	
IF OBJECT_ID('tempdb..#ProjectFact_temp') IS NULL
BEGIN
	CREATE TABLE #ProjectFact_temp (ProjectID INT, PeriodID INT, CostType INT, CreditDebitID INT, Summa FLOAT)
	CREATE NONCLUSTERED INDEX IDX_ProjectFact_temp_CreditDebitID ON [dbo].#ProjectPlan_temp (CreditDebitID)
	CREATE NONCLUSTERED INDEX IDX_ProjectFact_temp_CostType ON [dbo].#ProjectPlan_temp (CostType)
END ELSE
	TRUNCATE TABLE #ProjectFact_temp

IF OBJECT_ID('tempdb..#CreditLoan') IS NULL
BEGIN
	CREATE TABLE #CreditLoan (ProjectID INT, PeriodID INT, PlanSumma FLOAT, FactSumma FLOAT, TYPE INT)
	CREATE NONCLUSTERED INDEX IDX_CreditLoan_ProjectID ON [dbo].#CreditLoan ([ProjectID])
	CREATE NONCLUSTERED INDEX IDX_CreditLoan_ProjectID_PeriodID ON [dbo].#CreditLoan ([ProjectID], PeriodID)
	CREATE NONCLUSTERED INDEX IDX_CreditLoan_TYPE ON [dbo].#CreditLoan (TYPE)
END ELSE
	TRUNCATE TABLE #CreditLoan

SELECT @BudgetObject_ID = dbo._GetIDObject(1, 'Budget')

-- выполнение певрой очереди готовим данные для расчета
PRINT '1---------------------------------------------------------------------------------'
EXEC pd_FillFactors_getPlan_Temp @Level

PRINT '2---------------------------------------------------------------------------------'
EXEC pd_FillFactors_getFact_Temp @Level

PRINT '3---------------------------------------------------------------------------------'
EXEC pd_FillFactors_getCreditLoan @Level, @CurrencyID, @BudgetsGroupID
	
-- собираем все проекты
TRUNCATE TABLE #Prj

INSERT #Prj
SELECT DISTINCT ProjectID
FROM
	#ProjectPlan_temp
UNION
SELECT DISTINCT ProjectID
FROM
	#ProjectFact_temp

TRUNCATE TABLE #Coef

-- выполнение второй очереди
PRINT '4---------------------------------------------------------------------------------'
EXEC pd_FillFactors_1

PRINT '5---------------------------------------------------------------------------------'
EXEC pd_FillFactors_2 @Level

PRINT '6---------------------------------------------------------------------------------'
EXEC pd_FillFactors_3 @Level

PRINT '7---------------------------------------------------------------------------------'
EXEC pd_FillFactors_4 @Level, @CostTemplateID, @BudgetsGroupID

PRINT '8---------------------------------------------------------------------------------'
EXEC pd_FillFactors_5

PRINT '9---------------------------------------------------------------------------------'
EXEC pd_FillFactors_6

	SET STATISTICS TIME OFF

--	select PeriodID, Type, sum(PlanAllCoef), sum(FactAllCoef), sum(PlanParentCoef), sum(FactParentCoef) FROM #Coef group by PeriodID, Type ORDER BY 1
--	select * FROM #Coef order BY 4,2,9

	-- Подсчитываем распределяемые суммы 
	-- здесь все суммы которые надо распределить вместе с проектами на которые распределяем
	---------------------------------------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#TempPlan') IS NULL
		CREATE TABLE #TempPlan(ProjectID INT, PeriodID INT, Summa float, DistribTypeID INT, CostDivisionID INT, CostTypeID INT, IsAll BIT, StateID INT)
	IF OBJECT_ID('tempdb..#TempFact') IS NULL
		CREATE TABLE #TempFact(ProjectID INT, PeriodID INT, Summa float, CostTypeID INT, StateID INT)

	-- CostType =	1 - это самый верхний распределяемый - распределяется только он на все где Distributed = 1
	--				2 - сам распределяемый и всасываемый на него идут распределения
	IF OBJECT_ID('tempdb..#Payments') IS NULL
		CREATE TABLE #Payments(ProjectID INT, ParentProjectID INT, PeriodID INT, StateID INT, [DistrType] INT, [CostType] INT, isAll BIT, Summa float)
	IF OBJECT_ID('tempdb..#f') IS NULL
	BEGIN
		CREATE TABLE #f(ProjectID INT, PeriodID INT, Summa float, [CostType] INT, StateID INT, DistribTypeID INT, CostDivisionID INT)
		CREATE NONCLUSTERED INDEX IDX_f_ProjectID_PeriodID_Summa_CostType_StateID ON [dbo].[#f] ([ProjectID], [PeriodID],[Summa],[CostType],[StateID])
	END

	IF OBJECT_ID('tempdb..#Budgets') IS NULL
		CREATE TABLE #Budgets(ProjectID INT, ParentProjectID INT, PeriodID INT, StateID INT, [DistrType] INT, [CostType] INT, isAll BIT, Summa float)
	IF OBJECT_ID('tempdb..#p') IS NULL
	BEGIN
		CREATE TABLE #p(ProjectID INT, PeriodID INT, Summa float, [CostType] INT, StateID INT, DistribTypeID INT, CostDivisionID INT)
		CREATE NONCLUSTERED INDEX IDX_p_ProjectID_PeriodID_Summa_CostType_StateID ON [dbo].[#p] ([ProjectID],[PeriodID],[Summa],[CostType],[StateID])
	END
-- отберем сразу же нужные платежи и строки бюджетов которые распределяются

PRINT '[pd_GetProjectDistrib]---------------------------------------------------------------------------------'
	SET STATISTICS TIME ON
	IF NOT EXISTS (SELECT 1 FROM #Payments) AND NOT EXISTS (SELECT 1 FROM #Budgets)
		-- отберем сразу же нужные платежи и строки бюджетов которые распределяются
		EXEC [dbo].[pd_GetProjectDistrib] @CurrencyID, @BudgetsGroupID, @ConfirmLevel 
SET STATISTICS TIME OFF

PRINT 'pd_DistribToProject---------------------------------------------------------------------------------'
	SET STATISTICS TIME ON
	EXEC pd_DistribToProject @Level
SET STATISTICS TIME OFF


PRINT 'pd_DistribToProject---------------------------------------------------------------------------------'
SET STATISTICS TIME ON



EXEC pd_DistribToProject @Level

SET STATISTICS TIME OFF
	
PRINT 'pd_DistribToProject_2---------------------------------------------------------------------------------'
SET STATISTICS TIME ON

	IF EXISTS (SELECT 1 FROM #States WHERE [Distribtype] = 7) 
		EXEC pd_DistribToProject_2 @Level, @VersionDate
	
SET STATISTICS TIME OFF
	
PRINT 'INSERT---------------------------------------------------------------------------------'
SET STATISTICS TIME ON
	
	IF @level = 1
	BEGIN
	-- это готовые суммы, которые легли непосредственно на конечные проекты
	IF @ByStates = 1
		INSERT #ReadyFact (ProjectID
						 , PeriodID
						 , DistribTypeID
						 , CostDivisionID
						 , CostTypeID
						 , StateID
						 , Summa)
		SELECT f.ProjectID
			 , PeriodID
			 , s.DistribType
			 , s.CostDivisionID
			 , s.CostType
			 , s.StateID
			 , sum(Summa)
		FROM
			#f f
			JOIN (SELECT ProjectID
				  FROM
					  #ProjectIDs) a
				ON a.ProjectID = f.ProjectID -- то что выбрали
			JOIN #Projects AS pr2
				ON pr2.ProjectID = a.ProjectID AND [Type] IN (1, 4) AND [fDistributed] = 1 -- должно быть или проектом или цфо
			JOIN #States AS s
				ON s.CostType = f.CostType AND f.StateID = s.StateID
		WHERE
			EXISTS (SELECT 1
					FROM
						#ProjectIDs AS pr
					WHERE
						a.ProjectID = pr.ProjectID)
		GROUP BY
			f.ProjectID
		  , PeriodID
		  , s.DistribType
		  , s.CostDivisionID
		  , s.CostType
		  , s.StateID
	ELSE
		INSERT #ReadyFact (ProjectID
						 , PeriodID
						 , DistribTypeID
						 , CostDivisionID
						 , CostTypeID
						 , Summa)
		SELECT f.ProjectID
			 , PeriodID
			 , s.DistribType
			 , s.CostDivisionID
			 , s.CostType
			 , sum(Summa)
		FROM
			#f f
			JOIN (SELECT ProjectID
				  FROM
					  #Projects) a
				ON a.ProjectID = f.ProjectID -- то что выбрали
			JOIN #Projects AS pr2
				ON pr2.ProjectID = a.ProjectID AND [Type] IN (1, 4) AND [fDistributed] = 1 -- должно быть или проектом или цфо
			JOIN #States AS s
				ON s.CostType = f.CostType AND f.StateID = s.StateID
		--WHERE EXISTS (SELECT 1 FROM #ProjectIDs AS pr WHERE a.ProjectID = pr.ProjectID)
		GROUP BY
			f.ProjectID
		  , PeriodID
		  , s.DistribType
		  , s.CostDivisionID
		  , s.CostType
	-- то что легло не на проекты например на родительские
	INSERT #TempFact (ProjectID
					, PeriodID
					, CostTypeID
					, StateID
					, Summa)
	SELECT f.ProjectID
		 , PeriodID
		 , a.[Type]
		 , f.StateID
		 , sum(Summa)
	FROM
		#f f
		JOIN (SELECT ProjectID
				   , [Type]
			  FROM
				  #Projects
			  WHERE
				  fCostInProject = 1
				  AND [Type] IN (2, 3, 5)) a
			ON a.ProjectID = f.ProjectID -- то что легло на распределяемые
		JOIN #States AS s
			ON s.CostType = a.Type AND f.StateID = s.StateID
	GROUP BY
		f.ProjectID
	  , PeriodID
	  , a.[Type]
	  , f.StateID

	IF @ByStates = 1
		INSERT #ReadyPlan (ProjectID
						 , PeriodID
						 , DistribTypeID
						 , CostDivisionID
						 , CostTypeID
						 , StateID
						 , Summa)
		SELECT f.ProjectID
			 , PeriodID
			 , s.DistribType
			 , s.CostDivisionID
			 , s.CostType
			 , s.StateID
			 , sum(Summa)
		FROM
			#p f
			JOIN (SELECT ProjectID
				  FROM
					  #ProjectIDs) a
				ON a.ProjectID = f.ProjectID -- то что выбрали
			JOIN #Projects AS pr2
				ON pr2.ProjectID = a.ProjectID AND [Type] IN (1, 4) AND [pDistributed] = 1 -- должно быть или проектом или цфо на который распределяется
			JOIN #States AS s
				ON s.CostType = f.CostType AND f.StateID = s.StateID
		WHERE
			EXISTS (SELECT 1
					FROM
						#ProjectIDs AS pr
					WHERE
						a.ProjectID = pr.ProjectID)
		GROUP BY
			f.ProjectID
		  , PeriodID
		  , s.DistribType
		  , s.CostDivisionID
		  , s.CostType
		  , s.StateID
	ELSE
		INSERT #ReadyPlan (ProjectID
						 , PeriodID
						 , DistribTypeID
						 , CostDivisionID
						 , CostTypeID
						 , Summa)
		SELECT f.ProjectID
			 , PeriodID
			 , s.DistribType
			 , s.CostDivisionID
			 , s.CostType
			 , sum(Summa)
		FROM
			#p f
			JOIN (SELECT ProjectID
				  FROM
					  #Projects) a
				ON a.ProjectID = f.ProjectID -- то что выбрали
			JOIN #Projects AS pr2
				ON pr2.ProjectID = a.ProjectID AND [Type] IN (1, 4) AND [pDistributed] = 1 -- должно быть или проектом или цфо на который распределяется
			JOIN #States AS s
				ON s.CostType = f.CostType AND f.StateID = s.StateID
		--WHERE EXISTS (SELECT 1 FROM #ProjectIDs AS pr WHERE a.ProjectID = pr.ProjectID)
		GROUP BY
			f.ProjectID
		  , PeriodID
		  , s.DistribType
		  , s.CostDivisionID
		  , s.CostType

	-- то что легло не на проекты например на родительские
	INSERT #TempPlan (ProjectID
					, PeriodID
					, CostTypeID
					, StateID
					, Summa)
	SELECT f.ProjectID
		 , PeriodID
		 , a.[Type]
		 , f.StateID
		 , sum(Summa)
	FROM
		#p f
		JOIN (SELECT ProjectID
				   , [Type]
			  FROM
				  #Projects
			  WHERE
				  pCostInProject = 1
				  AND [Type] IN (2, 3, 5)) a
			ON a.ProjectID = f.ProjectID -- то что легло на распределяемые
		JOIN #States AS s
			ON s.CostType = a.Type AND f.StateID = s.StateID
	GROUP BY
		f.ProjectID
	  , PeriodID
	  , a.[Type]
	  , f.StateID
	TRUNCATE TABLE #f
	TRUNCATE TABLE #p
	END
	SET @Level = @Level + 1
SET STATISTICS TIME OFF
END
select * FROM #Coef order BY 2,4,9
IF @ByStates = 1
BEGIN 
	INSERT #Fact (ProjectID
			  , PeriodID
			  , CostDivisionID
			  , CostTypeID
			  , StateID
			  , Summa)
	SELECT ProjectID
	   , PeriodID
	   , CostDivisionID
	   , CostType
	   , StateID
	   , sum(Summa)
	FROM
	  (SELECT ProjectID
			, PeriodID
			, CostDivisionID
			, CostType
			, StateID
			, Summa
	   FROM
		   #f AS f
	   UNION ALL
	   SELECT ProjectID
			, PeriodID
			, CostDivisionID
			, CostTypeID
			, StateID
			, Summa
	   FROM
		   #ReadyFact) a
	GROUP BY
	  ProjectID
	, PeriodID
	, CostDivisionID
	, CostType
	, StateID

	INSERT #Plan (ProjectID
				, PeriodID
				, CostDivisionID
				, CostTypeID
				, StateID
				, Summa)
	SELECT ProjectID
		 , PeriodID
		 , CostDivisionID
		 , CostType
		 , StateID
		 , sum(Summa)
	FROM
		(SELECT ProjectID
			  , PeriodID
			  , CostDivisionID
			  , CostType
			  , StateID
			  , Summa
		 FROM
			 #p AS f
		 UNION ALL
		 SELECT ProjectID
			  , PeriodID
			  , CostDivisionID
			  , CostTypeID
			  , StateID
			  , Summa
		 FROM
			 #ReadyPlan) a
	GROUP BY
		ProjectID
	  , PeriodID
	  , CostDivisionID
	  , CostType
	  , StateID
END ELSE
BEGIN
	INSERT #Fact (ProjectID
				, PeriodID
				, CostDivisionID
				, CostTypeID
				, Summa)
	SELECT ProjectID
		 , PeriodID
		 , CostDivisionID
		 , CostType
		 , sum(Summa)
	FROM
		(SELECT ProjectID
			  , PeriodID
			  , CostDivisionID
			  , CostType
			  , Summa
		 FROM
			 #f AS f
		 UNION ALL
		 SELECT ProjectID
			  , PeriodID
			  , CostDivisionID
			  , CostTypeID
			  , Summa
		 FROM
			 #ReadyFact) a
	GROUP BY
		ProjectID
	  , PeriodID
	  , CostDivisionID
	  , CostType

	INSERT #Plan (ProjectID
				, PeriodID
				, CostDivisionID
				, CostTypeID
				, Summa)
	SELECT ProjectID
		 , PeriodID
		 , CostDivisionID
		 , CostType
		 , sum(Summa)
	FROM
		(SELECT ProjectID
			  , PeriodID
			  , CostDivisionID
			  , CostType
			  , Summa
		 FROM
			 #p AS f
		 UNION ALL
		 SELECT ProjectID
			  , PeriodID
			  , CostDivisionID
			  , CostTypeID
			  , Summa
		 FROM
			 #ReadyPlan) a
	GROUP BY
		ProjectID
	  , PeriodID
	  , CostDivisionID
	  , CostType
	END

/*
SELECT CostDivisionID, PeriodID, sum(Summa) from #Plan group BY CostDivisionID, PeriodID ORDER BY 1,2
SELECT CostDivisionID, PeriodID, sum(Summa) from #Fact group BY CostDivisionID, PeriodID ORDER BY 1,2
SELECT * from #p
*/

/*
SELECT * from #Plan
SELECT * from #Fact
SELECT sum(Summa) from #ProjectPlan
SELECT sum(Summa) from #ProjectFact
*/
/*

SELECT *--PeriodID, [Type], SUM(PlanAllCoef), SUM(FactAllCoef), SUM(PlanParentCoef), SUM(FactParentCoef) 
FROM #Coef 
--GROUP BY PeriodID, [Type]
where PeriodID = 121 and type = 1
order BY 2,4,9
SELECT * FROM #Budgets where periodid = 121
*/

