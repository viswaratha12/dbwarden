/****** Object:  Table [dbo].[T_Bionet_Hosts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Bionet_Hosts](
	[Host] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IP] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Alias] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [smalldatetime] NULL,
	[Last_Online] [smalldatetime] NULL,
	[Instruments] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NOT NULL,
	[Tag] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Bionet_Hosts] PRIMARY KEY CLUSTERED 
(
	[Host] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Bionet_Hosts] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Bionet_Hosts] ADD  CONSTRAINT [DF_T_Bionet_Hosts_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Bionet_Hosts] ADD  CONSTRAINT [DF_T_Bionet_Hosts_Active]  DEFAULT ((1)) FOR [Active]
GO
