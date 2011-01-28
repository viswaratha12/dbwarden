/****** Object:  StoredProcedure [dbo].[RequestPurgeTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.RequestPurgeTask
/****************************************************
**
**	Desc: 
**		Looks for dataset that is best candidate to be purged
**		If found, dataset archive status is set to 'Purge In Progress'
**		and information needed for purge task is returned
**		in the output arguments
**
**		Alternatively, if @infoOnly is > 0, then will return the
**		next N datasets that would be purged on the specified server,
**		or on a series of servers (if @StorageServerName and/or @StorageVol are blank)
**		N is 10 if @infoOnly = 1; N is @infoOnly if @infoOnly is greater than 1
**
**		Note that PreviewPurgeTaskCandidates calls this procedure, sending a positive value for @infoOnly
**
**	Return values: 0: success, otherwise, error code
**	
**  If DatasetID is returned 0, no available dataset was found
**
**  Example syntax for Preview:
**     exec RequestPurgeTask 'proto-9', @StorageVol='g:\', @infoOnly = 1
**
**	Auth:	grk
**	Date:	03/04/2003
**			02/11/2005 grk - added @RawDataType to output
**			06/02/2009 mem - Decreased population of #PD to be limited to 2 rows
**			12/13/2010 mem - Added @infoOnly and defined defaults for several parameters
**			12/30/2010 mem - Updated to allow @StorageServerName and/or @StorageVol to be blank
**						   - Added @PreviewSql
**			01/04/2011 mem - Now initially favoring datasets at least 4 months old, then checking datasets where the most recent job was a year ago, then looking at newer datasets
**    
*****************************************************/
(
	@StorageServerName varchar(64),					-- Input param: Storage server to use, for example 'proto-9'; if blank, then returns candidates for all storage servers; when blank, then @StorageVol is ignored
	@dataset varchar(128) = '' output,
	@DatasetID int = 0 output,
	@Folder varchar(256) = '' output, 
	@StorageVol varchar(256) output,				-- Input/output param: Volume on storage server to use, for example 'g:\'; if blank, then returns candidates for all drives on given server (or all servers if @StorageServerName is blank)
	@storagePath varchar(256) = '' output, 
	@StorageVolExternal varchar(256) = '' output,	-- Use instead of @StorageVol when manager is not on same machine as dataset folder
	@RawDataType varchar(32) = '' output,
	@ParamList varchar(1024) = '' output,			-- for future use
	@message varchar(512) = '' output,
	@infoOnly int = 0,								-- Set to positive number to preview the candidates; 1 will preview the first 10 candidates; values over 1 will return the specified number of candidates
	@PreviewSql tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @CandidateCount int
	declare @PreviewCount int

	Declare @Continue tinyint
	Declare @PurgeViewEntryID int
	Declare @PurgeViewName varchar(64)
	Declare @PurgeViewSourceDesc varchar(90)
	Declare @HoldoffDays int
	Declare @OrderByCol varchar(64)

	Declare @S varchar(2048)
	
	Set @CandidateCount = 0
	Set @PreviewCount = 2

	
	--------------------------------------------------
	-- Validate the inputs
	--------------------------------------------------
	Set @StorageServerName = IsNull(@StorageServerName, '')
	
	If @StorageServerName = ''
		Set @StorageVol = ''
	Else
		Set @StorageVol = IsNull(@StorageVol, '')

	Set @InfoOnly = IsNull(@InfoOnly, 0)

	If @infoOnly = 0
	Begin
		-- Verify that both @StorageServerName and @StorageVol are specified
		If @StorageServerName = '' OR @StorageVol = ''
		Begin
			Set @message = 'Error, both a storage server and a storage volume must be specified when @infoOnly = 0'
			Set @myError = 50000
			Goto Done
		End
	End
	Else
	Begin
		If @infoOnly > 1
			Set @PreviewCount = @infoOnly
		Else
			Set @PreviewCount = 10
	End
	
	Set @PreviewSql = IsNull(@PreviewSql, 0)
	
	
	--------------------------------------------------
	-- Clear the outputs
	--------------------------------------------------	
	set @DatasetID = 0
	set @dataset = ''
	set @DatasetID = ''
	set @Folder = ''
	set @storagePath = ''
	set @StorageVolExternal = ''
	set @RawDataType = ''
	set @ParamList = ''
	set @message = ''

	--------------------------------------------------
	-- temporary table to hold candidate purgable datasets
	---------------------------------------------------

	CREATE TABLE #PD (
		EntryID int identity(1,1),
		DatasetID  int,
		MostRecent  datetime,
		Source varchar(90),
		StorageServerName varchar(64) NULL,
		ServerVol varchar(128) NULL
	) 

	CREATE INDEX #IX_PD_StorageServerAndVol ON #PD (StorageServerName, ServerVol)

	CREATE TABLE #TmpStorageVolsToSkip (
		StorageServerName varchar(64),
		ServerVol varchar(128)
	)
	
	CREATE TABLE #TmpPurgeViews (
		EntryID int identity(1,1),
		PurgeViewName varchar(64),
		HoldoffDays int,
		OrderByCol varchar(64)		
	)
	
	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- purgable datasets for given storage server
	---------------------------------------------------
	
	-- The candidates come from three separate views, which we define in #TmpPurgeViews
	--
	-- We're querying each view twice because we want to first purge datasets at least 
	-- ~4 months old with rating No Interest, then purge datasets with the most recent job over 365 days ago, 
	-- then start purging newer datasets
	--
	INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
	VALUES ('V_Purgable_Datasets_NoInterest', 120,  'Created')
	
	INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
	VALUES ('V_Purgable_Datasets_NoJob',      160, 'Created')

	INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
	VALUES ('V_Purgable_Datasets',            365, 'MostRecentJob')
	
	INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
	VALUES ('V_Purgable_Datasets_NoInterest', 14,  'Created')

	INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
	VALUES ('V_Purgable_Datasets_NoJob',      21, 'Created')
	
	INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
	VALUES ('V_Purgable_Datasets',            -1, 'MostRecentJob')
	
	---------------------------------------------------
	-- Process each of the views in #TmpPurgeViews
	---------------------------------------------------
	
	Set @Continue = 1
	Set @PurgeViewEntryID = 0
	
	While @Continue = 1
	Begin -- <a>
	
		SELECT TOP 1 @PurgeViewEntryID = EntryID,
		             @PurgeViewName = PurgeViewName,
		             @HoldoffDays = HoldoffDays,
		             @OrderByCol = OrderByCol
		FROM #TmpPurgeViews
		WHERE EntryID > @PurgeViewEntryID
		ORDER BY EntryID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
			Set @Continue = 0
		Else
		Begin -- <b>
			
			/*
			** The following is a simpler query that can be used when 
			**   looking for candidates on a specific volume on a specific server
			** It is more efficient than the larger query below (which uses Row_Number() to rank things)
			** However, it doesn't run that much faster, and thus, for simplicity, we're always using the larger query
			**
				Set @S = ''

				Set @S = @S + ' INSERT INTO #PD( DatasetID,'
				Set @S = @S +                  ' MostRecent,'
				Set @S = @S +                  ' Source,'
				Set @S = @S +                  ' StorageServerName,'
				Set @S = @S +                  ' ServerVol)'
				Set @S = @S + ' SELECT TOP (' + Convert(varchar(12), @PreviewCount) + ')'
				Set @S = @S +        ' Dataset_ID, '
				Set @S = @S +          @OrderByCol + ', '
				Set @S = @S +        '''' + @PurgeViewName + ''' AS Source,'
				Set @S = @S +        ' StorageServerName,'
				Set @S = @S +        ' ServerVol'
				Set @S = @S + ' FROM ' + @PurgeViewName
				Set @S = @S + ' WHERE     (StorageServerName = ''' + @StorageServerName + ''')'
				Set @S = @S +       ' AND (ServerVol = ''' + @StorageVol + ''')'
				
				If @HoldoffDays >= 0
					Set @S = @S +   ' AND DATEDIFF(DAY, ' + @OrderByCol + ', GetDate()) > ' + Convert(varchar(24), @HoldoffDays)

				Set @S = @S + ' ORDER BY ' + @OrderByCol + ', Dataset_ID'
			*/
			
			Set @PurgeViewSourceDesc = @PurgeViewName
			If @HoldoffDays >= 0
				Set @PurgeViewSourceDesc = @PurgeViewSourceDesc + '_' + Convert(varchar(24), @HoldoffDays) + 'MinDays'
				
			-- Find the top @PreviewCount candidates for each drive on each server 
			-- (limiting by @StorageServerName or @StorageVol if they are defined)
			
			Set @S = ''
			Set @S = @S + ' INSERT INTO #PD( DatasetID,'
			Set @S = @S +                  ' MostRecent,'
			Set @S = @S +                  ' Source,'
			Set @S = @S +                  ' StorageServerName,'
			Set @S = @S +                  ' ServerVol)'
			Set @S = @S + ' SELECT Dataset_ID, '
			Set @S = @S +          @OrderByCol + ', '
			Set @S = @S +        ' Source,'
			Set @S = @S +        ' StorageServerName,'
			Set @S = @S +        ' ServerVol'
			Set @S = @S + ' FROM ( SELECT Src.Dataset_ID, '
			Set @S = @S +                'Src.' + @OrderByCol + ', '
			Set @S = @S +               '''' + @PurgeViewSourceDesc + ''' AS Source,'
			Set @S = @S +               ' Row_Number() OVER ( PARTITION BY Src.StorageServerName, Src.ServerVol '
			Set @S = @S +                                   ' ORDER BY Src.' + @OrderByCol + ', Src.Dataset_ID ) AS RowNumVal,'
			Set @S = @S +               ' Src.StorageServerName,'
			Set @S = @S +               ' Src.ServerVol'
			Set @S = @S +        ' FROM ' + @PurgeViewName + ' Src'
			Set @S = @S +               ' LEFT OUTER JOIN #TmpStorageVolsToSkip '
			Set @S = @S +                 ' ON Src.StorageServerName = #TmpStorageVolsToSkip.StorageServerName AND'
			Set @S = @S +                ' Src.ServerVol         = #TmpStorageVolsToSkip.ServerVol '
			Set @S = @S +               ' LEFT OUTER JOIN #PD '
			Set @S = @S +                 ' ON Src.Dataset_ID = #PD.DatasetID'
			Set @S = @S +        ' WHERE #TmpStorageVolsToSkip.StorageServerName IS NULL'
			Set @S = @S +               ' AND #PD.DatasetID IS NULL '
				
			If @StorageServerName <> ''
				Set @S = @S +           ' AND (Src.StorageServerName = ''' + @StorageServerName + ''')'

			If @StorageVol <> ''
				Set @S = @S +           ' AND (Src.ServerVol = ''' + @StorageVol + ''')'

			If @HoldoffDays >= 0
				Set @S = @S +           ' AND DATEDIFF(DAY, ' + @OrderByCol + ', GetDate()) > ' + Convert(varchar(24), @HoldoffDays)

			Set @S = @S +     ') LookupQ'
			Set @S = @S + ' WHERE RowNumVal <= ' + Convert(varchar(12), @PreviewCount)
			Set @S = @S + ' ORDER BY StorageServerName, ServerVol, ' + @OrderByCol + ', Dataset_ID'
			
			If @PreviewSql <> 0
				Print @S
				
			Exec (@S)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error populating temporary table'
				goto done
			end
			
			Set @CandidateCount = @CandidateCount + @myRowCount
		
		
			If (@infoOnly = 0)
			Begin
				If @CandidateCount > 0
					Set @continue = 0
			End
			Else
			Begin -- <c>
				If @StorageServerName <> '' AND @StorageVol <> ''
				Begin
					If @CandidateCount >= @PreviewCount
						Set @Continue = 0
				End
				Else
				Begin -- <d>
					-- Count the number of candidates on each volume on each storage server
					-- Add entries to #TmpStorageVolsToSkip
					
					INSERT INTO #TmpStorageVolsToSkip( StorageServerName,
													   ServerVol )
					SELECT Src.StorageServerName,
						Src.ServerVol
					FROM ( SELECT StorageServerName,
								ServerVol
						FROM #PD
						GROUP BY StorageServerName, ServerVol
						HAVING COUNT(*) >= @PreviewCount 
						) AS Src
						LEFT OUTER JOIN #TmpStorageVolsToSkip AS Target
						ON Src.StorageServerName = Target.StorageServerName AND
							Src.ServerVol = Target.ServerVol
					WHERE Target.ServerVol IS NULL
					
				End -- </d>
				
			End -- </c>
		
		End -- </b>
	End -- </a>
	
		
	If @infoOnly <> 0
	Begin
		SELECT #PD.*,
		  DFP.Dataset,
		       DFP.Dataset_Folder_Path,
		       DFP.Archive_Folder_Path,
		       DA.AS_State_ID AS Achive_State_ID,
		       DA.AS_State_Last_Affected AS Achive_State_Last_Affected,
		       DA.AS_Purge_Holdoff_Date AS Purge_Holdoff_Date,
		       DA.AS_Instrument_Data_Purged AS Instrument_Data_Purged,
		       dbo.udfCombinePaths(SPath.SP_vol_name_client, SPath.SP_path) AS Storage_Path_Client,
		       dbo.udfCombinePaths(SPath.SP_vol_name_Server, SPath.SP_path) AS Storage_Path_Server,
		       ArchPath.AP_archive_path AS Archive_Path_Unix
		FROM #PD
		     INNER JOIN T_Dataset_Archive DA
		       ON DA.AS_Dataset_ID = #PD.DatasetID
		     INNER JOIN V_Dataset_Folder_Paths DFP
		       ON DA.AS_Dataset_ID = DFP.Dataset_ID
		     INNER JOIN T_Dataset DS	     
	           ON DS.Dataset_ID = DA.AS_Dataset_ID
		     INNER JOIN T_Storage_Path SPath
	          ON DS.DS_storage_path_ID = SPath.SP_path_ID
	         INNER JOIN T_Archive_Path ArchPath
	          ON DA.AS_storage_path_ID = ArchPath.AP_path_ID
		ORDER BY #PD.EntryID

		Goto Done		
	End
	
	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'RequestPurgeTask'
	begin transaction @transName

	---------------------------------------------------
	-- Select and lock a specific purgable dataset by joining
	-- from the local pool to the actual archive table
	---------------------------------------------------

	SELECT TOP 1 @datasetID = AS_Dataset_ID
	FROM T_Dataset_Archive WITH ( HoldLock )
	     INNER JOIN #PD
	       ON DatasetID = AS_Dataset_ID
	WHERE (AS_state_ID = 3)
	ORDER BY #PD.EntryID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'could not load temporary table'
		goto done
	end
	
	if @datasetID = 0
	begin
		rollback transaction @transName
		goto done
	end
	
	---------------------------------------------------
	-- update archive state to show purge in progress
	---------------------------------------------------

	UPDATE T_Dataset_Archive
	SET AS_state_ID = 7 -- "purge in progress"
	WHERE (AS_Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Update operation failed'
		goto done
	end

	commit transaction @transName

	---------------------------------------------------
	-- get information for assigned dataset
	---------------------------------------------------

	SELECT @dataset = DS.Dataset_Num,
	       @DatasetID = DS.Dataset_ID,
	       @Folder = DS.DS_folder_name,
	       @StorageVol = SPath.SP_vol_name_server,
	       @storagePath = SPath.SP_path,
	       @StorageVolExternal = SPath.SP_vol_name_client,
	       @RawDataType = InstClass.raw_data_type
	FROM T_Dataset DS
	     INNER JOIN T_Dataset_Archive DA
	       ON DS.Dataset_ID = DA.AS_Dataset_ID
	     INNER JOIN T_Storage_Path SPath
	       ON DS.DS_storage_path_ID = SPath.SP_path_ID
	     INNER JOIN T_Instrument_Name InstName
	       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
	     INNER JOIN T_Instrument_Class InstClass
	       ON InstName.IN_class = InstClass.IN_class
	WHERE DS.Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		rollback transaction @transName
		set @message = 'Find purgeable dataset operation failed'
		goto done
	end
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[RequestPurgeTask] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestPurgeTask] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPurgeTask] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPurgeTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPurgeTask] TO [PNL\D3M580] AS [dbo]
GO
