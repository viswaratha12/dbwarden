/****** Object:  View [dbo].[V_Bionet_Hosts_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_Hosts_Export]
AS
Select Host,
       IP,
       Alias,        
       Entered,
       Last_Online,
       Comment
       Instruments,
       Tag
FROM T_Bionet_Hosts
WHERE Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_Hosts_Export] TO [DDL_Viewer] AS [dbo]
GO
