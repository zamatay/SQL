/*
with objects_text as (
select cast(a AS XML).query('/a').value('.', 'varchar(max)') text, sc.name, OBJECTPROPERTY(object_id, 'IsAnsiNullsOn') IsAnsiNullsOn, OBJECTPROPERTY(object_id, 'IsQuotedIdentOn') IsQuotedIdentOn
	from sys.objects sc
	cross APPLY (select text  from syscomments where id=sc.object_id order by colid for XML path('a')) t(a)
where type in ('FN', 'P', 'TR', 'TF', 'V')),
createFind as (select CHARINDEX('create', text) pos, * from objects_text where IsAnsiNullsOn=0 or IsQuotedIdentOn=0)
select SUBSTRING(text, 1, pos - 1) + 'ALTER' + SUBSTRING(text, pos + 6, len(text)-pos-6), text from createFind where IsAnsiNullsOn=0 or IsQuotedIdentOn = 0
*/
declare 
	@sql_text nvarchar(max),
	@name varchar(max)

--print 'SET QUOTED_IDENTIFIER ON
--SET ANSI_NULLS ON';r

declare ms_crs_syscom  CURSOR LOCAL FOR 
with objects_text as (
select replace(replace(replace(cast(a AS XML).query('/a').value('.', 'varchar(max)'), '   ', ' '), '  ', ' '), '  ', ' ') text, sc.name, OBJECTPROPERTY(object_id, 'IsAnsiNullsOn') IsAnsiNullsOn, OBJECTPROPERTY(object_id, 'IsQuotedIdentOn') IsQuotedIdentOn
, case type when 'FN' then 'FUNCTION' when 'P' then 'PROCEDURE' when 'TR' then 'TRIGGER' when 'TF' then 'FUNCTION' when 'V' then 'VIEW' end typeText
	from sys.objects sc
	cross APPLY (select text  from syscomments where id=sc.object_id order by colid for XML path('a')) t(a)
where type in ('FN', 'P', 'TR', 'TF', 'V')),
createFind as (select CHARINDEX('create ' + typeText, text) pos, * from objects_text where IsAnsiNullsOn=0 or IsQuotedIdentOn=0)
select SUBSTRING(text, 1, pos - 1) + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10) + 'ALTER ' + typeText + SUBSTRING(text, pos + 7 + len(typeText), len(text)- 6 - pos-len(typeText)), name 
from createFind FOR READ ONLY
OPEN ms_crs_syscom
	WHILE 1=1
	begin
		FETCH NEXT from ms_crs_syscom into @sql_text, @name;
		set @sql_text = replace(@sql_text, 'SET QUOTED_IDENTIFIER OFF', 'SET QUOTED_IDENTIFIER ON');
		set @sql_text = replace(@sql_text, 'SET ANSI_NULLS OFF', 'SET ANSI_NULLS ON');

		BEGIN TRY
			--print @sql_text
			exec sys.sp_executesql @sql_text
			print 'OK: ' + @name
		END TRY
		begin CATCH
			print 'ERROR: ' + @name
			--print @sql_text
		END CATCH
		if @@fetch_status < 0 BREAK;
	end
