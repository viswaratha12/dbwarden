/****** Object:  View [dbo].[V_Historic_Log_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Historic_Log_Report
AS
SELECT Entry_ID AS Entry, posted_by AS [Posted By], 
   posting_time AS [Posting Time], type AS Type, 
   message AS Message, DBName AS [DB Name]
FROM T_Historic_Log_Entries

GO
