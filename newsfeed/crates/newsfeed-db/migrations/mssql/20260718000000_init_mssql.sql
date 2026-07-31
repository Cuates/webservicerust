USE [master]
GO
/****** Object:  Database [media]    Script Date: 2026-07-18 07:29:06 ******/
CREATE DATABASE [media]
 CONTAINMENT = NONE
GO
USE [media]
GO
USE [media]
GO
/****** Object:  UserDefinedFunction [dbo].[OmitCharacters]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
-- ===========================
--       File: OmitCharacters
--    Created: 07/22/2020
--    Updated: 10/01/2020
-- Programmer: Cuates
--  Update By: Cuates
--    Purpose: Omit characters
-- ===========================

-- Function Create
create function [dbo].[OmitCharacters]
(
  -- Parameters
  @inputString nvarchar(max),
  @characterInputString nvarchar(max)
)
returns nvarchar(max)
as
begin
  -- Declare variables
  declare @inputStringLength int
  declare @curPos int
  declare @stringResult nvarchar(max)
  declare @delimiterCharacter nvarchar(1)

  -- Declare temporary table
  declare @inputStringTemp table
  (
    istID int identity (1, 1) primary key,
    inputAsciiCharacter nvarchar(1) null,
    inputUnicodeCharacter int null
  )

  -- Declare temporary table
  declare @characterStringTemp table
  (
    cstID int identity (1, 1) primary key,
    asciiCharacter nvarchar(1) null,
    unicodeCharacter int null
  )

  -- Set variables
  set @delimiterCharacter = N','
  set @inputStringLength = len(@inputString)
  set @curPos = 1
  set @stringResult = ''

  -- Check if parameter is empty string
  if @inputString = ''
    begin
      -- Set variable to null if empty string
      set @inputString = nullif(@inputString, '')
    end

  -- Check if parameter is empty string
  if @characterInputString = ''
    begin
      -- Set variable to null if empty string
      set @characterInputString = nullif(@characterInputString, '')
    end

  -- Check if parameters are null
  if @inputString is not null and @characterInputString is not null
    begin
      -- Loop through input string
      while @curPos <= @inputStringLength
        begin
          -- Insert select each character from input string
          insert into @inputStringTemp (inputAsciiCharacter, inputUnicodeCharacter)
          select
          substring(@inputString, @curPos, 1),
          unicode(substring(@inputString, @curPos, 1))

          -- Increment position
          set @curPos = @curPos + 1
        end

      -- Insert select each character from character input string
      insert into @characterStringTemp (asciiCharacter, unicodeCharacter)
      select
      substring([value], 1, 1),
      unicode(substring([value], 1, 1))
      from string_split(@characterInputString, @delimiterCharacter)
      group by substring([value], 1, 1), unicode(substring([value], 1, 1))

      -- Update table to include delimiter character
      update @characterStringTemp
      set
      asciiCharacter = @delimiterCharacter,
      unicodeCharacter = unicode(@delimiterCharacter)
      where
      asciiCharacter = '' and
      unicodeCharacter is null

      -- Set variable combining each row into one row as a single string
      select
      @stringResult = string_agg(iif(cst.cstID is null, ' ', ist.inputAsciiCharacter), '') within group (order by ist.istID asc)
      from @inputStringTemp ist
      left join @characterStringTemp cst on cst.asciiCharacter = ist.inputAsciiCharacter and cst.unicodeCharacter = ist.inputUnicodeCharacter

      -- Loop through variable string until no more exists
      while charindex('  ', @stringResult) > 0
        begin
          -- Convert double spaces into one space
          set @stringResult = replace(@stringResult, '  ', ' ')
        end

      -- Set variable
      set @stringResult = trim(@stringResult)
    end
  else
    begin
      -- Set variable
      set @stringResult = null
    end

  -- Return variable
  return @stringResult
end
GO

/****** Object:  Table [dbo].[NewsFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
CREATE TABLE [dbo].[NewsFeed](
	[nfID] [bigint] IDENTITY(1,1) NOT NULL,
	[title] [nvarchar](255) NOT NULL,
	[imageurl] [nvarchar](255) NULL,
	[feedurl] [nvarchar](768) NOT NULL,
	[actualurl] [nvarchar](255) NULL,
	[publish_date] [datetime2](6) NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
 CONSTRAINT [PK_NewsFeed_title] PRIMARY KEY CLUSTERED 
(
	[title] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NewsFeedTemp]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
CREATE TABLE [dbo].[NewsFeedTemp](
	[title] [nvarchar](max) NULL,
	[imageurl] [nvarchar](max) NULL,
	[feedurl] [nvarchar](max) NULL,
	[actualurl] [nvarchar](max) NULL,
	[publish_date] [nvarchar](max) NULL,
	[created_date] [datetime2](6) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[NewsFeed] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[NewsFeed] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[NewsFeedTemp] ADD  DEFAULT (getdate()) FOR [created_date]
GO
-- =================================================
--       File: extractNewsFeed
--    Created: 10/30/2020
--    Updated: 02/02/2021
-- Programmer: Cuates
--  Update By: Cuates
--    Purpose: Extract News Feed
-- =================================================

-- Procedure Create
create procedure [dbo].[extractNewsFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @title nvarchar(max) = null,
  @imageurl nvarchar(max) = null,
  @feedurl nvarchar(max) = null,
  @actualurl nvarchar(max) = null,
  @limit nvarchar(max) = null,
  @sort nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @omitOptionMode as nvarchar(max)
  declare @omitTitle as nvarchar(max)
  declare @omitImageURL as nvarchar(max)
  declare @omitFeedURL as nvarchar(max)
  declare @omitActualURL as nvarchar(max)
  declare @omitLimit as nvarchar(max)
  declare @omitSort as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthTitle as int
  declare @maxLengthImageURL as int
  declare @maxLengthFeedURL as int
  declare @maxLengthActualURL as int
  declare @maxLengthSort as int
  declare @lowerLimit as int
  declare @upperLimit as int
  declare @defaultLimit as int
  declare @dSQL as nvarchar(max)
  declare @dSQLWhere as nvarchar(max) = ''

  -- Set variables
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitle = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitImageURL = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitFeedURL = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitActualURL = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitLimit = N'-,0,1,2,3,4,5,6,7,8,9'
  set @omitSort = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @maxLengthOptionMode = 255
  set @maxLengthTitle = 255
  set @maxLengthImageURL = 255
  set @maxLengthFeedURL = 768
  set @maxLengthActualURL = 255
  set @maxLengthSort = 255
  set @lowerLimit = 1
  set @upperLimit = 100
  set @defaultLimit = 25

  -- Check if parameter is not null
  if @optionMode is not null
    begin
      -- Omit characters
      set @optionMode = dbo.OmitCharacters(@optionMode, @omitOptionMode)

      -- Set character limit
      set @optionMode = trim(substring(@optionMode, 1, @maxLengthOptionMode))

      -- Check if empty string
      if @optionMode = ''
        begin
          -- Set parameter to null if empty string
          set @optionMode = nullif(@optionMode, '')
        end
    end

  -- Check if parameter is not null
  if @title is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @title = dbo.OmitCharacters(@title, @omitTitle)

      -- Set character limit
      set @title = trim(substring(@title, 1, @maxLengthTitle))

      -- Check if empty string
      if @title = ''
        begin
          -- Set parameter to null if empty string
          set @title = nullif(@title, '')
        end
    end

  -- Check if parameter is not null
  if @imageurl is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @imageurl = dbo.OmitCharacters(@imageurl, @omitImageURL)

      -- Set character limit
      set @imageurl = trim(substring(@imageurl, 1, @maxLengthImageURL))

      -- Check if empty string
      if @imageurl = ''
        begin
          -- Set parameter to null if empty string
          set @imageurl = nullif(@imageurl, '')
        end
    end

  -- Check if parameter is not null
  if @feedurl is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @feedurl = dbo.OmitCharacters(@feedurl, @omitFeedURL)

      -- Set character limit
      set @feedurl = trim(substring(@feedurl, 1, @maxLengthFeedURL))

      -- Check if empty string
      if @feedurl = ''
        begin
          -- Set parameter to null if empty string
          set @feedurl = nullif(@feedurl, '')
        end
    end

  -- Check if parameter is not null
  if @actualurl is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @actualurl = dbo.OmitCharacters(@actualurl, @omitActualURL)

      -- Set character limit
      set @actualurl = trim(substring(@actualurl, 1, @maxLengthActualURL))

      -- Check if empty string
      if @actualurl = ''
        begin
          -- Set parameter to null if empty string
          set @actualurl = nullif(@actualurl, '')
        end
    end

  -- Check if parameter is not null
  if @limit is not null
    begin
      -- Omit characters
      set @limit = dbo.OmitCharacters(@limit, @omitLimit)

      -- Set character limit
      set @limit = trim(@limit)

      -- Check if empty string
      if @limit = ''
        begin
          -- Set parameter to null if empty string
          set @limit = nullif(@limit, '')
        end
    end

  -- Check if parameter is not null
  if @sort is not null
    begin
      -- Omit characters
      set @sort = dbo.OmitCharacters(@sort, @omitSort)

      -- Set character limit
      set @sort = trim(substring(@sort, 1, @maxLengthSort))

      -- Check if empty string
      if @sort = ''
        begin
          -- Set parameter to null if empty string
          set @sort = nullif(@sort, '')
        end
    end

  -- Check if option mode extract news feed
  if @optionMode = 'extractNewsFeed'
    begin
      -- Check if limit is given
      if @limit is null or @limit not between @lowerLimit and @upperLimit
        begin
          -- Set limit to default number
          set @limit = @defaultLimit
        end

      -- Check if sort is given
      if @sort is null or lower(@sort) not in ('desc', 'asc')
        begin
          -- Set sort to default sorting
          set @sort = 'asc'
        end

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      set @dSQL =
      'select
      top (@_limitString)
      nf.title as [title],
      nf.imageurl as [imageurl],
      nf.feedurl as [feedurl],
      nf.actualurl as [actualurl],
      format(nf.publish_date, ''yyyy-MM-dd HH:mm:ss.ffffff'',''en-us'') as [publishdate]
      from dbo.NewsFeed nf'

      -- Check if where clause is given
      if @title is not null
        begin
          -- Set variable
          set @dSQLWhere = 'nf.title = @_titleString'
        end

      -- Check if where clause is given
      if @imageurl is not null
        begin
          -- Check if value is string null
          if lower(@imageurl) = 'null'
            begin
              -- Check if dynamic SQL is not empty
              if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = @dSQLWhere + ' and nf.imageurl is null'
                end
              else
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = 'nf.imageurl is null'
                end
            end
          else
            -- Else proceed with the normal select call
            begin
                  if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = @dSQLWhere + ' and nf.imageurl = @_imageurlString'
                end
              else
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = 'nf.imageurl = @_imageurlString'
                end
            end
        end

      -- Check if where clause is given
      if @feedurl is not null
        begin
          -- Check if dynamic SQL is not empty
          if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = @dSQLWhere + ' and nf.feedurl = @_feedurlString'
            end
          else
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = 'nf.feedurl = @_feedurlString'
            end
        end

      -- Check if where clause is given
      if @actualurl is not null
        begin
          -- Check if value is string null
          if lower(@imageurl) = 'null'
            begin
              -- Check if dynamic SQL is not empty
              if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = @dSQLWhere + ' and nf.actualurl is null'
                end
              else
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = 'nf.actualurl is null'
                end
            end
          else
            -- Else proceed with the normal select call
            begin
              -- Check if dynamic SQL is not empty
              if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = @dSQLWhere + ' and nf.actualurl = @_actualurlString'
                end
              else
                begin
                  -- Include the next filter into the where clause
                  set @dSQLWhere = 'nf.actualurl = @_actualurlString'
                end
            end
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      if @sort = 'desc'
        begin
          set @dSQL = @dSQL + @dSQLWhere + ' order by nf.publish_date desc, nf.title desc, nf.imageurl desc, nf.feedurl desc, nf.actualurl desc'
        end
      else
        begin
          set @dSQL = @dSQL + @dSQLWhere + ' order by nf.publish_date asc, nf.title asc, nf.imageurl asc, nf.feedurl asc, nf.actualurl asc'
        end

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_titleString as nvarchar(255), @_imageurlString as nvarchar(255), @_feedurlString as nvarchar(768), @_actualurlString as nvarchar(255), @_limitString as int',
      @_titleString = @title, @_imageurlString = @imageurl, @_feedurlString = @feedurl, @_actualurlString = @actualurl, @_limitString = @limit
    end
end
GO

/****** Object:  StoredProcedure [dbo].[cud_bulk_json_newsfeed] ******/
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cud_bulk_json_newsfeed]
    @optionmode nvarchar(max),
    @payload nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @parsed TABLE (
        title nvarchar(255),
        imageurl nvarchar(255),
        feedurl nvarchar(768),
        actualurl nvarchar(255),
        publish_date datetime2(6)
    );
    
    INSERT INTO @parsed (title, imageurl, feedurl, actualurl, publish_date)
    SELECT 
        JSON_VALUE(value, '$.title'),
        NULLIF(TRIM(JSON_VALUE(value, '$.image_url')), ''),
        JSON_VALUE(value, '$.feed_url'),
        NULLIF(TRIM(JSON_VALUE(value, '$.actual_url')), ''),
        TRY_CAST(JSON_VALUE(value, '$.publish_date') AS datetime2(6))
    FROM OPENJSON(@payload)
    WHERE JSON_VALUE(value, '$.title') IS NOT NULL AND TRIM(JSON_VALUE(value, '$.title')) <> ''
      AND JSON_VALUE(value, '$.feed_url') IS NOT NULL AND TRIM(JSON_VALUE(value, '$.feed_url')) <> ''
      AND JSON_VALUE(value, '$.publish_date') IS NOT NULL AND TRIM(JSON_VALUE(value, '$.publish_date')) <> '';

    DECLARE @json nvarchar(max);

    IF @optionmode = 'insertNewsFeed' OR @optionmode = 'insertFeed'
    BEGIN
        DECLARE @inserted TABLE (title nvarchar(255));
        
        INSERT INTO dbo.NewsFeed (title, imageurl, feedurl, actualurl, publish_date, created_date, modified_date)
        OUTPUT inserted.title INTO @inserted
        SELECT p.title, p.imageurl, p.feedurl, p.actualurl, p.publish_date, GETDATE(), GETDATE()
        FROM @parsed p
        WHERE NOT EXISTS (SELECT 1 FROM dbo.NewsFeed nf WHERE nf.title = p.title);
        
        SET @json = (
            SELECT 
                CASE WHEN i.title IS NOT NULL THEN 'Success' ELSE 'Skipped' END AS Status,
                CASE WHEN i.title IS NOT NULL THEN 'Record(s) inserted' ELSE 'SKIPPED_EXISTS' END AS Message
            FROM @parsed p
            LEFT JOIN @inserted i ON p.title = i.title
            FOR JSON PATH
        );
    END
    ELSE IF @optionmode = 'updateNewsFeed' OR @optionmode = 'updateFeed'
    BEGIN
        DECLARE @updated TABLE (title nvarchar(255));
        
        UPDATE nf
        SET imageurl = p.imageurl,
            feedurl = p.feedurl,
            actualurl = p.actualurl,
            publish_date = p.publish_date,
            modified_date = GETDATE()
        OUTPUT inserted.title INTO @updated
        FROM dbo.NewsFeed nf
        INNER JOIN @parsed p ON nf.title = p.title
        WHERE NOT (
            (nf.imageurl = p.imageurl OR (nf.imageurl IS NULL AND p.imageurl IS NULL)) AND
            nf.feedurl = p.feedurl AND
            (nf.actualurl = p.actualurl OR (nf.actualurl IS NULL AND p.actualurl IS NULL)) AND
            nf.publish_date = p.publish_date
        );
        
        SET @json = (
            SELECT 
                CASE 
                    WHEN u.title IS NOT NULL THEN 'Success'
                    WHEN nf.title IS NOT NULL THEN 'Skipped'
                    ELSE 'Skipped'
                END AS Status,
                CASE 
                    WHEN u.title IS NOT NULL THEN 'Record(s) updated'
                    WHEN nf.title IS NOT NULL THEN 'SKIPPED_EXISTS'
                    ELSE 'SKIPPED_NOT_FOUND'
                END AS Message
            FROM @parsed p
            LEFT JOIN dbo.NewsFeed nf ON p.title = nf.title
            LEFT JOIN @updated u ON p.title = u.title
            FOR JSON PATH
        );
    END
    ELSE IF @optionmode = 'deleteNewsFeed' OR @optionmode = 'deleteFeed'
    BEGIN
        DECLARE @deleted TABLE (title nvarchar(255));
        
        DELETE nf
        OUTPUT deleted.title INTO @deleted
        FROM dbo.NewsFeed nf
        INNER JOIN @parsed p ON nf.title = p.title;
        
        SET @json = (
            SELECT 
                CASE WHEN d.title IS NOT NULL THEN 'Success' ELSE 'Skipped' END AS Status,
                CASE WHEN d.title IS NOT NULL THEN 'Record(s) deleted' ELSE 'SKIPPED_NOT_FOUND' END AS Message
            FROM @parsed p
            LEFT JOIN @deleted d ON p.title = d.title
            FOR JSON PATH
        );
    END

    SELECT ISNULL(@json, '[]');
END
GO
USE [master]
GO
