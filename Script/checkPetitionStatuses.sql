	;with a as (
	select PetitionStatuse_id, b.status_id, p.id
	from r_Petitions p
    left join
	    (select top 1 with ties OurClient_id, Petition_id, id Contract_id, summa
			from x_Contracts 
			where del = 0 and Petition_id is not null and Contract_id is null and FlagInOut = 0 and ContractStatus_id in (1,2) 
		and Client_id not in (select Client_id from OurFirms where del = 0)
		order by row_number() over(partition by OurClient_id, Petition_id order by id desc)) cp on cp.OurClient_id = p.OurFirm_id and cp.Petition_id = p.id
    --����������� ������� - JoinSQL
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
    --��������� ���������� ��� �����
    when IsSign.IsAnnulManager != 0 
        or
        IsSign.IsAnnulDSRIM != 0 then 7
    --��������� �����
    when IsSign.IsRejectDSRIM != 0 then 9
    --��������� ����� � ���������
    --��������� � ���������
    when IsSign.IsAnnulDSRIMCondition != 0 then 11
    --��������� �������
    --��������� ���
    when IsSign.IsAnnulBack != 0 then 10 
    --������� ������������
    when
        dbo.r_get_Petition_DSRIM_Confirmation(p.id) = 1
    then
        case 
            --��������� �����, ����������� ����� � ����������� � ��������
            --������ �������
            --���������� (���� �������)
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  
                and IsSign.IsAgreedClient != 0 
                and cp.Contract_id is not NULL then 6
            --��������� �����, ����������� ����� � ����������� � ��������
            --������ �������
            --�� ��������� ��������
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  
                and IsSign.IsAgreedClient != 0 
                and fp.Contract_id is not NULL then 8
            --��������� �����, ����������� ����� � ����������� � ��������
            --�� ���������� ��������
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  
                and IsSign.IsAgreedClient != 0 then 5
            --��������� ����� � ����������� �����
            --�� ������������ � ��������
            when IsSign.IsSignDSRIM != 0 
                and IsSign.IsAgreedDSRIM != 0  then 4
           --��������� �����
           --� ������ � �����
            when IsSign.IsSignDSRIM != 0 then 3
            --�� ��������� �����
            --�� ������������ � �����
            when IsSign.IsSignDSRIM = 0 and IsSign.IsSignManager != 0 then 2
            --�� ��������
            else 1
        end   
	--�� ������� ������������
    else 
        case 
            --��������� ���������� � ����������� � ��������
            --������ �������
            --���������� (���� �������)
            when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0)) 
                and IsSign.IsAgreedClient != 0  
                and cp.Contract_id is not NULL then 6
            --��������� ���������� � ����������� � ��������
            --�� ��������� ��������
            when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0))
                and IsSign.IsAgreedClient != 0  
                and fp.Contract_id is not NULL then 8
            --��������� ���������� � ����������� � ��������
            --�� ���������� ��������
            when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0))
                and IsSign.IsAgreedClient != 0  then 5
            --��������� ����������
            --�� ������������ � ��������
           when (IsSign.IsSignManager != 0 or (IsSign.IsSignDSRIM != 0 and IsSign.IsAgreedDSRIM != 0)) 
                then 4   
            --�� ��������
            --�� ����������
            else 1
        end
	end
	) b(status_id)
	where p.del = 0
)
select * from a where isnull(PetitionStatuse_id, 0) != isnull(status_id, 0)

--exec [r_SetStatusPetition] '38617'