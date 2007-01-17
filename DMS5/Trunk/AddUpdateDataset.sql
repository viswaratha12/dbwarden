/****** Object:  StoredProcedure [dbo].[AddUpdateDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateDataset
/****************************************************
**		File: 
**		Name: AddNewDataset
**		Desc: Adds new dataset entry to DMS database
**
**		Return values: 0: success, otherwise, error code
** 
**		Parameters:
**
**		Auth: grk
**		Date: 2/13/2003
**		      1/10/2002
**            12/10/2003 grk added wellplate, internal standards, and LC column stuff
**            1/11/2005 grk added bad dataset stuff
**            2/23/2006 grk added LC cart tracking stuff and EUS stuff
**            1/12/2007 grk  added verification mode
**    
*****************************************************/
	@datasetNum varchar(64),
	@experimentNum varchar(64),
	@operPRN varchar(64),
	@instrumentName varchar(64),
	@msType varchar(20),
	@LCColumnNum varchar(64),
	@wellplateNum varchar(64) = 'na',
	@wellNum varchar(64) = 'na',
	@secSep varchar(64) = 'na',
	@internalStandards varchar(64) = 'none',
	@comment varchar(512) = 'na',
	@rating varchar(32) = 'Unknown',
	@LCCartName varchar(128),
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@requestID int = 0,
	@mode varchar(12) = 'add', -- or 'update', or 'bad'
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @msg varchar(256)

	declare @folderName varchar(64)
	

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@secSep) < 1
	begin
		set @myError = 51017
		RAISERROR ('Separation type was blank',
			10, 1)
	end
	--
	if LEN(@LCColumnNum) < 1
	begin
		set @myError = 51016
		RAISERROR ('LC Column number was blank',
			10, 1)
	end
	--
	if LEN(@datasetNum) < 1
	begin
		set @myError = 51010
		RAISERROR ('Dataset number was blank',
			10, 1)
	end
	--
	set @folderName = @datasetNum
	--
	if LEN(@experimentNum) < 1
	begin
		set @myError = 51011
		RAISERROR ('Experiment number was blank',
			10, 1)
	end
	--
	if LEN(@folderName) < 1
	begin
		set @myError = 51012
		RAISERROR ('Folder name was blank',
			10, 1)
	end
	--
	if LEN(@operPRN) < 1
	begin
		set @myError = 51013
		RAISERROR ('Operator payroll number/HID was blank',
			10, 1)
	end
	--
	if LEN(@instrumentName) < 1
	begin
		set @myError = 51014
		RAISERROR ('Instrument name was blank',
			10, 1)
	end
	--
	if LEN(@msType) < 1
	begin
		set @myError = 51015
		RAISERROR ('Dataset type was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError
		
	---------------------------------------------------
	-- Resolve id for rating
	---------------------------------------------------

	declare @ratingID int

	if @Mode = 'bad'
	begin
		set @ratingID = -1 -- "No Data"
		set @Mode = 'add'
	end
	else
	begin
		execute @ratingID = GetDatasetRatingID @rating
		if @ratingID = 0
		begin
			set @msg = 'Could not find entry in database for rating "' + @rating + '"'
			RAISERROR (@msg, 10, 1)
			return 51017
		end
	end

		
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @datasetID int
	declare @curDSTypeID int
	declare @curDSInstID int
	declare @curDSStateID int
	set @datasetID = 0
	SELECT 
		@datasetID = Dataset_ID,
		@curDSInstID = DS_instrument_name_ID, 
		@curDSStateID = DS_state_ID
    FROM T_Dataset 
	WHERE (Dataset_Num = @datasetNum)

--	execute @datasetID = GetDatasetID @datasetNum

	-- cannot create an entry that already exists
	--
	if @datasetID <> 0 and (@mode = 'add' or @mode = 'check_add')
	begin
		set @msg = 'Cannot add: Dataset "' + @datasetNum + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @datasetID = 0 and (@mode = 'update' or @mode = 'check_update')
	begin
		set @msg = 'Cannot update: Dataset "' + @datasetNum + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end
	
	---------------------------------------------------
	-- Resolve ID for LC Column
	---------------------------------------------------
	
	declare @columnID int
	set @columnID = -1
	--
	SELECT @columnID = ID
	FROM T_LC_Column
	WHERE (SC_Column_Number = @LCColumnNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up column ID'
		RAISERROR (@msg, 10, 1)
		return 51093
	end
	if @columnID = -1
	begin
		set @msg = 'Could not resolve column number to ID'
		RAISERROR (@msg, 10, 1)
		return 51094
	end

	---------------------------------------------------
	-- Resolve ID for @secSep
	---------------------------------------------------

	declare @sepID int
	set @sepID = 0
	--
	SELECT @sepID = SS_ID
	FROM T_Secondary_Sep
	WHERE SS_name = @secSep	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up separation type ID'
		RAISERROR (@msg, 10, 1)
		return 51098
	end
	if @sepID = 0
	begin
		set @msg = 'Could not resolve separation type to ID'
		RAISERROR (@msg, 10, 1)
		return 51099
	end

	---------------------------------------------------
	-- Resolve ID for @internalStandards
	---------------------------------------------------
	if @internalStandards = ''
		set @internalStandards = 'none'

	declare @intStdID int
	set @intStdID = -1
	--
	SELECT @intStdID = Internal_Std_Mix_ID
	FROM [T_Internal_Standards]
	WHERE [Name] = @internalStandards	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up internal standards ID'
		RAISERROR (@msg, 10, 1)
		return 51095
	end
	if @intStdID = -1
	begin
		set @msg = 'Could not resolve internal standards to ID'
		RAISERROR (@msg, 10, 1)
		return 51096
	end

	---------------------------------------------------
	-- Resolve experiment ID
	---------------------------------------------------

	declare @experimentID int
	execute @experimentID = GetExperimentID @experimentNum
	if @experimentID = 0
	begin
		set @msg = 'Could not find entry in database for experiment "' + @experimentNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51012
	end
	
	---------------------------------------------------
	-- Resolve dataset type ID
	---------------------------------------------------

	declare @datasetTypeID int
	execute @datasetTypeID = GetDatasetTypeID @msType
	if @datasetTypeID = 0
	begin
		set @msg = 'Could not find entry in database for dataset type'
		RAISERROR (@msg, 10, 1)
		return 51013
	end

	---------------------------------------------------
	-- Resolve instrument ID
	---------------------------------------------------

	declare @instrumentID int
	execute @instrumentID = GetinstrumentID @instrumentName
	if @instrumentID = 0
	begin
		set @msg = 'Could not find entry in database for instrument "' + @instrumentName + '"'
		RAISERROR (@msg, 10, 1)
		return 51014
	end

	-- not valid to change instrument unless dataset in new state
	--
	if (@mode = 'update' or @mode = 'check_update') and @instrumentID <> @curDSInstID and @curDSStateID <> 1
	begin
		set @msg = 'Cannot change instrument if dataset not in "new" state'
		RAISERROR (@msg, 10, 1)
		return 51023
	end
	
	---------------------------------------------------
	-- Resolve user ID for operator PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @operPRN
	if @userID = 0
	begin
		set @msg = 'Could not find entry in database for operator PRN "' + @operPRN + '"'
		RAISERROR (@msg, 10, 1)
		return 51019
	end

	declare @storagePathID int
	set @storagePathID = 2 -- index of "none" in table

	---------------------------------------------------
	-- Verify acceptable combination of EUS fields
	---------------------------------------------------
	
	if (@mode = 'add' or @mode = 'check_add') AND @requestID <> 0 AND (@eusProposalID <> '' OR @eusUsageType <> '' OR @eusUsersList <> '')
	begin
		set @msg = 'Either a Request must be specified, or EMSL user parameters must be specified, but not both'
		RAISERROR (@msg, 10, 1)
		return 51043
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	
	if @Mode = 'add'
	begin	
		-- Start transaction
		--
		declare @transName varchar(32)
		set @transName = 'AddNewDataset'
		begin transaction @transName

		-- insert values into a new row
		--
		INSERT INTO T_Dataset(
				Dataset_Num, 
				DS_Oper_PRN, 
				DS_comment, 
				DS_created, 
				DS_instrument_name_ID, 
				DS_type_ID, 
				DS_well_num, 
				DS_sec_sep, 
				DS_state_ID, 
				DS_folder_name, 
				DS_storage_path_ID, 
				Exp_ID,
				DS_rating,
				DS_LC_column_ID, 
				DS_wellplate_num, 
				DS_internal_standard_ID
				) 
			VALUES (
				@datasetNum,
				@operPRN,
				@comment,
				getdate(),
				@instrumentID,
				@datasetTypeID,
				@wellNum,
				@secSep,
				1,
				@folderName,
				@storagePathID,
				@experimentID,
				@ratingID,
				@columnID,
				@wellplateNum,
				@intStdID
				)
 
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert operation failed: "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		set @datasetID = IDENT_CURRENT('T_Dataset')

		---------------------------------------------------
		-- if scheduled run is not specified, create one
		---------------------------------------------------
		declare @result int

		if @requestID = 0
		begin
			declare @reqName varchar(128)
			set @reqName = 'AutoReq_' + @datasetNum
			exec @result = AddUpdateRequestedRun
								@reqName,
								@experimentNum,
								@operPRN,
								@instrumentName,
								'none',
								@msType,
								'na',
								'na',
								'na',
								'na',
								'na',
								'Automatically created by Dataset entry',
								@eusProposalID,
								@eusUsageType,
								@eusUsersList,
								'add',
								@requestID output,
								@message output
			--
			set @myError = @result
			--
			if @myError <> 0
			begin
				set @msg = 'Create scheduled run failed: "' + @datasetNum + '"->' + @message
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51017
			end
		end

		---------------------------------------------------
		-- if a cart name is specified, update it for the 
		-- requested run
		---------------------------------------------------
		if @LCCartName <> ''
		begin
			exec @result = UpdateCartParameters
								'CartName',
								@requestID,
								@LCCartName output,
								@message output
			--
			set @myError = @result
			--
			if @myError <> 0
			begin
				set @msg = 'Update cart name update failed: "' + @datasetNum + '"->' + @message
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51017
			end
		end
		---------------------------------------------------
		-- consume the scheduled run 
		---------------------------------------------------
		set @datasetID = 0
		SELECT 
			@datasetID = Dataset_ID
		FROM T_Dataset 
		WHERE (Dataset_Num = @datasetNum)

		exec @result = ConsumeScheduledRun @datasetID, @requestID, @message output
		--
		set @myError = @result
		--
		if @myError <> 0
		begin
			set @msg = 'Consume operation failed: "' + @datasetNum + '"->' + @message
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return 51016
		end

		commit transaction @transName
	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Dataset 
		SET 
				DS_Oper_PRN = @operPRN, 
				DS_comment = @comment, 
				DS_instrument_name_ID = @instrumentID, 
				DS_type_ID = @datasetTypeID, 
				DS_well_num = @wellNum, 
				DS_sec_sep = @secSep, 
				DS_folder_name = @folderName, 
				Exp_ID = @experimentID,
				DS_rating = @ratingID,
				DS_LC_column_ID = @columnID, 
				DS_wellplate_num = @wellplateNum, 
				DS_internal_standard_ID = @intStdID
		WHERE (Dataset_Num = @datasetNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode

	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS_DS_Entry]
GO
