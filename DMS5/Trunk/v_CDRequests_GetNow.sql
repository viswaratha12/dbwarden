/****** Object:  View [dbo].[v_CDRequests_GetNow] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO






CREATE VIEW dbo.v_CDRequests_GetNow
AS
SELECT v_CDRequests_GetAllNew.*
FROM v_CDRequests_GetAllNew
WHERE (CDB_schedule = 'Now')
GO
