/****** Object:  Table [dbo].[T_LC_Column] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Column](
	[SC_Column_Number] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_Packing_Mfg] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_LC_Column_SC_Packing_Mfg]  DEFAULT ('na'),
	[SC_Packing_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_Particle_size] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_Particle_type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_Column_Inner_Dia] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_Column_Outer_Dia] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_Length] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_State] [int] NOT NULL CONSTRAINT [DF_T_LC_Column_SC_State]  DEFAULT (0),
	[SC_Operator_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SC_Comment] [varchar](244) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SC_Created] [datetime] NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_T_LC_Column] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_LC_Column] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_LC_Column] ON [dbo].[T_LC_Column] 
(
	[SC_Column_Number] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_LC_Column]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Column_T_LC_Column_State_Name] FOREIGN KEY([SC_State])
REFERENCES [T_LC_Column_State_Name] ([LCS_ID])
GO
ALTER TABLE [dbo].[T_LC_Column] CHECK CONSTRAINT [FK_T_LC_Column_T_LC_Column_State_Name]
GO
ALTER TABLE [dbo].[T_LC_Column]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Column_T_Users] FOREIGN KEY([SC_Operator_PRN])
REFERENCES [T_Users] ([U_PRN])
GO
ALTER TABLE [dbo].[T_LC_Column] CHECK CONSTRAINT [FK_T_LC_Column_T_Users]
GO
