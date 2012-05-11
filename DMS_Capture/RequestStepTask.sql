/****** Object:  StoredProcedure [dbo].[RequestStepTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestStepTask
/****************************************************
**
** Desc: 
**	Looks for capture job step that is appropriate for the given Processor Name.
**	If found, step is assigned to caller
**
**	Task assignment will be based on:
**	Assignment restrictions:
**     Job not in hold state:
**     Processor on storage machine (for step tools that require it):
**     Bionet access (for step tools that reqire it):
**     Maximum simultaneous captures for instrument (for step tools that reqire it):
**	Job-Tool priority
**	Job priority
**	Job number
**	Step Number
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	09/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/11/2010 grk - Job must be in new or busy states
**			01/20/2010 grk - Added logic for instrument/processor assignment
**			02/01/2010 grk - Added instrumentation for more logging of reject requests
**			03/12/2010 grk - Fixed problem with inadvertent throttling of step tools that aren't subject to it
**			03/21/2011 mem - Switched T_Jobs.State test from State IN (1,2) to State < 100
**			04/12/2011 mem - Now making an entry in T_Job_Step_Processing_Log for each job step assigned
**			05/18/2011 mem - No longer making an entry in T_Job_Request_Log for every request
**						   - Now showing the top @JobCountToPreview candidate steps when @infoOnly is > 0
**
*****************************************************/
  (
    @processorName VARCHAR(128),
    @jobNumber INT = 0 OUTPUT,			-- Job number assigned; 0 if no job available
    @message VARCHAR(512) OUTPUT,
    @infoOnly TINYINT = 0,				-- Set to 1 to preview the job that would be returned; Set to 2 to print debug statements with preview
    @ManagerVersion VARCHAR(128) = '',
    @JobCountToPreview INT = 10
  )
