---View used for displaying credit risk for users based on 
--credit ratings available from different credit rating agencies
use personal_fin_mange;
go;
Create VIEW CreditRiskView
AS
SELECT
    p.Profile_ID,p.First_Name,p.last_name,
    dbo.GetCreditRisk(p.Profile_ID) AS CreditRisk
FROM profile p
go;


--View, CreditRiskInsuranceSummaryView, provides a summary of insurance policies for 
--users, including policy details and an associated credit risk categorization based on their credit scores from the available credit rating agencies.
GO;
CREATE VIEW InsurancePoliciesSummaryView 
AS
SELECT
	p.profile_ID,
	p.First_Name,
	p.Last_Name,
	pd.Policy_ID,
	it.TYPE_ID AS Insurance_type,
	ip.Provider_Name,
	pd.Policy_Number,
	pd.Start_date,
	Pd.end_date
FROM
Policy_Details pd
	JOIN Insurance_Type it ON pd.Type_ID =it.Type_ID
	JOIN Insurance_Providers ip ON pd.Provider_ID = ip.Provider_id
	JOIN Profile p ON pd.Profile_ID = p.Profile_ID;
GO;

--View to fetch the financial summary of all the users to contain 
--bank balance, credit card due, loan payment due and  investment value 
create view 
FinancialSummary
AS
SELECT 
	p.Profile_ID,p.First_Name,p.last_name,
	dbo.GetUserBankAccountBalance(p.profile_id) as Bank, 
	dbo.GetUserTotalCreditCardDebt(p.profile_id),
	dbo.GetInvestmentValue(p.profile_id),
	dbo.GetPendingLoanPayment(p.profile_id)
from profile p;

-- View to display All the transactions(both credit and debit) at one place
CREATE VIEW vw_TransactionOverview AS
SELECT
    'Bank' AS TransactionSource,
    p.FIRST_NAME,
    BANK_TRANSACTION_ID AS TransactionID,
    a.ACCOUNT_ID,
    bi.NAME as Bank_Name,
    AMOUNT,
    TRANSACTION_DATE,
    b.TRANSACTION_TYPE,
    e.name as Expense_category
FROM BANK_TRANSACTION b
left join EXPENSE_CATEGORY e on b.EXPENSE_CATEGORY_ID = e.EXPENSE_CATEGORY_ID
join ACCOUNTS a on b.ACCOUNT_ID = a.ACCOUNT_ID
join BANK_INFORMATION bi on bi.BANK_ID = a.BANK_ID
Join profile p on a.PROFILE_ID = p.PROFILE_ID
UNION
SELECT
    'Credit Card' AS TransactionSource,
    p.FIRST_NAME,
    CC_TRANSACTION_ID AS TransactionID,
    cc.CREDIT_CARD_ID AS ACCOUNT_ID,
    bi.NAME as Bank_Name,
    AMOUNT,
    TRANSACTION_DATE,
    TRANSACTION_TYPE,
		e.name as Expense_category
FROM CREDIT_CARD_TRANSACTION c
left join EXPENSE_CATEGORY e on c.EXPENSE_CATEGORY_ID = e.EXPENSE_CATEGORY_ID
join CREDIT_CARD cc on cc.CREDIT_CARD_ID = c.CREDIT_CARD_ID
join BANK_INFORMATION bi on bi.BANK_ID = cc.BANK_ID
Join profile p on cc.PROFILE_ID = p.PROFILE_ID;




