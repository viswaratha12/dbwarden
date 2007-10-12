/****** Object:  Table [dbo].[T_AuxInfo_Target] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Target](
	[ID] [int] IDENTITY(500,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_Table] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_ID_Col] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_Name_Col] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_AuxInfo_Target] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO
