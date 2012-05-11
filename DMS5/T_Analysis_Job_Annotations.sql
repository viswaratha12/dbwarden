/****** Object:  Table [dbo].[T_Analysis_Job_Annotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Annotations](
	[Job_ID] [int] NOT NULL,
	[Key_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Analysis_Job_Annotations] PRIMARY KEY CLUSTERED 
(
	[Job_ID] ASC,
	[Key_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Trigger [dbo].[trig_u_T_Analysis_Job_Annotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trig_u_T_Analysis_Job_Annotations] ON [dbo].[T_Analysis_Job_Annotations] 
FOR UPDATE
AS
/****************************************************
**
**	Desc: 
**		Updates the Entered and Entered_By fields if any of the fields are changed
**
**		Auth: mem
**		Date: 05/04/2007 (Ticket:431)
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	If Update(Job_ID) OR
	   Update(Key_Name) OR
	   Update(Value)
	Begin

		UPDATE T_Analysis_Job_Annotations
		SET Entered = GetDate(),
			Entered_By = SYSTEM_USER
		FROM T_Analysis_Job_Annotations EA INNER JOIN
			 inserted ON EA.Job_ID = inserted.Job_ID AND EA.Key_Name = inserted.Key_Name
	End


GO
GRANT DELETE ON [dbo].[T_Analysis_Job_Annotations] TO [DMS_Annotation_User] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Analysis_Job_Annotations] TO [DMS_Annotation_User] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Analysis_Job_Annotations] TO [DMS_Annotation_User] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Annotations] TO [DMS_Annotation_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Annotations] TO [DMS_Annotation_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Annotations_T_Analysis_Job] FOREIGN KEY([Job_ID])
REFERENCES [T_Analysis_Job] ([AJ_jobID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations] CHECK CONSTRAINT [FK_T_Analysis_Job_Annotations_T_Analysis_Job]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Annotations_T_Annotation_Keys] FOREIGN KEY([Key_Name])
REFERENCES [T_Annotation_Keys] ([Key_Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations] CHECK CONSTRAINT [FK_T_Analysis_Job_Annotations_T_Annotation_Keys]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations] ADD  CONSTRAINT [DF_T_Analysis_Job_Annotations_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations] ADD  CONSTRAINT [DF_T_Analysis_Job_Annotations_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO