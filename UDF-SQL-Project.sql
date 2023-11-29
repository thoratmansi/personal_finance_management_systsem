use personal_fin_mange;
go;
create or alter function CalculateNewAverage 
(@avg DECIMAL(18,2), @quantity DECIMAL(18,2), 
@value DECIMAL(18,2), @new_quantity DECIMAL(18,2))
returns DECIMAL(18,2)
as
begin
	declare @new_avg DECIMAL(18,2)
	select @new_avg = ( (@avg * @quantity) + (@value * @new_quantity) ) / (@quantity + @new_quantity);


	return @new_avg
end;
go;


select dbo.CalculateNewAverage(50, 100, 55, -50);


--Calculate Credit Risk for an user based on the credit 
--rating from various credit agencies
go;
create or alter FUNCTION dbo.GetCreditRisk
(
    @ProfileID UNIQUEIDENTIFIER
)
returns NVARCHAR(50)
AS
BEGIN
    DECLARE @CreditRisk NVARCHAR(50)

    -- Temporary table to store credit risk calculations for each agency
   DECLARE @TempCreditRisk TABLE
    (
        AgencyName VARCHAR(20),
        CreditScore INT,
        MaxScore INT,
        CreditRisk INT
    );
	
    -- Populate the temporary variable with data from 
	--CREDIT_INFO and CREDIT_AGENCY tables
    INSERT INTO @TempCreditRisk (AgencyName, CreditScore, MaxScore, CreditRisk)
    SELECT
        CA.Name AS AgencyName,
        CI.CURRENT_SCORE AS CreditScore,
        CA.MAX_SCORE AS MaxScore,
        CASE
            WHEN CI.CURRENT_SCORE >= CA.MAX_SCORE*0.9 THEN 5
            WHEN CI.CURRENT_SCORE >= CA.MAX_SCORE*0.8 THEN 4
            WHEN CI.CURRENT_SCORE >= CA.MAX_SCORE*0.75 THEN 3
            WHEN CI.CURRENT_SCORE >= CA.MAX_SCORE*0.7 THEN 2
            ELSE 1
        END AS CreditRisk
    FROM
        CREDIT_INFO CI
    JOIN
        CREDIT_AGENCY CA ON CI.Agency_ID = CA.Agency_ID
    WHERE
        CI.PROFILE_ID = @ProfileID;


    -- Determine the overall credit risk based on the average credit risk from various agencies
    SELECT
        @CreditRisk = CASE
            WHEN AVG(CreditRisk) >= 4.5 THEN 'Excellent'
            WHEN AVG(CreditRisk) >= 3.5 THEN 'Very Good'
            WHEN AVG(CreditRisk) >= 2.5 THEN 'Good'
            WHEN AVG(CreditRisk) >= 1.5 THEN 'Fair'
            ELSE 'Poor'
        END
    FROM @TempCreditRisk;


	return @CreditRisk
END;
go;

--Calculate the EMI amount for the Load based on the principal amount,
--interest rate and term.
go;
create or alter FUNCTION CalculateEMI (
    @LoanAmount FLOAT,
    @AnnualInterestRate FLOAT,
    @LoanTermInYears INT
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @MonthlyInterestRate FLOAT;
    DECLARE @TotalInstallments INT;
    DECLARE @EMI FLOAT;

    SET @MonthlyInterestRate = @AnnualInterestRate / 12 / 100;
	
    SET @TotalInstallments = @LoanTermInYears * 12;
	
    SET @EMI = @LoanAmount * @MonthlyInterestRate * POWER(1 + @MonthlyInterestRate, @TotalInstallments) / (POWER(1 + @MonthlyInterestRate, @TotalInstallments) - 1);
    RETURN @EMI;
END;
go;
--Query to update the installment amount column using the CalculateEMI function
update Loans 
set installment_amount = dbo.CalculateEMI(loan_amount, interest_rate,loan_term);

--Calculate Loan_End_Date for the Loans table based on start date and number of months:
go;
CREATE FUNCTION dbo.CalculateLoanEndDate
(
    @StartDate DATE,
    @LoanTerm DECIMAL(4,2)
)
RETURNS DATE
AS
BEGIN
    DECLARE @EndDate DATE
    -- Add the number of months specified in LoanTerm to the StartDate
    SET @EndDate = DATEADD(MONTH, CAST(@LoanTerm AS INT), @StartDate)
    RETURN @EndDate
END;
go;

--Function to fetch the Total Account Balance from 
--different accounts for the provided user 
go;
create or alter FUNCTION dbo.GetUserBankAccountBalance
    (@UserID UNIQUEIDENTIFIER)
RETURNS MONEY
AS
BEGIN
    DECLARE @TotalBankBalance MONEY;

    SELECT @TotalBankBalance = ISNULL(SUM(a.current_balance), 0)
    FROM profile p
    LEFT JOIN accounts a ON p.PROFILE_ID = a.Profile_id
    WHERE p.PROFILE_ID = @UserID;
	
    RETURN @TotalBankBalance;
END;
go;
--Function to fetch the total credit card debt for the provided user 
go;
create or alter FUNCTION dbo.GetUserTotalCreditCardDebt
    (@UserID UNIQUEIDENTIFIER)
RETURNS MONEY
AS
BEGIN
    DECLARE @TotalCreditCardDebt MONEY;
	
    SELECT @TotalCreditCardDebt = ISNULL(SUM(cc.credit_due_amount), 0)
    FROM profile p
    LEFT JOIN credit_card cc ON p.PROFILE_ID = cc.Profile_id
    WHERE p.PROFILE_ID = @UserID;

    RETURN @TotalCreditCardDebt;
END;
go;

--Get the total value of the investments for the provided user
go;
create or alter FUNCTION dbo.GetInvestmentValue
    (@UserID UNIQUEIDENTIFIER)
RETURNS MONEY
AS
BEGIN
    DECLARE @TotalInvestmentValue MONEY;


    SELECT @TotalInvestmentValue = ISNULL(SUM(sb.quantity * sb.avg_value), 0)
    FROM Trading_Account ta
    JOIN STOCK_BOOK sb ON sb.ACCOUNT_ID = ta.ACCOUNT_ID
    WHERE ta.profile_id = @UserID;


    RETURN @TotalInvestmentValue;
END;
go;
--Get the total pending loan amount for the provided profile
go;
create or alter FUNCTION dbo.GetPendingLoanPayment
    (@UserID UNIQUEIDENTIFIER)
RETURNS MONEY
AS
BEGIN
    DECLARE @TotalLoanAmount MONEY;

    SELECT @TotalLoanAmount = ISNULL(SUM(PendingLoanAmount), 0)
    FROM (
        SELECT l.LOAN_AMOUNT - ISNULL(SUM(i.payment_amout), 0) AS PendingLoanAmount
        FROM loans l
        LEFT JOIN installments i ON l.LOAN_id = i.loan_id
        WHERE l.profile_id = @UserID
        GROUP BY l.loan_id, l.LOAN_AMOUNT
    ) AS Subquery;

    RETURN @TotalLoanAmount;
END;
go;
