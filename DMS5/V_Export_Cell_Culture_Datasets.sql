/****** Object:  View [dbo].[V_Export_Cell_Culture_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

                      
CREATE VIEW dbo.V_Export_Cell_Culture_Datasets
AS
SELECT DISTINCT T_Cell_Culture.CC_Name AS CellCulture, T_Cell_Culture.CC_ID AS CellCultureID, T_Dataset.Dataset_ID AS DatasetID
FROM         T_Cell_Culture INNER JOIN
                      T_Experiment_Cell_Cultures ON T_Cell_Culture.CC_ID = T_Experiment_Cell_Cultures.CC_ID INNER JOIN
                      T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID INNER JOIN
                      T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Export_Cell_Culture_Datasets] TO [DDL_Viewer] AS [dbo]
GO
