/****** Object:  View [dbo].[V_MyEMSL_Supplemental_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Supplemental_Metadata]
AS
SELECT TOP (1000) 
       DS.Dataset_ID AS dataset_id,
       DS.Dataset_Num AS dataset_name,
       E.Exp_ID AS experiment_id,
       E.Experiment_Num AS experiment_name,
       C.Campaign_ID AS campaign_id,
       C.Campaign_Num AS campaign_name,
       Org.Organism_ID AS organism_id,
       Org.OG_name AS organism_name,
       Org.NCBI_Taxonomy_ID AS ncbi_taxonomy_id,
       DS.Acq_Time_Start AS acquisition_time,
       DS.Acq_Length_Minutes AS acquisition_length,
       DS.Scan_Count AS number_of_scans,
       RR.RDS_Sec_Sep AS separation_type,
       DTN.DST_name AS dataset_type
FROM T_Campaign C
     INNER JOIN T_Experiments E
       ON C.Campaign_ID = E.EX_campaign_ID
     INNER JOIN T_Dataset DS
       ON E.Exp_ID = DS.Exp_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
ORDER BY DS.Dataset_ID DESC


GO