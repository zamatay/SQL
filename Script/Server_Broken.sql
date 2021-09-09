/*
ALTER DATABASE vkb_test1 set enable_broker
ALTER  DATABASE vkb_test1 SET NEW_BROKER WITH ROLLBACK IMMEDIATE 
*/

-- отлалвливаем сообщение
ALTER QUEUE TargetService
  WITH ACTIVATION(
    STATUS = ON,
    -- выполняемая процедура
    PROCEDURE_NAME = fillPayments,
    MAX_QUEUE_READERS = 10,
    EXECUTE AS OWNER)
    

-- создаем тип
CREATE MESSAGE TYPE [PayType] VALIDATION = NONE 

-- создаем контракт
CREATE CONTRACT [Payments] ([PayType] SENT BY ANY)

-- отправляем сообщение
    DECLARE @Handler uniqueidentifier

	BEGIN DIALOG   @Handler
		FROM SERVICE    [SourceService]
		TO SERVICE      'TargetService'
		ON CONTRACT     [Payments];

	SEND ON CONVERSATION  @Handler
	  MESSAGE TYPE [PayType] (N'Payments hase been changed')

	END CONVERSATION  @Handler
	
-- проверка
/*
CREATE table ##paymentstemp(ProjectID INT, PeriodID INT, Summa MONEY, CreditDebitID INT, StateID INT)

truncate table ##paymentstemp	
*/

INSERT INTO dbo.Payments
default VALUES

SELECT * FROM ##paymentstemp
