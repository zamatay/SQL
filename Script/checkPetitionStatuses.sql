	;with a as (
	select PetitionStatuse_id, b.status_id, p.id
	from r_Petitions p
    left join
	    (select top 1 with ties OurClient_id, Petition_id, id Contract_id, summa
			from x_Contracts 
			where del = 0 and Petition_id is not null and Contract_id is null and FlagInOut = 0 and ContractStatus_id in (1,2) 
		and Client_id not in (select Client_id from OurFirms where del = 0)
		order by row_number() over(partition by OurClient_id, Petition_id order by id desc)) cp on cp.OurClient_id = p.OurFirm_id and cp.Petition_id = p.id
    --Действующий договор - JoinSQL
    outer apply (
    select top 1 contract_id 
    from r_FlatsContract with (noexpand)
    where flat_id=p.flat_id 
        and ContractStatus_id in (1,2) 
        and FlagInOut = 0 
        and PotentialClient_id = p.PotentialClient_id
        and Client_id not in (select Client_id from dbo.OurFirms)
        ) fp
	left join r_PetitionCalcStatuses IsSign ON IsSign.Petition_id = p.id 
	outer apply (select
	case 
    when IsSign.IsContractTerminate != 0 then 12
    --отклонено менеджером или ДСРиМ
    when IsSign.IsAnnulManager != 0 
        or
        IsSign.IsAnnulDSRIM != 0 then 7
    --Отклонено ДСРиМ
    when IsSign.IsRejectDSRIM != 0 then 9
    --отклонено ДСРИМ с условиями
    --Отклонено с условиями
    when IsSign.IsAnnulDSRIMCondition != 0 then 11
    --отклонено БэкОфис
    --Отклонено БЭК
    when IsSign.IsAnnulBack != 0 then 10 
    --требует согласования
    when
        dbo.r_get_Petition_DSRIM_Confirmation(p.id) = 1
    then
        case 
            --подписано ДСРиМ, согласовано ДСРиМ и согласовано с клиентом
            --создан договор
            --Отработана (есть договор)
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  
                and IsSign.IsAgreedClient != 0 
                and cp.Contract_id is not NULL then 6
            --подписано ДСРиМ, согласовано ДСРиМ и согласовано с клиентом
            --найден договор
            --На изменение договора
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  
                and IsSign.IsAgreedClient != 0 
                and fp.Contract_id is not NULL then 8
            --подписано ДСРиМ, согласовано ДСРиМ и согласовано с клиентом
            --На заключение договора
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  
                and IsSign.IsAgreedClient != 0 then 5
            --подписано ДСРиМ и согласовано ДСРиМ
            --На согласование с клиентом
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  then 4
           --подписано ДСРИМ
           --В работе у ДСРиМ
            when IsSign.IsSignDSRIM != 0 then 3
            --не подписано ДСРиМ
            --На согласование в ДСРиМ
            when IsSign.IsSignDSRIM = 0 and IsSign.IsSignManager != 0 then 2
            --не определён
            else 1
        end   
	--не требует согласования
    else 
        case 
            --подписано менеджером и согласовано с клиентом
            --создан договор
            --Отработана (есть договор)
            when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0)) 
                and IsSign.IsAgreedClient != 0  
                and cp.Contract_id is not NULL then 6
            --подписано менеджером и согласовано с клиентом
            --На изменение договора
            when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0))
                and IsSign.IsAgreedClient != 0  
                and fp.Contract_id is not NULL then 8
            --подписано менеджером и согласовано с клиентом
            --На заключение договора
            when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0))
                and IsSign.IsAgreedClient != 0  then 5
            --подписано менеджером
            --На согласование с клиентом
           when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0)) 
                then 4   
            --не определён
            --Не обработана
            else 1
        end
	end
	) b(status_id)
	where p.del = 0
)
select * from a where isnull(PetitionStatuse_id, 0) != isnull(status_id, 0)

--exec [r_SetStatusPetition] '38617'