/****** Object:  View [dbo].[V_DMS_Data_Package_Aggregation_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Data_Package_Aggregation_Jobs]
AS
SELECT TPJ.Data_Package_ID,
       AJ.AJ_jobID AS Job,
       AnalysisTool.AJT_toolName AS Tool,
       DS.Dataset_Num AS Dataset,
       DSArch.Archive_Path + '\' AS ArchiveStoragePath,
       dbo.udfCombinePaths(SP.SP_vol_name_client, SP.SP_path) AS ServerStoragePath,
       DS.DS_folder_name AS DatasetFolder,
       AJ.AJ_resultsFolderName AS ResultsFolder,
       AJ.AJ_datasetID AS DatasetID,
       Org.Name AS Organism,
       InstName.IN_name AS InstrumentName,
       InstName.IN_Group as InstrumentGroup,
       InstName.IN_class AS InstrumentClass,
       AJ.AJ_finish AS Completed,
       AJ.AJ_parmFileName AS ParameterFileName,
       AJ.AJ_settingsFileName AS SettingsFileName,
       AJ.AJ_organismDBName AS OrganismDBName,
       AJ.AJ_proteinCollectionList AS ProteinCollectionList,
       AJ.AJ_proteinOptionsList AS ProteinOptions,
       AnalysisTool.AJT_resultType AS ResultType,
       DS.DS_created,
       TPJ.[Package Comment] AS PackageComment,
       InstClass.raw_data_type as RawDataType,
       E.Experiment_Num AS Experiment,
       E.EX_reason AS Experiment_Reason,
       E.EX_comment AS Experiment_Comment,
       Org.NEWT_ID AS Experiment_NEWT_ID,
       Org.NEWT_Name AS Experiment_NEWT_Name
FROM S_Analysis_Job AS AJ
     INNER JOIN S_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN S_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN S_Instrument_Class AS InstClass 
       ON InstName.IN_class = InstClass.IN_class
     INNER JOIN S_Storage_Path AS SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
     INNER JOIN S_Experiment_List AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN S_Analysis_Tool AS AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN S_Campaign_List AS Campaign
       ON E.EX_campaign_ID = Campaign.Campaign_ID
     INNER JOIN S_V_Organism AS Org
       ON E.EX_organism_ID = Org.Organism_ID     
     INNER JOIN S_V_Dataset_Archive_Path AS DSArch
       ON DS.Dataset_ID = DSArch.Dataset_ID
     INNER JOIN dbo.T_Data_Package_Analysis_Jobs AS TPJ
       ON TPJ.Job = AJ.AJ_jobID


GO
