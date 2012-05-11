/****** Object:  View [dbo].[V_Run_Tracking_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  VIEW V_Run_Tracking_List_Report  
AS                   
SELECT     DS.Dataset_ID AS ID, DS.Dataset_Num AS Dataset, DS.Acq_Time_Start AS Time_Start, DS.Acq_Time_End AS Time_End, DS.Acq_Length_Minutes AS Duration, 
                      DS.Interval_to_Next_DS AS Interval, T_Instrument_Name.IN_name AS Instrument, DSN.DSS_name AS State, DRN.DRN_name AS Rating, 
                      'C:' + LC.SC_Column_Number AS LC_Column, RR.ID AS Request, RR.RDS_WorkPackage AS Work_Package, RR.RDS_EUS_Proposal_ID AS EUS_Proposal, 
                      EUT.Name AS EUS_Usage, C.Campaign_ID, C.CM_Fraction_EMSL_Funded AS Fraction_EMSL_Funded, C.CM_EUS_Proposal_List AS Campaign_Proposals, 
                      DATEPART(YEAR, DS.Acq_Time_Start) AS Year, DATEPART(MONTH, DS.Acq_Time_Start) AS Month, DATEPART(DAY, DS.Acq_Time_Start) AS Day
FROM         T_Dataset AS DS INNER JOIN
                      T_Instrument_Name ON DS.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
                      T_Experiments AS E ON DS.Exp_ID = E.Exp_ID INNER JOIN
                      T_Campaign AS C ON E.EX_campaign_ID = C.Campaign_ID INNER JOIN
                      T_DatasetStateName AS DSN ON DS.DS_state_ID = DSN.Dataset_state_ID INNER JOIN
                      T_DatasetRatingName AS DRN ON DS.DS_rating = DRN.DRN_state_ID INNER JOIN
                      T_LC_Column AS LC ON DS.DS_LC_column_ID = LC.ID LEFT OUTER JOIN
                      T_Requested_Run AS RR ON DS.Dataset_ID = RR.DatasetID INNER JOIN
                      T_EUS_UsageType AS EUT ON RR.RDS_EUS_UsageType = EUT.ID
GO
