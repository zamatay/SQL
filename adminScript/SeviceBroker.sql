--alter database vkb_test1 set enable_broker
--alter database vkb_test1 set disable_broker
CREATE MESSAGE TYPE mt_PetitionStatus validation = none
--drop message type mt_PetitionStatus 
create contract c_PetitionStatus (mt_PetitionStatus sent by any)
--drop contract c_PetitionStatus
/*
DROP QUEUE [q_petitionStatus]
*/
CREATE QUEUE [q_petitionStatus]
    WITH
    ACTIVATION (
		STATUS = ON, 
        PROCEDURE_NAME = r_petitionReadQueue,
		MAX_QUEUE_READERS = 10,
        EXECUTE AS OWNER ) ;
CREATE SERVICE [srv_PetitionStatus] ON QUEUE [q_petitionStatus] (c_PetitionStatus)
--DROP SERVICE [srv_PetitionStatus]

-- ��������� ���������
DECLARE @convHandler uniqueidentifier

BEGIN DIALOG   @convHandler
    FROM SERVICE    srv_PetitionStatus
    TO SERVICE      'srv_PetitionStatus'
    ON CONTRACT     [c_PetitionStatus]
WITH ENCRYPTION = OFF;
SEND ON CONVERSATION  @convHandler 
   MESSAGE TYPE [mt_PetitionStatus] (N'raznoe')

END CONVERSATION  @convHandler


RECEIVE top(1) try_convert(varchar(max), message_body), * from q_petitionStatus

select * from sys.service_broker_endpoints
select * from sys.service_queue_usages
select * from sys.conversation_endpoints

select * from sys.service_queues

select * from sys.service_message_types
select * from sys.service_contracts
select * from sys.service_queues
select * from sys.services

select * from sys.service_broker_endpoints
select * from sys.conversation_endpoints order by security_timestamp

select * from sys.dm_broker_activated_tasks
select * from sys.dm_broker_queue_monitors
select * from sys.dm_broker_connections
select * from sys.dm_broker_forwarded_messages

--������ �������� ��������� ��� ���������� ���� �������� (���� �� ������ �� sql.ru):
--CREATE PROCEDURE dbo.usp_EndAllConversations AS
BEGIN
 DECLARE @sql NVARCHAR(MAX) = N''
 SELECT @sql = @sql + REPLACE('END CONVERSATION "' + CONVERT(NVARCHAR(36), [conversation_handle]) +
'" WITH CLEANUP', NCHAR(34), NCHAR(39)) + NCHAR(59) + NCHAR(13) + NCHAR(10)
 FROM sys.conversation_endpoints WHERE [state] <> 'CD';
 PRINT @sql;
 EXEC (@sql);
END

�����������
������� ����������� ��� Service Broker:
1. �������� ��������� ������������� ��� �������.
2. �������� ������� � SQL Server Profiler ��� Extended Events.
3. ������������ � ������� ������� ssbdiagnose.
��� ������� ������ ����� � ������ ������� ����� ��������� ������������ �������� ������������ (��.
������������ � ������ (��������� Service Broker)) � ������������ ���� ����� ��������� � �����.
�������� ������� ���������� ��������� (��������� Service Broker).
��������� ������������� � �������
��� ��������� �������� Service Broker ������������ �������������:
� ����� ����������� ��� Service Broker: sys.service_broker_endpoints.
� ���� ���������: sys.service_message_types.
o ��������� XML-���� ��� �������� ������� ���������:
sys.message_type_xml_schema_collection_usages.
� ���������: sys.service_contracts.
o ������������� ����� ��������� ��� ����������: sys.service_contract_message_usages.
� �������: sys.service_queues.
� ������: sys.services.
o ������������� �������� ��� �����: sys.service_queue_usages.
o ������������� ���������� ��� �����: sys.service_contract_usages.
� ��������: sys.routes.
� ��������� �������� �����: sys.remote_service_bindings.
� ���������� �����: sys.conversation_priorities.
��� ������� ������ � �������� ��������� Service Broker ������������ �������������:
� ��������� � ������� �������: sys.service_broker_endpoints.
����� ��������� ����� ���������� � ��������� � ��������� ������ � ���� transmission_status.
����� ������� ���� is_conversation_error ��� ���������� ��������� �� ������.
� �������� �������: sys.conversation_endpoints.
��������� ������������� ������� ���������� �� ���������� ��� ����. ���� state � state_desc
��������� ��������� �������, � �.�. ������� ������ (�������� 'ER' � 'ERROR' ��������������).
� �������� ������ ��������: sys.conversation_endpoints.
������������� ����� ������������ ������������ ���������������� �������������:
� �������� ��������� ��� ����������� �������� ���������: sys.dm_broker_activated_tasks.
� ������ ��������� �������, ����������� ��������� �������� �������� ��� ��������� ��������
���������: sys.dm_broker_queue_monitors.
� ������������ Service Broker c������ �����������: sys.dm_broker_connections.
� ���������, ������������ � ������ ������: sys.dm_broker_forwarded_messages.
��� ������������� ��������� �������� ����� ���������� � ���������� � ���������, ������� �����
������������ ��� ������. �� ��� �� �������� ��������� ���������� �� �������, ����������� ��� ��
�����������.
13
�� ������ ������������� ����� ������������� ������� ��� ������ ��� ������� ��� ����������� ��� 