/****** Object:  StoredProcedure [dbo].[DeleteDataPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteDataPackage]
/****************************************************
**
**  Desc:   Deletes the data package, including deleting rows in the associated tracking tables:
**            T_Data_Package_Analysis_Jobs
**            T_Data_Package_Datasets
**            T_Data_Package_Experiments
**            T_Data_Package_Biomaterial
**            T_Data_Package_EUS_Proposals
**
**            Use with caution!
**
**  Auth:   mem
**  Date:   04/08/2016 mem - Initial release
**          05/18/2016 mem - Log errors to T_Log_Entries
**          04/05/2019 mem - Log the data package ID, Name, first dataset, and last dataset associated with a data package
**                         - Change the default for @infoOnly to 1
**
*****************************************************/
(
    @packageID int,
    @message varchar(512) = '' output,
    @infoOnly tinyint = 1
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @dataPackageName varchar(128)

    Declare @datasetOrExperiment varchar(64) = ''
    Declare @datasetOrExperimentCount int = 0

    Declare @firstDatasetOrExperiment varchar(128)
    Declare @lastDatasetOrExperiment varchar(128)

    Declare @logMessage varchar(1024)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 1)

    BEGIN TRY 

        If Not Exists (SELECT * FROM T_Data_Package WHERE ID = @packageID)
        Begin
            Set @message = 'Data package ' + Cast(@packageID as varchar(9)) + ' not found in T_Data_Package'
            If @infoOnly <> 0
                Select @message AS Warning
            Else            
                Print @message
        End
        Else
        Begin
            If @infoOnly <> 0
            Begin
                ---------------------------------------------------
                -- Preview the data package to be deleted
                ---------------------------------------------------
                --
                SELECT [ID],
                       [Name],
                       [Package Type],
                       [Biomaterial Item Count],
                       [Experiment Item Count],
                       [EUS Proposals Count],
                       [Dataset Item Count],
                       [Analysis Job Item Count],
                       [Campaign Count],
                       [Total Item Count],
                       [State],
                       [Share Path],
                       [Description],
                       [Comment],
                       [Owner],
                       Requester,
                       Created,
                       [Last Modified]
                FROM V_Data_Package_Detail_Report
                WHERE ID = @packageID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                
            End
            Else
            Begin

                ---------------------------------------------------
                -- Lookup the data package name
                ---------------------------------------------------
                --
                SELECT @dataPackageName = [Name]
                FROM T_Data_Package 
                WHERE ID = @packageID

                ---------------------------------------------------
                -- Find the first and last dataset in the data package
                ---------------------------------------------------
                --
                SELECT @firstDatasetOrExperiment = Min(Dataset),
                       @lastDatasetOrExperiment = Max(Dataset),
                       @datasetOrExperimentCount = Count(*)
                FROM T_Data_Package_Datasets
                WHERE Data_Package_ID = @packageID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                Begin
                    Set @datasetOrExperiment = 'Datasets'
                End
                Else
                Begin
                    SELECT @firstDatasetOrExperiment = Min(Experiment),
                           @lastDatasetOrExperiment = Max(Experiment),
                           @datasetOrExperimentCount = Count(*)
                    FROM T_Data_Package_Experiments
                    WHERE Data_Package_ID = @packageID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                    Begin
                        Set @datasetOrExperiment = 'Experiments'
                    End
                End

                ---------------------------------------------------
                -- Lookup the share path on Protoapps
                ---------------------------------------------------
                --
                Declare @sharePath varchar(1024) = ''
            
                SELECT @sharePath = Share_Path
                FROM V_Data_Package_Paths
                WHERE ID = @packageID

                Begin Tran
                
                ---------------------------------------------------
                -- Delete the associated items
                ---------------------------------------------------
                --
                exec DeleteAllItemsFromDataPackage @packageID=@packageID, @mode='delete', @message=@message output
                
                If @message <> ''
                Begin
                    Print @message
                    Set @message = ''
                End
                
                DELETE FROM T_Data_Package
                WHERE ID = @packageID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                
                If @myRowCount = 0
                    Set @message = 'No rows were deleted from T_Data_Package for data package ' + Cast(@packageID as varchar(9)) + '; this is unexpected'                    
                Else
                    set @message = 'Deleted data package ' + Cast(@packageID as varchar(9)) + ' and all associated metadata'    
                

                -- Log the deletion
                -- First append the data package name
                Set @logMessage = @message + ': ' + @dataPackageName

                If @datasetOrExperimentCount > 0
                Begin
                    -- Next append the dataset or experiment names
                    Set @logMessage = @logMessage + 
                            '; Included ' + Cast(@datasetOrExperimentCount As Varchar(12)) + ' ' + @datasetOrExperiment + ': ' + 
                            IsNull(@firstDatasetOrExperiment, '') + ' - ' + IsNull(@lastDatasetOrExperiment, '')
                End
                
                Exec PostLogEntry 'Normal', @logMessage, 'DeleteDataPackage'                        

                Commit

                ---------------------------------------------------
                -- Display some messages
                ---------------------------------------------------
                --

                Print @message
                Print ''
                Print 'Be sure to delete directory ' + @sharePath
                
            End
        End
        
    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        Declare @msgForLog varchar(512) = ERROR_MESSAGE()
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
        
        Exec PostLogEntry 'Error', @msgForLog, 'DeleteDataPackage'
    END CATCH
    
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
Done:
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[DeleteDataPackage] TO [DDL_Viewer] AS [dbo]
GO
