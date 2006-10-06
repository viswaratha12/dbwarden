/****** Object:  View [dbo].[V_Requested_Run_Batch_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Requested_Run_Batch_Entry
AS
SELECT R.ID AS ID, R.Batch AS Name, R.Description AS Description, 
dbo.GetBatchRequestedRunList(R.ID) AS RequestedRunList, 
U.U_PRN AS OwnerPRN, R.Requested_Batch_Priority AS [RequestedBatchPriority],
R.Requested_Completion_Date AS [RequestedCompletionDate],
R.Justification_for_High_Priority AS [JustificationHighPriority],
R.Comment AS [Comment]
FROM T_Requested_Run_Batches R 
     JOIN T_Users U ON R.Owner = U.ID


GO
