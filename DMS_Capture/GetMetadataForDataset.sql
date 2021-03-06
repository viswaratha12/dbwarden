/****** Object:  StoredProcedure [dbo].[GetMetadataForDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMetadataForDataset]
/****************************************************
**
**	Desc:   Populate a temporary table with metadata for the given dataset
**
**  The calling procedure must create this temporary table:
**
**      CREATE TABLE #ParamTab
**      (
**          [Section] varchar(128),
**          [Name] varchar(128),
**          [Value] varchar(MAX)
**      )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/29/2009 grk - Initial release
**          11/03/2009 dac - Corrected name of dataset number column in global metadata
**          06/12/2018 mem - Now including Experiment_Labelling, Reporter_MZ_Min, and Reporter_MZ_Max
**    
*****************************************************/
(
    @datasetName varchar(128)
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Insert "global" metadata
    ---------------------------------------------------

    Declare @stepParmSectionName varchar(32) = 'Meta'

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Investigation', 'Proteomics')
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Instrument_Type', 'Mass spectrometer')

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_Number', @datasetName)

    ---------------------------------------------------
    -- Insert primary metadata for the dataset
    ---------------------------------------------------

    Declare @datasetCreated datetime
    Declare @instrumentName varchar(50)
    Declare @datasetComment varchar(500)
    Declare @datasetSecSep varchar(64)
    Declare @datasetWellNum varchar(64)
    Declare @experimentName varchar(64)
    Declare @experimentResearcherPRN varchar(64)
    Declare @organismName varchar(64)
    Declare @experimentComment varchar(500)
    Declare @experimentSampleConc varchar(64)
    Declare @experimentLabelling varchar(64)
    Declare @labellingReporterMzMin float
    Declare @labellingReporterMzMax float
    Declare @labNotebook varchar(64)
    Declare @campaignName varchar(64)
    Declare @campaignProject varchar(64)
    Declare @campaignComment varchar(500)
    Declare @campaignCreated datetime
    Declare @experimentReason varchar(500)
    Declare @cellCultureList varchar(500)

    --
    SELECT @datasetCreated = DS_created,
           @instrumentName = IN_name,
           @datasetComment = DS_comment,
           @datasetSecSep = DS_sec_sep,
           @datasetWellNum = DS_well_num,
           @experimentName = Experiment_Num,
           @experimentResearcherPRN = EX_researcher_PRN,
           @organismName = EX_organism_name,
           @experimentComment = EX_comment,
           @experimentSampleConc = EX_sample_concentration,
           @experimentLabelling = EX_Labelling,
           @labellingReporterMzMin = IsNull(Reporter_Mz_Min, 0),
           @labellingReporterMzMax = IsNull(Reporter_Mz_Max, 0),
           @labNotebook = EX_lab_notebook_ref,
           @campaignName = Campaign_Num,
           @campaignProject = CM_Project_Num,
           @campaignComment = CM_comment,
           @campaignCreated = CM_created,
           @experimentReason = EX_Reason,
           @cellCultureList = EX_cell_culture_list
    FROM V_DMS_Get_Dataset_Info
    WHERE Dataset_Num = @datasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        -- Dataset not found
        Return 20000
    End

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_created', @datasetCreated)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Instrument_name', @instrumentName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_comment', @datasetComment)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_sec_sep', @datasetSecSep)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_well_num', @datasetWellNum)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Num', @experimentName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_researcher_PRN', @experimentResearcherPRN)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Reason', @experimentReason)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Cell_Culture', @cellCultureList)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_organism_name', @organismName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_comment', @experimentComment)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_sample_concentration', @experimentSampleConc)
    
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_sample_labelling', @experimentLabelling)

    If @labellingReporterMzMin > 0
    Begin
        INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_labelling_reporter_mz_min', Cast(@labellingReporterMzMin As varchar(19)))
        INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_labelling_reporter_mz_max', Cast(@labellingReporterMzMax As varchar(19)))
    End

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_lab_notebook_ref', @labNotebook)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_Num', @campaignName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_Project_Num', @campaignProject)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_comment', @campaignComment)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_created', @campaignCreated)

    ---------------------------------------------------
    -- Insert auxiliary metadata for the dataset's experiment
    ---------------------------------------------------

    INSERT INTO #ParamTab ([Section], [Name], Value)  
    SELECT @stepParmSectionName AS [Section], 'Meta_Aux_Info:' + Target + ':' + Category + '.' + Subcategory + '.' + Item AS [Name], [Value]
    FROM V_DMS_Get_Experiment_Metadata
    WHERE Experiment_Num = @experimentName
    ORDER BY [Name]

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[GetMetadataForDataset] TO [DDL_Viewer] AS [dbo]
GO
