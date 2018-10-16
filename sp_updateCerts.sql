/***********************************************************************************************************
this stored procedure will update energove cert table and update a history table
tables used: LNI_AUDIT, LNI_Staging, and COLICENSECERTIFICATION.

************************************************************************************************************/

CREATE PROCEDURE USP_updateCerts
AS
BEGIN

SET NOCOUNT ON
DECLARE @COSIMPLELICCERTID char(36),
	    @GLOBALENTITYID char(36),
		@LNILICENSE varchar(255),
		@LicenseExpirationDate datetime,
		@Status varchar(255)


DECLARE CertsToUpdate CURSOR READ_ONLY
FOR  --reduce this set to only records where the expiration data is greater on lni staging side of things.
SELECT EGCERT.COSIMPLELICCERTID, EGCERT.GLOBALENTITYID, LNI.ContractorLicenseNumber as LNILICENSE, LNI.LicenseExpirationDate,
 (LNI.ContractorLicenseStatus + '      '+ LNI.ContractorLicenseSuspendDate) as Status
FROM COLICENSECERTIFICATION EGCERT inner join LNI_Staging LNI on EGCERT.LICENSENUMBER = LNI.ContractorLicenseNumber 
WHERE EGCERT.EXPIREDATE <> LNI.LicenseExpirationDate and EGCERT.EXPIREDATE <=getdate()+90


OPEN CertsToUpdate
FETCH NEXT FROM CertsToUpdate INTO @COSIMPLELICCERTID, @GLOBALENTITYID, @LNILICENSE, @LicenseExpirationDate, @Status

WHILE @@FETCH_STATUS = 0
BEGIN
			
			INSERT INTO LNI_AUDIT ([COSIMPLELICCERTID],[LICENSENUMBER],[COMMENTS],[EXPIREDATE],
			[GLOBALENTITYID],[INSERTDATE],[LNI_LICENSE],[LNI_COMMENTS],[LNI_EXPIREDATE]) select [COSIMPLELICCERTID],[LICENSENUMBER],[COMMENTS],[EXPIREDATE],
			[GLOBALENTITYID],getdate(),@LNILICENSE,@Status, @LicenseExpirationDate from COLICENSECERTIFICATION where COSIMPLELICCERTID = @COSIMPLELICCERTID 
			and GLOBALENTITYID = @GLOBALENTITYID and LICENSENUMBER = @LNILICENSE


			UPDATE 	COLICENSECERTIFICATION
			SET EXPIREDATE = @LicenseExpirationDate, COMMENTS = @Status 
			WHERE COSIMPLELICCERTID = @COSIMPLELICCERTID and GLOBALENTITYID = @GLOBALENTITYID and LICENSENUMBER = @LNILICENSE

			FETCH NEXT FROM CertsToUpdate INTO @COSIMPLELICCERTID, @GLOBALENTITYID, @LNILICENSE, @LicenseExpirationDate, @Status
END

CLOSE CertsToUpdate
DEALLOCATE CertsToUpdate

END

/******************************************************************************************************
*******************************************************************************************************/







/*******************************************Create Audit Table************************************************************
This audit table stores every record that was updated. It old values and new values for each run. The table can be used to 
troubleshoot values.
************************************************************************************************************************/



CREATE TABLE [dbo].[LNI_AUDIT](
	[COSIMPLELICCERTID] [char](36) NOT NULL,
	[LICENSENUMBER] [nvarchar](255) NOT NULL,
	[COMMENTS] [nvarchar](max) NULL,
	[EXPIREDATE] [datetime] NULL,
	[GLOBALENTITYID] [char](36) NULL,
	[INSERTDATE] [datetime] NOT NULL,
	[LNI_LICENSE] [nvarchar](255) NOT NULL,
	[LNI_COMMENTS] [nvarchar](max) NOT NULL,
	[LNI_EXPIREDATE] [datetime] NOT NULL


) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO






/*****************************************Create Staging Table***********************************************************

This table is used to temporaryly store data from the State LNI and is used to update energov license table.

*************************************************************************************************************************/




USE [EnerGov_Prod]
GO


CREATE TABLE [dbo].[LNI_STAGING](
	[BusinessName] [varchar](250) NULL,
	[ContractorLicenseNumber] [varchar](250) NULL,
	[ContractorLicenseTypeCode] [varchar](250) NULL,
	[ContractorLicenseTypeCodeDesc] [varchar](250) NULL,
	[Address1] [varchar](250) NULL,
	[Address2] [varchar](250) NULL,
	[City] [varchar](250) NULL,
	[State] [varchar](250) NULL,
	[Zip] [varchar](250) NULL,
	[PhoneNumber] [varchar](250) NULL,
	[LicenseEffectiveDate] [varchar](250) NULL,
	[LicenseExpirationDate] [varchar](250) NULL,
	[BusinessTypeCode] [varchar](250) NULL,
	[BusinessTypeCodeDesc] [varchar](250) NULL,
	[SpecialtyCode1] [varchar](250) NULL,
	[SpecialtyCode1Desc] [varchar](250) NULL,
	[SpecialtyCode2] [varchar](250) NULL,
	[SpecialtyCode2Desc] [varchar](250) NULL,
	[UBI] [varchar](250) NULL,
	[PrimaryPrincipalName] [varchar](250) NULL,
	[StatusCode] [varchar](250) NULL,
	[ContractorLicenseStatus] [varchar](250) NULL,
	[ContractorLicenseSuspendDate] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO



/*******************************troubleshooting scripts************************************************************************


*******************************************************************************************************************************/



select * from LNI_AUDIT where insertdate >= '2018-10-12 00:00:00.000'

select * from LNI_STAGING

select cast(INSERTDATE as date) as RunDate, case when Datepart(HOUR,CONVERT(varchar(50),INSERTDATE,108)) > 12 then '2' else '1' end as Run,  count(*) as Processed  from LNI_AUDIT
group by cast(INSERTDATE as date), Datepart(HOUR,CONVERT(varchar(50),INSERTDATE,108))
order by RunDate












