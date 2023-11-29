use personal_fin_mange;
--Inserting data into Notification table Based on due date and number of 
--days of period

go;
Create PROCEDURE InsertNotificationsBasedOnDueDays
   @ProfileId UNIQUEIDENTIFIER,
   @DueMonthPeriod int
AS
BEGIN
   SET NOCOUNT ON;
   
   DECLARE @CurrentDate DATE = GETDATE();
   DECLARE @DueDate DATE = DATEADD(DAY, @DueMonthPeriod, @CurrentDate);
   
   INSERT INTO dbo.NOTIFICATION ([NOTIFICATION_ID], [PROFILE_ID], [Notification_TYPE], [TIMESTAMP], [AMOUNT], [DUE_DATE], [MESSAGE], [ISREAD])
   SELECT NEWID(), TA.PROFILE_ID, 'SIP_DUE', GETDATE(), SD.AMOUNT, SD.NXT_PAY_DATE, 'Please pay for your SIP holdings due', 0
   FROM dbo.Trading_Account TA
   JOIN dbo.STOCK_BOOK SB ON TA.ACCOUNT_ID = SB.ACCOUNT_ID
   JOIN dbo.SIP_DETAILS SD ON SB.HOLDING_ID = SD.SIP_HOLDING_ID
   WHERE TA.PROFILE_ID = @ProfileId AND SD.NXT_PAY_DATE <= @DueDate;
   
   INSERT INTO dbo.NOTIFICATION ([NOTIFICATION_ID], [PROFILE_ID], [Notification_TYPE], [TIMESTAMP], [AMOUNT], [DUE_DATE], [MESSAGE], [ISREAD])
   SELECT NEWID(), PD.PROFILE_ID, IT.NAME, GETDATE(), PD.PAYMENT_AMOUNT, PD.NEXT_PAY_DATE, 'Please pay your insurance fees before due', 0
   FROM dbo.POLICY_DETAILS PD
   JOIN dbo.INSURANCE_TYPE IT on PD.TYPE_ID = IT.TYPE_ID
   WHERE PD.PROFILE_ID = @ProfileId AND PD.NEXT_PAY_DATE <= @DueDate;

   INSERT INTO dbo.NOTIFICATION ([NOTIFICATION_ID], [PROFILE_ID], [Notification_TYPE], [TIMESTAMP], [AMOUNT], [DUE_DATE], [MESSAGE], [ISREAD])
   SELECT NEWID(), CC.PROFILE_ID, 'CreditCard', GETDATE(), CC.PAYMENT_DUE_AMOUNT, CC.DUE_DATE, 'Please pay the credit card due amount before the due period.', 0
   FROM dbo.CREDIT_CARD CC
   WHERE CC.PROFILE_ID = @ProfileId AND CC.DUE_DATE <= @DueDate;

   INSERT INTO dbo.NOTIFICATION ([NOTIFICATION_ID], [PROFILE_ID], [Notification_TYPE], [TIMESTAMP], [AMOUNT], [DUE_DATE], [MESSAGE], [ISREAD])
   SELECT NEWID(), LL.PROFILE_ID, LL.LOAN_NAME, GETDATE(), IT.DUE_AMOUNT, DATEADD(month,1,IT.due_date), 'Please pay the Installment amount before the due period.', 0
   FROM dbo.LOANS LL
   JOIN dbo.INSTALLMENTS IT on LL.LOAN_ID = IT.LOAN_ID
   WHERE LL.PROFILE_ID = @ProfileId
   AND IT.DUE_DATE = (
   SELECT MAX(DUE_DATE)
   FROM dbo.INSTALLMENTS
   WHERE LOAN_ID = LL.LOAN_ID
   ) and
   DATEADD(month,1,IT.due_date) <= @DueDate;
END;

--A procedure that takes profile_id as input and takes all accounts
--owned by the profile_id from the from the account table, and 
--takes expenses spent by the accounts of that profile from the
--Bank_transactions table and returns the total amount and 
--percentage spent by the profile_id on particular expense category

go;
CREATE PROCEDURE GetProfileExpenses
    @ProfileID UNIQUEIDENTIFIER
AS
BEGIN
    -- Temporary table to store total expenses per category
    SELECT 
        EC.NAME AS CategoryName, 
        SUM(BT.AMOUNT) AS TotalAmount
    INTO #CategoryExpenses
    FROM 
        ACCOUNTS A
    JOIN 
        BANK_TRANSACTION BT ON A.ACCOUNT_ID = BT.ACCOUNT_ID
    JOIN 
        EXPENSE_CATEGORY EC ON BT.EXPENSE_CATEGORY_ID = EC.EXPENSE_CATEGORY_ID
    WHERE 
        A.PROFILE_ID = @ProfileID
    GROUP BY 
        EC.NAME
    -- Calculate total expenses
    DECLARE @TotalExpenses MONEY
    SELECT @TotalExpenses = SUM(TotalAmount) FROM #CategoryExpenses
    -- Select final results with percentage calculation
    SELECT 
        CategoryName, 
        TotalAmount, 
        (TotalAmount / @TotalExpenses) * 100 AS Percentage
    FROM 
        #CategoryExpenses
    -- Cleanup temporary table
    DROP TABLE #CategoryExpenses
END

--For a profile which is having good credit score and
--having no loans provide a loan offer using the notification table.
go;
create PROCEDURE InsertLoanDealNotification
AS
BEGIN
   SET NOCOUNT ON;
   DECLARE @CurrentDate DATETIME = GETDATE();
   IF NOT EXISTS (
       SELECT 1
       FROM dbo.NOTIFICATION
       WHERE [PROFILE_ID] IN (
           SELECT CRV.PROFILE_ID
           FROM dbo.CreditRiskView CRV
           LEFT JOIN dbo.Loans LL ON CRV.PROFILE_ID = LL.PROFILE_ID
           WHERE CRV.CreditRisk IN ('Very Good', 'Excellent')
           AND LL.PROFILE_ID IS NULL
       )
       AND [Notification_TYPE] = 'LOAN DEAL'
   )
   BEGIN
   INSERT INTO dbo.NOTIFICATION ([NOTIFICATION_ID], [PROFILE_ID], [Notification_TYPE], [TIMESTAMP], [AMOUNT], [DUE_DATE], [MESSAGE], [ISREAD])
   SELECT NEWID(), CRV.PROFILE_ID, 'LOAN DEAL', GETDATE(),'5000', DATEADD(DAY,10,GETDATE()), 'HAVE A LOAN DEAL, CLAIM IN 10 DAYS', 0
   FROM dbo.CreditRiskView CRV
   LEFT JOIN dbo.Loans LL ON CRV.PROFILE_ID = LL.PROFILE_ID
   WHERE CRV.CreditRisk IN ('Very Good', 'Excellent')
   AND LL.PROFILE_ID IS NULL;
   End
END;

EXEC InsertLoanDealNotification;

--Stored Procedure to execute a InsertNotificationBasedOnDueDays with 3 days grace days, and add notification to all the users regarding the payment due date 
-- and loan offers 
GO;
CREATE PROC dbo.send_notification_to_users
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER;

    DECLARE UserCursor CURSOR FOR
    SELECT DISTINCT PROFILE_ID
    FROM profile;

    OPEN UserCursor;
    FETCH NEXT FROM UserCursor INTO @UserID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.InsertNotificationsBasedOnDueDays @UserID,3;
        EXEC dbo.InsertLoanDealNotification;
        FETCH NEXT FROM UserCursor INTO @UserID;
    END

    CLOSE UserCursor;
    DEALLOCATE UserCursor;
END;





