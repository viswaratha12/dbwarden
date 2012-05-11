/****** Object:  View [dbo].[V_Pipeline_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Job_Parameters]
AS
SELECT J.Job,
       J.Script,
       J.Dataset,
       JobParams.Name AS Param_Name,
       JobParams.Value AS Param_Value
FROM T_Jobs J
     INNER JOIN T_Scripts S
       ON J.Script = S.Script
     INNER JOIN V_Job_Processing_Time JPT
       ON J.Job = JPT.Job
     CROSS Apply dbo.GetJobParamTableLocal(J.Job) JobParams


GO