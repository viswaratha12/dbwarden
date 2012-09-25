/****** Object:  StoredProcedure [dbo].[UpdateUserPermissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.UpdateUserPermissions
/****************************************************
**
**	Desc: Updates user permissions in the current DB
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	07/31/2012 mem - Initial Version
**			08/22/2012 mem - Now updating T_Log_Entries
**    
*****************************************************/
AS
	Set NoCount On
	

	if exists (select * from sys.schemas where name = 'DMSReader')
		drop schema DMSReader
	if exists (select * from sys.sysusers where name = 'DMSReader')
		drop user DMSReader
	create user DMSReader for login DMSReader
	exec sp_addrolemember 'db_datareader', 'DMSReader'
		
		
	if exists (select * from sys.schemas where name = 'DMSWebUser')
		drop schema DMSWebUser
	if exists (select * from sys.sysusers where name = 'DMSWebUser')
		drop user DMSWebUser
	create user DMSWebUser for login DMSWebUser
	exec sp_addrolemember 'db_datareader', 'DMSWebUser'
	exec sp_addrolemember 'DMS_SP_User', 'DMSWebUser'

	GRANT UPDATE ON [dbo].[T_Log_Entries] ([Entered_By]) TO [DMS_SP_User] AS [dbo]

	grant showplan to DMSReader
	grant showplan to DMSWebUser

	Return 0


GO