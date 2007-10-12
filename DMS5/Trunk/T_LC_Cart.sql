/****** Object:  Table [dbo].[T_LC_Cart] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[Cart_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Cart_State_ID] [int] NOT NULL CONSTRAINT [DF_T_LC_Cart_Cart_State_ID]  DEFAULT (2),
	[Cart_Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_LC_Cart] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_LC_Cart] UNIQUE NONCLUSTERED 
(
	[Cart_Name] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_LC_Cart]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_T_LC_Cart_State] FOREIGN KEY([Cart_State_ID])
REFERENCES [T_LC_Cart_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart] CHECK CONSTRAINT [FK_T_LC_Cart_T_LC_Cart_State]
GO
