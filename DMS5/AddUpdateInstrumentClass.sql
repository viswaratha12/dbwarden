/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentClass] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateInstrumentClass
/****************************************************
**
**	Desc: Adds new or updates existing Instrument Class in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@InstrumentClass      Instrument class
**		@isPurgable           Determines if the instrument class is purgable 
**		@rawDataType	      Specifies the raw data type for the instrument class
**		@requiresPreparation  Determines if the instrument class requires preparation
**	
**
**	Auth:	jds
**	Date:	07/06/2006
**			07/25/2007 mem - Added parameter @allowedDatasetTypes
**			09/17/2009 mem - Removed parameter @allowedDatasetTypes (Ticket #748)
**			06/21/2010 mem - Added parameter @Params
**			11/16/2010 mem - Added parameter @Comment
**    
*****************************************************/
(
	@InstrumentClass varchar(32), 
	@isPurgable varchar(1), 
	@rawDataType varchar(32), 
	@requiresPreparation varchar(1), 
	@Params text,
	@Comment varchar(255),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)

	declare @xmlParams xml

	set @xmlParams = @Params
	set @message = ''
	

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@InstrumentClass) < 1
	begin
		set @myError = 51000
		RAISERROR ('Instrument Class was blank',
			10, 1)
	end

	if LEN(@isPurgable) < 1
	begin
		set @myError = 51001
		RAISERROR ('Is Purgable was blank',
			10, 1)
	end
	--
	if LEN(@rawDataType) < 1
	begin
		set @myError = 51002
		RAISERROR ('Raw Data Type was blank',
			10, 1)
	end
	--
	if LEN(@requiresPreparation) < 1
	begin
		set @myError = 51003
		RAISERROR ('Requires Preparation was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

--	declare @tempInstrumentClass varchar(32)
--	set @tempInstrumentClass = ''
	--
--	execute @tempInstrumentClass = GetInstrumentClass @InstrumentClass

	-- cannot create an entry that already exists
	--
--	if @tempInstrumentClass <> '' and @mode = 'add'
--	begin
--		set @msg = 'Cannot add: Instrument Class "' + @InstrumentClass + '" already in database '
--		RAISERROR (@msg, 10, 1)
--		return 51004
--	end

	-- cannot update a non-existent entry
	--
--	if @tempInstrumentClass = '' and @mode = 'update'
--	begin
--		set @msg = 'Cannot update: Instrument Class "' + @InstrumentClass + '" is not in database '
--		RAISERROR (@msg, 10, 1)
--		return 51004
--	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Instrument_Class (
			IN_class,
			is_purgable,
			raw_data_type,
			requires_preparation,
			Params,
			Comment
		) VALUES (
			@InstrumentClass,
			@isPurgable,
			@rawDataType,
			@requiresPreparation,
			@xmlParams,
			@Comment
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @InstrumentClass + '"'
			RAISERROR (@msg, 15, 1)
			return 51007
		end
	end -- add mode



	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Instrument_Class
		SET 
			is_purgable = @isPurgable, 
			raw_data_type = @rawDataType, 
			requires_preparation = @requiresPreparation,
			Params = @xmlParams,
			Comment = @Comment
		WHERE (IN_class = @InstrumentClass)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @InstrumentClass + '"'
			RAISERROR (@msg, 15, 1)
			return 51004
		end
	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentClass] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentClass] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentClass] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentClass] TO [PNL\D3M580] AS [dbo]
GO