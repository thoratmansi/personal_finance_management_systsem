use personal_fin_mange;

------ Non Clustered Indexes (Policy & Insurance tables) ----
-- INSURANCE_PROVIDERS table
CREATE INDEX IX_ProviderName ON INSURANCE_PROVIDERS (PROVIDER_NAME);
CREATE INDEX IX_ContactEmail ON INSURANCE_PROVIDERS (CONTACT_EMAIL);
-- INSURANCE_TYPE table
CREATE INDEX IX_InsuranceTypeName ON INSURANCE_TYPE (NAME);
-- POLICY_DETAILS table
CREATE INDEX IX_ProviderID ON POLICY_DETAILS (PROVIDER_ID);
CREATE INDEX IX_TypeID ON POLICY_DETAILS (TYPE_ID);
CREATE INDEX IX_ProfileID ON POLICY_DETAILS (PROFILE_ID);
CREATE INDEX IX_NextPayDate ON POLICY_DETAILS (NEXT_PAY_DATE);
-- CLAIM_HISTORY table
CREATE INDEX IX_PolicyID ON CLAIM_HISTORY (POLICY_ID);
--------------------------------------------------------------
------ Non Clustered Indexes (Bank & Credit card Transaction) ----
--Bank transaction table
-- Create a non-clustered index on the ACCOUNT_ID column for BANK_TRANSACTION table
CREATE NONCLUSTERED INDEX IX_AccountID
ON dbo.BANK_TRANSACTION (ACCOUNT_ID);

-- Create a non-clustered index on the TRANSACTION_DATE column for BANK_TRANSACTION table
CREATE NONCLUSTERED INDEX IX_BankTransactionDate
ON dbo.BANK_TRANSACTION (TRANSACTION_DATE);

-- Create a non-clustered index on the CREDIT_CARD_ID column for CREDIT_CARD_TRANSACTION table
CREATE NONCLUSTERED INDEX IX_CreditCardID
ON dbo.CREDIT_CARD_TRANSACTION (CREDIT_CARD_ID);

-- Create a non-clustered index on the TRANSACTION_DATE column for CREDIT_CARD_TRANSACTION table
CREATE NONCLUSTERED INDEX IX_CreditCardTransactionDate
ON dbo.CREDIT_CARD_TRANSACTION (TRANSACTION_DATE);

