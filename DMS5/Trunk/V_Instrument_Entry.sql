/****** Object:  View [dbo].[V_Instrument_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Entry]
AS
SELECT Instrument_ID AS ID,
       IN_name AS InstrumentName,
       IN_Description AS Description,
       IN_class AS InstrumentClass,
       IN_group AS InstrumentGroup,
       IN_Room_Number AS RoomNumber,
       IN_capture_method AS CaptureMethod,
       RTRIM(IN_status) AS Status,
       IN_usage AS USAGE,
       IN_operations_role AS OperationsRole,
       IN_source_path_ID AS SourcePathID,
       IN_storage_path_ID AS StoragePathID
FROM dbo.T_Instrument_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Entry] TO [PNL\D3M580] AS [dbo]
GO
