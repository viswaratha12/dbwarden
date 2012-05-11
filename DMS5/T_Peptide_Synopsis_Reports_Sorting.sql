/****** Object:  Table [dbo].[T_Peptide_Synopsis_Reports_Sorting] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Peptide_Synopsis_Reports_Sorting](
	[Report_Sort_ID] [int] IDENTITY(1,1) NOT NULL,
	[Report_Sort_Value] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Report_Sort_Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Peptide_Synopsis_Reports_Sorting] PRIMARY KEY CLUSTERED 
(
	[Report_Sort_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO