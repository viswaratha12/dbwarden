/****** Object:  Table [dbo].[T_MyEMSL_TestUploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MyEMSL_TestUploads](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Job] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[Subfolder] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FileCountNew] [int] NULL,
	[FileCountUpdated] [int] NULL,
	[Bytes] [bigint] NULL,
	[UploadTimeSeconds] [real] NULL,
	[StatusURI_PathID] [int] NULL,
	[ContentURI_PathID] [int] NULL,
	[StatusNum] [int] NULL,
	[Verified] [tinyint] NOT NULL,
	[Ingest_Steps_Completed] [tinyint] NULL,
	[ErrorCode] [int] NULL,
	[Entered] [datetime] NOT NULL,
	[EUS_InstrumentID] [int] NULL,
	[EUS_ProposalID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_UploaderID] [int] NULL,
 CONSTRAINT [PK_T_MyEMSL_TestUploads] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_MyEMSL_TestUploads] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_MyEMSL_TestUploads_Dataset_ID_include_StatusNum] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_TestUploads_Dataset_ID_include_StatusNum] ON [dbo].[T_MyEMSL_TestUploads]
(
	[Dataset_ID] ASC
)
INCLUDE([StatusNum]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_TestUploads_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_TestUploads_Entered] ON [dbo].[T_MyEMSL_TestUploads]
(
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_TestUploads_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_TestUploads_Job] ON [dbo].[T_MyEMSL_TestUploads]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_TestUploads_StatusNum_include_Entry_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_TestUploads_StatusNum_include_Entry_ID] ON [dbo].[T_MyEMSL_TestUploads]
(
	[StatusNum] ASC
)
INCLUDE([Entry_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_MyEMSL_TestUploads] ADD  CONSTRAINT [DF_T_MyEMSL_TestUploads_Verified]  DEFAULT ((0)) FOR [Verified]
GO
ALTER TABLE [dbo].[T_MyEMSL_TestUploads] ADD  CONSTRAINT [DF_T_MyEMSL_TestUploads_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_MyEMSL_TestUploads]  WITH CHECK ADD  CONSTRAINT [FK_T_MyEMSL_TestUploads_T_URI_Paths_ContentURI] FOREIGN KEY([ContentURI_PathID])
REFERENCES [dbo].[T_URI_Paths] ([URI_PathID])
GO
ALTER TABLE [dbo].[T_MyEMSL_TestUploads] CHECK CONSTRAINT [FK_T_MyEMSL_TestUploads_T_URI_Paths_ContentURI]
GO
ALTER TABLE [dbo].[T_MyEMSL_TestUploads]  WITH CHECK ADD  CONSTRAINT [FK_T_MyEMSL_TestUploads_T_URI_Paths_StatusURI] FOREIGN KEY([StatusURI_PathID])
REFERENCES [dbo].[T_URI_Paths] ([URI_PathID])
GO
ALTER TABLE [dbo].[T_MyEMSL_TestUploads] CHECK CONSTRAINT [FK_T_MyEMSL_TestUploads_T_URI_Paths_StatusURI]
GO
