--begin tran
	declare @ids table(id int identity, ext_id int, exec_id int)
	declare @request			varchar(max), 
			@application_uuid	varchar(40),
			@id					int,
			@exec_id			int
	declare dataset cursor local fast_forward for 
	select trim(request), json_value(request, '$.payload.application_id'), id from s_post_log where Ext_ID = -1

	open dataset 
	fetch from dataset into  @request, @application_uuid, @id
	
	while @@fetch_status = 0 
	begin
		BEGIN TRY  
			if trim(@application_uuid) <> ''
			begin
				insert into @ids(exec_id)
				exec r_ProcessApplication @request
				update @ids set ext_id = @id where id = @@identity
			end;
		END TRY  
		BEGIN CATCH  
			print @request
		END CATCH  
	  	fetch from dataset into  @request, @application_uuid, @id
	end
	update s_post_log set ext_id = i.exec_id
	from s_post_log l
		join @ids i on i.ext_id = l.id
	select * from s_post_log where ext_id = -1
	select * from r_MortgageRequests where MortgageRequestHeader_id=26947
	close dataset
	deallocate dataset

--rollback tran