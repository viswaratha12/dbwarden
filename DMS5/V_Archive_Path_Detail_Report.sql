/****** Object:  View [dbo].[V_Archive_Path_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_Path_Detail_Report]
AS
SELECT TAP.AP_path_ID AS ID,
       TAP.AP_archive_path AS [Archive Path],
       TAP.AP_Server_Name AS [Archive Server],
       TAP.AP_network_share_path AS [Network Share Path],
       TIN.IN_name AS [Instrument Name],
       TAP.Note,
       TAP.AP_Function AS Status,
       TAP.AP_archive_URL AS [Archive URL]
FROM dbo.T_Archive_Path AS TAP
     INNER JOIN dbo.T_Instrument_Name AS TIN
       ON TAP.AP_instrument_name_ID = TIN.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
