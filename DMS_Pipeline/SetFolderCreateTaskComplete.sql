/****** Object:  StoredProcedure [dbo].[SetFolderCreateTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetFolderCreateTaskComplete
/****************************************************
**
**	Desc: 
**    Make entry in step completion table
**    (SetAnalysisJobComplete)
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			03/17/2011 mem - Initial version
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
    @taskID int,
    @completionCode int,					-- 0 means success; non-zero means failure
    @message varchar(512)='' output			-- Output message
)
As
	set nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0
	
	set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'SetFolderCreateTaskComplete', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End
	
	---------------------------------------------------
	-- get current state of this task
	---------------------------------------------------
	--
	declare @processor varchar(64)
	set @processor = ''
	--
	declare @state tinyint
	set @state = 0
	--
	SELECT	
		@state = State,
		@processor = Processor
	FROM T_Data_Folder_Create_Queue
	WHERE (Entry_ID = @taskID)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting task from T_Data_Folder_Create_Queue'
		goto Done
	end
	--
	if @state <> 2
	begin
		set @myError = 67
		set @message = 'Task ' + convert(varchar(12), @taskID) 
		
		if @myRowCount = 0
			set @message = @message + ' was not found in T_Data_Folder_Create_Queue'
		else
			set @message = @message + ' is not in correct state to be completed; expecting State=2 but actually ' + convert(varchar(12), @state)
		goto Done
	end

	---------------------------------------------------
	-- Determine completion state
	---------------------------------------------------
	--
	declare @stepState int

	if @completionCode = 0
		set @stepState = 3
	else
		set @stepState = 4

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'SetStepTaskComplete'
		
	-- Start transaction
	begin transaction @transName

	---------------------------------------------------
	-- Update job step
	---------------------------------------------------
	--
	UPDATE T_Data_Folder_Create_Queue
	SET    State = @stepState,
		   Finish = GetDate(),
		   Completion_Code = @completionCode
	WHERE  (Entry_ID = @taskID)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating T_Data_Folder_Create_Queue'
		goto Done
	end

	-- update was successful
	commit transaction @transName
		
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetFolderCreateTaskComplete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetFolderCreateTaskComplete] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetFolderCreateTaskComplete] TO [svc-dms] AS [dbo]
GO
