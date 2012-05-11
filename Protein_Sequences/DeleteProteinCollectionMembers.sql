/****** Object:  StoredProcedure [dbo].[DeleteProteinCollectionMembers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE DeleteProteinCollectionMembers
/****************************************************
**
**	Desc: Deletes Protein Collection Member Entries from a given Protein Collection ID
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 10/07/2004
**    
*****************************************************/
(
	@Collection_ID int,
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
	
	declare @result int
	
	---------------------------------------------------
	-- Check if collection is OK to delete
	---------------------------------------------------
	
	declare @collectionState int
	
	SELECT @collectionState = Collection_State_ID
		FROM T_Protein_Collections
		WHERE Protein_Collection_ID = @Collection_ID
						
		declare @Collection_Name varchar(128)
		declare @State_Name varchar(64)
		
	SELECT @Collection_Name = FileName
		FROM T_Protein_Collections
		WHERE (Protein_Collection_ID = @Collection_ID)
	
	SELECT @State_Name = State
		FROM T_Protein_Collection_States
		WHERE (Collection_State_ID = @collectionState)					

	if @collectionState > 2	
	begin
		set @msg = 'Cannot Delete collection "' + @Collection_Name + '": ' + @State_Name + ' collections are protected'
		RAISERROR (@msg,10, 1)
			
		return 51140
	end
	
	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteProteinCollectionMembers'
	begin transaction @transName
--	print 'start transaction' -- debug only

	---------------------------------------------------
	-- delete any entries for the parameter file from the entries table
	---------------------------------------------------

	DELETE FROM T_Protein_Collection_Members 
	WHERE (Protein_Collection_ID = @Collection_ID)
	
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from entries table was unsuccessful for collection',
			10, 1)
		return 51130
	end
			
	commit transaction @transname
	
	return 0


GO
GRANT EXECUTE ON [dbo].[DeleteProteinCollectionMembers] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteProteinCollectionMembers] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO