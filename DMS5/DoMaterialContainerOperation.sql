/****** Object:  StoredProcedure [dbo].[DoMaterialContainerOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[DoMaterialContainerOperation]
/****************************************************
**
**  Desc: Do an operation on a container, using the container name
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          10/01/2009 mem - Expanded error message
**          08/19/2010 grk - try-catch for error handling
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Prevent updating containers of type 'na'
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
    @name varchar(128),                 -- Container name
    @mode varchar(32),                  -- 'move_container', 'retire_container', 'retire_container_and_contents', 'unretire_container'
    @message varchar(512) output,
    @callingUser varchar (128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    set @message = ''
    Declare @msg varchar(512) = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'DoMaterialContainerOperation', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    BEGIN TRY 

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @name = Ltrim(Rtrim(IsNull(@name, '')))
    Set @mode = Ltrim(Rtrim(IsNull(@mode, '')))

    If Len(@name) = 0
    Begin
        set @msg = 'Container name cannot be empty'
        RAISERROR (@msg, 11, 1)
    End

    If Exists (Select * From V_Material_Containers_List_Report Where Container = @name And [Type] = 'na')
    Begin
        set @msg = 'Container "' + @name + '" cannot be updated by the website; contact a DMS admin (see DoMaterialContainerOperation)'
        RAISERROR (@msg, 11, 1)
    End

    Declare @tmpID int = 0
    --
    SELECT @tmpID = ID
    FROM T_Material_Containers
    WHERE Tag = @name
    --
    if @tmpID = 0
    begin
        set @msg = 'Could not find the container named "' + @name + '" (mode is ' + @mode + ')'
        RAISERROR (@msg, 11, 1)
    end
    else
    begin
        Declare @iMode varchar(32) = @mode
        Declare @containerList varchar(4096) = @tmpID
        Declare @newValue varchar(128) = ''
        Declare @comment varchar(512) = ''

        exec @myError = UpdateMaterialContainers
                @iMode,
                @containerList,
                @newValue,
                @comment,
                @msg output,
                @callingUser

        if @myError <> 0
        begin
            RAISERROR (@msg, 11, 2)
        end
    end

    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
            
        Exec PostLogEntry 'Error', @message, 'DoMaterialContainerOperation'
    END CATCH
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialContainerOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoMaterialContainerOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialContainerOperation] TO [Limited_Table_Write] AS [dbo]
GO
