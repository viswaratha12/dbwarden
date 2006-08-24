/****** Object:  Table [dbo].[T_EUS_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_Users](
	[PERSON_ID] [int] NOT NULL CONSTRAINT [DF__T_EUS_Use__PERSO__73901351]  DEFAULT ('0'),
	[NAME_FM] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__T_EUS_Use__NAME___7484378A]  DEFAULT (null),
	[Site_Status] [tinyint] NOT NULL CONSTRAINT [DF_T_EUS_Users_Stie_Status]  DEFAULT (2),
 CONSTRAINT [PK_T_EUS_Users] PRIMARY KEY CLUSTERED 
(
	[PERSON_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin]
GO
GRANT INSERT ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin]
GO
GRANT DELETE ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Users] ([PERSON_ID]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Users] ([PERSON_ID]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Users] ([NAME_FM]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Users] ([NAME_FM]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Users] ([Site_Status]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Users] ([Site_Status]) TO [DMS_EUS_Admin]
GO
ALTER TABLE [dbo].[T_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_EUS_Users_T_EUS_Site_Status] FOREIGN KEY([Site_Status])
REFERENCES [T_EUS_Site_Status] ([ID])
GO
