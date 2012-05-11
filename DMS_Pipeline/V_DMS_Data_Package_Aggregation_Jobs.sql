/****** Object:  View [dbo].[V_DMS_Data_Package_Aggregation_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_Data_Package_Aggregation_Jobs
AS
SELECT Data_Package_ID, Job, Tool, Dataset, ArchiveStoragePath, ServerStoragePath, 
       DatasetFolder, ResultsFolder, MAX(SharedResultsFolder) AS SharedResultsFolder,
       DatasetID, Organism, InstrumentName, InstrumentClass, Completed,
       ParameterFileName, SettingsFileName, OrganismDBName, ProteinCollectionList, ProteinOptions,
       ResultType, DS_created, PackageComment
FROM ( SELECT Src.Data_Package_ID,
              Src.Job,
              Src.Tool,
              Src.Dataset,
              Src.ArchiveStoragePath,
              Src.ServerStoragePath,
              Src.DatasetFolder,
              Src.ResultsFolder,
              ISNULL(JSH.Output_Folder_Name, '') AS SharedResultsFolder,
              Src.DatasetID,
              Src.Organism,
              Src.InstrumentName,
              Src.InstrumentClass,
              Src.Completed,
              Src.ParameterFileName,
              Src.SettingsFileName,
              Src.OrganismDBName,
              Src.ProteinCollectionList,
              Src.ProteinOptions,
              Src.ResultType,
              Src.DS_created,
              ISNULL(Src.PackageComment, '') AS PackageComment
       FROM dbo.S_Data_Package_Aggregation_Jobs Src
            LEFT OUTER JOIN S_Production_Pipeline_Job_Steps_History JSH
              ON Src.Job = JSH.Job AND
                 JSH.Most_Recent_Entry = 1 AND
                 JSH.Shared_Result_Version > 0 
     ) LookupQ
GROUP BY Data_Package_ID, Job, Tool, Dataset, ArchiveStoragePath, ServerStoragePath, 
         DatasetFolder, ResultsFolder, DatasetID, Organism, InstrumentName, InstrumentClass, Completed,
         ParameterFileName, SettingsFileName, OrganismDBName, ProteinCollectionList, ProteinOptions,
         ResultType, DS_created, PackageComment

GO