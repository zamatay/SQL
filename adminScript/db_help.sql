-- �������� ����
DBCC CHECKDB WITH NO_INFOMSGS;

-- ������ ������ �����
DBCC SQLPERF (Logspace) 

-- ���������� ���������� � �������� ������� ��� ���� ���
exec sp_msforeachdb 'USE ?; DBCC UPDATEUSAGE(?)'

-- ������ tempdb ��� ����������� �������
DBCC FREESYSTEMCACHE ('ALL')
DBCC SHRINKFILE (N'XBC_data' , 0, TRUNCATEONLY)

-- ������ "����������� �����" ��� ���� ���
exec sp_msforeachdb 'USE ?; CHECKPOINT'