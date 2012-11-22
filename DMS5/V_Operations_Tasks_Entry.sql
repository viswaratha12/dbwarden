/****** Object:  View [dbo].[V_Operations_Tasks_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_Entry] AS 
SELECT  ID ,
        Tab ,
        Requestor ,
        Requested_Personal AS RequestedPersonal ,
        Assigned_Personal AS AssignedPersonal ,
        Description ,
        Comments ,
        Status ,
        Priority ,
        Work_Package ,
        Created
FROM    T_Operations_Tasks


GO