CLOSE ms_crs_syscom
DEALLOCATE ms_crs_syscom
/*
select cast(a AS XML).query('/a').value('.', 'varchar(max)') text, sc.name, OBJECTPROPERTY(object_id, 'IsAnsiNullsOn') IsAnsiNullsOn, OBJECTPROPERTY(object_id, 'IsQuotedIdentOn') IsQuotedIdentOn
	from sys.objects sc
	cross APPLY (select text  from syscomments where id=sc.object_id order by colid for XML path('a')) t(a)
where type in ('FN', 'P', 'TR', 'TF', 'V') and ( OBJECTPROPERTY(object_id, 'IsAnsiNullsOn') = 0 or OBJECTPROPERTY(object_id, 'IsQuotedIdentOn') = 0)

with objects_text as (
select cast(a AS XML).query('/a').value('.', 'varchar(max)') text, sc.name, OBJECTPROPERTY(object_id, 'IsAnsiNullsOn') IsAnsiNullsOn, OBJECTPROPERTY(object_id, 'IsQuotedIdentOn') IsQuotedIdentOn
	from sys.objects sc
	cross APPLY (select text  from syscomments where id=sc.object_id order by colid for XML path('a')) t(a)
where type in ('FN', 'P', 'TR', 'TF', 'V'))
select * from objects_text where name = 'm_PrepareToRecalc'

select text, * from syscomments where id=object_id('m_PrepareToRecalc') order by colid
    
	  --подготовка к пересчету  CREATE   PROCEDURE [dbo].[m_PrepareToRecalc](@CountToUpdate int out) AS    if object_id(N'tempdb..#_DoNotRefresh') is null   create table #_DoNotRefresh(id int)    --ќбнулить те, что не имеют timeorder  update m_GoodsMove  set IsCorrect=0  where TimeOrder is null  --обнулить приходы и св€зынные с ними расходы    --Ќовые добавленные записи в m_GoodsMove не имеют TimeOrder,  его необходимо проставить  --ѕростановка TimeOrder  declare @idStart int,   @DC datetime,   @DCD datetime,   @dCnt int,   @id int  declare @tmpTimeOrders Table (id int, TimeOrder int identity(2,2) )      --перва€ непроставленна€ запись  select top 1 @DC=DateClose, @DCD = DateCloseDoc, @dCnt=dCount, @id=id  from m_GoodsMove   where TimeOrder is null  order by DateClose, DateCloseDoc, dCount desc, id    --TimeOrder предыдущей записи перед первой непроставленной  select top 1 @idStart=TimeOrder  from m_GoodsMove  where DateClose<=@DC and (DateCloseDoc <= @DCD or DateClose < @DC) and (dCount>=@dCnt or DateClose<@DC or DateCloseDoc < @DCD) and (id<@id or DateClose<@DC or DateCloseDoc<@DCD or dCount>@dCnt)  order by DateClose desc, DateCloseDoc desc, dCount, id desc    insert into @tmpTimeOrders (id)  select id  from m_GoodsMove  where DateClose>=@DC and (DateCloseDoc>=@DCD or DateClose > @DC) and (dCount<=@dCnt or DateClose>@DC or DateCloseDoc>@DCD) and (id>=@id or DateClose>@DC or DateCloseDoc>@DCD or dCount<@dCnt)  order by DateClose, DateCloseDoc, dCount desc, id    update gm  set TimeOrder=t.TimeOrder+ IsNull(@idStart,0)  from m_GoodsMove gm   join @tmpTimeOrders t on gm.id=t.id    --TimeOrder проставлено    --“еперь необходимо сбросить IsCorrect на 0 у всех, что после неправильных. “акже необходимо восстановить значени€  --Rest у приходов, сбросить у них IsCorrect, а также у всех записей, что идут после этих приходов.    declare @FirstWrong Table (Rest_id int, id int, TimeOrder int)  declare @PriorWrong Table(Rest_id int, id int, TimeOrder int)  declare @c int    set @c=1    --ѕервые неправильные значени€  insert into @FirstWrong (Rest_id, id, TimeOrder)  select mg1.Rest_id, mg1.id, mg1.TimeOrder  from   (select distinct rest_id   from m_GoodsMove   where IsCorrect = 0  ) mg   join m_GoodsMove mg1 on mg1.id=(          select top 1 id          from m_GoodsMove          where IsCorrect=0 and Rest_id=mg.Rest_id          order by DateClose, DateCloseDoc, dCount desc, id         )    update gm  set IsCorrect=0, Rest= case when dCount>0 then dCount else null end  from m_GoodsMove gm   join @FirstWrong t on gm.Rest_id=t.Rest_id  where gm.TimeOrder>=t.TimeOrder      while @c>0  begin   delete from @PriorWrong     insert into @PriorWrong(Rest_id, id, TimeOrder)   select t.Rest_id, t.id,  case  when g.FirstTimeOrder is not null and g.LastTimeOrder is not null then         case when g.FirstTimeOrder<=g.LastTimeOrder then g.FirstTimeOrder else g.LastTimeOrder end       when g.FirstTimeOrder is null then g.LastTimeOrder       else g.FirstTimeOrder      end   from @FirstWrong t    join (     select gm.Rest_id, min(gm1.TimeOrder) as FirstTimeOrder, min(gm2.TimeOrder) as LastTimeOrder     from m_GoodsMove gm      left join m_GoodsMove gm1 on gm.FirstPrihod=gm1.id      left join m_GoodsMove gm2 on gm.LastPrihod=gm2.id     where gm.IsCorrect=0     group by gm.Rest_id     ) g on t.Rest_id=g.Rest_id and ((t.TimeOrder>g.FirstTimeOrder) or (t.TimeOrder>g.LastTimeOrder))       select @c=count(*) from @PriorWrong   if @c>0   begin    update f    set TimeOrder=p.TimeOrder    from @FirstWrong f     join @PriorWrong p on f.Rest_id=p.Rest_id      update gm    set IsCorrect=0, Rest= case when dCount>0 then dCount else null end    from m_GoodsMove gm     join @FirstWrong t on gm.Rest_id=t.Rest_id    where gm.TimeOrder>=t.TimeOrder   end    end --while @c>0    --¬се потенциально неправильные записи обновлены, флаги сброшены.    --ќбновить агреггирующие строки  declare @Avgs Table (Period_id int, DateClose datetime, TimeOrder int, Rest_id int)    insert into @Avgs(Period_id, TimeOrder, Rest_id)  select Period_id, max(TimeOrder), Rest_id  from m_GoodsMove g  where IsCorrect=0 and Period_id in (select id from FinancePeriods where del=0 and Method_id in (select id from FinanceCalcMethods where SysName='Avg' and del=0))  group by Period_id, Rest_id    update a  set DateClose=DateAdd(ss, -1, fp.DateEnd) from @Avgs a   join FinancePeriods fp on a.Period_id=fp.id    --обновление существующих строк  update gm  set  DateClose = case when a.dateClose is null then GetDate() else a.DateClose end,    DateCloseDoc = case when a.dateClose is null then GetDate() else a.DateClose end,   TimeOrder=a.TimeOrder+1  from m_GoodsMove gm   join @Avgs a on gm.Period_id=a.Period_id and gm.Document_id is null and a.Rest_id=gm.Rest_id    --добавление новых агреггирующих строк  declare @Valuta_id int  set @Valuta_id=(select top 1 Valuta_id from m_GoodsMove where Valuta_id is not null)    insert into m_GoodsMove(del, IsCorrect, Document_id, Period_id, Valuta_id, dCount, dPrice, Rest, DateClose, TimeOrder, Rest_id, DateCloseDoc)  select 0, 0, null, a.Period_id, @Valuta_id, 0, 0, 0, a.DateClose, a.TimeOrder+1, a.Rest_id, a.DateClose  from @Avgs a   left join m_GoodsMove gm on a.Period_id=gm.Period_id and gm.Document_id is null and a.Rest_id=gm.Rest_id  where gm.id is null and a.dateClose is not null    --Avg добавлено и обновлено    --“.к. производ€тс€ изменени€ только по расходным строкам, а у приходных мен€етс€ только остаток, то это значит,   --что все приходные строки, кроме агреггирующих и внутреннего перемещени€, теперь правильные.  update mgm1  set IsCorrect=1  from m_GoodsMove mgm1   left join m_GoodsMove mgm2 on mgm1.id = mgm2.toID  where mgm1.dCount>0 and mgm1.Document_id is not null --and id not in (select toID from m_GoodsMove)   and mgm2.id is null    set @CountToUpdate=(select max(a.cnt)  from ( select Rest_id, Count(*) as Cnt   from m_GoodsMove    where IsCorrect=0   group by Rest_id) a  )  select @CountToUpdate=IsNull(@CountToUpdate, 0)    drop table #_DoNotRefresh    --если есть временна€ таблица дл€ хранени€ документов дл€ обновлени€ суммы (внутреннее перемещение)  --то туда надо залить идентификаторы этих документов  if object_id(N'tempdb..#DocsToUpdate') is not null   insert into #DocsToUpdate(id)   select distinct d.id   from m_GoodsMove gm    join m_Document d on gm.Document_id=d.id and d.del=0    join m_TypeDoc td on td.id=d.TypeDoc_id   where td.Options &1024 = 1024 and gm.IsCorrect=0        
	  */


