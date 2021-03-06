GO

CREATE FUNCTION [dbo].[x_GetRunRequestDatasetListLegacy]
/****************************************************
**
**	Desc:
**
**	Return values: quoted list of datasets in run request
**
**	Parameters:
**
**
**	Auth:	grk
**	Date:	11/9/2005
**			05/03/2012 mem - Updated @entryList to varchar(max)
**
*****************************************************/
(
@requestID int
)
RETURNS @datasets TABLE
   (
    dataset varchar(128)
   )
AS
	BEGIN
		declare @entryList varchar(max)
		declare @message varchar(512)
		--
		SELECT @entryList = AJR_datasets
		FROM T_Analysis_Job_Request
		WHERE (AJR_requestID = @requestID)

--		declare @entryListQuoted varchar(8000)
--		exec QuoteNameList @entryList, @entryListQuoted output, @message output

--		declare @sql nvarchar(4000)
--		set @sql = REPLACE('SELECT DISTINCT Instrument FROM V_Dataset_Detail_Report_Ex WHERE Dataset IN (XDSLX)', 'XDSLX', @entryListQuoted)
--		exec sp_executesql @sql


		declare @delimiter char(1)
		set @delimiter = ','

		declare @EOL int
		declare @count int

		declare @myError int
		set @myError = 0

		declare @myRowCount int
		set @myRowCount = 0
		--
		declare @id int
		--
		declare @curPos int
		set @curPos = 1
		declare @field varchar(128)

		-- process lists into rows
		-- and insert into DB table
		--
		set @count = 0
		set @EOL = 0
		declare @EndOfField int

		while @EOL = 0
		begin
			set @count = @count + 1

			-- process the  next field from the list
			--
			set @field = ''
			set @EOL = 0

			-- find position of delimiter
			--
			set @EndOfField = charindex(@delimiter, @entryList, @curPos)

			-- if delimiter not found, field contains rest of string
			-- and end-of-line condition is set
			--
			if @EndOfField = 0
			begin
				set @EndOfField = LEN(@entryList) + 1
				set @EOL = 1
			end

			-- extract field based on positions
			--
			set @field = ltrim(rtrim(substring(@entryList, @curPos, @EndOfField - @curPos)))

			-- advance current starting position beyond current field
			-- and set end-of-line condition if it is past the end of the line
			--
			set @curPos = @EndOfField + 1
			if @curPos > LEN(@entryList)
				set @EOL = 1

			if @field <> ''
			begin
				INSERT INTO @datasets
					(dataset)
				VALUES
					(@field)
			end
		end

		RETURN
	END



GO


INSERT INTO T_Analysis_Job_Request_Datasets( Request_ID,
                                             Dataset_ID )
SELECT DISTINCT LookupQ.Request_ID,
                ds.dataset_id
FROM ( SELECT AJR_requestID Request_ID,
              dataset
       FROM T_Analysis_Job_Request
            CROSS APPLY dbo.[x_GetRunRequestDatasetListLegacy] ( AJR_requestID ) ) LookupQ
     INNER JOIN T_Dataset DS
       ON LookupQ.dataset = DS.Dataset_Num


drop function x_GetRunRequestDatasetListLegacy

SELECT Request_ID, Count(*) FROM T_Analysis_Job_Request_Datasets Group By Request_ID

