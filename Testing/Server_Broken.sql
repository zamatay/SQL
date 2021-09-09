/*
ALTER DATABASE vkb_test1 set enable_broker
ALTER  DATABASE vkb_test1 SET NEW_BROKER WITH ROLLBACK IMMEDIATE 
*/

-- ������������ ���������
ALTER QUEUE TargetService
  WITH ACTIVATION(
    STATUS = ON,
    -- ����������� ���������
    PROCEDURE_NAME = fillPayments,
    MAX_QUEUE_READERS = 10,
    EXECUTE AS OWNER)
    

-- ������� ���
CREATE MESSAGE TYPE [PayType] VALIDATION = NONE 

-- ������� ��������
CREATE CONTRACT [Payments] ([PayType] SENT BY ANY)

-- ���������� ���������
    DECLARE @Handler uniqueidentifier

	BEGIN DIALOG   @Handler
		FROM SERVICE    [SourceService]
		TO SERVICE      'TargetService'
		ON CONTRACT     [Payments];

	SEND ON CONVERSATION  @Handler
	  MESSAGE TYPE [PayType] (N'Payments hase been changed')

	END CONVERSATION  @Handler
	
-- ��������
/*
CREATE table ##paymentstemp(ProjectID INT, PeriodID INT, Summa MONEY, CreditDebitID INT, StateID INT)

truncate table ##paymentstemp	
*/

INSERT INTO dbo.Payments
default VALUES

SELECT * FROM ##paymentstemp
