/****** Object:  View [dbo].[V_Find_Scheduled_Run_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Find_Scheduled_Run_History
AS
SELECT     dbo.T_Requested_Run_History.ID AS Request_ID, dbo.T_Requested_Run_History.RDS_Name AS Request_Name, 
                      dbo.T_Requested_Run_History.RDS_created AS Req_Created, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.DS_created, dbo.T_Requested_Run_History.RDS_WorkPackage AS Work_Package, 
                      dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Requested_Run_History.RDS_Oper_PRN AS Requestor, 
                      dbo.T_Requested_Run_History.RDS_instrument_name AS Instrument, dbo.T_DatasetTypeName.DST_name AS Run_Type, 
                      dbo.T_Requested_Run_History.RDS_comment AS Comment, dbo.T_Requested_Run_History.RDS_BatchID AS Batch, 
                      dbo.T_Requested_Run_History.RDS_Blocking_Factor AS Blocking_Factor
FROM         dbo.T_Requested_Run_History INNER JOIN
                      dbo.T_Dataset ON dbo.T_Requested_Run_History.DatasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_DatasetTypeName ON dbo.T_Requested_Run_History.RDS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run_History.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID


GO
