/****** Object:  StoredProcedure [dbo].[SetMyEMSLUploadManuallyVerified] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetMyEMSLUploadManuallyVerified
/****************************************************
**
**	Desc: 
**		Use this stored procedure to mark an ArchiveVerify job step or ArchiveStatusCheck as complete
**
**		This is required when the automated processing fails, but you have 
**		manually verified that the files are downloadable from MyEMSL
**
**		In particular, use this procedure if the MyEMSL status page shows an error in step 5 or 6, 
**		yet the files were manually confirmed to have been successfully uploaded
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	10/03/2013 mem - Initial version
**			07/13/2017 mem - Pass both StatusNumList and StatusURIList to SetMyEMSLUploadVerified
**    
*****************************************************/
(
	@Job int,
	@StatusNumList varchar(64) = '',		-- Required only if the step tool is ArchiveStatusCheck
	@infoOnly tinyint = 1,
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @Job = IsNull(@Job, 0)
	Set @StatusNumList = IsNull(@StatusNumList, '')
	Set @infoOnly = IsNull(@infoOnly, 1)
	
	Set @message = ''
	
	If @Job <= 0
	Begin
		Set @message = '@Job must be positive; unable to continue'
		Set @myError = 60000
		Goto Done
	End

	---------------------------------------------------
	-- Make sure the Job exists and has a failed ArchiveVerify step 
	-- or failed ArchiveStatusCheck step
	---------------------------------------------------
	
	Declare @DatasetID int = 0
	Declare @Step int = 0
	Declare @Tool varchar(128)
	Declare @State int = 0
	Declare @outputFolderName varchar(128) = ''
	
	SELECT TOP 1 @DatasetID = J.Dataset_ID,
	       @Step = JS.Step_Number,
	       @Tool = JS.Step_Tool,
	       @State = JS.State,
	       @outputFolderName = JS.Output_Folder_Name
	FROM T_Jobs J
	     INNER JOIN T_Job_Steps JS
	       ON JS.Job = J.Job
	WHERE J.Job = @Job AND
	      JS.Step_Tool IN ('ArchiveVerify', 'ArchiveStatusCheck') AND
	      JS.State <> 5
	ORDER BY JS.Step_Number

	If IsNull(@Step, 0) = 0
	Begin
		Set @message = 'Job ' + Convert(varchar(12), @Job) + ' does not have an ArchiveVerify step or ArchiveStatusCheck step'
		Set @myError = 60001
		Goto Done
	End
	
	If NOT @State IN (2, 6)
	Begin
		Set @message = 'The ' + @Tool + ' step for Job ' + Convert(varchar(12), @Job) + ' is in state ' + Convert(varchar(12), @State) + '; to use this procedure the state must be 2 or 6'
		Set @myError = 60002
		Goto Done
	End	
	
	If @Tool = 'ArchiveStatusCheck' And LTrim(RTrim(@StatusNumList)) = ''
	Begin
		Set @message = '@StatusNumList cannot be empty when the tool is ArchiveStatusCheck'
		Set @myError = 60003
		Goto Done
	End
	
	---------------------------------------------------
	-- Perform the update
	---------------------------------------------------
	
	If @infoOnly = 1
	Begin
		SELECT Job,
		       Step_Number,
		       Step_Tool,
		       State,
		       5 AS NewState,
		       'Manually verified that files were successfully uploaded' AS Evaluation_Message
		FROM T_Job_Steps
		WHERE (Job = @job) AND
		      (Step_Number = @Step)

	End
	Else
	Begin
	
		UPDATE T_Job_Steps
		SET State = 5,
		    Completion_Code = 0,
		    Completion_Message = '',
		    Evaluation_Code = 0,
		    Evaluation_Message = 'Manually verified that files were successfully uploaded'
		WHERE (Job = @job) AND
		      (Step_Number = @Step) AND
		      State IN (2, 6)
		
		Set @myRowCount = @@RowCount
		
		If @myRowCount = 0
		Begin
			Set @message = 'Update failed; the job step was not in the correct state (or was not found)'
			Set @myError = 60004
			Goto Done
		End
	End
	
	If @Tool = 'ArchiveVerify'
	Begin
		Declare @MyEMSLStateNew tinyint = 2
		
		If @infoOnly= 1
			Select 'exec S_UpdateMyEMSLState @datasetID=' + Convert(varchar(12), @datasetID) + ', @outputFolderName=''' + @outputFolderName + ''', @MyEMSLStateNew=' + Convert(varchar(12), @MyEMSLStateNew) AS Command
		Else
			exec S_UpdateMyEMSLState @datasetID, @outputFolderName, @MyEMSLStateNew
	End
	
	If @Tool = 'ArchiveStatusCheck'
	Begin
		Declare @VerifiedStatusNumTable as Table(StatusNum int NOT NULL)
				
		---------------------------------------------------
		-- Find the Status URIs that correspond to the values in @StatusNumList
		---------------------------------------------------
		
		INSERT INTO @VerifiedStatusNumTable (StatusNum)
		SELECT DISTINCT Value
		FROM dbo.udfParseDelimitedIntegerList(@StatusNumList, ',')
		ORDER BY Value
		
		Declare @StatusURIList varchar(4000)
		
		SELECT @StatusURIList = Coalesce(@StatusURIList + ', ' + MU.Status_URI, MU.Status_URI)
		FROM V_MyEMSL_Uploads MU
		     INNER JOIN @VerifiedStatusNumTable SL
		       ON MU.StatusNum = SL.StatusNum
		
		If @infoOnly = 1
			Select 'exec SetMyEMSLUploadVerified @datasetID=' + 
			       Convert(varchar(12), @datasetID) + 
			       ', @StatusNumList=''' + @StatusNumList + '''' + 
			       ', @StatusURIList=''' + @StatusURIList + '''' AS Command
		Else
			exec SetMyEMSLUploadVerified @DatasetID, @StatusNumList, @StatusURIList
		
	End
	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in SetArchiveVerifyManuallyChecked'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		Exec PostLogEntry 'Error', @message, 'SetArchiveVerifyManuallyChecked'
	End	

	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetMyEMSLUploadManuallyVerified] TO [DDL_Viewer] AS [dbo]
GO
