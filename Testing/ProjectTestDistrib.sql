ALTER DATABASE vkb_test1  set compatibility_level = 100
ALTER DATABASE vkb_test1 set compatibility_level = 140
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
------------------
DECLARE
    @StartDate          DateTime,
    @StartPeriod        int,
    @FinishDate         DateTime,
    @FinishPeriod       int,
    @NowPeriod          int,
    @CurrencyID         int,
    @CostTemplateID     int,
    @Level              int,
    @BudgetsGroupID     int,
    @SalesPlanGroupID   int,
    @ExcludeInternal    INT,
    @SalesPlanValuesID  int,
    @GroupPeriodID      INT, 
    @WithProject        BIT,
    @ProjectRate        INT,
    @ConfirmLevel       INT,
    @VersionDate        DATETIME,
    @ProjectEndRates    INT,
    @FirmProhectOwnerID INT,
    @WithCache          BIT,
	@byStates			BIT

SELECT @GroupPeriodID = 3

SELECT  @StartDate = '20181201', @FinishDate = '20190131 23:59:59', @CurrencyID = 31, 
        @ExcludeInternal = 2, @CostTemplateID = 32, @BudgetsGroupID = 1, 
        @SalesPlanGroupID = 1, @WithProject = 0, @ProjectRate = 11,
        @ConfirmLevel = ISNULL(7, i), @VersionDate = '20191231', @ProjectEndRates = NULL,
        @FirmProhectOwnerID = 1, @WithCache = 0
FROM _GlobalOptions
WHERE Name = 'BudgetConfirmLevel'
-- create temp table
--------------------------------------------------------------------------------
CREATE TABLE #FirmIDs(FirmID INT PRIMARY KEY)
CREATE TABLE #States(StateID INT)
CREATE TABLE #Projects(ProjectID INT)
CREATE TABLE #ProjectFact(ProjectID INT)
CREATE TABLE #ProjectPlan(ProjectID INT)
CREATE TABLE #Coef(ProjectID INT)
CREATE TABLE #ProjectIDs(ProjectID INT Primary Key, EndPeriod INT)
CREATE TABLE #Plan(ProjectID INT)
CREATE TABLE #Fact(ProjectID INT)
CREATE TABLE #BudgetsVersions(BudgetVersion_id INT PRIMARY KEY)


DECLARE @RC BIT
EXECUTE @RC = pd_AddColumnForCalcProject
IF @RC = 0
BEGIN
    DECLARE @Str VARCHAR(128)
    SET @Str = 'Не найдена одна из необходимых таблиц'
    RAISERROR(@Str, 16, 1)
    RETURN
END

-- insert FIRMIDs 
--------------------------------------------------------------------------------
INSERT INTO #FirmIDs(FirmID, isMain)
SELECT id, CASE WHEN parent_id IS NULL THEN 1 ELSE 0 end 
FROM OurFirms f
WHERE del = 0 and ( id in (1) )
-- insert ProjectIDs 
--------------------------------------------------------------------------------
INSERT INTO #ProjectIDs(ProjectID, EndPeriod)
SELECT DISTINCT _of.id, case when isOwner is null then 0 else p.id end
FROM ObjectsFinance _of
	LEFT JOIN ProjectRateValues prv on prv.ProjectRate_id = @ProjectEndRates and prv.ObjectFinance_id = _of.id and prv.del = 0
	LEFT JOIN Period p on prv.Date BETWEEN Begin_Data AND End_Data AND group_id = 3
