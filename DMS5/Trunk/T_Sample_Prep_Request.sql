/****** Object:  Table [dbo].[T_Sample_Prep_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Prep_Request](
	[Request_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requester_PRN] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reason] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cell_Culture_List] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Biohazard_Level] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Campaign] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Number_of_Samples] [int] NULL,
	[Sample_Name_List] [varchar](1500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Prep_Method] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Prep_By_Robot] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Special_Instructions] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Naming_Convention] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Assigned_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Work_Package_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[User_Proposal_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Replicates_of_Samples] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Technical_Replicates] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Analysis_Specifications] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Priority] [tinyint] NULL,
	[Created] [datetime] NOT NULL,
	[State] [tinyint] NOT NULL,
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Requested_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StateChanged] [datetime] NOT NULL,
	[UseSingleLCColumn] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Internal_standard_ID] [int] NOT NULL,
	[Postdigest_internal_std_ID] [int] NOT NULL,
	[Estimated_Completion] [datetime] NULL,
	[Estimated_MS_runs] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_UsageType] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_User_List] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Project_Number] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Facility] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Separation_Type] [varchar](1200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Sample_Prep_Request] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Sample_Prep_Request] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Sample_Prep_Request] ON [dbo].[T_Sample_Prep_Request] 
(
	[Request_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_Sample_Prep_Req] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Trigger [dbo].[trig_d_Sample_Prep_Req] on [dbo].[T_Sample_Prep_Request]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Sample_Prep_Request_Updates for the deleted sample prep request
**
**	Auth:	mem
**	Date:	05/16/2008
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Sample_Prep_Request_Updates for each entry deleted from T_Sample_Prep_Request
	INSERT INTO T_Sample_Prep_Request_Updates (
			Request_ID, 
			System_Account, 
			Beginning_State_ID, 
			End_State_ID)
	SELECT 	deleted.ID, 
		   	REPLACE (SUSER_SNAME() , 'pnl\' , '' ) + '; ' + ISNULL(deleted.Request_Name, 'Unknown Request'),
			deleted.state,
			0 AS End_State_ID
	FROM deleted
	ORDER BY deleted.ID

GO
/****** Object:  Trigger [dbo].[trig_i_Sample_Prep_Req] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Trigger [dbo].[trig_i_Sample_Prep_Req] on [dbo].[T_Sample_Prep_Request]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Sample_Prep_Request_Updates for the new sample prep request
**
**	Auth:	mem
**	Date:	05/16/2008
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Sample_Prep_Request_Updates (
			Request_ID, 
			System_Account, 
			Beginning_State_ID, 
			End_State_ID)
	SELECT 	inserted.ID, 
		   	REPLACE (SUSER_SNAME() , 'pnl\' , '' ),
			0,
			inserted.state
	FROM inserted
	ORDER BY inserted.ID

GO
/****** Object:  Trigger [dbo].[trig_u_Sample_Prep_Req] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Sample_Prep_Req] on [dbo].[T_Sample_Prep_Request]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Sample_Prep_Request_Updates for the updated sample prep request
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			05/16/2008 mem - Fixed bug that was inserting the Beginning_State_ID and End_State_ID values backward
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Sample_Prep_Request_Updates (
			Request_ID, 
			System_Account, 
			Beginning_State_ID, 
			End_State_ID)
	SELECT 	inserted.ID, 
		   	REPLACE (SUSER_SNAME() , 'pnl\' , '' ),
			deleted.state,
			inserted.state
	FROM deleted INNER JOIN inserted ON deleted.ID = inserted.ID
	ORDER BY inserted.ID


GO
GRANT DELETE ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_EUS_Proposals] FOREIGN KEY([EUS_Proposal_ID])
REFERENCES [T_EUS_Proposals] ([PROPOSAL_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_EUS_Proposals]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards] FOREIGN KEY([Internal_standard_ID])
REFERENCES [T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards1] FOREIGN KEY([Postdigest_internal_std_ID])
REFERENCES [T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards1]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_State_Name] FOREIGN KEY([State])
REFERENCES [T_Sample_Prep_Request_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_State_Name]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [CK_T_Sample_Prep_Request_SamplePrepRequestName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Request_Name],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [CK_T_Sample_Prep_Request_SamplePrepRequestName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_State]  DEFAULT (1) FOR [State]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_StateChanged]  DEFAULT (getdate()) FOR [StateChanged]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_UseSingleLCColumn]  DEFAULT ('No') FOR [UseSingleLCColumn]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Internal_standard_ID]  DEFAULT (0) FOR [Internal_standard_ID]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Postdigest_internal_std_ID]  DEFAULT (0) FOR [Postdigest_internal_std_ID]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Factility]  DEFAULT ('EMSL') FOR [Facility]
GO
