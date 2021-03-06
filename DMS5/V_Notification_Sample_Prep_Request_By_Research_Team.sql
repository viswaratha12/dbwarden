/****** Object:  View [dbo].[V_Notification_Sample_Prep_Request_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_Sample_Prep_Request_By_Research_Team] AS
SELECT DISTINCT TNE.ID AS Seq,
                TET.Name AS Event,
                T_Sample_Prep_Request.ID AS Entity,
                T_Sample_Prep_Request.Request_Name AS Name,
                T.Campaign,
                T.[User],
                T.[Role],
                TNE.Entered,
                TET.Target_Entity_Type AS [#EntityType],
                T.[#PRN],
                TET.ID AS EventType,
                TNE.Event_Type AS EventTypeID,
                TET.Link_Template
FROM T_Notification_Event TNE
     INNER JOIN T_Notification_Event_Type AS TET
       ON TET.ID = TNE.Event_Type
     INNER JOIN T_Sample_Prep_Request
       ON TNE.Target_ID = T_Sample_Prep_Request.ID
     INNER JOIN T_Sample_Prep_Request_State_Name
       ON T_Sample_Prep_Request.State = T_Sample_Prep_Request_State_Name.State_ID
     INNER JOIN ( SELECT T_Campaign.Campaign_Num AS Campaign,
                         T_Users.U_Name AS [User],
                         dbo.GetResearchTeamUserRoleList(SRTM.Team_ID, SRTM.User_ID) AS [Role],
                         T_Users.U_PRN AS [#PRN]
                  FROM T_Campaign
                       INNER JOIN T_Research_Team
                         ON T_Campaign.CM_Research_Team = T_Research_Team.ID
                       INNER JOIN T_Research_Team_Membership AS SRTM
                         ON T_Research_Team.ID = SRTM.Team_ID
                       INNER JOIN T_Users
                         ON SRTM.User_ID = T_Users.ID
                       INNER JOIN T_Research_Team_Roles AS SRTR
                         ON SRTM.Role_ID = SRTR.ID
                  WHERE T_Campaign.CM_State = 'Active' AND
                        T_Users.U_active = 'Y' 
                ) AS T
       ON T.Campaign = T_Sample_Prep_Request.Campaign
WHERE TET.Target_Entity_Type = 3 AND
      TET.Visible = 'Y'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Sample_Prep_Request_By_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
