/****** Object:  StoredProcedure [dbo].[GetDatasetTypeID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure GetDatasetTypeID
/****************************************************
**
**	Desc: Gets DatasetTypeID for given for given dataset type name
**
**	Return values: 0: failure, otherwise, campaign ID
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	01/26/2001
**			09/02/2010 mem - expanded @datasetType to varchar(50)
**    
*****************************************************/
(
	@datasetType varchar(50) = ''
)
As
	declare @datasetTypeID int
	set @datasetTypeID = 0
	
	SELECT @datasetTypeID = DST_Type_ID 
	FROM T_DatasetTypeName 
	WHERE (DST_name = @datasetType)
	
	return(@datasetTypeID)
	

GO
GRANT EXECUTE ON [dbo].[GetDatasetTypeID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetTypeID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetTypeID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetTypeID] TO [PNL\D3M580] AS [dbo]
GO