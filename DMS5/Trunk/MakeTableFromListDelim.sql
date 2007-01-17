/****** Object:  UserDefinedFunction [dbo].[MakeTableFromListDelim] ******/
CREATE FUNCTION dbo.MakeTableFromListDelim
/****************************************************
**
**	Desc: 
**  Returns a table filled with the contents of a delimited list
**
**	Return values: 
**
**	Parameters:
**	
**
**		Auth: grk
**		Date: 1/8/2007
**    
*****************************************************/
(
@list varchar(8000),
@delimiter char(1) = ','
)
RETURNS @theTable TABLE
   (
    Item varchar(128)
   )
AS
	BEGIN
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
			set @EndOfField = charindex(@delimiter, @list, @curPos)

			-- if delimiter not found, field contains rest of string
			-- and end-of-line condition is set
			--
			if @EndOfField = 0
			begin
				set @EndOfField = LEN(@list) + 1
				set @EOL = 1
			end
			
			-- extract field based on positions
			--
			set @field = ltrim(rtrim(substring(@list, @curPos, @EndOfField - @curPos)))

			-- advance current starting position beyond current field
			-- and set end-of-line condidtion if it is past the end of the line
			--
			set @curPos = @EndOfField + 1
			if @curPos > LEN(@list)
				set @EOL = 1
			
			if @field <> ''
			begin
				INSERT INTO @theTable
					(Item)
				VALUES     
					(@field)
			end
		end

		RETURN
	END
GO
