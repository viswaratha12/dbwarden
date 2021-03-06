/****** Object:  StoredProcedure [dbo].[AddUpdateAnalysisJobProcessorGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddUpdateAnalysisJobProcessorGroup
/****************************************************
**
**  Desc: Adds new or edits existing T_Analysis_Job_Processor_Group
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
** Auth:	grk
** Date:	02/07/2007
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**    
**	Pacific Northwest National Laboratory, Richland, WA
**	Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@ID int output,
	@GroupName varchar(64),
	@GroupDescription varchar(512),
	@GroupEnabled char(1),
	@AvailableForGeneralProcessing char(1),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''


	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated


	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_Analysis_Job_Processor_Group
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
		begin
		set @message = 'No entry could be found in database for update'
		RAISERROR (@message, 10, 1)
		return 51007
		end
	end


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
			
		INSERT INTO T_Analysis_Job_Processor_Group (
			Group_Name, 
			Group_Description, 
			Group_Enabled, 
			Available_For_General_Processing
		) VALUES (
			@GroupName, 
			@GroupDescription, 
			@GroupEnabled, 
			@AvailableForGeneralProcessing
		)
		/**/
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		end

		-- return ID of newly created entry
		--
		set @ID = IDENT_CURRENT('T_Analysis_Job_Processor_Group')

		-- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processor_Group
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Analysis_Job_Processor_Group', 'ID', @ID, @CallingUser, @EntryDateColumnName='Last_Affected'
			
	 end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--

		UPDATE T_Analysis_Job_Processor_Group 
		SET 
		Group_Name = @GroupName, 
		Group_Description = @GroupDescription, 
		Group_Enabled = @GroupEnabled, 
		Available_For_General_Processing = @AvailableForGeneralProcessing
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		end
	
		-- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processor_Group
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Analysis_Job_Processor_Group', 'ID', @ID, @CallingUser, @EntryDateColumnName='Last_Affected'

	end -- update mode

	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJobProcessorGroup] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAnalysisJobProcessorGroup] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJobProcessorGroup] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJobProcessorGroup] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAnalysisJobProcessorGroup] TO [PNL\D3M580] AS [dbo]
GO
