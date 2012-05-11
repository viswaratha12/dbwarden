/****** Object:  View [dbo].[V_Instrument_Usage_Report_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Instrument_Usage_Report_Entry AS 
 SELECT 
	EMSL_Inst_ID AS EMSLInstID,
	Instrument AS Instrument,
	Type AS Type,
	Start AS Start,
	Minutes AS Minutes,
	Proposal AS Proposal,
	Usage AS Usage,
	Users AS Users,
	Operator AS Operator,
	Comment AS Comment,
	Year AS Year,
	Month AS Month,
	ID AS ID,
	Seq AS Seq
FROM T_EMSL_Instrument_Usage_Report


GO