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

-- отправить сообщение
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

--Пример хранимой процедуры для завершения всех диалогов (взят из форума на sql.ru):
--CREATE PROCEDURE dbo.usp_EndAllConversations AS
BEGIN
 DECLARE @sql NVARCHAR(MAX) = N''
 SELECT @sql = @sql + REPLACE('END CONVERSATION "' + CONVERT(NVARCHAR(36), [conversation_handle]) +
'" WITH CLEANUP', NCHAR(34), NCHAR(39)) + NCHAR(59) + NCHAR(13) + NCHAR(10)
 FROM sys.conversation_endpoints WHERE [state] <> 'CD';
 PRINT @sql;
 EXEC (@sql);
END

Диагностика
Способы диагностики для Service Broker:
1. Просмотр системных представлений или функций.
2. Просмотр событий в SQL Server Profiler или Extended Events.
3. Тестирование с помощью утилиты ssbdiagnose.
При анализе причин сбоев в первую очередь нужно проверить корректность настроек безопасности (см.
Безопасность и защита (компонент Service Broker)) и соответствие имен типов сообщений и служб.
Основные понятия устранения неполадок (компонент Service Broker).
Системные представления и функции
Для просмотра объектов Service Broker используются представления:
• Точки подключения для Service Broker: sys.service_broker_endpoints.
• Типы сообщений: sys.service_message_types.
o Коллекции XML-схем для проверки формата сообщений:
sys.message_type_xml_schema_collection_usages.
• Контракты: sys.service_contracts.
o Использование типов сообщений для контрактов: sys.service_contract_message_usages.
• Очереди: sys.service_queues.
• Службы: sys.services.
o Использование очередей для служб: sys.service_queue_usages.
o Использование контрактов для служб: sys.service_contract_usages.
• Маршруты: sys.routes.
• Удаленные привязки служб: sys.remote_service_bindings.
• Приоритеты служб: sys.conversation_priorities.
Для анализа работы и текущего состояния Service Broker используются представления:
• Сообщения в очереди передач: sys.service_broker_endpoints.
Может содержать общую информацию о проблемах с передачей данных в поле transmission_status.
Также имеется поле is_conversation_error для фильтрации сообщений об ошибке.
• Активные диалоги: sys.conversation_endpoints.
Позволяет анализировать текущую активность на инициаторе или цели. Поля state и state_desc
описывают состояния диалога, в т.ч. наличие ошибок (значения 'ER' и 'ERROR' соответственно).
• Активные группы диалогов: sys.conversation_endpoints.
Дополнительно можно использовать динамические административные представления:
• Хранимые процедуры как обработчики входящих сообщений: sys.dm_broker_activated_tasks.
• Список мониторов очереди, выполняющих активацию хранимых процедур для обработки входящих
сообщений: sys.dm_broker_queue_monitors.
• Используемые Service Broker cетевые подключения: sys.dm_broker_connections.
• Сообщения, пересылаемые в данный момент: sys.dm_broker_forwarded_messages.
Эти представления позволяют получить общую информацию о настройках и состоянии, которую можно
использовать для аудита. Но они не содержат детальную информацию об ошибках, необходимых для их
исправления.
13
На основе представлений можно разрабатывать запросы для аудита или скрипты как инструменты для 