AS 
  SET nocount ON

  DECLARE @myError INT
  DECLARE @myRowCount INT
  SET @myError = 0
  SET @myRowCount = 0
	
  DECLARE @jobAssigned TINYINT
  SET @jobAssigned = 0

  DECLARE @CandidateJobStepsToRetrieve INT
  SET @CandidateJobStepsToRetrieve = 25


	---------------------------------------------------
	-- Validate the inputs; clear the outputs
	---------------------------------------------------

	SET @processorName = ISNULL(@processorName, '')
	SET @jobNumber = 0
	SET @message = ''
	SET @infoOnly = ISNULL(@infoOnly, 0)
	SET @ManagerVersion = ISNULL(@ManagerVersion, '')
	SET @JobCountToPreview = ISNULL(@JobCountToPreview, 10)


	IF @JobCountToPreview > @CandidateJobStepsToRetrieve 
		SET @CandidateJobStepsToRetrieve = @JobCountToPreview

	---------------------------------------------------
	-- Show processor name if @infoOnly is non-zero
	---------------------------------------------------
	--
	IF @infoOnly <> 0
		SELECT @processorName AS Processor, @infoOnly AS infoOnlyLevel
			
	---------------------------------------------------
	-- The capture task manager expects a non-zero 
	-- return value if no jobs are available
	-- Code 53000 is used for this
	---------------------------------------------------
	--
	DECLARE @jobNotAvailableErrorCode INT
	SET @jobNotAvailableErrorCode = 53000

	If @infoOnly > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTask: Starting; make sure this is a valid processor'

	---------------------------------------------------
	-- Make sure this is a valid processor 
	-- (and capitalize it according to T_Local_Processors)
	---------------------------------------------------
	--
	DECLARE @machine VARCHAR(64)
	--
	SELECT @machine = Machine,
	       @processorName = Processor_Name
	FROM T_Local_Processors
	WHERE Processor_Name = @processorName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	IF @myError <> 0 
    BEGIN
		SET @message = 'Error looking for processor in T_Local_Processors'
		GOTO Done
    END

	-- check if no processor found?
	IF @myRowCount = 0 
    BEGIN
		SET @message = 'Processor not defined in T_Local_Processors: ' + @processorName
		SET @myError = @jobNotAvailableErrorCode
		GOTO Done
    END
	
	---------------------------------------------------
	-- Update processor's request timestamp
	-- (to show when the processor was most recently active)
	---------------------------------------------------
	--
	IF @infoOnly = 0 
    BEGIN
		UPDATE T_Local_Processors
		SET Latest_Request = GETDATE(),
		    Manager_Version = @ManagerVersion
		WHERE Processor_Name = @processorName
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @myError <> 0 
		BEGIN
			SET @message = 'Error updating latest processor request time'
			GOTO Done
		END
    END
	
	---------------------------------------------------
	-- get list of step tools currently assigned to processor
	-- active tools that are presently handled by this processor
	-- (don't use tools that require bionet if processor machine doesn't have it)
	---------------------------------------------------
	--
  CREATE TABLE #AvailableProcessorTools
    (
      Tool_Name VARCHAR(64),
      Tool_Priority TINYINT,
      Only_On_Storage_Server CHAR(1),
      Instrument_Capacity_Limited CHAR(1),
      Bionet_OK CHAR(1),
      Processor_Assignment_Applies CHAR(1)
    )
	--
  INSERT  INTO #AvailableProcessorTools
          ( Tool_Name,
            Tool_Priority,
            Only_On_Storage_Server,
            Instrument_Capacity_Limited,
            Bionet_OK,
            Processor_Assignment_Applies
          )
          SELECT
            T_Processor_Tool.Tool_Name,
            T_Processor_Tool.Priority,
            T_Step_Tools.Only_On_Storage_Server,
            T_Step_Tools.Instrument_Capacity_Limited,
            CASE WHEN ( Bionet_Required = 'Y' )
                      AND ( Bionet_Available <> 'Y' ) THEN 'N'
                 ELSE 'Y'
            END AS Bionet_OK,
            T_Step_Tools.Processor_Assignment_Applies
          FROM
            T_Local_Processors
            INNER JOIN T_Processor_Tool ON T_Local_Processors.Processor_Name = T_Processor_Tool.Processor_Name
            INNER JOIN T_Step_Tools ON T_Processor_Tool.Tool_Name = T_Step_Tools.Name
            INNER JOIN T_Machines ON T_Local_Processors.Machine = T_Machines.Machine
          WHERE
            ( T_Processor_Tool.Enabled > 0 )
            AND ( T_Local_Processors.State = 'E' )
            AND ( T_Local_Processors.Processor_Name = @processorName )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
  	--
	IF @myError <> 0 
    BEGIN
		SET @message = 'Error getting processor tools'
		GOTO Done
    END

	---------------------------------------------------
	-- bail out if no tools available, and we are not 
	-- in infoOnly mode
	---------------------------------------------------
	--
    DECLARE @num_tools INT
	SELECT
	  @num_tools = COUNT(*)
	FROM
	  #AvailableProcessorTools
	--
	IF @infoOnly = 0 AND @num_tools = 0 
	BEGIN
	  SET @message = 'No tools presently available for processor "'+ @processorName +'"'
	  SET @myError = @jobNotAvailableErrorCode
	  GOTO Done
	END

	---------------------------------------------------
	-- Get list of instrument and their current loading
	-- (steps in busy state that have step tools that are 
	-- instrument capacity limited tools - summed by Instrument
	---------------------------------------------------
	--
  CREATE TABLE #InstrumentLoading
    (
      Instrument VARCHAR(64),
      Captures_In_Progress INT,
      Max_Simultaneous_Captures INT,
      Available_Capacity INT
    )
	--
  INSERT  INTO #InstrumentLoading
          ( Instrument,
            Captures_In_Progress,
            Max_Simultaneous_Captures,
            Available_Capacity
          )
          SELECT
            T_Jobs.Instrument,
            COUNT(*) AS Captures_In_Progress,
            T_Jobs.Max_Simultaneous_Captures,
            Available_Capacity = T_Jobs.Max_Simultaneous_Captures - COUNT(*)
          FROM
            T_Job_Steps
            INNER JOIN T_Step_Tools ON T_Job_Steps.Step_Tool = T_Step_Tools.Name
            INNER JOIN T_Jobs ON T_Job_Steps.Job = T_Jobs.Job
          WHERE
         ( T_Job_Steps.State = 4 )
            AND ( T_Step_Tools.Instrument_Capacity_Limited = 'Y' )
          GROUP BY
            T_Jobs.Instrument,
            T_Jobs.Max_Simultaneous_Captures
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	IF @myError <> 0 
    BEGIN
      SET @message = 'Error populating #InstrumentLoading temp table'
      GOTO Done
    END

	---------------------------------------------------
	-- Is processor assigned to any instrument?
	---------------------------------------------------
	--
	DECLARE @processorIsAssigned INT
	SET @processorIsAssigned = 0
	--
	SELECT
		@processorIsAssigned = COUNT(*)
	FROM
		T_Processor_Instrument
	WHERE
		Processor_Name = @processorName

	---------------------------------------------------
	-- Get list of instruments that have processor assignments
	---------------------------------------------------
	--
	CREATE TABLE #InstrumentProcessor
	(
		Instrument VARCHAR(64),
		Assigned_To_This_Processor INT,
		Assigned_To_Any_Processor INT
	)
	INSERT  INTO #InstrumentProcessor (
		Instrument,
		Assigned_To_This_Processor,
		Assigned_To_Any_Processor
	)
	SELECT
	  Instrument_Name AS Instrument,
	  SUM(CASE WHEN Processor_Name = @processorName THEN 1 ELSE 0 END) AS Assigned_To_This_Processor,
	  SUM(1) AS Assigned_To_Any_Processor
	FROM
	  T_Processor_Instrument
	WHERE
	  Enabled = 1
	GROUP BY
	  Instrument_Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	IF @myError <> 0 
    BEGIN
      SET @message = 'Error populating #InstrumentProcessor temp table'
      GOTO Done
    END

	---------------------------------------------------
	-- table variable to hold job step candidates
	-- for possible assignment
	---------------------------------------------------
	--
  CREATE TABLE #Tmp_CandidateJobSteps
    (
      Seq SMALLINT IDENTITY(1, 1)
                   NOT NULL,
      Job INT,
      Step_Number INT,
      Job_Priority INT,
      Step_Tool VARCHAR(64),
      Tool_Priority INT
    )

	---------------------------------------------------
	-- get list of viable job step assignments organized
	-- by processor in order of assignment priority
	---------------------------------------------------
	--
	INSERT  INTO #Tmp_CandidateJobSteps
          ( Job,
            Step_Number,
            Job_Priority,
            Step_Tool,
            Tool_Priority
          )
          SELECT TOP ( @CandidateJobStepsToRetrieve )
            T_Jobs.Job,
            Step_Number,
            T_Jobs.Priority,
            Step_Tool,
            Tool_Priority
          FROM
            T_Job_Steps
            INNER JOIN dbo.T_Jobs ON T_Job_Steps.Job = T_Jobs.Job
            INNER JOIN #AvailableProcessorTools ON Step_Tool = Tool_Name
            LEFT OUTER JOIN #InstrumentProcessor ON #InstrumentProcessor.Instrument = T_Jobs.Instrument
            LEFT OUTER JOIN #InstrumentLoading ON #InstrumentLoading.Instrument = T_Jobs.Instrument
          WHERE
			GETDATE() > dbo.T_Job_Steps.Next_Try
            AND ( T_Job_Steps.State = 2 )
            AND Bionet_OK = 'Y'
            AND T_Jobs.State < 100
            AND NOT ( Only_On_Storage_Server = 'Y' AND Storage_Server <> @machine )
            AND ( #AvailableProcessorTools.Instrument_Capacity_Limited = 'N' OR (NOT ISNULL(Available_Capacity, 1) < 1) )
            AND (
				(Processor_Assignment_Applies = 'N')
				OR
				( 
					( @processorIsAssigned > 0 AND isnull(Assigned_To_This_Processor, 0) > 0 ) 
					OR 
					( @processorIsAssigned = 0 AND isnull(Assigned_To_Any_Processor, 0) = 0 ) 
				)
			)
          ORDER BY
            Tool_Priority,
            T_Jobs.Priority,
            T_Jobs.Job,
            Step_Number
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
    --
 DECLARE @num_candidates INT
    SET @num_candidates = @myRowCount

	---------------------------------------------------
	-- bail out if no steps available, and we are not 
	-- in infoOnly mode
	---------------------------------------------------
	--
  IF @infoOnly = 0 AND @num_candidates = 0 
    BEGIN
      SET @message = 'No candidates presently available'
      SET @myError = @jobNotAvailableErrorCode
      GOTO Done
    END

	---------------------------------------------------
	-- Try to assign step
	---------------------------------------------------

	If @infoOnly > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTask: Start transaction'

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
  DECLARE @transName VARCHAR(32)
  SET @transName = 'RequestStepTask'
		
	-- Start transaction
  BEGIN TRANSACTION @transName
	
	---------------------------------------------------
	-- get best step candidate in order of preference:
	--   Assignment priority (prefer directly associated jobs to general pool)
	--   Job-Tool priority
	--   Overall job priority
	--   Later steps over earler steps
	--   Job number
	---------------------------------------------------
	--
  DECLARE @stepNumber INT
  SET @stepNumber = 0
  DECLARE @stepTool VARCHAR(64)
	--
  SELECT TOP 1
    @jobNumber = TJS.Job,
    @stepNumber = TJS.Step_Number,
  	@stepTool =   TJS.Step_Tool
  FROM
    T_Job_Steps TJS WITH ( HOLDLOCK )
    INNER JOIN #Tmp_CandidateJobSteps CJS ON CJS.Job = TJS.Job
                                             AND CJS.Step_Number = TJS.Step_Number
  WHERE
    TJS.State = 2
  ORDER BY
    Seq
  	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
  IF @myError <> 0 
    BEGIN
      ROLLBACK TRANSACTION @transName
      SET @message = 'Error searching for job step'
      GOTO Done
    END

  IF @myRowCount > 0 
    SET @jobAssigned = 1

	---------------------------------------------------
	-- If a job step was assigned and 
	-- if we are not in infoOnly mode 
	-- then update the step state to Running
	---------------------------------------------------
	--
  IF @jobAssigned = 1
    AND @infoOnly = 0 
    BEGIN --<e>
      UPDATE
        T_Job_Steps
      SET
        State = 4,
        Processor = @processorName,
        Machine = @machine,
        Start = GETDATE(),
        Finish = NULL
      WHERE
        Job = @jobNumber
        AND Step_Number = @stepNumber
  		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
      IF @myError <> 0 
        BEGIN
          ROLLBACK TRANSACTION @transName
          SET @message = 'Error updating job step'
          GOTO Done
        END
    END --<e>
       
	-- update was successful
  COMMIT TRANSACTION @transName

	---------------------------------------------------
	-- temp table to hold job parameters
	--
  CREATE TABLE #ParamTab
    (
      [Section] VARCHAR(128),
      [Name] VARCHAR(128),
      [Value] VARCHAR(MAX)
    )

  IF @jobAssigned = 1 
    BEGIN
    
		if @infoOnly = 0
		begin
			---------------------------------------------------
			-- Add entry to T_Job_Step_Processing_Log
			---------------------------------------------------
			
			INSERT INTO T_Job_Step_Processing_Log (Job, Step, Processor)
			VALUES (@jobNumber, @stepNumber, @processorName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end

		If @infoOnly > 1
			Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTask: Call GetJobStepParams'
			
		---------------------------------------------------
		-- Job was assigned; get step parameters
		---------------------------------------------------

		-- get job step parametes into temp table
		EXEC @myError = GetJobStepParams @jobNumber, @stepNumber,
		@message OUTPUT, @DebugMode = @infoOnly

		-- get metadata for dataset if request is going to dataset info tool
		IF @stepTool = 'DatasetInfo'
		BEGIN
			DECLARE @dataset VARCHAR(128)
			SELECT @dataset = Dataset FROM T_Jobs WHERE Job = @jobNumber
			EXEC GetMetadataForDataset @dataset
		END

		IF @infoOnly <> 0 AND LEN(@message) = 0 
		SET @message = 'Job ' + CONVERT(VARCHAR(12), @jobNumber) + ', Step '+ CONVERT(VARCHAR(12), @stepNumber) + ' would be assigned to ' + @processorName
	END
  ELSE 
    BEGIN
		---------------------------------------------------
		-- No job step found; update @myError and @message
		---------------------------------------------------
		--
      SET @myError = @jobNotAvailableErrorCode
      SET @message = 'No available jobs'
		
    END


	---------------------------------------------------
	-- dump candidate list if in infoOnly mode
	---------------------------------------------------
	--
	If @infoOnly <> 0
	Begin
		If @infoOnly > 1
			Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Preview results'

		-- Preview the next @JobCountToPreview available jobs

		SELECT TOP ( @JobCountToPreview ) 
		       Seq,
		       Tool_Priority,
		       Job_Priority,
		       CJS.Job,
		       Step_Number,
		       Step_Tool,
		       J.Dataset,
		       @processorName AS Processor
		FROM #Tmp_CandidateJobSteps CJS
		     INNER JOIN T_Jobs J
		       ON CJS.Job = J.Job

		---------------------------------------------------
		-- dump candidate list if infoOnly mode is 2 or higher
		---------------------------------------------------
		--
		IF @infoOnly >= 2
		BEGIN
			EXEC RequestStepTaskExplanation @processorName, @processorIsAssigned, @infoOnly, @machine
		END
		
	End


	---------------------------------------------------
	-- output job parameters as resultset 
	---------------------------------------------------
	--
	SELECT Name AS Parameter,
	       Value
	FROM #ParamTab

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
  Done:
  
	/*
	** Uncomment the following to log all job requests
		
		INSERT INTO T_Job_Request_Log (
			Processor,
			ReturnCode,
			Message,
			Num_Tools,
			Num_Candidates,
			Job,
			Step
		) VALUES (
			@processorName,
			@myError,
			@message,
			@num_tools,
			@num_candidates,
			@jobNumber,
			@stepNumber
		)
		
	*
	*/

  RETURN @myError

GO
GRANT EXECUTE ON [dbo].[RequestStepTask] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestStepTask] TO [svc-dms] AS [dbo]
GO