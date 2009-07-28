/****** Object:  StoredProcedure [dbo].[AddUpdateExperiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateExperiment
/****************************************************
**
**	Desc:	Adds a new experiment to DB
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	01/8/2002 - initial release
**			08/25/2004 jds - updated proc to add T_Enzyme table value
**			06/10/2005 grk - added handling for sample prep request
**			10/28/2005 grk - added handling for internal standard
**			11/11/2005 grk - added handling for postdigest internal standard
**			11/21/2005 grk - fixed update error for postdigest internal standard
**			01/12/2007 grk - added verification mode
**			01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**			04/30/2007 grk - added better name validation (Ticket #450)
**			02/13/2008 mem - Now checking for @badCh = '[space]' (Ticket #602)
**			03/13/2008 grk - added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter @callingUser
**			03/25/2008 mem - Now calling AlterEventLogEntryUser if @callingUser is not blank (Ticket #644)
**			07/16/2009 grk - added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**
*****************************************************/
(
	@experimentNum varchar(50),
	@campaignNum varchar(50),
	@researcherPRN varchar(50),
	@organismName varchar(50),
	@reason varchar(250) = 'na',
	@comment varchar(250) = Null,
	@sampleConcentration varchar(32) = 'na',
	@enzymeName varchar(50) = 'Trypsin',
	@labNotebookRef varchar(64) = 'na',
	@labelling varchar(64) = 'none',
	@cellCultureList varchar(200) = '',
	@samplePrepRequest int = 0,
	@internalStandard varchar(50),
	@postdigestIntStd varchar(50),
	@wellplateNum varchar(64),
	@wellNum varchar(8),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@container varchar(128) = 'na', 
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @result int
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@experimentNum) < 1
	begin
		set @myError = 51030
		RAISERROR ('experimentNum was blank',
			10, 1)
	end
	--
	if LEN(@campaignNum) < 1
	begin
		set @myError = 51031
		RAISERROR ('campaignNum was blank',
			10, 1)
	end
	--
	if LEN(@researcherPRN) < 1
	begin
		set @myError = 51032
		RAISERROR ('researcherPRN was blank',
			10, 1)
	end
	--
	if LEN(@organismName) < 1
	begin
		set @myError = 51033
		RAISERROR ('organismName was blank',
			10, 1)
	end
	--
	if LEN(@reason) < 1
	begin
		set @myError = 51034
		RAISERROR ('reason was blank',
			10, 1)
	end
	--
	if LEN(@labelling) < 1
	begin
		set @myError = 51031
		RAISERROR ('Labelling was blank',
			10, 1)
	end
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- validate name
	---------------------------------------------------

	declare @badCh varchar(128)
	set @badCh =  dbo.ValidateChars(@experimentNum, '')
	if @badCh <> ''
	begin
		If @badCh = '[space]'
			set @msg = 'Experiment name may not contain spaces'
		Else
			set @msg = 'Experiment name may not contain the character(s) "' + @badCh + '"'

		RAISERROR (@msg, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @experimentID int
	set @experimentID = 0
	--
	declare @curContainerID int
	set @curContainerID = 0
	--
	SELECT 
		@experimentID = Exp_ID,
		@curContainerID = EX_Container_ID
	FROM T_Experiments 
	WHERE (Experiment_Num = @experimentNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to resolve experiment ID'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	-- cannot create an entry that already exists
	--
	if @experimentID <> 0 and (@mode = 'add' or @mode = 'check_add')
	begin
		set @msg = 'Cannot add: Experiment "' + @experimentNum + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51035
	end

	-- cannot update a non-existent entry
	--
	if @experimentID = 0 and (@mode = 'update' or @mode = 'check_update')
	begin
		set @msg = 'Cannot update: Experiment "' + @experimentNum + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51035
	end

	---------------------------------------------------
	-- Resolve campaign ID
	---------------------------------------------------

	declare @campaignID int
	execute @campaignID = GetCampaignID @campaignNum
	if @campaignID = 0
	begin
		set @msg = 'Could not find entry in database for campaignNum "' + @campaignNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51036
	end

	---------------------------------------------------
	-- Resolve researcher PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @researcherPRN
	if @userID = 0
	begin
		set @msg = 'Could not find entry in database for researcher PRN "' + @researcherPRN + '"'
		RAISERROR (@msg, 10, 1)
		return 51037
	end

	---------------------------------------------------
	-- Resolve organism ID
	---------------------------------------------------

	declare @organismID int
	execute @organismID = GetOrganismID @organismName
	if @organismID = 0
	begin
		set @msg = 'Could not find entry in database for organismName "' + @organismName + '"'
		RAISERROR (@msg, 10, 1)
		return 51038
	end


	---------------------------------------------------
	-- set up and validate wellplate values
	---------------------------------------------------

	declare @wellIndex int
	exec @myError = ValidateWellplateLoading
						@wellplateNum  output,
						@wellNum  output,
						1,
						@wellIndex output,
						@msg  output
	if @myError <> 0
	begin
		RAISERROR (@msg, 10, 1)
		return @myError
	end

	-- make sure we do not put two experiments in the same place
	--
	if exists (SELECT * FROM T_Experiments WHERE EX_wellplate_num = @wellplateNum AND EX_well_num = @wellNum) AND @mode = 'add'
	begin
		set @msg = 'There is another experiment assigned to the same wellplate and well'
		RAISERROR (@msg, 10, 1)
		return 51043
	end
	if exists (SELECT * FROM T_Experiments WHERE EX_wellplate_num = @wellplateNum AND EX_well_num = @wellNum AND Experiment_Num <> @experimentNum) AND @mode = 'update'
	begin
		set @msg = 'There is another experiment assigned to the same wellplate and well'
		RAISERROR (@msg, 10, 1)
		return 51044
	end

	---------------------------------------------------
	-- Resolve enzyme ID
	---------------------------------------------------

	declare @enzymeID int
	execute @enzymeID = GetEnzymeID @enzymeName
	if @enzymeID = 0
	begin
		set @msg = 'Could not find entry in database for enzymeName "' + @enzymeName + '"'
		RAISERROR (@msg, 10, 1)
		return 51038
	end

	---------------------------------------------------
	-- Resolve labelling ID
	---------------------------------------------------

	declare @labelID int
	set @labelID = 0
	--
	SELECT @labelID = ID
	FROM T_Sample_Labelling
	WHERE (Label = @labelling)
	--
	if @labelID < 0
	begin
		set @msg = 'Could not find entry in database for labelling "' + @labelling + '"'
		RAISERROR (@msg, 10, 1)
		return 51038
	end
	
	---------------------------------------------------
	-- Resolve predigestion internal standard ID
	---------------------------------------------------

	declare @internalStandardID int
	set @internalStandardID = 0
	--
	SELECT @internalStandardID = Internal_Std_Mix_ID
	FROM T_Internal_Standards
	WHERE (Name = @internalStandard)
	--
	if @internalStandardID = 0
	begin
		set @msg = 'Could not find entry in database for predigestion internal standard "' + @internalStandard + '"'
		RAISERROR (@msg, 10, 1)
		return 51009
	end

	---------------------------------------------------
	-- Resolve postdigestion internal standard ID
	---------------------------------------------------
	-- 
	declare @postdigestIntStdID int
	set @postdigestIntStdID = 0
	--
	SELECT @postdigestIntStdID = Internal_Std_Mix_ID
	FROM T_Internal_Standards
	WHERE (Name = @postdigestIntStd)
	--
	if @postdigestIntStdID = 0
	begin
		set @msg = 'Could not find entry in database for postdigestion internal standard "' + @postdigestIntStdID + '"'
		RAISERROR (@msg, 10, 1)
		return 51009
	end

	---------------------------------------------------
	-- Resolve container name to ID
	---------------------------------------------------

	declare @contID int
	set @contID = 0
	--
	SELECT @contID = ID
	FROM         T_Material_Containers
	WHERE     (Tag = @container)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not resove container name "' + @container + '" to ID'
		RAISERROR (@msg, 10, 1)
		return 510019
	end

	---------------------------------------------------
	-- Resolve current container id to name
	---------------------------------------------------
	declare @curContainerName varchar(125)
	set @curContainerName = ''
	--
	SELECT @curContainerName = Tag 
	FROM T_Material_Containers 
	WHERE ID = @curContainerID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error resolving name of current container'
		RAISERROR (@msg, 10, 1)
		return 510027
	end

	---------------------------------------------------
	-- Resolve cell cultures
	---------------------------------------------------
	
	-- create tempoary table to hold names of cell cultures as input
	--
	create table #CC (
		name varchar(128) not null
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not create temporary table for cell culture list'
		RAISERROR (@msg, 10, 1)
		return 51078
	end

	-- get names of cell cultures from list argument into table
	--
	insert into #CC (name) 
	select item from MakeTableFromListDelim(@cellCultureList, ';')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not populate temporary table for cell culture list'
		RAISERROR (@msg, 10, 1)
		return 51079
	end
	
	-- verify that cell cultures exist
	--
	declare @cnt int
	set @cnt = -1
	SELECT @cnt = count(*) 
	FROM #CC 
	WHERE [name] not in (
		SELECT CC_Name
		FROM	T_Cell_Culture
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Was not able to check for cell cultures in database'
		RAISERROR (@msg, 10, 1)
		return 51080
	end
	--
	if @cnt <> 0 
	begin
		set @msg = 'One or more cell cultures was not in database'
		RAISERROR (@msg, 10, 1)
		return 51081	
	end

	declare @transName varchar(32)

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	
	if @Mode = 'add'
	begin

		-- Start transaction
		--
		set @transName = 'AddNewExperiment'
		begin transaction @transName

		INSERT INTO T_Experiments(
				Experiment_Num, 
				EX_researcher_PRN, 
				EX_organism_ID, 
				EX_reason, 
				EX_comment, 
				EX_created, 
				EX_sample_concentration, 
				EX_enzyme_ID, 
				EX_Labelling, 
				EX_lab_notebook_ref, 
				EX_campaign_ID,
				EX_cell_culture_list,
				EX_sample_prep_request_ID,
				EX_internal_standard_ID,
				EX_postdigest_internal_std_ID,
				EX_Container_ID,
				EX_wellplate_num, 
				EX_well_num 
			) VALUES (
				@experimentNum, 
				@researcherPRN, 
				@organismID, 
				@reason, 
				@comment, 
				GETDATE(), 
				@sampleConcentration, 
				@enzymeID,
				@labelling, 
				@labNotebookRef,
				@campaignID,
				@cellCultureList,
				@samplePrepRequest,
				@internalStandardID,
				@postdigestIntStdID,
				@contID,
				@wellplateNum,
				@wellNum

			)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @experimentNum + '"'
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return 51007
		end

		set @experimentID = IDENT_CURRENT('T_Experiments')

		declare @StateID int
		set @StateID = 1
		
		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 3, @experimentID, @StateID, @callingUser

		-- Add the cell cultures
		--
		execute @result = AddExperimentCellCulture
								@experimentID,
								@cellCultureList,
								@message output
		--
		if @result <> 0
		begin
			set @msg = 'Could not add experiment cell cultures to database for experiment: "' + @experimentNum + '" ' + @message
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return @result
		end

		--  material movement logging
		--	
		if @curContainerID != @contID
		begin
			exec PostMaterialLogEntry
				'Experiment Move',
				@experimentNum,
				'na',
				@container,
				@callingUser,
				'Experiment added'
		end

		-- we made it this far, commit
		--
		commit transaction @transName

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------

	if @Mode = 'update' 
	begin
		set @myError = 0

		-- Start transaction
		--
		set @transName = 'AddNewExperiment'
		begin transaction @transName

		UPDATE T_Experiments SET 
			EX_researcher_PRN = @researcherPRN, 
			EX_organism_ID = @organismID, 
			EX_reason = @reason, 
			EX_comment = @comment, 
			EX_sample_concentration = @sampleConcentration, 
			EX_enzyme_ID = @enzymeID,
			EX_Labelling = @labelling, 
			EX_lab_notebook_ref = @labNotebookRef, 
			EX_campaign_ID = @campaignID,
			EX_cell_culture_list = @cellCultureList,
			EX_sample_prep_request_ID = @samplePrepRequest,
			EX_internal_standard_ID = @internalStandardID,
			EX_postdigest_internal_std_ID = @postdigestIntStdID,
			EX_Container_ID = @contID,
			EX_wellplate_num = @wellplateNum, 
			EX_well_num = @wellNum
		WHERE 
			(Experiment_Num = @experimentNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @experimentNum + '"'
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return 51004
		end

		-- Add the cell cultures
		--
		execute @result = AddExperimentCellCulture
								@experimentID,
								@cellCultureList,
								@message output
		--
		if @result <> 0
		begin
			set @msg = 'Could not update experiment cell cultures to database for experiment: "' + @experimentNum + '" ' + @message
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return @result
		end

		--  material movement logging
		--	
		if @curContainerID != @contID
		begin
			exec PostMaterialLogEntry
				'Experiment Move',
				@experimentNum,
				@curContainerName,
				@container,
				@callingUser,
				'Experiment updated'
		end

		-- we made it this far, commit
		--
		commit transaction @transName

	end -- update mode

	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateExperiment] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperiment] TO [DMS2_SP_User]
GO
