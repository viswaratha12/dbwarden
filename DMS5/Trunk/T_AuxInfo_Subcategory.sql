/****** Object:  Table [dbo].[T_AuxInfo_Subcategory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Subcategory](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Parent_ID] [int] NULL,
	[Sequence] [tinyint] NOT NULL CONSTRAINT [DF_T_AuxInfo_Subcategory_Sequence]  DEFAULT (0),
 CONSTRAINT [PK_T_AuxInfo_Subcategory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_AuxInfo_Subcategory]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Subcategory_T_AuxInfo_Category] FOREIGN KEY([Parent_ID])
REFERENCES [T_AuxInfo_Category] ([ID])
GO
