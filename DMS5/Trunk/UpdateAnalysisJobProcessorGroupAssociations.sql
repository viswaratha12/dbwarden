/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobProcessorGroupAssociations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateAnalysisJobProcessorGroupAssociations
/****************************************************
**
**	Desc:
**   Sets jobs in the job list to be associated with the given 
**   analysis job processor group
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 02/15/2007 Ticket #386
**            02/20/2007 grk - fixed references to "Group" column in associations table
**                       grk - 'add' mode removes association with any other groups
**    
*****************************************************/
    @JobList varchar(6000),
    @processorGroupID varchar(32),
    @newValue varchar(64),  -- ignore for now, may need in future
    @mode varchar(12) = '', -- 'add', 'replace', 'remove'
    @message varchar(512) output
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	declare @list varchar(1024)

	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @JobList = ''
	begin
		set @message = 'Job list is empty'
		RAISERROR (@message, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- resolve processor group ID
	---------------------------------------------------
	declare @gid int
	set @gid = CAST(@processorGroupID as int)
	--
/*
	SELECT @gid = ID
	FROM T_Analysis_Job_Processor_Group
	WHERE (Group_Name = @processorGroupName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking up processor group name'
		return @myError
	end
	--
	if @gid = 0
	begin
		set @myError = 5
		set @message = 'Processor group could not be found'
		return @myError
	end
*/
	---------------------------------------------------
	--  Create temporary table to hold list of jobs
	---------------------------------------------------
 
 	CREATE TABLE #TAJ (
		Job int
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary job table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Populate table from job list  
	---------------------------------------------------

	INSERT INTO #TAJ
	(Job)
	SELECT Item
	FROM MakeTableFromList(@JobList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary job table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Verify that all jobs exist 
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN cast(Job as varchar(12))
		ELSE ', ' + cast(Job as varchar(12))
		END
	FROM
		#TAJ
	WHERE 
		NOT Job IN (SELECT AJ_jobID FROM T_Analysis_Job)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking job existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following jobs from list were not in database:"' + @list + '"'
		return 51007
	end
	
	declare @jobCount int
	SELECT @jobCount = count(*) FROM #TAJ
	set @message = 'Number of affected jobs:' + cast(@jobCount as varchar(12))

	---------------------------------------------------
	-- get rid of existing associations if we are
	-- replacing them with jobs in list
	---------------------------------------------------
	--
	if @mode = 'replace'
	begin
		DELETE FROM T_Analysis_Job_Processor_Group_Associations
		WHERE (Group_ID = @gid)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error deleting existing group associations'
			return @myError
		end
	end

	---------------------------------------------------
	-- remove selected jobs from associations
	---------------------------------------------------
	if @mode = 'remove' or @mode = 'add'
	begin
		DELETE FROM T_Analysis_Job_Processor_Group_Associations
		WHERE
			Job_ID IN (SELECT Job FROM #TAJ) 
			-- AND Group_ID = @gid  -- will need this in future if multiple associations allowed per job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error removing selected jobs from association'
			return @myError
		end
	end

	---------------------------------------------------
	-- add associations for new jobs to list
	---------------------------------------------------
	--
	if @mode = 'replace' or @mode = 'add'
	begin
		INSERT INTO T_Analysis_Job_Processor_Group_Associations
			(Job_ID, Group_ID)
		SELECT Job, @gid
		FROM #TAJ
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error adding new associations'
			return @myError
		end
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------

	return @myError
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobProcessorGroupAssociations] TO [DMS_Analysis]
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobProcessorGroupAssociations] TO [DMS2_SP_User]
GO
