DECLARE @xml xml

SET @xml = 
'<payments id="2" GUID="0B825B42-7C70-4942-85BA-03235C0AF23C" Editor="2595" Creator="2595" DateEdit="2013-09-05T12:52:57.030" DateCreate="2013-09-05T12:52:40" del="1" ObjectFinance_id="799" state_id="1170" OurFirms_id="30" x_Contracts_id="81296" x_Contracts_summa="1.0000" client_id="1461" Debit_type="1161" Debit_id="60" Credit_type="911" Credit_id="1461" Comment="���, ����������� �������������������, ������ 96 �� 15 08 13" PAY_NUM="2" DatePay="2013-08-21T00:00:00" CreditDebitInternal="1" Summa="1.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="30" CreditFirm_type="911" CreditFirm_id="1461" IsPlan="1" />
<payments id="31" GUID="C4340EAC-991F-4F75-B863-7F8BD627F812" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:25:55.433" DateCreate="2008-01-16T10:51:09" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 19 �� 14/01/2008 �� ����� 22431,8 ��� �� ������������&#xD;&#xA;" PAY_NUM="������ �� �������" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="32" GUID="76A0AC5E-EBD9-45E8-815A-C6E577A72F17" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:27:02.420" DateCreate="2008-01-16T11:00:19" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 20 �� 14/01/2008 �� ����� 4119,8 ��� �� ������������&#xD;&#xA;" PAY_NUM="32" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="33" GUID="F2F0179E-F6EC-4FFF-AB47-3F3B58025D8C" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:40:29.653" DateCreate="2008-01-16T11:02:22" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 21 �� 14/01/2008 �� ����� 34314,27 ��� �� ������������&#xD;&#xA;" PAY_NUM="33" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="34" GUID="FB8F2C1B-7C77-42A1-BEBD-9C64A7D03965" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:41:12.920" DateCreate="2008-01-16T11:05:08" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 18 �� 14/01/2008 �� ����� 1935,2  ��� �� ������������&#xD;&#xA;" PAY_NUM="34" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="35" GUID="F6162677-7BCF-4B34-80EF-5CBDAD2E9FD1" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:41:28.513" DateCreate="2008-01-16T11:05:12" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 14 �� 14/01/2008 �� ����� 15040  ��� �� ������������&#xD;&#xA;" PAY_NUM="35" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="36" GUID="51EFC798-826F-4207-9012-A6A909CC0457" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:41:47.247" DateCreate="2008-01-16T11:07:07" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 15 �� 14/01/2008 �� ����� 1573  ��� �� ������������&#xD;&#xA;" PAY_NUM="36" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="37" GUID="0E336AE0-CFB6-4688-9E1D-6848DC2A7B59" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:42:02.843" DateCreate="2008-01-16T11:07:30" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 16 �� 14/01/2008 �� ����� 7200  ��� �� ������������&#xD;&#xA;" PAY_NUM="37" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="38" GUID="9C3440EC-AFA4-4DAA-AF24-2937E095FBAA" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:42:16.420" DateCreate="2008-01-16T11:07:54" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 17 �� 14/01/2008 �� ����� 80000  ��� �� ������������&#xD;&#xA;" PAY_NUM="38" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />
<payments id="39" GUID="36304DA3-6E39-40CF-81A0-F84F9D747099" Editor="2481" Creator="2478" DateEdit="2008-01-22T09:42:27.827" DateCreate="2008-01-16T11:08:21" del="0" state_id="1101" Departament_id="20" OurFirms_id="2" client_id="30" Debit_type="1161" Debit_id="4" Credit_type="911" Credit_id="30" DateClose="2008-01-22T00:00:00" Comment="�������������� �� ������� �������� ������� �������� ��������� � 13 �� 14/01/2008 �� ����� 6348  ��� �� ������������&#xD;&#xA;" PAY_NUM="39" DatePay="2008-01-14T00:00:00" CreditDebitInternal="1" Summa="8.0000" Valuta="12" DebitFirm_type="19870" DebitFirm_id="2" CreditFirm_type="911" CreditFirm_id="30" IsPlan="0" />'

SELECT 
   t.p.value('@id', 'VARCHAR(8000)') AS id,
   t.p.value('@GUID', 'VARCHAR(8000)') AS lastName
FROM @xml.nodes('/payments') t(p)
   
   