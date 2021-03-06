/****** Object:  View [dbo].[V_EUS_Active_Proposal_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Active_Proposal_List_Report]
AS
SELECT P.Proposal_ID AS [Proposal ID],
       P.Title,
       P.Proposal_Type,
       dbo.GetProposalEUSUsersList(P.Proposal_ID, 'L', 100) AS [User Last Names]
FROM T_EUS_Proposals P
WHERE (State_ID IN (2, 5))

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Active_Proposal_List_Report] TO [DDL_Viewer] AS [dbo]
GO
