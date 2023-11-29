--Constraint to check the validity of password last updated column in USER_DETAILS table
alter table user_details 
add constraint valid_PASSWORD_LAST_UPDATED check(PASSWORD_LAST_UPDATED <= GETDATE());
--Constraint to check the validity of last login date column in USER_DETAILS table
alter table user_details 
add constraint valid_LAST_LOGIN_DATE check(LAST_LOGIN_DATE <= GETDATE());
--Constraint to check the validity of  FAILED_LOGIN_ATTEMPTS column 
alter table user_details 
add constraint VALID_FAILED_LOGIN_ATTEMPTS check(FAILED_LOGIN_ATTEMPTS >= 0);
--Constraint to check the validity of  email in the Profile table	
ALTER TABLE profile 
ADD CONSTRAINT valid_email CHECK(LTRIM(RTRIM(EMAIL)) LIKE '%_@__%.__%');
--Constraint to check the validity of DOB in profile Table 
ALTER TABLE PROFILE
ADD CONSTRAINT VALID_dob CHECK(DOB < GETDATE());
--Constraint to check the validity of mobile number in profile table
ALTER TABLE profile 
ADD CONSTRAINT VALID_MOBILE_NUMBER CHECK(MOBILE_NUMBER NOT LIKE '%[^0-9]%');
