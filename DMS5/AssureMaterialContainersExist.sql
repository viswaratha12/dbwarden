/****** Object:  StoredProcedure [dbo].[AssureMaterialContainersExist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AssureMaterialContainersExist
/****************************************************
**
**  Desc: 
**  Accepts mixed list of locations and containers,
**  makes new containers for locations, and returns
**  consolidated list
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**			04/27/2010 grk - initial release
**			09/23/2011 grk - accomodate researcher field in AddUpdateMaterialContainer
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
(
	@ContainerList varchar(1024) OUTPUT,
	@Comment varchar(1024),
	@Type varchar(32) = 'Box',
	@Researcher VARCHAR(128),
	@mode varchar(12) = 'verify_only', -- or 'create'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
AS
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	DECLARE @msg VARCHAR(512)
	set @msg = ''

	BEGIN TRY

	---------------------------------------------------
	-- get container list items into temp table
	---------------------------------------------------
	--
	CREATE TABLE #TL (
		Container VARCHAR(64) NULL,
		Item VARCHAR(256),
		IsContainer TINYINT null,
		IsLocation TINYINT null
	)
	--
	INSERT INTO #TL (Item, IsContainer, IsLocation)
	SELECT Item, 0, 0 FROM dbo.MakeTableFromList(@ContainerList)
	
	---------------------------------------------------
	-- mark list items as either container or location
	---------------------------------------------------
	--
	UPDATE #TL
	SET IsContainer = 1, Container = Item
	FROM 
	#TL INNER JOIN 
	T_Material_Containers ON Item = Tag
	
	UPDATE #TL 
	SET IsLocation = 1 
	FROM 
	#TL INNER JOIN 
	T_Material_Locations ON Item = Tag

--SELECT CONVERT(VARCHAR(10), IsContainer) AS C, CONVERT(VARCHAR(10), IsLocation) AS L, CONVERT(VARCHAR(32), Item) AS Item, Container FROM #TL

	---------------------------------------------------
	-- quick check of list
	---------------------------------------------------
	--
	DECLARE @s VARCHAR(MAX)
	SET @s = ''
	SELECT @s = @s + CASE WHEN @s <> '' THEN ', ' ELSE '' END + Item  FROM #TL WHERE IsLocation = 0 AND IsContainer = 0
	--
	IF @s <> ''
	BEGIN 
		RAISERROR('Item(s) "%s" is/are not containers or locations', 11, 14, @s)
	END 
	
	IF @mode = 'verify_only'
		RETURN @myError

	---------------------------------------------------
	-- make new containers for locations
	---------------------------------------------------
	--
	DECLARE @item VARCHAR(64)
	DECLARE @Container varchar(128)
	--
	DECLARE @done tinyint
	SET @done = 0
	WHILE @done = 0
	BEGIN 
		SET @item = ''
		SELECT @item = Item FROM #TL WHERE IsLocation > 0
		
		IF @item = ''
			SET @done = 1
		ELSE 
		BEGIN
			/**/
			SET @Container = '(generate name)'
			EXEC @myError = AddUpdateMaterialContainer
								@Container = @container output,
								@Type = @Type,
								@Location = @item, 
								@Comment = @Comment,
								@Barcode = '',
								@Researcher = @Researcher,
								@mode = 'add',
								@message = @msg output, 
								@callingUser = @callingUser
			--
			IF @myError <> 0
				RAISERROR('AddUpdateMaterialContainer: %s', 11, 21, @msg)
			
						
			UPDATE #TL
			SET Container = @Container, IsContainer = 1, IsLocation = 0
			WHERE Item = @item
		END 
	END 

	---------------------------------------------------
	-- make consolidated list of containers
	---------------------------------------------------
	--
	SET @s = ''
	SELECT @s = @s + CASE WHEN @s <> '' THEN ', ' ELSE '' END  + Container  FROM #TL WHERE NOT Container IS NULL 
	SET @ContainerList = @s

	END TRY 
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
--		IF (XACT_STATE()) <> 0
--			ROLLBACK TRANSACTION;

		Exec PostLogEntry 'Error', @message, 'AssureMaterialContainersExist'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AssureMaterialContainersExist] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AssureMaterialContainersExist] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AssureMaterialContainersExist] TO [Limited_Table_Write] AS [dbo]
GO
