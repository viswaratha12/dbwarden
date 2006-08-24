/****** Object:  View [dbo].[V_Req_Run_Instrument_Picklist_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Req_Run_Instrument_Picklist_Ex
AS
SELECT     IN_name AS val, '' AS ex
FROM         T_Instrument_Name
WHERE     (NOT (IN_name LIKE 'SW_%')) AND (IN_status = 'active')
UNION
SELECT     'LCQ' AS val, '' AS ex

GO
