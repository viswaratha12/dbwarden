/****** Object:  StoredProcedure [dbo].[UpdateDatasetIntervalForMultipleInstruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDatasetIntervalForMultipleInstruments
/****************************************************
**
**  Desc: 
**    Updates dataset interval and creates entries 
**    for long intervals in the intervals table for 
**    all production instruments 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	02/09/2012 
**			03/07/2012 mem - Added parameters @DaysToProcess, @infoOnly, and @message
**			03/21/2012 grk - Added call to UpdateEMSLInstrumentUsageReport
**			03/22/2012 mem - Added parameter @UpdateEMSLInstrumentUsage
**			03/26/2012 grk - Added call to UpdateEMSLInstrumentUsageReport for previous month
**			03/27/2012 grk - Added code to delete entries from T_EMSL_Instrument_Usage_Report
**			03/27/2012 grk - Using V_Instrument_Tracked
**          04/09/2012 grk - modified algorithm
**    
*****************************************************/
(
    @DaysToProcess int = 30,
    @UpdateEMSLInstrumentUsage tinyint = 1,
    @infoOnly tinyint = 0,
	@message varchar(512) = '' output
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

	Set @DaysToProcess = IsNull(@DaysToProcess, 30)
	Set @message = ''	
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- set up date interval and key values
	---------------------------------------------------
	
	DECLARE @endDate DATETIME =  GETDATE()
	DECLARE @startDate DATETIME = DATEADD(DAY, -@DaysToProcess, @endDate)
	DECLARE @currentYear INT = DATEPART(YEAR, @endDate)
	DECLARE @currentMonth INT = DATEPART(MONTH, @endDate)
	DECLARE @day INT = DATEPART(DAY, @endDate)
	DECLARE @hour INT = DATEPART(HOUR, @endDate)
	DECLARE @prevDate DATETIME = DATEADD(MONTH, -1, @endDate)						
	DECLARE @prevMonth INT = DATEPART(MONTH, @prevDate)
	DECLARE @prevYear INT = DATEPART(YEAR, @prevDate)
	
	---------------------------------------------------
	-- temp table to hold list of production instruments
	---------------------------------------------------
	
	CREATE TABLE #Tmp_Instruments (
		Seq INT IDENTITY(1,1) NOT NULL,
		Instrument varchar(65)
	)

	---------------------------------------------------
	-- process updates for all instruments, one at a time
	---------------------------------------------------
	BEGIN TRY 

		---------------------------------------------------
		-- get list of tracked instruments
		---------------------------------------------------

		INSERT INTO #Tmp_Instruments (Instrument)
		SELECT [Name] FROM V_Instrument_Tracked

		---------------------------------------------------
		-- update intervals for given instrument
		---------------------------------------------------
		
		DECLARE @instrument VARCHAR(64)
		DECLARE @index INT = 0
		DECLARE @done TINYINT = 0

		WHILE @done = 0
		BEGIN -- <a>
			SET @instrument = NULL 
			SELECT TOP 1 @instrument = Instrument 
			FROM #Tmp_Instruments 
			WHERE Seq > @index
			
			SET @index = @index + 1
			
			IF @instrument IS NULL 
			BEGIN 
				SET @done = 1
			END 
			ELSE 
			BEGIN -- <b>
				EXEC UpdateDatasetInterval @instrument, @startDate, @endDate, @message output, @infoOnly=@infoOnly
				
				If @UpdateEMSLInstrumentUsage <> 0
				BEGIN --<c>
					---------------------------------------------------
					-- if we just crossed the monthly boundary,
					-- update previous month
					--------------------------------------------------- 
					IF @day <= 4
					BEGIN --<d>
						EXEC UpdateEMSLInstrumentUsageReport @instrument, @prevDate, @message output
					END --<d>
					
					---------------------------------------------------
					-- update curent month
					--------------------------------------------------- 
					EXEC UpdateEMSLInstrumentUsageReport @instrument, @endDate, @message output
				END --<c>
					
			END  -- </b>
		END -- </a>


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	If @infoOnly <> 0 and @myError <> 0
		Print @message
		
	RETURN @myError

GO