JOIN dbo.p_OurFirmProjectRoles ofpr ON _of.id = ofpr.Project_id AND ofpr.del = 0 AND ofpr.OurFirm_id IN (SELECT FirmID FROM #FirmIDs)
left join (SELECT DISTINCT Project_id, 1 isOwner from p_OurFirmProjectRoles where ProjectRole_id = 1 AND ourFirm_id IN (SELECT FirmID FROM #FirmIDs)) isOwner on isOwner.Project_id  = _of.id
WHERE [_of].del = 0 AND  not (_of.id is null )  AND _of.id in (SELECT DISTINCT Project_id FROM dbo.p_OurFirmProjectRoles
WHERE del = 0 AND ISNULL(ProjectRole_id, 0) IN (ISNULL(ProjectRole_id, 0))
AND OurFirm_id IN (SELECT FirmID FROM #FirmIDs)
)
--------------------------------------------------------------------------------
-- отбираем действующие версии бюджета
INSERT INTO #BudgetsVersions(BudgetVersion_id, BudgetsGroup_id)
SELECT id, BudgetsGroup_id FROM dbo.GetBudgetVersion(@ConfirmLevel, @VersionDate) where BudgetsGroup_id = @BudgetsGroupID
DECLARE
	@BudgetObject_ID	INT


SELECT @BudgetObject_ID = dbo._GetIDObject(1, 'Budget')

declare 
	@FirmIDs VARCHAR(MAX),
	@Plan_Cache	INT,
	@Fact_Cache	INT
set @FirmIDs = '';
select @FirmIDs=@FirmIDs+cast(FirmID as varchar(max))+';' from #FirmIDs order by FirmID

if @withCache=1
begin
	-- находим закешированные данные
	;with cache as 
	(select * 
		from CalcProjectCache 
	where FirmIDs=@FirmIDs 
		and ConfirmLevel=@ConfirmLevel 
		and VersionDate=@VersionDate 
		and Temlate_id=@CostTemplateID 
		and BudgetsGroup_id=@BudgetsGroupID 
		and ExcludeInternal=@ExcludeInternal
	)


	select @Plan_Cache = max(case when [type] = 0 then id end), @Fact_Cache = max(case when [type] = 1 then id end) from cache

	-- если нашли план
	if @Plan_Cache is not null 
	begin
		insert into #ProjectPlan(ProjectID, PeriodID, Summa, CostType, [Level], CreditDebitID, StateID)
		select Project_ID, Period_ID, Summa, CostType_id, [Level], CreditDebit_id, State_id
		from CalcProjectCachePlan where CalcProjectCache_id=@Plan_Cache
		IF @ByStates = 1
		BEGIN 
			INSERT #Plan (ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, Summa)
			SELECT Project_ID, Period_ID, CostDivision_ID, CostType_ID, State_ID, Summa FROM CalcDistribCachePlan
			WHERE CalcProjectCache_id = @Plan_Cache
		END ELSE
		BEGIN
			INSERT #Plan (ProjectID, PeriodID, CostDivisionID, CostTypeID, Summa)
			SELECT Project_ID, Period_ID, CostDivision_ID, CostType_ID, sum(Summa) FROM CalcDistribCachePlan
			WHERE CalcProjectCache_id = @Plan_Cache
			GROUP BY Project_ID, Period_ID, CostDivision_ID, CostType_ID
		END
	end

	-- если нашли факт
	if @Fact_Cache is not null 
	begin
		INSERT #ProjectFact (ProjectID, PeriodID, Summa, CostType, [Level], CreditDebitID, StateID)
		select Project_ID, Period_ID, Summa, CostType_id, [Level], CreditDebit_id, State_id
		from CalcProjectCacheFact where CalcProjectCache_id=@Fact_Cache

		IF @ByStates = 1
		BEGIN 
			INSERT #Fact (ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, Summa)
			SELECT Project_ID, Period_ID, CostDivision_ID, CostType_ID, State_ID, Summa FROM CalcDistribCacheFact
			WHERE CalcProjectCache_id = @Fact_Cache
		END ELSE
		BEGIN
			INSERT #Fact (ProjectID, PeriodID, CostDivisionID, CostTypeID, Summa)
			SELECT Project_ID, Period_ID, CostDivision_ID, CostType_ID, sum(Summa) FROM CalcDistribCacheFact
			WHERE CalcProjectCache_id = @Fact_Cache
			GROUP BY Project_ID, Period_ID, CostDivision_ID, CostType_ID
		END
	end
end

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
			  , checkPeriod
			  ,ExcludeDistribInChild)
SELECT ctd.State_id
	 , ctd.DistribType_id
	 , ctd.CostsType_id
	 , ctd.CostDivision_id
	 , dt.CheckPeriod
	 , ctd.ExcludeDistribInChild
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

EXEC pd_GetProjects @BudgetsGroupID


CREATE TABLE #Clients (id INT IDENTITY, ClientID INT, FirmID INT)
INSERT INTO #Clients (ClientID, FirmID)
SELECT Client_id, fi.FirmID
FROM
	dbo.OurFirms _of
	JOIN #FirmIDs fi ON (@ExcludeInternal = 2 
		AND _of.id IN (SELECT id FROM dbo.OurFirms WHERE isnull(parent_id, id) IN (SELECT isnull(Parent_ID, id) FROM dbo.OurFirms WHERE id = fi.FirmID
																				  AND id IN (SELECT FirmID FROM #FirmIDs)))) 
		OR (@ExcludeInternal = 1 AND _of.id IN (SELECT FirmID FROM #FirmIDs))
WHERE
	_of.del = 0

-- заполняем таблицу с коэфициентами курсов которые нам могут понадобиться в бюджетах и платежах.
---------------------------------------------------------------------------------------------------------------------------------
if object_id ('tempdb..#curs') is not null drop TABLE #curs;
WITH cte (date, valuta_id) as (
	SELECT Begin_Data, Valuta_id from budget b
	left JOIN Period p ON p.id = period_id
	WHERE b.del = 0
	UNION
	SELECT datepay, Valuta from Payments p WHERE del = 0
	)
SELECT date, c.Valuta_ID, c1.Curs/c2.curs koef INTO #curs 
FROM cte c
	left JOIN CURS c1 ON c1.id = (SELECT TOP 1 id from CURS where del = 0 AND c.valuta_id = Valuta_id and c.Date > Data ORDER BY Data desc)
	left JOIN CURS c2 ON c2.id = (SELECT TOP 1 id from CURS where del = 0 AND valuta_id = @CurrencyID and c.Date > Data ORDER BY Data desc)

CREATE index IX_curs_date_valuta on #curs (date, Valuta_id) include (koef)

-- Прямые расходы и приходы по проекту
---------------------------------------------------------------------------------------------------------------------------------

-- содержит все как прямые поступления и затраты по проекту
-- так и на распределяемые проекты и цфо
-- и не распределяемы проекты и ЦФО
-- Все то что необходимо для подсчета коэфициентов
-- факт
EXEC pd_GetProjectCD @BudgetsGroupID, @CurrencyID, @ConfirmLevel, @Plan_Cache, @Fact_Cache
-- Используемые коэфициенты
---------------------------------------------------------------------------------------------------------------------------------
-- таблица с проектами на что распределяем
CREATE TABLE #Prj (ProjectID INT)
-- определяем уровень подсчета если есть
-- с чего распределять и на что распределять распределяемое то уровень первый
-- иначе сразу уровень 2
SET @level = 1;

WHILE @Level < 3
BEGIN
	IF NOT EXISTS (SELECT 1 FROM #Projects WHERE ((pCostInProject|fCostInProject)&(pDistributed|fDistributed)) = 1) and @Level = 2 break;

	IF OBJECT_ID('tempdb..#ReadyPlan') IS NULL
		CREATE TABLE #ReadyPlan(ProjectID INT, PeriodID INT, Summa float, DistribTypeID INT, CostDivisionID INT, CostTypeID INT, StateID INT, ExcludeDistribInChild BIT)
	IF OBJECT_ID('tempdb..#ReadyFact') IS NULL
		CREATE TABLE #ReadyFact(ProjectID INT, PeriodID INT, Summa float, DistribTypeID INT, CostDivisionID INT, CostTypeID INT, StateID INT, ExcludeDistribInChild BIT)


	IF OBJECT_ID('tempdb..#ProjectPlan_temp') IS NULL
	BEGIN
		CREATE TABLE #ProjectPlan_temp (ProjectID INT, PeriodID INT, CostType INT, CreditDebitID INT, Summa FLOAT, ExcludeDistribInChild BIT)
		CREATE NONCLUSTERED INDEX IDX_ProjectPlan_temp_CreditDebitID ON [dbo].#ProjectPlan_temp (CreditDebitID)
		CREATE NONCLUSTERED INDEX IDX_ProjectPlan_temp_CostType ON [dbo].#ProjectPlan_temp (CostType)
	END ELSE
		TRUNCATE TABLE #ProjectPlan_temp
		
	IF OBJECT_ID('tempdb..#ProjectFact_temp') IS NULL
	BEGIN
		CREATE TABLE #ProjectFact_temp (ProjectID INT, PeriodID INT, CostType INT, CreditDebitID INT, Summa FLOAT, ExcludeDistribInChild BIT)
		CREATE NONCLUSTERED INDEX IDX_ProjectFact_temp_CreditDebitID ON [dbo].#ProjectFact_temp (CreditDebitID)
		CREATE NONCLUSTERED INDEX IDX_ProjectFact_temp_CostType ON [dbo].#ProjectFact_temp (CostType)
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

	-- выполнение певрой очереди готовим данные для расчета
	EXEC pd_FillFactors_getPlan_Temp @Level

	EXEC pd_FillFactors_getFact_Temp @Level

	EXEC pd_FillFactors_getCreditLoan @Level, @CurrencyID, @BudgetsGroupID

	EXEC pd_FillFactors @Level, @CostTemplateID, @CurrencyID, @BudgetsGroupID

	--select type, PeriodID, sum(PlanAllCoef), sum(FactAllCoef), sum(PlanParentCoef), sum(FactParentCoef) from #coef  group by type, PeriodID order by 2
	select type, PeriodID, sum(PlanAllCoef), sum(FactAllCoef), sum(PlanParentCoef), sum(FactParentCoef) from #coef where type = 6 group by type, PeriodID having sum(PlanAllCoef) is null  order by 2
	--select * from #coef  where type = 6 and PeriodID = 236
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
		CREATE TABLE #f(ProjectID INT, PeriodID INT, Summa float, [CostType] INT, StateID INT, DistribTypeID INT, CostDivisionID INT, Distr_Summa money, Limit  money, NotDistr_Summa money, Coef float)
		CREATE NONCLUSTERED INDEX IDX_f_ProjectID_PeriodID_Summa_CostType_StateID ON [dbo].[#f] ([ProjectID], [PeriodID],[Summa],[CostType],[StateID])
	END

	IF OBJECT_ID('tempdb..#Budgets') IS NULL
		CREATE TABLE #Budgets(ProjectID INT, ParentProjectID INT, PeriodID INT, StateID INT, [DistrType] INT, [CostType] INT, isAll BIT, Summa float)
	IF OBJECT_ID('tempdb..#p') IS NULL
	BEGIN
		CREATE TABLE #p(ProjectID INT, PeriodID INT, Summa float, [CostType] INT, StateID INT, DistribTypeID INT, CostDivisionID INT, Distr_Summa money, Limit  money, NotDistr_Summa money, Coef float)
		CREATE NONCLUSTERED INDEX IDX_p_ProjectID_PeriodID_Summa_CostType_StateID ON [dbo].[#p] ([ProjectID],[PeriodID],[Summa],[CostType],[StateID])
	END

	-- отберем сразу же нужные платежи и строки бюджетов которые распределяются
	IF NOT EXISTS (SELECT 1 FROM #Payments)
		exec pd_GetProjectDistrib_fact @CurrencyID
	IF NOT EXISTS (SELECT 1 FROM #Budgets)
		exec pd_GetProjectDistrib_plan @CurrencyID, @BudgetsGroupID, @ConfirmLevel



	;WITH Budgets_temp as 
	(
		SELECT ProjectID, PeriodID, Summa, DistrType, StateID, IsAll, CostType FROM #Budgets
			  UNION ALL
		SELECT ProjectID, PeriodID, Summa, 2, StateID, 0, CostTypeID FROM #TempPlan
	), Project_temp AS
	(
		SELECT * FROM #Projects WHERE [pDistributed] = 1 AND ProjectID IN (SELECT ProjectID FROM #Coef)
	)
	,b as (
		SELECT pr.ProjectID ProjectID, p.ProjectID ProjectID_b
		FROM (select distinct projectid, costtype, DistrType from Budgets_temp) p
			LEFT JOIN #Projects AS pr2 ON pr2.ProjectID = p.ProjectID
			LEFT JOIN Project_temp pr ON ((p.CostType = 3 AND pr2.ParentProjectID = pr.ParentProjectID) OR (p.CostType = 2 AND p.ProjectID = pr.ParentProjectID) OR (p.CostType IN (1, 4)))
		WHERE @Level = p.DistrType AND pr.ProjectID <> p.ProjectID
	)

	, a as 
	(
		SELECT b.ProjectID ProjectID, p.PeriodID, p.CostType, p.IsAll, p.StateID, sum(p.Summa) Summa
		FROM Budgets_temp p
			LEFT JOIN b AS b ON b.ProjectID_b = p.ProjectID
		GROUP BY b.ProjectID, p.PeriodID, p.CostType, p.IsAll, p.StateID
	), Itogo AS 
	(
		SELECT 
			a.ProjectID, 
			a.PeriodID, 
			SUMMA,
			CASE WHEN a.IsAll = 0 THEN c.PlanParentCoef WHEN a.IsAll = 1 THEN c.PlanAllCoef ELSE 1 END coef, 
			a.CostType, 
			a.StateID, 
			s.DistribType, 
			s.CostDivisionID
		FROM
			a
			LEFT JOIN #States s ON s.StateID = a.StateID AND s.CostType = a.CostType
			LEFT JOIN #Projects AS pr ON pr.ProjectID = a.ProjectID AND [Type] IN (1, 2, 3, 4)
			LEFT JOIN #Coef c ON (c.[Type] = s.DistribType OR (s.DistribType = 7 AND c.[type] = 6)) AND (c.PeriodID = a.PeriodID or c.PeriodID is null) AND c.ProjectID = a.ProjectID
		WHERE SUMMA IS NOT NULL AND (a.PeriodID BETWEEN pr.PlanPeriodFrom AND pr.PlanPeriodTo OR isnull(s.CheckPeriod, 0) = 0)
	)
	SELECT ProjectID, PeriodID, SUMMA, coef, CostType, StateID, DistribType, CostDivisionID
	FROM Itogo 
	WHERE ((SUMMA is not null and coef IS NOT NULL) OR DistribType = 7) and PeriodID = 236



;WITH Budgets_temp as 
	(
		SELECT ProjectID, PeriodID, Summa, DistrType, StateID, IsAll, CostType FROM #Budgets
			  UNION ALL
		SELECT ProjectID, PeriodID, Summa, 2, StateID, 0, CostTypeID FROM #TempPlan
	), Project_temp AS
	(
		SELECT * FROM #Projects WHERE [pDistributed] = 1 AND ProjectID IN (SELECT ProjectID FROM #Coef)
	)
	,b as (
		SELECT pr.ProjectID ProjectID, p.ProjectID ProjectID_b
		FROM (select distinct projectid, costtype, DistrType from Budgets_temp) p
			LEFT JOIN #Projects AS pr2 ON pr2.ProjectID = p.ProjectID
			LEFT JOIN Project_temp pr ON ((p.CostType = 3 AND pr2.ParentProjectID = pr.ParentProjectID) OR (p.CostType = 2 AND p.ProjectID = pr.ParentProjectID) OR (p.CostType IN (1, 4, 7)) OR (p.CostType = 7 and pr.ProjectID > 0))
		WHERE @Level = p.DistrType AND pr.ProjectID <> p.ProjectID
	)
	, a as 
	(
		SELECT b.ProjectID ProjectID, p.PeriodID, p.CostType, p.IsAll, p.StateID, sum(p.Summa) Summa
		FROM Budgets_temp p
			LEFT JOIN b AS b ON b.ProjectID_b = p.ProjectID
		GROUP BY b.ProjectID, p.PeriodID, p.CostType, p.IsAll, p.StateID
	), Itogo AS 
	(
		SELECT 
			a.ProjectID, 
			a.PeriodID, 
			SUMMA,
			CASE WHEN IsAll = 2 THEN c.PlanProjectCoef WHEN a.IsAll = 0 THEN c.PlanParentCoef WHEN a.IsAll = 1 THEN c.PlanAllCoef ELSE 1 END coef, 
			a.CostType, 
			a.StateID, 
			s.DistribType, 
			s.CostDivisionID
		FROM
			a
			LEFT JOIN #States s ON s.StateID = a.StateID AND s.CostType = a.CostType
			LEFT JOIN #Projects AS pr ON pr.ProjectID = a.ProjectID AND [Type] IN (1, 2, 3, 4)
			LEFT JOIN #Coef c ON (c.[Type] = s.DistribType OR (s.DistribType = 7 AND c.[type] = 6)) AND (c.PeriodID = a.PeriodID or c.PeriodID is null) AND c.ProjectID = a.ProjectID
		WHERE SUMMA IS NOT NULL AND (a.PeriodID BETWEEN pr.PlanPeriodFrom AND pr.PlanPeriodTo OR isnull(s.CheckPeriod, 0) = 0)
	)
	SELECT ProjectID, PeriodID, SUMMA*coef SummaCoef, SUMMA, coef, CostType, StateID, DistribType, CostDivisionID
	FROM Itogo 
	WHERE ((SUMMA is not null and coef IS NOT NULL) OR DistribType = 7) and PeriodID=228
	order by 2


	EXEC pd_DistribToProject @Level, @Plan_Cache, @Fact_Cache

	select @level
	select * from #p order by 2
select * from #Coef where periodid=228
	IF EXISTS (SELECT 1 FROM #States WHERE [Distribtype] = 7) 
		EXEC pd_DistribToProject_2 @Level, @VersionDate, @Plan_Cache, @Fact_Cache



	EXEC pd_SaveTempResult_fact @Level
	EXEC pd_SaveTempResult_plan @Level

	TRUNCATE TABLE #f
	TRUNCATE TABLE #p

	
	SET @Level = @Level + 1
END

select * from #Coef where periodid<=228 and type=1 order by 3

select * from CostDivisions
select * from CostTemplatesDetail where state_id in (1002,1050) and del = 0 and CostTemplate_id=32


IF @ByStates = 1
BEGIN 
	if @Fact_Cache is null
		INSERT #Fact (ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, Summa)
		SELECT ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, sum(Summa) FROM #ReadyFact
		GROUP BY ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID

	if @Plan_Cache is null
		INSERT #Plan (ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, Summa)
		SELECT ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, sum(Summa) FROM #ReadyPlan
		GROUP BY ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID
END ELSE
BEGIN
	if @Fact_Cache is null
		INSERT #Fact (ProjectID, PeriodID, CostDivisionID, CostTypeID, Summa)
		SELECT ProjectID, PeriodID, CostDivisionID, CostTypeID, sum(Summa) FROM #ReadyFact
		GROUP BY ProjectID, PeriodID, CostDivisionID, CostTypeID

	if @Plan_Cache is null
		INSERT #Plan (ProjectID, PeriodID, CostDivisionID, CostTypeID, Summa)
		SELECT ProjectID, PeriodID, CostDivisionID, CostTypeID, sum(Summa) FROM #ReadyPlan
		GROUP BY ProjectID, PeriodID, CostDivisionID, CostTypeID
END


if @Plan_Cache is null
begin
	select @Plan_Cache = id from CalcProjectCache 
	where FirmIDs=@FirmIDs and ConfirmLevel=@ConfirmLevel and VersionDate=@VersionDate and Temlate_id=@CostTemplateID and BudgetsGroup_id=@BudgetsGroupID and ExcludeInternal=@ExcludeInternal and [type]=0

	if @Plan_Cache is not null
	begin
		delete from CalcDistribCachePlan where CalcProjectCache_id = @Plan_Cache
		delete from CalcProjectCachePlan where CalcProjectCache_id = @Plan_Cache
	end else
	begin
		insert into CalcProjectCache([Date], FirmIDs, ConfirmLevel, VersionDate, Temlate_id, BudgetsGroup_id, ExcludeInternal, [Type])
		select getDate(), @FirmIDs, @ConfirmLevel, @VersionDate, @CostTemplateID, @BudgetsGroupID, @ExcludeInternal, 0
		select @Plan_Cache = @@IDENTITY
	end
	
	insert CalcDistribCachePlan(Project_ID, Period_ID, CostDivision_ID, CostType_id, State_id, Summa, CalcProjectCache_id)
	SELECT ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, sum(Summa), @Plan_Cache FROM #ReadyPlan
	GROUP BY ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID

	insert CalcProjectCachePlan(Project_ID, Period_ID, CostType_id, State_id, Summa, CalcProjectCache_id, CreditDebit_id, [Level])
	select ProjectID, PeriodID, CostType, StateID, Summa, @Plan_Cache, CreditDebitID, [Level] from #ProjectPlan
end

if @Fact_Cache is null
begin
	select @Fact_Cache = id from CalcProjectCache 
	where FirmIDs=@FirmIDs and ConfirmLevel=@ConfirmLevel and VersionDate=@VersionDate and Temlate_id=@CostTemplateID and BudgetsGroup_id=@BudgetsGroupID and ExcludeInternal=@ExcludeInternal and [type]=1

	if @Fact_Cache is not null
	begin
		delete from CalcDistribCacheFact where CalcProjectCache_id = @Fact_Cache
		delete from CalcProjectCacheFact where CalcProjectCache_id = @Fact_Cache
	end else
	begin
		insert into CalcProjectCache([Date], FirmIDs, ConfirmLevel, VersionDate, Temlate_id, BudgetsGroup_id, ExcludeInternal, [Type])
		select getDate(), @FirmIDs, @ConfirmLevel, @VersionDate, @CostTemplateID, @BudgetsGroupID, @ExcludeInternal, 1
		select @Fact_Cache = @@IDENTITY
	end
	
	insert CalcDistribCacheFact(Project_ID, Period_ID, CostDivision_ID, CostType_id, State_id, Summa, CalcProjectCache_id)
	SELECT ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID, sum(Summa), @Fact_Cache FROM #ReadyFact
	GROUP BY ProjectID, PeriodID, CostDivisionID, CostTypeID, StateID

	insert CalcProjectCacheFact(Project_ID, Period_ID, CostType_id, State_id, Summa, CalcProjectCache_id, CreditDebit_id, [Level])
	select ProjectID, PeriodID, CostType, StateID, Summa, @Fact_Cache, CreditDebitID, [Level] from #ProjectFact
end


/*
select * 
	from #p1 p1
	full join #p2 p2 on p1.ProjectID = p2.ProjectID and p1.PeriodID = p2.PeriodID  and p1.CostType = p2.CostType  and p1.StateID = p2.StateID and p1.DistribTypeID = p2.DistribTypeID  and p1.CostDivisionID = p2.CostDivisionID
where isnull(p1.Summa, 0) != isnull(p2.Summa, 0)
*/

select * from #ProjectPlan where periodid <=228 order by 2