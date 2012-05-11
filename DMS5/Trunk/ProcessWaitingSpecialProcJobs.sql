/****** Object:  StoredProcedure [dbo].[ProcessWaitingSpecialProcJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE ProcessWaitingSpecialProcJobs
/****************************************************
** 
**	Desc:	Examines jobs in T_Analysis_Job that are in state 19="Special Proc. Waiting"
**			For each, checks whether the Special Processing text now matches an existing job
**			If a match is found, changes the job state to 1="New"
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	05/04/2012 mem - Initial version
**    
*****************************************************/
(
	@WaitThresholdHours int = 72,				-- Hours between when a job is created and when we'll start posting messages to the error log that the job is waiting too long
	@ErrorMessagePostingIntervalHours int = 24,	-- Hours between posting a message to the error log that a job has been waiting more than @WaitThresholdHours; used to prevent duplicate messages from being posted every few minutes
	@InfoOnly tinyint = 0,						-- 1 to preview the jobs that would be set to state "New"; will also display any jobs waiting more than @WaitThresholdHours
	@PreviewSql tinyint = 0,
	@JobsToProcess int = 0,
	@message varchar(512) = '' output,			-- Status message
	@JobsUpdated int = 0 output					-- Number of jobs whose state was set to 1
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @continue tinyint
	Declare @JobsProcessed int = 0
	
	Declare @Job int
	Declare @Dataset varchar(256)
	Declare @SpecialProcessingText varchar(1024)
	Declare @LastAffected datetime
	Declare @ReadyToProcess tinyint
	
	Declare @JobMessage varchar(512)
	
	Declare @HoursSinceStateLastChanged real
	Declare @HoursSinceLastLogEntry real
	
	Declare @SourceJob int
	Declare @AutoQueryUsed tinyint
	Declare @SourceJobState int
	Declare @SourceJobResultsFolder varchar(255)
	Declare @WarningMessage varchar(512)
	
	Declare @TagAvailable tinyint
	Declare @TagEntryID int
	Declare @TagName varchar(12)
	Declare @SourceJobCurrent int
							
	-- The following table variable tracks the tag names that we look for
	Declare @TagNamesTable table (
		Entry_ID int Identity(1,1),
		TagName varchar(12)
	)

	INSERT INTO @TagNamesTable(TagName) Values ('SourceJob')
	INSERT INTO @TagNamesTable(TagName) Values ('Job2')
	INSERT INTO @TagNamesTable(TagName) Values ('Job3')
	INSERT INTO @TagNamesTable(TagName) Values ('Job4')
	
	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------

	Set @WaitThresholdHours = IsNull(@WaitThresholdHours, 72)
	Set @ErrorMessagePostingIntervalHours = IsNull(@ErrorMessagePostingIntervalHours, 24)
	Set @PreviewSql = IsNull(@PreviewSql, 0)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @JobsToProcess = IsNull(@JobsToProcess, 0)
	
	Set @message = ''
	Set @JobsUpdated = 0
	
	If @ErrorMessagePostingIntervalHours < 1
		Set @ErrorMessagePostingIntervalHours = 1
	
	------------------------------------------------
	-- Create a table to track the jobs to update
	------------------------------------------------
	--
	CREATE TABLE #Tmp_JobsWaiting
	(
		Job int not null,
		Last_Affected datetime null,
		ReadyToProcess tinyint null,
		Message varchar(512) null,
	)

	BEGIN TRY

		Set @continue = 1
		Set @Job = -1
		
		While @continue = 1 And (@JobsToProcess <= 0 Or @JobsProcessed < @JobsToProcess)
		Begin -- <a>
		
			SELECT TOP 1 @Job = J.AJ_jobID,
			             @Dataset = DS.Dataset_Num,
			             @SpecialProcessingText = J.AJ_specialProcessing,
			             @LastAffected = J.AJ_Last_Affected
			FROM T_Analysis_Job J
			     INNER JOIN T_Dataset DS
			       ON J.AJ_datasetID = DS.Dataset_ID
			WHERE (J.AJ_StateID = 19) AND
			      (J.AJ_jobID > @Job)
			ORDER BY J.AJ_jobID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
				Set @continue = 0
			Else
			Begin -- <b>
			
				Set @JobsProcessed = @JobsProcessed + 1					
				Set @JobMessage = ''
				Set @ReadyToProcess = 0
						
				Set @SourceJob = 0
				Set @SourceJobResultsFolder = ''
				Set @WarningMessage = ''
			
				-- Process @SpecialProcessingText to look for the tags in @TagNamesTable
				Set @TagAvailable = 1
				Set @TagEntryID = -1
				
				While @TagAvailable = 1
				Begin -- <c1>
					SELECT TOP 1 @TagEntryID = Entry_ID,
					             @TagName = TagName
					FROM @TagNamesTable
					WHERE Entry_ID > @TagEntryID
					ORDER BY Entry_ID
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount

					If @myRowCount = 0
						Set @TagAvailable = 0
					Else
					Begin -- <d>
						If CharIndex(@TagName + ':', @SpecialProcessingText) > 0
						Begin -- <e>
							
							Set @TagName = @TagName
							Set @SourceJobCurrent = 0
							Set @WarningMessage = ''
							Set @ReadyToProcess = 0
							
							Exec @myError = DMS_Pipeline.dbo.LookupSourceJobFromSpecialProcessingText 
										@Job,
										@Dataset, 
										@SpecialProcessingText, 
										@TagName,
										@SourceJob = @SourceJobCurrent output, 
										@AutoQueryUsed = @AutoQueryUsed output,
										@WarningMessage = @WarningMessage output, 
										@PreviewSql = @PreviewSql
							
							Set @WarningMessage = IsNull(@WarningMessage, '')
							
							If @WarningMessage = '' And IsNull(@SourceJobCurrent, 0) > 0
								Set @ReadyToProcess = 1
							Else
								Set @JobMessage = @WarningMessage

										
							If @ReadyToProcess = 1
							Begin -- <f>
							
								If @TagName = 'SourceJob'
									Set @SourceJob = @SourceJobCurrent
									
								Set @SourceJobState = 0
								
								SELECT @SourceJobState = AJ_StateID
								FROM T_Analysis_Job
								WHERE AJ_JobID = @SourceJob
								--
								SELECT @myError = @@error, @myRowCount = @@rowcount

								If @myRowCount = 0
								Begin					
									Set @ReadyToProcess = 0
									Set @JobMessage = 'Source job ' + Convert(varchar(12), @SourceJob) + ' not found in T_Analysis_Job'
								End
								Else
								Begin
									If @SourceJobState IN (4, 14)
										Set @JobMessage = 'Ready'
									Else
									Begin					
										Set @ReadyToProcess = 0
										Set @JobMessage = 'Source job ' + Convert(varchar(12), @SourceJob) + ' exists but has state = ' + Convert(varchar(12), @SourceJobState)
									End
								End
							End -- </f>
							
							If @ReadyToProcess = 0
								Set @TagAvailable= 0

						End -- </e>
					End -- </d>
				End -- </c1>
				
				If @ReadyToProcess = 0
				Begin -- <c2>
					Set @HoursSinceStateLastChanged = DateDiff(minute, @LastAffected, GetDate()) / 60.0
					
					If @HoursSinceStateLastChanged > @WaitThresholdHours And @PreviewSql = 0
					Begin -- <d>
						Declare @message2 varchar(512)
						Set @message2 = 'Waiting for ' + Convert(varchar(12), @HoursSinceStateLastChanged) + ' hours'

						If @JobMessage = ''
							Set @JobMessage = @message2
						Else
							Set @JobMessage = @JobMessage + '; ' + @message2
													 
						If @InfoOnly = 0
						Begin				
							-- Log an error message
							Set @message = 'Job ' + Convert(varchar(12), @Job) + ' has been in state "Special Proc. Waiting" for over ' + Convert(varchar(12), @WaitThresholdHours) + ' hours'
							exec PostLogEntry 'Error', @message, 'ProcessWaitingSpecialProcJobs', @duplicateEntryHoldoffHours = @ErrorMessagePostingIntervalHours
						End
														
					End -- </d>
					
				End -- </c2>
				
				INSERT INTO #Tmp_JobsWaiting (Job, Last_Affected, ReadyToProcess, Message)
				Values (@Job, @LastAffected, @ReadyToProcess, @JobMessage)
			
			End -- </a>
			
		End -- </a>
		
		
		If @infoOnly <> 0 Or @PreviewSql <> 0
		Begin
			------------------------------------------------
			-- Preview the jobs
			------------------------------------------------
			
			SELECT *
			FROM #Tmp_JobsWaiting
			ORDER BY Job
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

		End
		Else
		Begin
			------------------------------------------------
			-- Update the jobs
			------------------------------------------------
			
			UPDATE T_Analysis_Job
			SET AJ_StateID = 1
			FROM T_Analysis_Job AJ INNER JOIN #Tmp_JobsWaiting ON #Tmp_JobsWaiting.Job = AJ.AJ_JobID
			WHERE #Tmp_JobsWaiting.ReadyToProcess = 1
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
				
			Set @JobsUpdated = @myRowCount
					
		End
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH

	return @myError

GO
