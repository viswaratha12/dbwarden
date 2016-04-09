/****** Object:  StoredProcedure [dbo].[StoreMyEMSLUploadStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.StoreMyEMSLUploadStats
/****************************************************
**
**	Desc: 
**		Store MyEMSL upload stats in T_MyEMSL_Uploads
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	03/29/2012 mem - Initial version
**			04/02/2012 mem - Now populating StatusURI_PathID, ContentURI_PathID, and StatusNum
**			04/06/2012 mem - No longer posting a log message if @StatusURI is blank and @FileCountNew=0 and @FileCountUpdated=0
**			08/19/2013 mem - Removed parameter @UpdateURIPathIDsForExistingJob
**			09/06/2013 mem - No longer using @ContentURI
**			09/11/2013 mem - No longer calling PostLogEntry if @StatusURI is invalid but @ErrorCode is non-zero
**			10/01/2015 mem - Added parameter @UsedTestInstance
**			01/04/2016 mem - Added parameters @EUSUploaderID, @EUSInstrumentID, and @EUSProposalID
**						   - Removed parameter @ContentURI
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**    
*****************************************************/
(
    @Job int,
	@DatasetID int,
	@Subfolder varchar(128),
	@FileCountNew int,
	@FileCountUpdated int,
	@Bytes bigint,
	@UploadTimeSeconds real,
	@StatusURI varchar(255),
	@ErrorCode int,
	@UsedTestInstance tinyint=0,
	@EUSInstrumentID int=null,					-- EUS Instrument ID
	@EUSProposalID varchar(10)=null,			-- EUS Proposal ID
	@EUSUploaderID int=null,					-- The EUS ID of the instrument operator
	@message varchar(512)='' output,
	@infoOnly tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @EntryID int
	Declare @Dataset varchar(128) = ''

	Declare @CharLoc int
	Declare @SubString varchar(256)
	Declare @LogMsg varchar(512) = ''
	
	Declare @InvalidFormat tinyint

	Declare @StatusURI_PathID int = 1
	Declare @StatusURI_Path varchar(512) = ''
	Declare @StatusNum int = null
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @Job = IsNull(@Job, 0)
	Set @DatasetID = IsNull(@DatasetID, 0)
	Set @Subfolder = IsNull(@Subfolder, '')
	Set @StatusURI = IsNull(@StatusURI, '')
	Set @UsedTestInstance = IsNull(@UsedTestInstance, 0)

	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- Make sure @Job is defined in T_Jobs
	---------------------------------------------------
	
	IF NOT EXISTS (SELECT * FROM T_Jobs where Job = @Job)
	Begin
		Set @message = 'Job not found in T_Jobs: ' + CONVERT(varchar(12), @Job)
		If @infoOnly <> 0
			Print @message
		return 50000
	End
	
	-----------------------------------------------
	-- Analyze @StatusURI to determine the base URI and the Status Number
	-- For example, in https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/644749/xml
	-- extract out     https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
	-- and also        644749
	-----------------------------------------------
	--
	Set @StatusURI_PathID = 1
	Set @StatusURI_Path = ''
	Set @StatusNum = null
	
	If @StatusURI = '' and @FileCountNew = 0 And @FileCountUpdated = 0
	Begin
		-- Nothing to do; leave @StatusURI_PathID as 1
		Set @StatusURI_PathID = 1
	End
	Else
	Begin -- <a1>
		
		-- Setup the log message in case we need it; also, set @InvalidFormat to 1 for now
		Set @LogMsg = 'Unable to extract StatusNum from StatusURI for job ' + Convert(varchar(12), @Job) + ', dataset ' + Convert(varchar(12), @DatasetID)
		Set @InvalidFormat = 1
		
		Set @CharLoc = CharIndex('/status/', @StatusURI)
		If @CharLoc = 0
			Set @LogMsg = @LogMsg + ': /status/ not found in ' + @StatusURI
		Else
		Begin -- <b1>
			-- Extract out the base path, for example:
			-- https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
			Set @StatusURI_Path = SUBSTRING(@StatusURI, 1, @CharLoc + 7)
			
			-- Extract out the text after /status/, for example:
			-- 644749/xml
			Set @SubString = SubString(@StatusURI, @CharLoc + 8, 255)
			
			-- Find the first non-numeric character in @SubString
			set @CharLoc = PATINDEX('%[^0-9]%', @SubString)
			
			If @CharLoc <= 0
			Begin
				Set @StatusNum = Try_Convert(int, @SubString)
				If IsNull(@SubString, '') <> '' And Not @StatusNum Is Null
				Begin
					Set @InvalidFormat = 0
				End
				Else
				Begin
					Set @LogMsg = @LogMsg + ': number not found after /status/ in ' + @StatusURI
				End
			End
			
			If @CharLoc = 1
			Begin
				Set @LogMsg = @LogMsg + ': number not found after /status/ in ' + @StatusURI
			End
			
			If @CharLoc > 1
			Begin
				Set @StatusNum = CONVERT(int, SUBSTRING(@SubString, 1, @CharLoc-1))
				Set @InvalidFormat = 0
			End
			
		End -- </b1>
		
		If @InvalidFormat <> 0
		Begin
			If @infoOnly = 0
			Begin
				If @ErrorCode = 0
					Exec PostLogEntry 'Error', @LogMsg, 'StoreMyEMSLUploadStats'
			End
			else
				Print @LogMsg
		End
		Else
		Begin -- <b2>
			-- Resolve @StatusURI_Path to @StatusURI_PathID
			
			Exec @StatusURI_PathID = GetURIPathID @StatusURI_Path, @infoOnly=@infoOnly
			
			If @StatusURI_PathID <= 1
			Begin
				Set @LogMsg = 'Unable to resolve StatusURI_Path to URI_PathID for job ' + Convert(varchar(12), @Job) + ', dataset ' + Convert(varchar(12), @DatasetID) + ': ' + @StatusURI_Path
				
				If @infoOnly = 0
					Exec PostLogEntry 'Error', @LogMsg, 'StoreMyEMSLUploadStats'
				Else
					Print @LogMsg
			End
			Else
			Begin
				-- Blank out @StatusURI since we have successfully resolved it into @StatusURI_PathID and @StatusNum
				Set @StatusURI = ''
			End
			
		End -- </b2>
	End -- </a1>
	
	If @infoOnly <> 0
	Begin
		-----------------------------------------------
		-- Preview the data, then exit
		-----------------------------------------------
		
		SELECT @Job AS Job,
		       @DatasetID AS Dataset_ID,
		       @Subfolder AS Subfolder,
		       @FileCountNew AS FileCountNew,
		       @FileCountUpdated AS FileCountUpdated,
		       @Bytes / 1024.0 / 1024.0 AS MB_Transferred,
		       @UploadTimeSeconds AS UploadTimeSeconds,
		       @StatusURI AS URI,
		       @StatusURI_PathID AS StatusURI_PathID,
		       @StatusNum as StatusNum,	
		       @ErrorCode AS ErrorCode
		       
		
	End
	Else
	Begin -- <a3>
		
		If @UsedTestInstance = 0
		Begin
				
			-----------------------------------------------
			-- Add a new row to T_MyEmsl_Uploads
			-----------------------------------------------
			--
			INSERT INTO T_MyEmsl_Uploads (Job, Dataset_ID, Subfolder, 
			                              FileCountNew, FileCountUpdated, 
			                              Bytes, UploadTimeSeconds, 
			                              StatusURI_PathID, StatusNum,
			                              EUS_InstrumentID, EUS_ProposalID, EUS_UploaderID,	
			                              ErrorCode, Entered )
			SELECT @Job,
			       @DatasetID,
			       @Subfolder,
			       @FileCountNew,
			       @FileCountUpdated,
			       @Bytes,
			       @UploadTimeSeconds,
			       @StatusURI_PathID,
			       @StatusNum,
			       @EUSInstrumentID,
			       @EUSProposalID,
			       @EUSUploaderID,
			       @ErrorCode,
			       GetDate()

			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error adding new row to T_MyEmsl_Uploads for job ' + Convert(varchar(12), @job)
			end	

		End
		Else
		Begin
			-----------------------------------------------
			-- Add a new row to T_MyEmsl_TestUploads
			-----------------------------------------------
			--
			INSERT INTO T_MyEmsl_TestUploads (Job, Dataset_ID, Subfolder, 
			                              FileCountNew, FileCountUpdated, 
			                              Bytes, UploadTimeSeconds, 
			                              StatusURI_PathID, StatusNum,
			                              EUS_InstrumentID, EUS_ProposalID, EUS_UploaderID,	
			                              ErrorCode, Entered )
			SELECT @Job,
			       @DatasetID,
			       @Subfolder,
			       @FileCountNew,
			       @FileCountUpdated,
			       @Bytes,
			       @UploadTimeSeconds,
			       @StatusURI_PathID,
			       @StatusNum,
			       @EUSInstrumentID,
			       @EUSProposalID,
			       @EUSUploaderID,
			       @ErrorCode,
			       GetDate()
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error adding new row to T_MyEmsl_TestUploads for job ' + Convert(varchar(12), @job)
			end	
		End

		
	End -- </a3>
	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in StoreMyEMSLUploadStats'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		If @InfoOnly = 0
			Exec PostLogEntry 'Error', @message, 'StoreMyEMSLUploadStats'
	End
	
	If Len(@message) > 0 AND @InfoOnly <> 0
		Print @message

	Return @myError




GO
GRANT EXECUTE ON [dbo].[StoreMyEMSLUploadStats] TO [DMS_SP_User] AS [dbo]
GO
