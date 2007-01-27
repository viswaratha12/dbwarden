/****** Object:  View [dbo].[V_Predefined_Analysis_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Predefined_Analysis_List_Report
AS
SELECT TOP 100 PERCENT PA.AD_ID AS ID, 
    PA.AD_instrumentClassCriteria AS [Instrument Class], 
    PA.AD_level AS [Level], PA.AD_sequence AS [Seq.], 
    PA.AD_nextLevel AS [Next Lvl.], 
    PA.AD_analysisToolName AS [Analysis Tool], 
    PA.AD_instrumentNameCriteria AS [Instrument Crit.], 
    PA.AD_organismNameCriteria AS [Organism Crit.], 
    PA.AD_campaignNameCriteria AS [Campaign Crit.], 
    PA.AD_experimentNameCriteria AS [Experiment Crit.], 
    PA.AD_labellingInclCriteria AS [ExpLabelingCrit.], 
    PA.AD_datasetNameCriteria AS [DatasetCrit.], 
    PA.AD_expCommentCriteria AS [ExpCommentCrit.], 
    PA.AD_parmFileName AS [Parm File], 
    PA.AD_settingsFileName AS [Settings File], 
    Org.OG_name AS Organism, 
    PA.AD_organismDBName AS [Organism DB], 
    PA.AD_proteinCollectionList AS [Prot. Coll. List], 
    PA.AD_proteinOptionsList AS [Prot. Opts. List], 
    PA.AD_priority AS priority
FROM T_Predefined_Analysis PA INNER JOIN
     T_Organisms Org ON PA.AD_organism_ID = Org.Organism_ID
WHERE (PA.AD_enabled > 0)
ORDER BY PA.AD_instrumentClassCriteria, PA.AD_level, 
    PA.AD_sequence, PA.AD_ID


GO
