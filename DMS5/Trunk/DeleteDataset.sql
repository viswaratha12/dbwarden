/****** Object:  StoredProcedure [dbo].[DeleteDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DeleteDataset
/****************************************************
**
**	Desc: Deletes given dataset from the dataset table
**        and all referencing tables
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 1/26/2001
**            3/1/2004 grk added uncomsume scheduled run
**            4/7/2006 grk got rid of dataset list stuff
**		      4/7/2006 grk Got ride of CDBurn stuff
**    
*****************************************************/
(
	@datasetNum varchar(128),
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	declare @datasetID int
	declare @state int
	
	declare @result int

	---------------------------------------------------
	-- get datasetID and current state
	---------------------------------------------------
	declare @wellplateNum varchar(50)
	declare @wellNum varchar(50)

	SELECT  
		@state = DS_state_ID,
		@datasetID = Dataset_ID,
		@wellplateNum = DS_wellplate_num, 
		@wellNum = DS_well_num
	FROM T_Dataset 
	WHERE (Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not get Id or state for dataset "' + @datasetNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51140
	end

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteDataset'
	begin transaction @transName
--	print 'start transaction' -- debug only

	---------------------------------------------------
	-- delete any entries for the dataset from the archive table
	---------------------------------------------------

	DELETE FROM T_Dataset_Archive 
	WHERE (AS_Dataset_ID = @datasetID)
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from archive table was unsuccessful for dataset',
			10, 1)
		return 51131
	end

	---------------------------------------------------
	-- delete any entries for the dataset from the analysis job table
	---------------------------------------------------

	DELETE FROM T_Analysis_Job 
	WHERE (AJ_datasetID = @datasetID)	
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from analysis job table was unsuccessful for dataset',
			10, 1)
		return 51132
	end
	
	---------------------------------------------------
	-- delete any auxiliary info associated with dataset
	---------------------------------------------------
		
	exec @result = DeleteAuxInfo 'Dataset', @datasetNum, @message output

	if @result <> 0
	begin
		rollback transaction @transName
		set @msg = 'Delete auxiliary information was unsuccessful for dataset: ' + @message
		RAISERROR (@msg, 10, 1)
		return 51136
	end

	---------------------------------------------------
	-- restore any consumed requested runs
	---------------------------------------------------

	exec @result = UnconsumeScheduledRun @datasetID, @wellplateNum, @wellNum, @message output
	if @result <> 0
	begin
		rollback transaction @transName
		set @msg = 'Unconsume operation was unsuccessful for dataset: ' + @message
		RAISERROR (@msg, 10, 1)
		return 51103
	end
	
	---------------------------------------------------
	-- delete entry from dataset table
	---------------------------------------------------

    DELETE FROM T_Dataset
    WHERE Dataset_ID =  @datasetID

	if @@rowcount <> 1
	begin
		rollback transaction @transName
		RAISERROR ('Delete from dataset table was unsuccessful for dataset',
			10, 1)
		return 51136
	end
	

	commit transaction @transName
	
	return 0



GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_DS_Entry]
GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_Ops_Admin]
GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_SP_User]
GO
