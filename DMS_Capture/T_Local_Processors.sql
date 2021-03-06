/****** Object:  Table [dbo].[T_Local_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Local_Processors](
	[Processor_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Latest_Request] [datetime] NULL,
	[Manager_Version] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Local_Processors] PRIMARY KEY CLUSTERED 
(
	[Processor_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Local_Processors] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Local_Processors] ADD  CONSTRAINT [DF_T_Local_Processors_State]  DEFAULT ('E') FOR [State]
GO
ALTER TABLE [dbo].[T_Local_Processors]  WITH CHECK ADD  CONSTRAINT [FK_T_Local_Processors_T_Machines] FOREIGN KEY([Machine])
REFERENCES [dbo].[T_Machines] ([Machine])
GO
ALTER TABLE [dbo].[T_Local_Processors] CHECK CONSTRAINT [FK_T_Local_Processors_T_Machines]
GO
