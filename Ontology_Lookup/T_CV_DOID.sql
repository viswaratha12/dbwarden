/****** Object:  Table [dbo].[T_CV_DOID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CV_DOID](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Term_PK] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Identifier] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Is_Leaf] [tinyint] NOT NULL,
	[Parent_term_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GrandParent_term_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GrandParent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_T_CV_DOID] PRIMARY KEY NONCLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_CV_DOID] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_DOID_Term_Name] ******/
CREATE CLUSTERED INDEX [IX_T_CV_DOID_Term_Name] ON [dbo].[T_CV_DOID]
(
	[Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_DOID_GrandParent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_DOID_GrandParent_Term_Name] ON [dbo].[T_CV_DOID]
(
	[GrandParent_term_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_DOID_Identifier] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_DOID_Identifier] ON [dbo].[T_CV_DOID]
(
	[Identifier] ASC
)
INCLUDE ( 	[Term_Name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_DOID_Parent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_DOID_Parent_Term_Name] ON [dbo].[T_CV_DOID]
(
	[Parent_term_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_CV_DOID] ADD  CONSTRAINT [DF_T_CV_DOID_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
