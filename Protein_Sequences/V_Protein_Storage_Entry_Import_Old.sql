/****** Object:  View [dbo].[V_Protein_Storage_Entry_Import_Old] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Storage_Entry_Import_Old
AS
SELECT     dbo.T_Protein_Names.Name, dbo.T_Protein_Names.Description, dbo.T_Proteins.Sequence, dbo.T_Proteins.Monoisotopic_Mass, 
                      dbo.T_Proteins.Average_Mass, dbo.T_Proteins.Length, dbo.T_Proteins.Molecular_Formula, dbo.T_Protein_Names.Annotation_Type_ID, 
                      dbo.T_Proteins.Protein_ID, dbo.T_Protein_Names.Reference_ID, dbo.T_Protein_Collection_Members.Protein_Collection_ID, 
                      dbo.T_Protein_Collections.Primary_Annotation_Type_ID, dbo.T_Proteins.SHA1_Hash, dbo.T_Protein_Collection_Members.Member_ID, 
                      dbo.T_Protein_Collection_Members.Sorting_Index
FROM         dbo.T_Annotation_Types INNER JOIN
                      dbo.T_Naming_Authorities ON dbo.T_Annotation_Types.Authority_ID = dbo.T_Naming_Authorities.Authority_ID INNER JOIN
                      dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Proteins ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Proteins.Protein_ID INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Protein_Names.Protein_ID AND 
                      dbo.T_Protein_Collection_Members.Original_Reference_ID = dbo.T_Protein_Names.Reference_ID INNER JOIN
                      dbo.T_Protein_Collections ON dbo.T_Protein_Collection_Members.Protein_Collection_ID = dbo.T_Protein_Collections.Protein_Collection_ID ON 
                      dbo.T_Annotation_Types.Annotation_Type_ID = dbo.T_Protein_Names.Annotation_Type_ID

GO
