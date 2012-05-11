/****** Object:  StoredProcedure [dbo].[AddUpdateLocalJobInBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateLocalJobInBroker
/****************************************************
**
**  Desc: 
**  Create or edit analysis job directly in broker database 
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth: grk
**  11/16/2010 grk - Initial release
**	03/15/2011 dac - Modified to allow updating in HOLD mode
**
*****************************************************/
(
	@job int OUTPUT,
	@scriptName varchar(64),
	@priority int,
	@jobParam varchar(8000),
	@comment varchar(512),
	@resultsFolderName varchar(128) OUTPUT,
	@mode varchar(12) = 'add', -- or 'update' or 'reset'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0
	
	DECLARE @DebugMode TINYINT = 0

	DECLARE @reset CHAR(1) = 'N'
	IF @mode = 'reset'
	BEGIN 
		SET @mode = 'update'
		SET @reset = 'Y'
	END 

	BEGIN TRY

		---------------------------------------------------
		-- does job exist
		---------------------------------------------------
		
		DECLARE 
			@id INT = 0,
			@state int = 0
		--
		SELECT
			@id = Job ,
			@state = State
		FROM dbo.T_Jobs
		WHERE Job = @job
		
		IF @mode = 'update' AND @id = 0
			RAISERROR ('Cannot update nonexistent job', 11, 2)

		IF @mode = 'update' AND NOT @state IN (1, 4, 5, 100) -- new, complete, failed, hold
			RAISERROR ('Cannot update job in state %d', 11, 3, @state)

		---------------------------------------------------
		-- verify parameters
		---------------------------------------------------

		---------------------------------------------------
		-- update mode 
		-- restricted to certain job states and limited to certain fields
		-- force reset of job?
		---------------------------------------------------
		
		IF @mode = 'update'
		BEGIN --<update>
			BEGIN TRANSACTION

			-- update job and params
			--
			UPDATE   dbo.T_Jobs
			SET      Priority = @priority ,
					Comment = @comment ,
					State = CASE WHEN @reset = 'Y' THEN 20 ELSE State END -- 20=resuming (UpdateJobState will handle final job state update)
			WHERE    Job = @job
			
			UPDATE   dbo.T_Job_Parameters
			SET      Parameters = CONVERT(XML, @jobParam)
			WHERE    job = @job
			COMMIT

		END --<update>
		

		---------------------------------------------------
		-- add mode
		---------------------------------------------------

		IF @mode = 'add'
		BEGIN --<add>

			set @message = 'Add mode is not implemented' + CONVERT(VARCHAR(12), @state)
			RAISERROR (@message, 11, 1)

			DECLARE @jobParamXML XML = CONVERT(XML, @jobParam)
/*			
			exec MakeLocalJobInBroker
					@scriptName,
					@priority,
					@jobParamXML,
					@comment,
					@DebugMode,
					@job OUTPUT,
					@resultsFolderName OUTPUT,
					@message OUTPUT
*/	
		END --<add>

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

	END CATCH

	return @myError



GO
GRANT EXECUTE ON [dbo].[AddUpdateLocalJobInBroker] TO [DMS_SP_User] AS [dbo]
GO