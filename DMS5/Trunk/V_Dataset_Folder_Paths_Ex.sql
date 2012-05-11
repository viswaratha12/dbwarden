/****** Object:  View [dbo].[V_Dataset_Folder_Paths_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Folder_Paths_Ex]
AS
SELECT DFP.Dataset,
       DFP.Dataset_ID,
       DFP.Dataset_Folder_Path,
       DFP.Archive_Folder_Path,
       DFP.Dataset_URL,
       DFP.Instrument_Data_Purged,
       InstName.IN_Name AS Instrument,
       DS.DS_Created AS Dataset_Created,
       Convert(varchar(8), DatePart(YEAR, DS.DS_Created)) + '_' + Convert(varchar(4), DatePart(quarter, DS.DS_Created)) AS Dataset_YearQuarter
FROM dbo.T_Dataset DS
     INNER JOIN dbo.V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Folder_Paths_Ex] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Folder_Paths_Ex] TO [PNL\D3M580] AS [dbo]
GO
