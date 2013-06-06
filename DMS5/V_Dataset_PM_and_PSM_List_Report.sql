/****** Object:  View [dbo].[V_Dataset_PM_and_PSM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_PM_and_PSM_List_Report] as
SELECT PM.Dataset_ID,
       PM.Dataset,
       PM.Instrument,
       ISNULL(-PM.PPM_Shift, QCM.MS1_5C) AS Mass_Error_PPM,
       CONVERT(decimal(9,2), QCM.XIC_FWHM_Q3) AS XIC_FWHM_Q3,
       DFP.Dataset_URL + 'QC/index.html' AS QC_Link,
       DTN.DST_name AS [Dataset Type],
       DS.DS_sec_sep AS [Separation Type],       
       PM.Task_ID AS PM_Task_ID,
       PM.Results_URL AS PM_Results_URL,
       PM.[AMTs 1pct FDR],
       PM.[AMTs 5pct FDR],
       PM.[AMTs 10pct FDR],
       PM.[AMTs 25pct FDR],
       PM.[AMTs 50pct FDR],
       PM.Task_Server AS PM_Server,
       PM.Task_Database AS PM_Database,
       PM.Comparison_Mass_Tag_Count,
       PM.Task_State_ID AS PM_Task_State_ID,
       PM.Tool_Name AS PM_Tool,
       PM.Task_Start AS PM_Start,
       PM.Ini_File_Name AS PM_Ini_File_Name,
       PSM.Job AS PSM_Job,
       PSM.State AS PSM_State,
       PSM.Tool AS PSM_Tool,
       PSM.Spectra_Searched,
       PSM.[Total PSMs MSGF],
       PSM.[Unique Peptides MSGF],
       PSM.[Unique Proteins MSGF],
       PSM.[Total PSMs FDR],
       PSM.[Unique Peptides FDR],
       PSM.[Unique Proteins FDR],
       PSM.[MSGF Threshold],
       PSM.[FDR Threshold (%)],
       PSM.Campaign,
       PSM.Experiment,
       PSM.[Parm File] AS PSM_Job_Param_File,
       PSM.Settings_File AS PSM_Job_Settings_File,
       PSM.Organism,
       PSM.[Organism DB] AS PSM_Job_Org_DB,
       PSM.[Protein Collection List] AS PSM_Job_Protein_Collection,
       PSM.[Comment] AS PSM_Job_Comment,
       PSM.Finished AS PSM_Job_Finished,
       PSM.Runtime AS PSM_Job_Runtime,
       PSM.[Job Request] AS PSM_Job_Request,
       PSM.[Results Folder Path],
       PSM.Rating AS DS_Rating,
       PM.[Acq Length] AS DS_Acq_Length,
       PM.Acq_Time_Start AS [Acq Start]
FROM V_MTS_PM_Results_List_Report PM
     INNER JOIN V_Dataset_Folder_Paths DFP 
       ON PM.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON PM.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_DatasetTypeName DTN 
       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN V_Dataset_QC_Metrics QCM
       ON PM.Dataset_ID = QCM.Dataset_ID
     LEFT OUTER JOIN V_Analysis_Job_PSM_List_Report PSM
       ON PSM.Dataset_ID = PM.Dataset_ID


GO
