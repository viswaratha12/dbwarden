/****** Object:  View [dbo].[V_Helper_NEWT_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW [dbo].[V_Helper_NEWT_List_Report]
AS
	SELECT identifier,
		   Term_Name,
		   Parent_term_name AS Parent,
		   GrandParent_term_name AS GrandParent,
		   Is_Leaf
	FROM V_CV_NEWT


GO
