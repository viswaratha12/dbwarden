/****** Object:  StoredProcedure [dbo].[DoFileAttachmentOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DoFileAttachmentOperation] 
/****************************************************
**
**  Desc: 
**    Performs operation given by @mode
**    on entity given by @ID
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 09/05/2012 
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@ID int,
	@mode varchar(12),
	@message varchar(512) output,
	@callingUser varchar(128) = ''
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 

		---------------------------------------------------
		-- 
		---------------------------------------------------
	
		if @mode = 'delete'
		begin
			UPDATE T_File_Attachment 
			SET Active = 0
			WHERE ID = @ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Delete operation failed'
				RAISERROR (@message, 10, 1)
				return 51007
			end
		end

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError
GO
GRANT EXECUTE ON [dbo].[DoFileAttachmentOperation] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoFileAttachmentOperation] TO [DMS2_SP_User] AS [dbo]
GO