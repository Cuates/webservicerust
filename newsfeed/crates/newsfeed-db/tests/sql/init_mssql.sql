USE [master]
GO
/****** Object:  Database [media]    Script Date: 2026-07-18 07:29:06 ******/
CREATE DATABASE [media]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'media', FILENAME = N'/var/opt/mssql/data/media.mdf' , SIZE = 335872KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'media_log', FILENAME = N'/var/opt/mssql/data/media_log.ldf' , SIZE = 30875648KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [media].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [media] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [media] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [media] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [media] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [media] SET ARITHABORT OFF 
GO
ALTER DATABASE [media] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [media] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [media] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [media] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [media] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [media] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [media] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [media] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [media] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [media] SET  DISABLE_BROKER 
GO
ALTER DATABASE [media] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [media] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [media] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [media] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [media] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [media] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [media] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [media] SET RECOVERY FULL 
GO
ALTER DATABASE [media] SET  MULTI_USER 
GO
ALTER DATABASE [media] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [media] SET DB_CHAINING OFF 
GO
ALTER DATABASE [media] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [media] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [media] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'media', N'ON'
GO
ALTER DATABASE [media] SET QUERY_STORE = OFF
GO
USE [media]
GO
ALTER DATABASE SCOPED CONFIGURATION SET ACCELERATED_PLAN_FORCING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET ASYNC_STATS_UPDATE_WAIT_AT_LOW_PRIORITY = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_ADAPTIVE_JOINS = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_MEMORY_GRANT_FEEDBACK = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_ON_ROWSTORE = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET CE_FEEDBACK = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET DEFERRED_COMPILATION_TV = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET DOP_FEEDBACK = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET DW_COMPATIBILITY_LEVEL = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION SET ELEVATE_ONLINE = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET ELEVATE_RESUMABLE = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET EXEC_QUERY_STATS_FOR_SCALAR_FUNCTIONS = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET FORCE_SHOWPLAN_RUNTIME_PARAMETER_COLLECTION = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET GLOBAL_TEMPORARY_TABLE_AUTO_DROP = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET IDENTITY_CACHE = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET INTERLEAVED_EXECUTION_TVF = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET ISOLATE_SECURITY_POLICY_CARDINALITY = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEDGER_DIGEST_STORAGE_ENDPOINT = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET LIGHTWEIGHT_QUERY_PROFILING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MEMORY_GRANT_FEEDBACK_PERCENTILE_GRANT = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MEMORY_GRANT_FEEDBACK_PERSISTENCE = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET OPTIMIZED_PLAN_FORCING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET OPTIMIZE_FOR_AD_HOC_WORKLOADS = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SENSITIVE_PLAN_OPTIMIZATION = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PAUSED_RESUMABLE_INDEX_ABORT_DURATION_MINUTES = 1440;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET ROW_MODE_MEMORY_GRANT_FEEDBACK = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET TSQL_SCALAR_UDF_INLINING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET VERBOSE_TRUNCATION_WARNINGS = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET XTP_PROCEDURE_EXECUTION_STATISTICS = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET XTP_QUERY_EXECUTION_STATISTICS = OFF;
GO
USE [media]
GO
/****** Object:  User [mediasql]    Script Date: 2026-07-18 07:29:07 ******/
CREATE USER [mediasql] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [mediasql]
GO
ALTER ROLE [db_datareader] ADD MEMBER [mediasql]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [mediasql]
GO
/****** Object:  UserDefinedFunction [dbo].[OmitCharacters]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[ActionStatus]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActionStatus](
	[asID] [bigint] IDENTITY(1,1) NOT NULL,
	[actionnumber] [int] NOT NULL,
	[actiondescription] [nvarchar](255) NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
 CONSTRAINT [PK_ActionStatus_actionnumber] PRIMARY KEY CLUSTERED 
(
	[actionnumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dbo.insertupdatedeleteBulkNewsFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dbo.insertupdatedeleteBulkNewsFeed](
	[title] [nvarchar](max) NULL,
	[imageurl] [nvarchar](max) NULL,
	[feedurl] [nvarchar](max) NULL,
	[actualurl] [nvarchar](max) NULL,
	[publishdate] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dbo.MovieFeedTemp]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dbo.MovieFeedTemp](
	[titlelong] [varchar](max) NULL,
	[titleshort] [varchar](max) NULL,
	[publish_date] [varchar](max) NULL,
	[info_url] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MediaAudioEncode]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MediaAudioEncode](
	[maeID] [bigint] IDENTITY(1,1) NOT NULL,
	[audioencode] [nvarchar](100) NOT NULL,
	[movieInclude] [tinyint] NOT NULL,
	[tvInclude] [tinyint] NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
 CONSTRAINT [PK_MediaAudioEncode_audioencode] PRIMARY KEY CLUSTERED 
(
	[audioencode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MediaDynamicRange]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MediaDynamicRange](
	[mdrID] [bigint] IDENTITY(1,1) NOT NULL,
	[dynamicrange] [nvarchar](100) NOT NULL,
	[movieInclude] [tinyint] NOT NULL,
	[tvInclude] [tinyint] NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
 CONSTRAINT [PK_MediaDynamicRange_dynamicrange] PRIMARY KEY CLUSTERED 
(
	[dynamicrange] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MediaResolution]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MediaResolution](
	[mrID] [bigint] IDENTITY(1,1) NOT NULL,
	[resolution] [nvarchar](100) NOT NULL,
	[movieInclude] [tinyint] NOT NULL,
	[tvInclude] [tinyint] NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
 CONSTRAINT [PK_MediaResolution_resolution] PRIMARY KEY CLUSTERED 
(
	[resolution] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MediaStreamSource]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MediaStreamSource](
	[mssID] [bigint] IDENTITY(1,1) NOT NULL,
	[streamsource] [nvarchar](100) NOT NULL,
	[streamdescription] [nvarchar](100) NOT NULL,
	[movieInclude] [tinyint] NOT NULL,
	[tvInclude] [tinyint] NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
 CONSTRAINT [PK_MediaStreamSource_streamsource] PRIMARY KEY CLUSTERED 
(
	[streamsource] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MediaVideoEncode]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MediaVideoEncode](
	[mveID] [bigint] IDENTITY(1,1) NOT NULL,
	[videoencode] [nvarchar](100) NOT NULL,
	[movieInclude] [tinyint] NOT NULL,
	[tvInclude] [tinyint] NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
 CONSTRAINT [PK_MediaVideoEncode_videoencode] PRIMARY KEY CLUSTERED 
(
	[videoencode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MovieFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MovieFeed](
	[mfID] [bigint] IDENTITY(1,1) NOT NULL,
	[titlelong] [nvarchar](255) NOT NULL,
	[titleshort] [nvarchar](255) NOT NULL,
	[publish_date] [datetime2](6) NOT NULL,
	[actionstatus] [int] NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
	[info_url] [nvarchar](max) NULL,
 CONSTRAINT [PK_MovieFeed_titlelong] PRIMARY KEY CLUSTERED 
(
	[titlelong] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MovieFeedTemp]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MovieFeedTemp](
	[titlelong] [nvarchar](max) NULL,
	[titleshort] [nvarchar](max) NULL,
	[publish_date] [nvarchar](max) NULL,
	[created_date] [datetime2](6) NULL,
	[info_url] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NewsFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[TVFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TVFeed](
	[tfID] [bigint] IDENTITY(1,1) NOT NULL,
	[titlelong] [nvarchar](255) NOT NULL,
	[titleshort] [nvarchar](255) NOT NULL,
	[publish_date] [datetime2](6) NOT NULL,
	[actionstatus] [int] NOT NULL,
	[created_date] [datetime2](6) NOT NULL,
	[modified_date] [datetime2](6) NULL,
	[info_url] [nvarchar](max) NULL,
 CONSTRAINT [PK_TVFeed_titlelong] PRIMARY KEY CLUSTERED 
(
	[titlelong] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TVFeedTemp]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TVFeedTemp](
	[titlelong] [nvarchar](max) NULL,
	[titleshort] [nvarchar](max) NULL,
	[publish_date] [nvarchar](max) NULL,
	[created_date] [datetime2](6) NULL,
	[info_url] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_MovieFeed_titleshort]    Script Date: 2026-07-18 07:29:07 ******/
CREATE NONCLUSTERED INDEX [IX_MovieFeed_titleshort] ON [dbo].[MovieFeed]
(
	[titleshort] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_TVFeed_titleshort]    Script Date: 2026-07-18 07:29:07 ******/
CREATE NONCLUSTERED INDEX [IX_TVFeed_titleshort] ON [dbo].[TVFeed]
(
	[titleshort] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ActionStatus] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[ActionStatus] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[MediaAudioEncode] ADD  DEFAULT ((0)) FOR [movieInclude]
GO
ALTER TABLE [dbo].[MediaAudioEncode] ADD  DEFAULT ((0)) FOR [tvInclude]
GO
ALTER TABLE [dbo].[MediaAudioEncode] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[MediaAudioEncode] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[MediaDynamicRange] ADD  DEFAULT ((0)) FOR [movieInclude]
GO
ALTER TABLE [dbo].[MediaDynamicRange] ADD  DEFAULT ((0)) FOR [tvInclude]
GO
ALTER TABLE [dbo].[MediaDynamicRange] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[MediaDynamicRange] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[MediaResolution] ADD  DEFAULT ((0)) FOR [movieInclude]
GO
ALTER TABLE [dbo].[MediaResolution] ADD  DEFAULT ((0)) FOR [tvInclude]
GO
ALTER TABLE [dbo].[MediaResolution] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[MediaResolution] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[MediaStreamSource] ADD  DEFAULT ((0)) FOR [movieInclude]
GO
ALTER TABLE [dbo].[MediaStreamSource] ADD  DEFAULT ((0)) FOR [tvInclude]
GO
ALTER TABLE [dbo].[MediaStreamSource] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[MediaStreamSource] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[MediaVideoEncode] ADD  DEFAULT ((0)) FOR [movieInclude]
GO
ALTER TABLE [dbo].[MediaVideoEncode] ADD  DEFAULT ((0)) FOR [tvInclude]
GO
ALTER TABLE [dbo].[MediaVideoEncode] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[MediaVideoEncode] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[MovieFeed] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[MovieFeed] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[MovieFeedTemp] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[NewsFeed] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[NewsFeed] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[NewsFeedTemp] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[TVFeed] ADD  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[TVFeed] ADD  DEFAULT (getdate()) FOR [modified_date]
GO
ALTER TABLE [dbo].[TVFeedTemp] ADD  DEFAULT (getdate()) FOR [created_date]
GO
/****** Object:  StoredProcedure [dbo].[extractControlMediaFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================
--       File: extractControlMediaFeed
--    Created: 11/16/2020
--    Updated: 11/18/2020
-- Programmer: Cuates
--  Update By: Cuates
--    Purpose: Extract Control Media Feed
-- =================================================

-- Procedure Create
create procedure [dbo].[extractControlMediaFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @actionnumber nvarchar(max) = null,
  @actiondescription nvarchar(max) = null,
  @audioencode nvarchar(max) = null,
  @dynamicrange nvarchar(max) = null,
  @resolution nvarchar(max) = null,
  @streamsource nvarchar(max) = null,
  @streamdescription nvarchar(max) = null,
  @videoencode nvarchar(max) = null,
  @limit nvarchar(max) = null,
  @sort nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @omitOptionMode as nvarchar(max)
  declare @omitActionNumber as nvarchar(max)
  declare @omitActionDescription as nvarchar(max)
  declare @omitMediaAudioEncode as nvarchar(max)
  declare @omitMediaDynamicRange as nvarchar(max)
  declare @omitMediaResolution as nvarchar(max)
  declare @omitMediaStreamSource as nvarchar(max)
  declare @omitMediaStreamDescription as nvarchar(max)
  declare @omitMediaVideoEncode as nvarchar(max)
  declare @omitLimit as nvarchar(max)
  declare @omitSort as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthActionNumber as int
  declare @maxLengthActionDescription as int
  declare @maxLengthMediaAudioEncode as int
  declare @maxLengthMediaDynamicRange as int
  declare @maxLengthMediaResolution as int
  declare @maxLengthMediaStreamSource as int
  declare @maxLengthMediaStreamDescription as int
  declare @maxLengthMediaVideoEncode as int
  declare @maxLengthTitleLong as int
  declare @maxLengthTitleShort as int
  declare @maxLengthSort as int
  declare @lowerLimit as int
  declare @upperLimit as int
  declare @defaultLimit as int
  declare @dSQL as nvarchar(max)
  declare @dSQLWhere as nvarchar(max) = ''

  -- Set variables
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitActionNumber = N'0,1,2,3,4,5,6,7,8,9'
  set @omitActionDescription = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitMediaAudioEncode = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9,.,-'
  set @omitMediaDynamicRange = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z'
  set @omitMediaResolution = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9'
  set @omitMediaStreamSource = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitMediaStreamDescription = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitMediaVideoEncode = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9'
  set @omitLimit = N'-,0,1,2,3,4,5,6,7,8,9'
  set @omitSort = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @maxLengthOptionMode = 255
  set @maxLengthActionNumber = 255
  set @maxLengthActionDescription = 255
  set @maxLengthMediaAudioEncode = 100
  set @maxLengthMediaDynamicRange = 100
  set @maxLengthMediaResolution = 100
  set @maxLengthMediaStreamSource = 100
  set @maxLengthMediaStreamDescription = 100
  set @maxLengthMediaVideoEncode = 100
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
  if @actionnumber is not null
    begin
      -- Omit characters
      set @actionnumber = dbo.OmitCharacters(@actionnumber, @omitActionNumber)

      -- Set character limit
      set @actionnumber = trim(substring(@actionnumber, 1, @maxLengthActionNumber))

      -- Check if empty string
      if @actionnumber = ''
        begin
          -- Set parameter to null if empty string
          set @actionnumber = nullif(@actionnumber, '')
        end
    end

  -- Check if parameter is not null
  if @actiondescription is not null
    begin
      -- Omit characters
      set @actiondescription = dbo.OmitCharacters(@actiondescription, @omitActionDescription)

      -- Set character limit
      set @actiondescription = trim(substring(@actiondescription, 1, @maxLengthActionDescription))

      -- Check if empty string
      if @actiondescription = ''
        begin
          -- Set parameter to null if empty string
          set @actiondescription = nullif(@actiondescription, '')
        end
    end

  -- Check if parameter is not null
  if @audioencode is not null
    begin
      -- Omit characters
      set @audioencode = dbo.OmitCharacters(@audioencode, @omitMediaAudioEncode)

      -- Set character limit
      set @audioencode = trim(substring(@audioencode, 1, @maxLengthMediaAudioEncode))

      -- Check if empty string
      if @audioencode = ''
        begin
          -- Set parameter to null if empty string
          set @audioencode = nullif(@audioencode, '')
        end
    end

  -- Check if parameter is not null
  if @dynamicrange is not null
    begin
      -- Omit characters
      set @dynamicrange = dbo.OmitCharacters(@dynamicrange, @omitMediaDynamicRange)

      -- Set character limit
      set @dynamicrange = trim(substring(@dynamicrange, 1, @maxLengthMediaDynamicRange))

      -- Check if empty string
      if @dynamicrange = ''
        begin
          -- Set parameter to null if empty string
          set @dynamicrange = nullif(@dynamicrange, '')
        end
    end

  -- Check if parameter is not null
  if @resolution is not null
    begin
      -- Omit characters
      set @resolution = dbo.OmitCharacters(@resolution, @omitMediaResolution)

      -- Set character limit
      set @resolution = trim(substring(@resolution, 1, @maxLengthMediaResolution))

      -- Check if empty string
      if @resolution = ''
        begin
          -- Set parameter to null if empty string
          set @resolution = nullif(@resolution, '')
        end
    end

  -- Check if parameter is not null
  if @streamsource is not null
    begin
      -- Omit characters
      set @streamsource = dbo.OmitCharacters(@streamsource, @omitMediaStreamSource)

      -- Set character limit
      set @streamsource = trim(substring(@streamsource, 1, @maxLengthMediaStreamSource))

      -- Check if empty string
      if @streamsource = ''
        begin
          -- Set parameter to null if empty string
          set @streamsource = nullif(@streamsource, '')
        end
    end

  -- Check if parameter is not null
  if @streamdescription is not null
    begin
      -- Omit characters
      set @streamdescription = dbo.OmitCharacters(@streamdescription, @omitMediaStreamDescription)

      -- Set character limit
      set @streamdescription = trim(substring(@streamdescription, 1, @maxLengthMediaStreamDescription))

      -- Check if empty string
      if @streamdescription = ''
        begin
          -- Set parameter to null if empty string
          set @streamdescription = nullif(@streamdescription, '')
        end
    end

  -- Check if parameter is not null
  if @videoencode is not null
    begin
      -- Omit characters
      set @videoencode = dbo.OmitCharacters(@videoencode, @omitMediaVideoEncode)

      -- Set character limit
      set @videoencode = trim(substring(@videoencode, 1, @maxLengthMediaVideoEncode))

      -- Check if empty string
      if @videoencode = ''
        begin
          -- Set parameter to null if empty string
          set @videoencode = nullif(@videoencode, '')
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

  -- Check if option mode is extract action status
  if @optionMode = 'extractActionStatus'
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
      cast(ast.actionnumber as nvarchar(255)) as [Action Number],
      ast.actiondescription as [Action Description]
      from dbo.ActionStatus ast'

      -- Check if where clause is given
      if @actionnumber is not null
        begin
          -- Set variable
          set @dSQLWhere = 'ast.actionnumber = (@_actionnumberString)'
        end

      -- Check if where clause is given
      if @actiondescription is not null
        begin
          -- Check if dynamic SQL is not empty
          if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = @dSQLWhere + ' and ast.actiondescription = @_actiondescriptionString'
            end
          else
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = 'ast.actiondescription = @_actiondescriptionString'
            end
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by ast.actionnumber ' + @sort + ', ast.actiondescription ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_actionnumberString as int, @_actiondescriptionString as nvarchar(255), @_limitString as int',
      @_actionnumberString = @actionnumber, @_actiondescriptionString = @actiondescription, @_limitString = @limit
    end

  -- Else check if option mode is extract media audio encode
  else if @optionMode = 'extractMediaAudioEncode'
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
      mae.audioencode as [Audio Encode],
      cast(mae.movieInclude as nvarchar(255)) as [Movie Include],
      cast(mae.tvInclude as nvarchar(255)) as [TV Include]
      from dbo.MediaAudioEncode mae'

      -- Check if where clause is given
      if @audioencode is not null
        begin
          set @dSQLWhere = 'mae.audioencode = @_audioencodeString'
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by mae.audioencode ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_audioencodeString nvarchar(100), @_limitString as int',
      @_audioencodeString = @audioencode, @_limitString = @limit
    end

-- Else check if option mode is delete temp tv
  else if @optionMode = 'extractMediaDynamicRange'
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
      mdr.dynamicrange as [Dynamic Range],
      cast(mdr.movieInclude as nvarchar(255)) as [Movie Include],
      cast(mdr.tvInclude as nvarchar(255)) as [TV Include]
      from dbo.MediaDynamicRange mdr'

      -- Check if where clause is given
      if @dynamicrange is not null
        begin
          -- Set variable
          set @dSQLWhere = 'mdr.dynamicrange = @_dynamicrangeString'
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by mdr.dynamicrange ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_dynamicrangeString nvarchar(100), @_limitString as int',
      @_dynamicrangeString = @dynamicrange, @_limitString = @limit
    end

  -- Else check if option mode is extract media resolution
  else if @optionMode = 'extractMediaResolution'
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
      mr.resolution as [Resolution],
      cast(mr.movieInclude as nvarchar(255)) as [Movie Include],
      cast(mr.tvInclude as nvarchar(255)) as [TV Include]
      from dbo.MediaResolution mr'

      -- Check if where clause is given
      if @resolution is not null
        begin
          -- Set variable
          set @dSQLWhere = 'mr.resolution = @_resolutionString'
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by mr.resolution ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_resolutionString nvarchar(100), @_limitString as int',
      @_resolutionString = @resolution, @_limitString = @limit
    end

  -- Else check if option mode is extract media stream source
  else if @optionMode = 'extractMediaStreamSource'
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
      mss.streamsource as [Stream Source],
      mss.streamdescription as [Stream Description],
      cast(mss.movieInclude as nvarchar(255)) as [Movie Include],
      cast(mss.tvInclude as nvarchar(255)) as [TV Include]
      from dbo.MediaStreamSource mss'

      -- Check if where clause is given
      if @streamsource is not null
        begin
          -- Set variable
          set @dSQLWhere = 'mss.streamsource = @_streamsourceString'
        end

      -- Check if where clause is given
      if @streamdescription is not null
        begin
          -- Check if dynamic SQL is not empty
          if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = @dSQLWhere + ' and mss.streamdescription = @_streamdescriptionString'
            end
          else
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = 'mss.streamdescription = @_streamdescriptionString'
            end
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by mss.streamsource ' + @sort + ', mss.streamdescription ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_streamsourceString as nvarchar(100), @_streamdescriptionString as nvarchar(100), @_limitString as int',
      @_streamsourceString = @streamsource, @_streamdescriptionString = @streamdescription, @_limitString = @limit
    end

  -- Else check if option mode is extract media video encode
  else if @optionMode = 'extractMediaVideoEncode'
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
      mve.videoencode as [Video Encode],
      cast(mve.movieInclude as nvarchar(255)) as [Movie Include],
      cast(mve.tvInclude as nvarchar(255)) as [TV Include]
      from dbo.MediaVideoEncode mve'

      -- Check if where clause is given
      if @videoencode is not null
        begin
          -- Set variable
          set @dSQLWhere = 'mve.videoencode = @_videoencodeString'
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by mve.videoencode ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_videoencodeString nvarchar(100), @_limitString as int',
      @_videoencodeString = @videoencode, @_limitString = @limit
    end
end
GO
/****** Object:  StoredProcedure [dbo].[extractMediaFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================
--               File: extractMediaFeed
--        Created: 10/28/2020
--        Updated: 09/15/2023
--  Programmer: Cuates
--    Update By: Cuates
--        Purpose: Extract Media Feed
-- =================================================

-- Procedure Create
CREATE procedure [dbo].[extractMediaFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @titlelong nvarchar(max) = null,
  @titleshort nvarchar(max) = null,
  --@infourl nvarchar(max) = null,
  @actionstatus nvarchar(max) = null,
  @limit nvarchar(max) = null,
  @sort nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @omitOptionMode as nvarchar(max)
  declare @omitTitleLong as nvarchar(max)
  declare @omitTitleShort as nvarchar(max)
  declare @omitInfoUrl as nvarchar(max)
  declare @omitActionStatus as nvarchar(max)
  declare @omitLimit as nvarchar(max)
  declare @omitSort as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthActionDescription as int
  declare @maxLengthMediaAudioEncode as int
  declare @maxLengthMediaDynamicRange as int
  declare @maxLengthMediaResolution as int
  declare @maxLengthMediaStreamSource as int
  declare @maxLengthMediaStreamDescription as int
  declare @maxLengthMediaVideoEncode as int
  declare @maxLengthTitleLong as int
  declare @maxLengthTitleShort as int
  declare @maxLengthInfoUrl as int
  declare @maxLengthActionStatus as int
  declare @maxLengthSort as int
  declare @lowerLimit as int
  declare @upperLimit as int
  declare @defaultLimit as int
  declare @dSQL as nvarchar(max)
  declare @dSQLWhere as nvarchar(max) = ''

  -- Set variables
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitleLong = N'-,.,0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitleShort = N'-,.,0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitInfoUrl = N'-,.,/,%,?,=,&,:,0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitActionStatus = N'0,1,2,3,4,5,6,7,8,9'
  set @omitLimit = N'-,0,1,2,3,4,5,6,7,8,9'
  set @omitSort = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @maxLengthOptionMode = 255
  set @maxLengthTitleLong = 255
  set @maxLengthTitleShort = 255
  set @maxLengthInfoUrl = 8000
  set @maxLengthActionStatus = 255
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
  if @titlelong is not null
    begin
      -- Omit characters
      set @titlelong = dbo.OmitCharacters(@titlelong, @omitTitleLong)

      -- Set character limit
      set @titlelong = trim(substring(@titlelong, 1, @maxLengthTitleLong))

      -- Check if empty string
      if @titlelong = ''
        begin
          -- Set parameter to null if empty string
          set @titlelong = nullif(@titlelong, '')
        end
    end

  -- Check if parameter is not null
  if @titleshort is not null
    begin
      -- Omit characters
      set @titleshort = dbo.OmitCharacters(@titleshort, @omitTitleShort)

      -- Set character limit
      set @titleshort = trim(substring(@titleshort, 1, @maxLengthTitleShort))

      -- Check if empty string
      if @titleshort = ''
        begin
          -- Set parameter to null if empty string
          set @titleshort = nullif(@titleshort, '')
        end
    end

  ---- Check if parameter is not null
  --if @infourl is not null
  --  begin
  --    -- Omit characters
  --    set @infourl = dbo.OmitCharacters(@infourl, @omitInfoUrl)

  --    -- Set character limit
  --    set @infourl = trim(substring(@infourl, 1, @maxLengthInfoUrl))

  --    -- Check if empty string
  --    if @infourl = ''
  --      begin
  --        -- Set parameter to null if empty string
  --        set @infourl = nullif(@infourl, '')
  --      end
  --  end

  -- Check if parameter is not null
  if @actionstatus is not null
    begin
      -- Omit characters
      set @actionstatus = dbo.OmitCharacters(@actionstatus, @omitActionStatus)

      -- Set character limit
      set @actionstatus = trim(substring(@actionstatus, 1, @maxLengthActionStatus))

      -- Check if empty string
      if @actionstatus = ''
        begin
          -- Set parameter to null if empty string
          set @actionstatus = nullif(@actionstatus, '')
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

  -- Else check if option mode is extract movie feed
  if @optionMode = 'extractMovieFeed'
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
      mf.titlelong as [titlelong],
      mf.titleshort as [titleshort],
	  mf.info_url as [infourl],
      format(mf.publish_date, ''yyyy-MM-dd HH:mm:ss.ffffff'',''en-us'') as [publishdate],
      cast(mf.actionstatus as nvarchar(255)) as [actionstatus]
      from dbo.MovieFeed mf'

      -- Check if where clause is given
      if @titlelong is not null
        begin
          -- Set variable
          set @dSQLWhere = 'mf.titlelong = @_titlelongString'
        end

      -- Check if where clause is given
      if @titleshort is not null
        begin
          -- Check if dynamic SQL is not empty
          if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = @dSQLWhere + ' and mf.titleshort = @_titleshortString'
            end
          else
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = 'mf.titleshort = @_titleshortString'
            end
        end

      -- Check if where clause is given
      if @actionstatus is not null
        begin
          -- Check if dynamic SQL is not empty
          if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = @dSQLWhere + ' and mf.actionstatus = (@_actionstatusString)'
            end
          else
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = 'mf.actionstatus = (@_actionstatusString)'
            end
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by mf.publish_date ' + @sort + ', mf.titlelong ' + @sort + ', mf.titleshort ' + @sort + ', mf.actionstatus ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_titlelongString as nvarchar(255), @_titleshortString as nvarchar(255), @_actionstatusString int, @_limitString as int',
      @_titlelongString = @titlelong, @_titleshortString = @titleshort, @_actionstatusString = @actionstatus, @_limitString = @limit
    end

  -- Else check if option mode is extract tv feed
  else if @optionMode = 'extractTVFeed'
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
      tvf.titlelong as [titlelong],
      tvf.titleshort as [titleshort],
	  tvf.info_url as [infourl],
      format(tvf.publish_date, ''yyyy-MM-dd HH:mm:ss.ffffff'',''en-us'') as [publishdate],
      cast(tvf.actionstatus as nvarchar(255)) as [actionstatus]
      from dbo.TVFeed tvf'

      -- Check if where clause is given
      if @titlelong is not null
        begin
          -- Set variable
          set @dSQLWhere = 'tvf.titlelong = @_titlelongString'
        end

      -- Check if where clause is given
      if @titleshort is not null
        begin
          -- Check if dynamic SQL is not empty
          if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = @dSQLWhere + ' and tvf.titleshort = @_titleshortString'
            end
          else
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = 'tvf.titleshort = @_titleshortString'
            end
        end

      -- Check if where clause is given
      if @actionstatus is not null
        begin
          -- Check if dynamic SQL is not empty
          if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = @dSQLWhere + ' and tvf.actionstatus = (@_actionstatusString)'
            end
          else
            begin
              -- Include the next filter into the where clause
              set @dSQLWhere = 'tvf.actionstatus = (@_actionstatusString)'
            end
        end

      -- Check if dynamic SQL is not empty
      if ltrim(rtrim(@dSQLWhere )) <> ltrim(rtrim(''))
        begin
          -- Include the where clause
          set @dSQLWhere = ' where ' + @dSQLWhere
        end

      -- Set the dynamic string with the where clause and sort option
      set @dSQL = @dSQL + @dSQLWhere + ' order by tvf.publish_date ' + @sort + ', tvf.titlelong ' + @sort + ', tvf.titleshort ' + @sort + ', tvf.actionstatus ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_titlelongString as nvarchar(255), @_titleshortString as nvarchar(255), @_actionstatusString int, @_limitString as int',
      @_titlelongString = @titlelong, @_titleshortString = @titleshort, @_actionstatusString = @actionstatus, @_limitString = @limit
    end
end
GO
/****** Object:  StoredProcedure [dbo].[extractNewsFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
      set @dSQL = @dSQL + @dSQLWhere + ' order by nf.publish_date ' + @sort + ', nf.title ' + @sort + ', nf.imageurl ' + @sort + ', nf.feedurl ' + @sort + ', nf.actualurl ' + @sort

      -- Execute dynamic statement with the parameterized values
      -- Important Note: Parameterizated values need to match the parameters they are matching at the top of the script
      exec sp_executesql @dSQL,
      N'@_titleString as nvarchar(255), @_imageurlString as nvarchar(255), @_feedurlString as nvarchar(768), @_actualurlString as nvarchar(255), @_limitString as int',
      @_titleString = @title, @_imageurlString = @imageurl, @_feedurlString = @feedurl, @_actualurlString = @actualurl, @_limitString = @limit
    end
end
GO
/****** Object:  StoredProcedure [dbo].[insertupdatedeleteBulkMediaFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================
--        File: insertupdatedeleteBulkMediaFeed
--     Created: 08/26/2020
--     Updated: 09/29/2023
--  Programmer: Cuates
--   Update By: Cuates
--     Purpose: Insert Update Delete Bulk Media Feed
-- =================================================

-- Procedure Create
CREATE procedure [dbo].[insertupdatedeleteBulkMediaFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @titlelong nvarchar(max) = null,
  @titleshort nvarchar(max) = null,
  @publishdate nvarchar(max) = null,
  @infourl nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @yearString as nvarchar(max)
  declare @omitOptionMode as nvarchar(max)
  declare @omitTitleLong as nvarchar(max)
  declare @omitTitleShort as nvarchar(max)
  declare @omitPublishDate as nvarchar(max)
  declare @omitInfoUrl as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthTitleLong as int
  declare @maxLengthTitleShort as int
  declare @maxLengthPublishDate as int
  declare @maxLengthInfoUrl as int
  declare @result as nvarchar(max)

  -- Set variables
  set @yearString = ''
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitleLong = N'-,.,'',0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitleShort = N'-,.,'',0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitPublishDate = N' ,-,/,0,1,2,3,4,5,6,7,8,9,:,.'
  set @omitInfoUrl = N'-,.,/,%,?,=,&,:,0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @maxLengthOptionMode = 255
  set @maxLengthTitleLong = 255
  set @maxLengthTitleShort = 255
  set @maxLengthPublishDate = 255
  set @maxLengthInfoUrl = 8000
  set @result = ''

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
  if @titlelong is not null
    begin
      -- Omit characters
      set @titlelong = dbo.OmitCharacters(@titlelong, @omitTitleLong)

      -- Set character limit
      set @titlelong = trim(substring(@titlelong, 1, @maxLengthTitleLong))

      -- Check if empty string
      if @titlelong = ''
        begin
          -- Set parameter to null if empty string
          set @titlelong = nullif(@titlelong, '')
        end
    end

  -- Check if parameter is not null
  if @titleshort is not null
    begin
      -- Omit characters
      set @titleshort = dbo.OmitCharacters(@titleshort, @omitTitleShort)

      -- Set character limit
      set @titleshort = trim(substring(@titleshort, 1, @maxLengthTitleShort))

      -- Check if empty string
      if @titleshort = ''
        begin
          -- Set parameter to null if empty string
          set @titleshort = nullif(@titleshort, '')
        end
    end

  -- Check if parameter is not null
  if @publishdate is not null
    begin
      -- Omit characters
      set @publishdate = dbo.OmitCharacters(@publishdate, @omitPublishDate)

      -- Set character limit
      set @publishdate = trim(substring(@publishdate, 1, @maxLengthPublishDate))

      -- Check if the parameter cannot be casted into a date time
      if try_cast(@publishdate as datetime2(6)) is null
        begin
          -- Set the string as empty to be nulled below
          set @publishdate = ''
        end

      -- Check if empty string
      if @publishdate = ''
        begin
          -- Set parameter to null if empty string
          set @publishdate = nullif(@publishdate, '')
        end
    end

  -- Check if parameter is not null
  if @infourl is not null
    begin
      -- Omit characters
      set @infourl = dbo.OmitCharacters(@infourl, @omitInfoUrl)

      -- Set character limit
      set @infourl = trim(substring(@infourl, 1, @maxLengthInfoUrl))

      -- Check if empty string
      if @infourl = ''
        begin
          -- Set parameter to null if empty string
          set @infourl = nullif(@infourl, '')
        end
    end

  -- Check if option mode is delete temp movie
  if @optionMode = 'deleteTempMovie'
    begin
      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Delete records
          delete
          from dbo.MovieFeedTemp

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) deleted"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch
        -- End catch block

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is delete temp tv
  else if @optionMode = 'deleteTempTV'
    begin
      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Delete records
          delete
          from dbo.TVFeedTemp

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) deleted"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch
        -- End catch block

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert temp movie
  else if @optionMode = 'insertTempMovie'
    begin
      -- Check if parameters are null
      if @titlelong is not null and @titleshort is not null and @publishdate is not null
        begin
          -- Begin the tranaction
          begin tran
            -- Begin the try block
            begin try
              -- Insert record
              insert into dbo.MovieFeedTemp
              (
                titlelong,
                titleshort,
				info_url,
                publish_date,
                created_date
              )
              values
              (
                @titlelong,
                lower(@titleshort),
				@infourl,
                @publishdate,
                cast(getdate() as datetime2(6))
              )

              -- Check if there is trans count
              if @@trancount > 0
                begin
                  -- Commit transactional statement
                  commit tran
                end

              -- Set message
              set @result = '{"Status": "Success", "Message": "Record(s) inserted"}'
            end try
            -- End try block
            -- Begin catch block
            begin catch
              -- Check if there is trans count
              if @@trancount > 0
                begin
                  -- Rollback to the previous state before the transaction was called
                  rollback
                end

              -- Set message
              set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
            end catch
            -- End catch block
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long, title short, and or publish date were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert temp tv
  else if @optionMode = 'insertTempTV'
    begin
      -- Check if parameters are null
      if @titlelong is not null and @titleshort is not null and @publishdate is not null
        begin
          -- Begin the tranaction
          begin tran
            -- Begin the try block
            begin try
              -- Insert record
              insert into dbo.TVFeedTemp
              (
                titlelong,
                titleshort,
				info_url,
                publish_date,
                created_date
              )
              values
              (
                @titlelong,
                lower(@titleshort),
				@infourl,
                @publishdate,
                cast(getdate() as datetime2(6))
              )

              -- Check if there is trans count
              if @@trancount > 0
                begin
                  -- Commit transactional statement
                  commit tran
                end

              -- Set message
              set @result = '{"Status": "Success", "Message": "Record(s) inserted"}'
            end try
            -- End try block
            -- Begin catch block
            begin catch
              -- Check if there is trans count
              if @@trancount > 0
                begin
                  -- Rollback to the previous state before the transaction was called
                  rollback
                end

              -- Set message
              set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
            end catch
            -- End catch block
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long, title short, and or publish date were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update bulk movie
  else if @optionMode = 'updateBulkMovie'
    begin
      -- Set variables
      select
      @yearString = iif(datepart(month, getdate()) <= 3, cast(datepart(year, dateadd(year, -1, getdate())) as nvarchar) + '|' + cast(datepart(year, getdate()) as nvarchar), cast(datepart(year, getdate()) as nvarchar))

      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Remove duplicate records based on group by
          ;with subMovieDetails as
          (
            -- Select unique records
            select
            trim(substring(dbo.OmitCharacters(mft.titlelong, @omitTitleLong), 1, @maxLengthTitleLong)) as titlelong,
            trim(substring(dbo.OmitCharacters(mft.titleshort, @omitTitleShort), 1, @maxLengthTitleShort)) as titleshort,
			trim(substring(dbo.OmitCharacters(mft.info_url, @omitInfoUrl), 1, @maxLengthInfoUrl)) as info_url,
            trim(substring(dbo.OmitCharacters(mft.publish_date, @omitPublishDate), 1, @maxLengthPublishDate)) as publish_date
            from dbo.MovieFeedTemp mft
            where
            (
              (
                trim(mft.titlelong) <> '' and
                trim(mft.titleshort) <> '' and
                trim(mft.publish_date) <> ''
              ) or
              (
                mft.titlelong is not null and
                mft.titleshort is not null and
                mft.publish_date is not null
              )
            )
            group by mft.titlelong, mft.titleshort, mft.info_url, mft.publish_date
          ),
          movieDetails as
          (
            -- Select unique records
            select
            smd.titlelong as titlelong,
            smd.titleshort as titleshort,
			smd.info_url as info_url,
            smd.publish_date as publish_date,
            mfas.actionstatus as actionstatus,
            mf.mfID as mfID
            from subMovieDetails smd
            left join dbo.MovieFeed mf on mf.titlelong = smd.titlelong
            left join dbo.MovieFeed mfas on mfas.titleshort = smd.titleshort
            join dbo.MediaAudioEncode mae on mae.movieInclude in (1) and smd.titlelong like concat('%', mae.audioencode, '%')
            left join dbo.MediaDynamicRange mdr on mdr.movieInclude in (1) and smd.titlelong like concat('%', mdr.dynamicrange, '%')
            join dbo.MediaResolution mr on mr.movieInclude in (1) and smd.titlelong like concat('%', mr.resolution, '%')
            left join dbo.MediaStreamSource mss on mss.movieInclude in (1) and smd.titlelong like concat('%', mss.streamsource, '%')
            join dbo.MediaVideoEncode mve on mve.movieInclude in (1) and smd.titlelong like concat('%', mve.videoencode, '%')
            inner join (select smdii.titlelong, max(smdii.publish_date) as publish_date from subMovieDetails smdii group by smdii.titlelong) as smdi on smdi.titlelong = smd.titlelong and smdi.publish_date = smd.publish_date
            where
            mfas.actionstatus not in (1) and
            mf.mfID is not null and
            (
              (
                @yearString like '%|%' and
                (
                  smd.titlelong like concat('%', substring(@yearString, 1, 4), '%') or
                  smd.titlelong like concat('%', substring(@yearString, 6, 9), '%')
                )
              ) or
              (
                smd.titlelong like concat('%', substring(@yearString, 1, 4), '%')
              )
            )
            group by smd.titlelong, smd.titleshort, smd.info_url, smd.publish_date, mfas.actionstatus, mf.mfID
          )

          -- Update records
          update dbo.MovieFeed
          set
		  info_url = md.info_url,
          publish_date = cast(md.publish_date as datetime2(6)),
          modified_date = cast(getdate() as datetime2(6))
          from movieDetails md
          where
          md.mfID = dbo.MovieFeed.mfID

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) updated"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update bulk tv
  else if @optionMode = 'updateBulkTV'
    begin
      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Remove duplicate records based on group by
          ;with subTVDetails as
          (
            -- Select unique records
            select
            trim(substring(dbo.OmitCharacters(tft.titlelong, @omitTitleLong), 1, @maxLengthTitleLong)) as titlelong,
            trim(substring(dbo.OmitCharacters(tft.titleshort, @omitTitleShort), 1, @maxLengthTitleShort)) as titleshort,
			trim(substring(dbo.OmitCharacters(tft.info_url, @omitInfoUrl), 1, @maxLengthInfoUrl)) as info_url,
            trim(substring(dbo.OmitCharacters(tft.publish_date, @omitPublishDate), 1, @maxLengthPublishDate)) as publish_date
            from dbo.TVFeedTemp tft
            where
            (
              (
                trim(tft.titlelong) <> '' and
                trim(tft.titleshort) <> '' and
                trim(tft.publish_date) <> ''
              ) or
              (
                tft.titlelong is not null and
                tft.titleshort is not null and
                tft.publish_date is not null
              )
            )
            group by tft.titlelong, tft.titleshort, tft.info_url, tft.publish_date
          ),
          tvDetails as
          (
            -- Select unique records
            select
            std.titlelong as titlelong,
            std.titleshort as titleshort,
			std.info_url as info_url,
            std.publish_date as publish_date,
            tfas.actionstatus as actionstatus,
            tf.tfID as tfID
            from subTVDetails std
            left join dbo.TVFeed tf on tf.titlelong = std.titlelong
            left join dbo.TVFeed tfas on tfas.titleshort = std.titleshort
            join dbo.MediaAudioEncode mae on mae.tvInclude in (1) and std.titlelong like concat('%', mae.audioencode, '%')
            left join dbo.MediaDynamicRange mdr on mdr.tvInclude in (1) and std.titlelong like concat('%', mdr.dynamicrange, '%')
            join dbo.MediaResolution mr on mr.tvInclude in (1) and std.titlelong like concat('%', mr.resolution, '%')
            left join dbo.MediaStreamSource mss on mss.tvInclude in (1) and std.titlelong like concat('%', mss.streamsource, '%')
            join dbo.MediaVideoEncode mve on mve.tvInclude in (1) and std.titlelong like concat('%', mve.videoencode, '%')
            inner join (select stdii.titlelong, max(stdii.publish_date) as publish_date from subTVDetails stdii group by stdii.titlelong) as stdi on stdi.titlelong = std.titlelong and stdi.publish_date = std.publish_date
            where
            tfas.actionstatus not in (1) and
            tf.tfID is not null
            group by std.titlelong, std.titleshort, std.info_url, std.publish_date, tfas.actionstatus, tf.tfID
          )

          -- Update records
          update dbo.TVFeed
          set
		  info_url = td.info_url,
          publish_date = cast(td.publish_date as datetime2(6)),
          modified_date = cast(getdate() as datetime2(6))
          from tvDetails td
          where
          td.tfID = dbo.TVFeed.tfID

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) updated"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert bulk movie
  else if @optionMode = 'insertBulkMovie'
    begin
      -- Set variables
      select
      @yearString = iif(datepart(month, getdate()) <= 3, cast(datepart(year, dateadd(year, -1, getdate())) as nvarchar) + '|' + cast(datepart(year, getdate()) as nvarchar), cast(datepart(year, getdate()) as nvarchar))

      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Remove duplicate records based on group by
          ;with subMovieDetails as
          (
            -- Select unique records
            select
            trim(substring(dbo.OmitCharacters(mft.titlelong, @omitTitleLong), 1, @maxLengthTitleLong)) as titlelong,
            trim(substring(dbo.OmitCharacters(mft.titleshort, @omitTitleShort), 1, @maxLengthTitleShort)) as titleshort,
			trim(substring(dbo.OmitCharacters(mft.info_url, @omitInfoUrl), 1, @maxLengthInfoUrl)) as info_url,
            trim(substring(dbo.OmitCharacters(mft.publish_date, @omitPublishDate), 1, @maxLengthPublishDate)) as publish_date
            from dbo.MovieFeedTemp mft
            where
            (
              (
                trim(mft.titlelong) <> '' and
                trim(mft.titleshort) <> '' and
                trim(mft.publish_date) <> ''
              ) or
              (
                mft.titlelong is not null and
                mft.titleshort is not null and
                mft.publish_date is not null
              )
            )
            group by mft.titlelong, mft.titleshort, mft.info_url, mft.publish_date
          ),
          movieDetails as
          (
            -- Select unique records
            select
            substring(dbo.OmitCharacters(smd.titlelong, @omitTitleLong), 1, @maxLengthTitleLong) as titlelong,
            substring(dbo.OmitCharacters(smd.titleshort, @omitTitleShort), 1, @maxLengthTitleShort) as titleshort,
			trim(substring(dbo.OmitCharacters(smd.info_url, @omitInfoUrl), 1, @maxLengthInfoUrl)) as info_url,
            substring(dbo.OmitCharacters(smd.publish_date, @omitPublishDate), 1, @maxLengthPublishDate) as publish_date,
            mfas.actionstatus as actionstatus,
            mf.mfID as mfID
            from subMovieDetails smd
            left join dbo.MovieFeed mf on mf.titlelong = smd.titlelong
            left join dbo.MovieFeed mfas on mfas.titleshort = smd.titleshort
            join dbo.MediaAudioEncode mae on mae.movieInclude in (1) and smd.titlelong like concat('%', mae.audioencode, '%')
            left join dbo.MediaDynamicRange mdr on mdr.movieInclude in (1) and smd.titlelong like concat('%', mdr.dynamicrange, '%')
            join dbo.MediaResolution mr on mr.movieInclude in (1) and smd.titlelong like concat('%', mr.resolution, '%')
            left join dbo.MediaStreamSource mss on mss.movieInclude in (1) and smd.titlelong like concat('%', mss.streamsource, '%')
            join dbo.MediaVideoEncode mve on mve.movieInclude in (1) and smd.titlelong like concat('%', mve.videoencode, '%')
            inner join (select smdii.titlelong, max(smdii.publish_date) as publish_date from subMovieDetails smdii group by smdii.titlelong) as smdi on smdi.titlelong = smd.titlelong and smdi.publish_date = smd.publish_date
            where
            (
              mfas.actionstatus not in (1) or
              mfas.actionstatus is null
            ) and
            mf.mfID is null and
            (
              (
                @yearString like '%|%' and
                (
                  smd.titlelong like concat('%', substring(@yearString, 1, 4), '%') or
                  smd.titlelong like concat('%', substring(@yearString, 6, 9), '%')
                )
              ) or
              (
                smd.titlelong like concat('%', substring(@yearString, 1, 4), '%')
              )
            )
            group by smd.titlelong, smd.titleshort, smd.info_url, smd.publish_date, mfas.actionstatus, mf.mfID
          )

          -- Insert records
          insert into dbo.MovieFeed
          (
            titlelong,
            titleshort,
			info_url,
            publish_date,
            actionstatus,
            created_date,
            modified_date
          )
          select
          md.titlelong,
          md.titleshort,
		  md.info_url,
          cast(md.publish_date as datetime2(6)),
          iif(md.actionstatus is null, 0, md.actionstatus),
          cast(getdate() as datetime2(6)),
          cast(getdate() as datetime2(6))
          from movieDetails md
          group by md.titlelong, md.titleshort, md.info_url, md.publish_date, md.actionstatus

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) inserted"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert bulk tv
  else if @optionMode = 'insertBulkTV'
    begin
      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Remove duplicate records based on group by
          ;with subTVDetails as
          (
            -- Select unique records
            select
            trim(substring(dbo.OmitCharacters(tft.titlelong, @omitTitleLong), 1, @maxLengthTitleLong)) as titlelong,
            trim(substring(dbo.OmitCharacters(tft.titleshort, @omitTitleShort), 1, @maxLengthTitleShort)) as titleshort,
			trim(substring(dbo.OmitCharacters(tft.info_url, @omitInfoUrl), 1, @maxLengthInfoUrl)) as info_url,
            trim(substring(dbo.OmitCharacters(tft.publish_date, @omitPublishDate), 1, @maxLengthPublishDate)) as publish_date
            from dbo.TVFeedTemp tft
            where
            (
              (
                trim(tft.titlelong) <> '' and
                trim(tft.titleshort) <> '' and
                trim(tft.publish_date) <> ''
              ) or
              (
                tft.titlelong is not null and
                tft.titleshort is not null and
                tft.publish_date is not null
              )
            )
            group by tft.titlelong, tft.titleshort, tft.info_url, tft.publish_date
          ),
          tvDetails as
          (
            -- Select unique records
            select
			substring(dbo.OmitCharacters(std.titlelong, @omitTitleLong), 1, @maxLengthTitleLong) as titlelong,
            substring(dbo.OmitCharacters(std.titleshort, @omitTitleShort), 1, @maxLengthTitleShort) as titleshort,
			trim(substring(dbo.OmitCharacters(std.info_url, @omitInfoUrl), 1, @maxLengthInfoUrl)) as info_url,
            substring(dbo.OmitCharacters(std.publish_date, @omitPublishDate), 1, @maxLengthPublishDate) as publish_date,
            tfas.actionstatus as actionstatus,
            tf.tfID as tfID
            from subTVDetails std
            left join dbo.TVFeed tf on tf.titlelong = std.titlelong
            left join dbo.TVFeed tfas on tfas.titleshort = std.titleshort
            join dbo.MediaAudioEncode mae on mae.tvInclude in (1) and std.titlelong like concat('%', mae.audioencode, '%')
            left join dbo.MediaDynamicRange mdr on mdr.tvInclude in (1) and std.titlelong like concat('%', mdr.dynamicrange, '%')
            join dbo.MediaResolution mr on mr.tvInclude in (1) and std.titlelong like concat('%', mr.resolution, '%')
            left join dbo.MediaStreamSource mss on mss.tvInclude in (1) and std.titlelong like concat('%', mss.streamsource, '%')
            join dbo.MediaVideoEncode mve on mve.tvInclude in (1) and std.titlelong like concat('%', mve.videoencode, '%')
            inner join (select stdii.titlelong, max(stdii.publish_date) as publish_date from subTVDetails stdii group by stdii.titlelong) as stdi on stdi.titlelong = std.titlelong and stdi.publish_date = std.publish_date
            where
            (
              tfas.actionstatus not in (1) or
              tfas.actionstatus is null
            ) and
            tf.tfID is null
            group by std.titlelong, std.titleshort, std.info_url, std.publish_date, tfas.actionstatus, tf.tfID
          )

          -- Insert records
          insert into dbo.TVFeed
          (
            titlelong,
            titleshort,
			info_url,
            publish_date,
            actionstatus,
            created_date,
            modified_date
          )
          select
          td.titlelong,
          td.titleshort,
		  td.info_url,
          cast(td.publish_date as datetime2(6)),
          iif(td.actionstatus is null, 0, td.actionstatus),
          cast(getdate() as datetime2(6)),
          cast(getdate() as datetime2(6))
          from tvDetails td
          group by td.titlelong, td.titleshort, td.info_url, td.publish_date, td.actionstatus

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) inserted"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch

      -- Select message
      select
      @result as [status]
    end
end
GO
/****** Object:  StoredProcedure [dbo].[insertupdatedeleteBulkNewsFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
--        File: insertupdatedeleteBulkNewsFeed
--     Created: 09/07/2020
--     Updated: 11/19/2020
--  Programmer: Cuates
--   Update By: Cuates
--     Purpose: Insert Update Delete Bulk News Feed
-- ================================================

-- Procedure Create
create procedure [dbo].[insertupdatedeleteBulkNewsFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @title nvarchar(max) = null,
  @imageurl nvarchar(max) = null,
  @feedurl nvarchar(max) = null,
  @actualurl nvarchar(max) = null,
  @publishdate nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @omitOptionMode as nvarchar(max)
  declare @omitTitle as nvarchar(max)
  declare @omitImageurl as nvarchar(max)
  declare @omitFeedurl as nvarchar(max)
  declare @omitActualurl as nvarchar(max)
  declare @omitPublishDate as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthTitle as int
  declare @maxLengthImageurl as int
  declare @maxLengthFeedurl as int
  declare @maxLengthActualurl as int
  declare @maxLengthPublishDate as int
  declare @result as nvarchar(max)

  -- Set variables
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitle = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitImageurl = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitFeedurl = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitActualurl = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitPublishDate = N' ,-,/,0,1,2,3,4,5,6,7,8,9,:,.'
  set @maxLengthOptionMode = 255
  set @maxLengthTitle = 255
  set @maxLengthImageurl = 255
  set @maxLengthFeedurl = 768
  set @maxLengthActualurl = 255
  set @maxLengthPublishDate = 255
  set @result = ''

  -- Check if parameter is not null
  if @optionMode is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
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
      set @imageurl = dbo.OmitCharacters(@imageurl, @omitImageurl)

      -- Set character limit
      set @imageurl = trim(substring(@imageurl, 1, @maxLengthImageurl))

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
      set @feedurl = dbo.OmitCharacters(@feedurl, @omitFeedurl)

      -- Set character limit
      set @feedurl = trim(substring(@feedurl, 1, @maxLengthFeedurl))

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
      set @actualurl = dbo.OmitCharacters(@actualurl, @omitActualurl)

      -- Set character limit
      set @actualurl = trim(substring(@actualurl, 1, @maxLengthActualurl))

      -- Check if empty string
      if @actualurl = ''
        begin
          -- Set parameter to null if empty string
          set @actualurl = nullif(@actualurl, '')
        end
    end

  -- Check if parameter is not null
  if @publishdate is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @publishdate = dbo.OmitCharacters(@publishdate, @omitPublishDate)

      -- Set character limit
      set @publishdate = trim(substring(@publishdate, 1, @maxLengthPublishDate))

      -- Check if the parameter cannot be casted into a date time
      if try_cast(@publishdate as datetime2(6)) is null
        begin
          -- Set the string as empty to be nulled below
          set @publishdate = ''
        end

      -- Check if empty string
      if @publishdate = ''
        begin
          -- Set parameter to null if empty string
          set @publishdate = nullif(@publishdate, '')
        end
    end

  -- Check if option mode is delete temp news
  if @optionMode = 'deleteTempNews'
    begin
      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Delete records
          delete
          from dbo.NewsFeedTemp

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) deleted"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch
        -- End catch block

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert temp news
  else if @optionMode = 'insertTempNews'
    begin
      -- Check if parameters are not null
      if @title is not null and @publishdate is not null
        begin
          -- Begin the tranaction
          begin tran
            -- Begin the try block
            begin try
              -- Insert record
              insert into dbo.NewsFeedTemp
              (
                title,
                imageurl,
                feedurl,
                actualurl,
                publish_date,
                created_date
              )
              values
              (
                @title,
                iif(trim(@imageurl) = '', null, @imageurl),
                @feedurl,
                iif(trim(@actualurl) = '', null, @actualurl),
                @publishdate,
                cast(getdate() as datetime2(6))
              )

              -- Check if there is trans count
              if @@trancount > 0
                begin
                  -- Commit transactional statement
                  commit tran
                end

              -- Set message
              set @result = '{"Status": "Success", "Message": "Record(s) inserted"}'
            end try
            -- End try block
            -- Begin catch block
            begin catch
              -- Check if there is trans count
              if @@trancount > 0
                begin
                  -- Rollback to the previous state before the transaction was called
                  rollback
                end

              -- Set message
              set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
            end catch
            -- End catch block
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title and or publish date were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update bulk news
  else if @optionMode = 'updateBulkNews'
    begin
      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Remove duplicate records based on group by
          ;with subNewsDetails as
          (
            -- Select unique records
            select
            trim(substring(dbo.OmitCharacters(nft.title, @omitTitle), 1, @maxLengthTitle)) as title,
            trim(substring(dbo.OmitCharacters(nft.imageurl, @omitImageurl), 1, @maxLengthImageurl)) as imageurl,
            trim(substring(dbo.OmitCharacters(nft.feedurl, @omitFeedurl), 1, @maxLengthFeedurl)) as feedurl,
            trim(substring(dbo.OmitCharacters(nft.actualurl, @omitActualurl), 1, @maxLengthActualurl)) as actualurl,
            trim(substring(dbo.OmitCharacters(nft.publish_date, @omitPublishDate), 1, @maxLengthPublishDate)) as publish_date
            from dbo.NewsFeedTemp nft
            where
            (
              (
                trim(nft.title) <> '' and
                trim(nft.feedurl) <> '' and
                trim(nft.publish_date) <> ''
              ) or
              (
                nft.title is not null and
                nft.feedurl is not null and
                nft.publish_date is not null
              )
            ) and
            (
              cast(nft.publish_date as datetime2(6)) >= dateadd(hour, -1, getdate()) and
              cast(nft.publish_date as datetime2(6)) <= dateadd(hour, 0, getdate())
            )
            group by nft.title, nft.imageurl, nft.feedurl, nft.actualurl, nft.publish_date
          ),
          newsDetails as
          (
            -- Select unique records
            select
            snd.title as title,
            snd.imageurl as imageurl,
            snd.feedurl as feedurl,
            snd.actualurl as actualurl,
            snd.publish_date as publish_date,
            nf.nfID as nfID
            from subNewsDetails snd
            left join dbo.NewsFeed nf on nf.title = snd.title
            inner join (select sndii.title, max(sndii.publish_date) as publish_date from subNewsDetails sndii group by sndii.title) as sndi on sndi.title = snd.title and sndi.publish_date = snd.publish_date
            where
            nf.nfID is not null
            group by snd.title, snd.imageurl, snd.feedurl, snd.actualurl, snd.publish_date, nf.nfID
          )

          -- Update records
          update dbo.NewsFeed
          set
          imageurl = iif(trim(nd.imageurl) = '', null, nd.imageurl),
          feedurl = nd.feedurl,
          actualurl = iif(trim(nd.actualurl) = '', null, nd.actualurl),
          publish_date = cast(nd.publish_date as datetime2(6)),
          modified_date = cast(getdate() as datetime2(6))
          from newsDetails nd
          where
          nd.nfID = dbo.NewsFeed.nfID

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) updated"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert bulk news
  else if @optionMode = 'insertBulkNews'
    begin
      -- Begin the tranaction
      begin tran
        -- Begin the try block
        begin try
          -- Remove duplicate records based on group by
          ;with subNewsDetails as
          (
            -- Select unique records
            select
            trim(substring(dbo.OmitCharacters(nft.title, @omitTitle), 1, @maxLengthTitle)) as title,
            trim(substring(dbo.OmitCharacters(nft.imageurl, @omitImageurl), 1, @maxLengthImageurl)) as imageurl,
            trim(substring(dbo.OmitCharacters(nft.feedurl, @omitFeedurl), 1, @maxLengthFeedurl)) as feedurl,
            trim(substring(dbo.OmitCharacters(nft.actualurl, @omitActualurl), 1, @maxLengthActualurl)) as actualurl,
            trim(substring(dbo.OmitCharacters(nft.publish_date, @omitPublishDate), 1, @maxLengthPublishDate)) as publish_date
            from dbo.NewsFeedTemp nft
            where
            (
              (
                trim(nft.title) <> '' and
                trim(nft.feedurl) <> '' and
                trim(nft.publish_date) <> ''
              ) or
              (
                nft.title is not null and
                nft.feedurl is not null and
                nft.publish_date is not null
              )
            ) -- and
            -- (
            --   cast(nft.publish_date as datetime2(6)) >= dateadd(hour, -1, getdate()) and
            --   cast(nft.publish_date as datetime2(6)) <= dateadd(hour, 0, getdate())
            -- )
            group by nft.title, nft.imageurl, nft.feedurl, nft.actualurl, nft.publish_date
          ),
          newsDetails as
          (
            -- Select unique records
            select
            snd.title as title,
            snd.imageurl as imageurl,
            snd.feedurl as feedurl,
            snd.actualurl as actualurl,
            snd.publish_date as publish_date,
            nf.nfID as nfID
            from subNewsDetails snd
            left join dbo.NewsFeed nf on nf.title = snd.title
            inner join (select sndii.title, max(sndii.publish_date) as publish_date from subNewsDetails sndii group by sndii.title) as sndi on sndi.title = snd.title and sndi.publish_date = snd.publish_date
            where
            nf.nfID is null
            group by snd.title, snd.imageurl, snd.feedurl, snd.actualurl, snd.publish_date, nf.nfID
          )

          -- Insert records
          insert into dbo.NewsFeed
          (
            title,
            imageurl,
            feedurl,
            actualurl,
            publish_date,
            created_date,
            modified_date
          )
          select
          nd.title,
          iif(trim(nd.imageurl) = '', null, nd.imageurl),
          nd.feedurl,
          iif(trim(nd.actualurl) = '', null, nd.actualurl),
          cast(nd.publish_date as datetime2(6)),
          cast(getdate() as datetime2(6)),
          cast(getdate() as datetime2(6))
          from newsDetails nd
          group by nd.title, nd.imageurl, nd.feedurl, nd.actualurl, nd.publish_date

          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Commit transactional statement
              commit tran
            end

          -- Set message
          set @result = '{"Status": "Success", "Message": "Record(s) inserted"}'
        end try
        -- End try block
        -- Begin catch block
        begin catch
          -- Check if there is trans count
          if @@trancount > 0
            begin
              -- Rollback to the previous state before the transaction was called
              rollback
            end

          -- Set message
          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
        end catch

      -- Select message
      select
      @result as [status]
    end
end
GO
/****** Object:  StoredProcedure [dbo].[insertupdatedeleteControlMediaFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
--        File: insertupdatedeleteControlMediaFeed
--     Created: 11/16/2020
--     Updated: 11/18/2020
--  Programmer: Cuates
--   Update By: Cuates
--     Purpose: Insert update delete control media feed
-- ================================================

-- Procedure Create
create procedure [dbo].[insertupdatedeleteControlMediaFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @actionnumber nvarchar(max) = null,
  @actiondescription nvarchar(max) = null,
  @audioencode nvarchar(max) = null,
  @dynamicrange nvarchar(max) = null,
  @resolution nvarchar(max) = null,
  @streamsource nvarchar(max) = null,
  @streamdescription nvarchar(max) = null,
  @videoencode nvarchar(max) = null,
  @movieinclude nvarchar(max) = null,
  @tvinclude nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @omitOptionMode as nvarchar(max)
  declare @omitActionNumber as nvarchar(max)
  declare @omitActionDescription as nvarchar(max)
  declare @omitMediaAudioEncode as nvarchar(max)
  declare @omitMediaDynamicRange as nvarchar(max)
  declare @omitMediaResolution as nvarchar(max)
  declare @omitMediaStreamSource as nvarchar(max)
  declare @omitMediaStreamDescription as nvarchar(max)
  declare @omitMediaVideoEncode as nvarchar(max)
  declare @omitMovieInclude as nvarchar(max)
  declare @omitTVInclude as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthActionNumber as int
  declare @maxLengthActionDescription as int
  declare @maxLengthMediaAudioEncode as int
  declare @maxLengthMediaDynamicRange as int
  declare @maxLengthMediaResolution as int
  declare @maxLengthMediaStreamSource as int
  declare @maxLengthMediaStreamDescription as int
  declare @maxLengthMediaVideoEncode as int
  declare @maxLengthMovieInclude as int
  declare @maxLengthTVInclude as int
  declare @result as nvarchar(max)

  -- Set variables
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitActionNumber = N'0,1,2,3,4,5,6,7,8,9'
  set @omitActionDescription = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitMediaAudioEncode = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9,.,-'
  set @omitMediaDynamicRange = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z'
  set @omitMediaResolution = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9'
  set @omitMediaStreamSource = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitMediaStreamDescription = N'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitMediaVideoEncode = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9'
  set @omitMovieInclude = N'0,1'
  set @omitTVInclude = N'0,1'
  set @maxLengthOptionMode = 255
  set @maxLengthActionNumber = 255
  set @maxLengthActionDescription = 255
  set @maxLengthMediaAudioEncode = 100
  set @maxLengthMediaDynamicRange = 100
  set @maxLengthMediaResolution = 100
  set @maxLengthMediaStreamSource = 100
  set @maxLengthMediaStreamDescription = 100
  set @maxLengthMediaVideoEncode = 100
  set @maxLengthMovieInclude = 1
  set @maxLengthTVInclude = 1
  set @result = ''

  -- Check if parameter is not null
  if @optionMode is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @optionMode = dbo.omitcharacters(@optionMode, @omitOptionMode)

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
  if @actionnumber is not null
    begin
      -- Omit characters
      set @actionnumber = dbo.OmitCharacters(@actionnumber, @omitActionNumber)

      -- Set character limit
      set @actionnumber = trim(substring(@actionnumber, 1, @maxLengthActionNumber))

      -- Check if empty string
      if @actionnumber = ''
        begin
          -- Set parameter to null if empty string
          set @actionnumber = nullif(@actionnumber, '')
        end
    end

  -- Check if parameter is not null
  if @actiondescription is not null
    begin
      -- Omit characters
      set @actiondescription = dbo.OmitCharacters(@actiondescription, @omitActionDescription)

      -- Set character limit
      set @actiondescription = trim(substring(@actiondescription, 1, @maxLengthActionDescription))

      -- Check if empty string
      if @actiondescription = ''
        begin
          -- Set parameter to null if empty string
          set @actiondescription = nullif(@actiondescription, '')
        end
    end

  -- Check if parameter is not null
  if @audioencode is not null
    begin
      -- Omit characters
      set @audioencode = dbo.OmitCharacters(@audioencode, @omitMediaAudioEncode)

      -- Set character limit
      set @audioencode = trim(substring(@audioencode, 1, @maxLengthMediaAudioEncode))

      -- Check if empty string
      if @audioencode = ''
        begin
          -- Set parameter to null if empty string
          set @audioencode = nullif(@audioencode, '')
        end
    end

  -- Check if parameter is not null
  if @dynamicrange is not null
    begin
      -- Omit characters
      set @dynamicrange = dbo.OmitCharacters(@dynamicrange, @omitMediaDynamicRange)

      -- Set character limit
      set @dynamicrange = trim(substring(@dynamicrange, 1, @maxLengthMediaDynamicRange))

      -- Check if empty string
      if @dynamicrange = ''
        begin
          -- Set parameter to null if empty string
          set @dynamicrange = nullif(@dynamicrange, '')
        end
    end

  -- Check if parameter is not null
  if @resolution is not null
    begin
      -- Omit characters
      set @resolution = dbo.OmitCharacters(@resolution, @omitMediaResolution)

      -- Set character limit
      set @resolution = trim(substring(@resolution, 1, @maxLengthMediaResolution))

      -- Check if empty string
      if @resolution = ''
        begin
          -- Set parameter to null if empty string
          set @resolution = nullif(@resolution, '')
        end
    end

  -- Check if parameter is not null
  if @streamsource is not null
    begin
      -- Omit characters
      set @streamsource = dbo.OmitCharacters(@streamsource, @omitMediaStreamSource)

      -- Set character limit
      set @streamsource = trim(substring(@streamsource, 1, @maxLengthMediaStreamSource))

      -- Check if empty string
      if @streamsource = ''
        begin
          -- Set parameter to null if empty string
          set @streamsource = nullif(@streamsource, '')
        end
    end

  -- Check if parameter is not null
  if @streamdescription is not null
    begin
      -- Omit characters
      set @streamdescription = dbo.OmitCharacters(@streamdescription, @omitMediaStreamDescription)

      -- Set character limit
      set @streamdescription = trim(substring(@streamdescription, 1, @maxLengthMediaStreamDescription))

      -- Check if empty string
      if @streamdescription = ''
        begin
          -- Set parameter to null if empty string
          set @streamdescription = nullif(@streamdescription, '')
        end
    end

  -- Check if parameter is not null
  if @videoencode is not null
    begin
      -- Omit characters
      set @videoencode = dbo.OmitCharacters(@videoencode, @omitMediaVideoEncode)

      -- Set character limit
      set @videoencode = trim(substring(@videoencode, 1, @maxLengthMediaVideoEncode))

      -- Check if empty string
      if @videoencode = ''
        begin
          -- Set parameter to null if empty string
          set @videoencode = nullif(@videoencode, '')
        end
    end

  -- Check if parameter is not null
  if @movieinclude is not null
    begin
      -- Omit characters
      set @movieinclude = dbo.OmitCharacters(@movieinclude, @omitMovieInclude)

      -- Set character limit
      set @movieinclude = trim(substring(@movieinclude, 1, @maxLengthMovieInclude))

      -- Check if empty string
      if @movieinclude = ''
        begin
          -- Set parameter to null if empty string
          set @movieinclude = nullif(@movieinclude, '')
        end
    end

  -- Check if parameter is not null
  if @tvinclude is not null
    begin
      -- Omit characters
      set @tvinclude = dbo.OmitCharacters(@tvinclude, @omitTVInclude)

      -- Set character limit
      set @tvinclude = trim(substring(@tvinclude, 1, @maxLengthTVInclude))

      -- Check if empty string
      if @tvinclude = ''
        begin
          -- Set parameter to null if empty string
          set @tvinclude = nullif(@tvinclude, '')
        end
    end

  -- Check if option mode is insert action status
  if @optionMode = 'insertActionStatus'
    begin
      -- Check if parameters are null
      if @actionnumber is not null and @actiondescription is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            ast.actionnumber as [actionnumber]
            from dbo.ActionStatus ast
            where
            ast.actionnumber = @actionnumber
            group by ast.actionnumber
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Insert record
                  insert into dbo.ActionStatus
                  (
                    actionnumber,
                    actiondescription,
                    created_date,
                    modified_date
                  )
                  values
                  (
                    @actionnumber,
                    @actiondescription,
                    cast(getdate() as datetime2(6)),
                    cast(getdate() as datetime2(6))
                  )

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record inserted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, action number and action description were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert media audio encode
  else if @optionMode = 'insertMediaAudioEncode'
    begin
      -- Check if parameters are null
      if @audioencode is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            mae.audioencode as [audioencode]
            from dbo.MediaAudioEncode mae
            where
            mae.audioencode = @audioencode
            group by mae.audioencode
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Insert record
                  insert into dbo.MediaAudioEncode
                  (
                    audioencode,
                    movieInclude,
                    tvInclude,
                    created_date,
                    modified_date
                  )
                  values
                  (
                    @audioencode,
                    @movieinclude,
                    @tvinclude,
                    cast(getdate() as datetime2(6)),
                    cast(getdate() as datetime2(6))
                  )

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record inserted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, audio encode, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert media dynamic range
  else if @optionMode = 'insertMediaDynamicRange'
    begin
      -- Check if parameters are null
      if @dynamicrange is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            mdr.dynamicrange as [dynamicrange]
            from dbo.MediaDynamicRange mdr
            where
            mdr.dynamicrange = @dynamicrange
            group by mdr.dynamicrange
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Insert record
                  insert into dbo.MediaDynamicRange
                  (
                    dynamicrange,
                    movieInclude,
                    tvInclude,
                    created_date,
                    modified_date
                  )
                  values
                  (
                    @dynamicrange,
                    @movieinclude,
                    @tvinclude,
                    cast(getdate() as datetime2(6)),
                    cast(getdate() as datetime2(6))
                  )

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record inserted"}'

                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, dynamic range, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert media resolution
  else if @optionMode = 'insertMediaResolution'
    begin
      -- Check if parameters are null
      if @resolution is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            mr.resolution as [resolution]
            from dbo.MediaResolution mr
            where
            mr.resolution = @resolution
            group by mr.resolution
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Insert record
                  insert into dbo.MediaResolution
                  (
                    resolution,
                    movieInclude,
                    tvInclude,
                    created_date,
                    modified_date
                  )
                  values
                  (
                    @resolution,
                    @movieinclude,
                    @tvinclude,
                    cast(getdate() as datetime2(6)),
                    cast(getdate() as datetime2(6))
                  )

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record inserted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, resolution, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert media stream source
  else if @optionMode = 'insertMediaStreamSource'
    begin
      -- Check if parameters are null
      if @streamsource is not null and @streamdescription is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            mss.streamsource as [streamsource]
            from dbo.MediaStreamSource mss
            where
            mss.streamsource = @streamsource
            group by mss.streamsource
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Insert record
                  insert into dbo.MediaStreamSource
                  (
                    streamsource,
                    streamdescription,
                    movieInclude,
                    tvInclude,
                    created_date,
                    modified_date
                  )
                  values
                  (
                    @streamsource,
                    @streamdescription,
                    @movieinclude,
                    @tvinclude,
                    cast(getdate() as datetime2(6)),
                    cast(getdate() as datetime2(6))
                  )

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record inserted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, stream source, stream description, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert media video encode
  else if @optionMode = 'insertMediaVideoEncode'
    begin
      -- Check if parameters are null
      if @videoencode is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            mve.videoencode as [videoencode]
            from dbo.MediaVideoEncode mve
            where
            mve.videoencode = @videoencode
            group by mve.videoencode
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Insert record
                  insert into dbo.MediaVideoEncode
                  (
                    videoencode,
                    movieInclude,
                    tvInclude,
                    created_date,
                    modified_date
                  )
                  values
                  (
                    @videoencode,
                    @movieinclude,
                    @tvinclude,
                    cast(getdate() as datetime2(6)),
                    cast(getdate() as datetime2(6))
                  )

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record inserted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, video encode, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update action status
  else if @optionMode = 'updateActionStatus'
    begin
      -- Check if parameters are null
      if @actionnumber is not null and @actiondescription is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            ast.actionnumber as [actionnumber]
            from dbo.ActionStatus ast
            where
            ast.actionnumber = @actionnumber
            group by ast.actionnumber
          )
            begin
              -- Check if record does not exist
              if not exists
              (
                -- Select record in question
                select
                ast.actionnumber as [actionnumber]
                from dbo.ActionStatus ast
                where
                ast.actionnumber = @actionnumber and
                ast.actiondescription = @actiondescription
                group by ast.actionnumber
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      update dbo.ActionStatus
                      set
                      actiondescription = @actiondescription,
                      modified_date = cast(getdate() as datetime2(6))
                      where
                      actionnumber = @actionnumber

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record already exists"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, action number and action description were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update media audio encode
  else if @optionMode = 'updateMediaAudioEncode'
    begin
      -- Check if parameters are null
      if @audioencode is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mae.audioencode as [audioencode]
            from dbo.MediaAudioEncode mae
            where
            mae.audioencode = @audioencode
            group by mae.audioencode
          )
            begin
              -- Check if record does not exist
              if not exists
              (
                -- Select record in question
                select
                mae.audioencode as [audioencode]
                from dbo.MediaAudioEncode mae
                where
                mae.audioencode = @audioencode and
                mae.movieInclude = @movieinclude and
                mae.tvInclude = @tvinclude
                group by mae.audioencode
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      update dbo.MediaAudioEncode
                      set
                      movieInclude = @movieinclude,
                      tvInclude = @tvinclude,
                      modified_date = cast(getdate() as datetime2(6))
                      where
                      audioencode = @audioencode

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record already exists"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, audio encode, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update media dynamic range
  else if @optionMode = 'updateMediaDynamicRange'
    begin
      -- Check if parameters are null
      if @dynamicrange is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mdr.dynamicrange as [dynamicrange]
            from dbo.MediaDynamicRange mdr
            where
            mdr.dynamicrange = @dynamicrange
            group by mdr.dynamicrange
          )
            begin
              -- Check if record does not exist
              if not exists
              (
                -- Select record in question
                select
                mdr.dynamicrange as [dynamicrange]
                from dbo.MediaDynamicRange mdr
                where
                mdr.dynamicrange = @dynamicrange and
                mdr.movieInclude = @movieinclude and
                mdr.tvInclude = @tvinclude
                group by mdr.dynamicrange
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      update dbo.MediaDynamicRange
                      set
                      movieInclude = @movieinclude,
                      tvInclude = @tvinclude,
                      modified_date = cast(getdate() as datetime2(6))
                      where
                      dynamicrange = @dynamicrange

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record already exists"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, dynamic range, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update media resolution
  else if @optionMode = 'updateMediaResolution'
    begin
      -- Check if parameters are null
      if @resolution is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mr.resolution as [resolution]
            from dbo.MediaResolution mr
            where
            mr.resolution = @resolution
            group by mr.resolution
          )
            begin
              -- Check if record does not exist
              if not exists
              (
                -- Select record in question
                select
                mr.resolution as [resolution]
                from dbo.MediaResolution mr
                where
                mr.resolution = @resolution and
                mr.movieInclude = @movieinclude and
                mr.tvInclude = @tvinclude
                group by mr.resolution
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      update dbo.MediaResolution
                      set
                      movieInclude = @movieinclude,
                      tvInclude = @tvinclude,
                      modified_date = cast(getdate() as datetime2(6))
                      where
                      resolution = @resolution

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record already exists"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, resolution, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update media stream source
  else if @optionMode = 'updateMediaStreamSource'
    begin
      -- Check if parameters are null
      if @streamsource is not null and @streamdescription is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mss.streamsource as [streamsource]
            from dbo.MediaStreamSource mss
            where
            mss.streamsource = @streamsource
            group by mss.streamsource
          )
            begin
              -- Check if record does not exist
              if not exists
              (
                -- Select record in question
                select
                mss.streamsource as [streamsource]
                from dbo.MediaStreamSource mss
                where
                mss.streamsource = @streamsource and
                mss.streamdescription = @streamdescription and
                mss.movieInclude = @movieinclude and
                mss.tvInclude = @tvinclude
                group by mss.streamsource
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      update dbo.MediaStreamSource
                      set
                      streamdescription = @streamdescription,
                      movieInclude = @movieinclude,
                      tvInclude = @tvinclude,
                      modified_date = cast(getdate() as datetime2(6))
                      where
                      streamsource = @streamsource

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record already exists"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, stream source, stream description, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update media video encode
  else if @optionMode = 'updateMediaVideoEncode'
    begin
      -- Check if parameters are null
      if @videoencode is not null and @movieinclude is not null and @tvinclude is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mve.videoencode as [videoencode]
            from dbo.MediaVideoEncode mve
            where
            mve.videoencode = @videoencode
            group by mve.videoencode
          )
            begin
              -- Check if record does not exist
              if not exists
              (
                -- Select record in question
                select
                mve.videoencode as [videoencode]
                from dbo.MediaVideoEncode mve
                where
                mve.videoencode = @videoencode and
                mve.movieInclude = @movieinclude and
                mve.tvInclude = @tvinclude
                group by mve.videoencode
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      update dbo.MediaVideoEncode
                      set
                      movieInclude = @movieinclude,
                      tvInclude = @tvinclude,
                      modified_date = cast(getdate() as datetime2(6))
                      where
                      videoencode = @videoencode

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record already exists"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, video encode, movie include, and tv include were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is delete action status
  else if @optionMode = 'deleteActionStatus'
    begin
      -- Check if parameters are not null
      if @actionnumber is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            ast.actionnumber as [actionnumber]
            from dbo.ActionStatus ast
            where
            ast.actionnumber = @actionnumber
            group by ast.actionnumber
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.ActionStatus
                  where
                  actionnumber = @actionnumber

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, action number was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete media audio encode
  else if @optionMode = 'deleteMediaAudioEncode'
    begin
      -- Check if parameters are not null
      if @audioencode is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mae.audioencode as [audioencode]
            from dbo.MediaAudioEncode mae
            where
            mae.audioencode = @audioencode
            group by mae.audioencode
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.MediaAudioEncode
                  where
                  audioencode = @audioencode

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, audio encode was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete media dynamic range
  else if @optionMode = 'deleteMediaDynamicRange'
    begin
      -- Check if parameters are not null
      if @dynamicrange is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mdr.dynamicrange as [dynamicrange]
            from dbo.MediaDynamicRange mdr
            where
            mdr.dynamicrange = @dynamicrange
            group by mdr.dynamicrange
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.MediaDynamicRange
                  where
                  dynamicrange = @dynamicrange

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, dynamic range was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete media resolution
  else if @optionMode = 'deleteMediaResolution'
    begin
      -- Check if parameters are not null
      if @resolution is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mr.resolution as [resolution]
            from dbo.MediaResolution mr
            where
            mr.resolution = @resolution
            group by mr.resolution
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.MediaResolution
                  where
                  resolution = @resolution

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, resolution was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete media stream source
  else if @optionMode = 'deleteMediaStreamSource'
    begin
      -- Check if parameters are not null
      if @streamsource is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mss.streamsource as [streamsource]
            from dbo.MediaStreamSource mss
            where
            mss.streamsource = @streamsource
            group by mss.streamsource
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.MediaStreamSource
                  where
                  streamsource = @streamsource

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, stream source was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete media video encode
  else if @optionMode = 'deleteMediaVideoEncode'
    begin
      -- Check if parameters are not null
      if @videoencode is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mve.videoencode as [videoencode]
            from dbo.MediaVideoEncode mve
            where
            mve.videoencode = @videoencode
            group by mve.videoencode
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.MediaVideoEncode
                  where
                  videoencode = @videoencode

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, video encode was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end
end
GO
/****** Object:  StoredProcedure [dbo].[insertupdatedeleteMediaFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
--        File: insertupdatedeleteMediaFeed
--     Created: 11/05/2020
--     Updated: 09/29/2023
--  Programmer: Cuates
--   Update By: Cuates
--     Purpose: Insert update delete media feed
-- ================================================

-- Procedure Create
CREATE procedure [dbo].[insertupdatedeleteMediaFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @titlelong nvarchar(max) = null,
  @titleshort nvarchar(max) = null,
  @titleshortold nvarchar(max) = null,
  @publishdate nvarchar(max) = null,
  @infourl nvarchar(max) = null,
  @actionstatus nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @omitOptionMode as nvarchar(max)
  declare @omitTitleLong as nvarchar(max)
  declare @omitTitleShort as nvarchar(max)
  declare @omitPublishDate as nvarchar(max)
  declare @omitInfoUrl as nvarchar(max)
  declare @omitActionStatus as nvarchar(max)
  declare @omitMovieInclude as nvarchar(max)
  declare @omitTVInclude as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthTitleLong as int
  declare @maxLengthTitleShort as int
  declare @maxLengthActionStatus as int
  declare @maxLengthPublishDate as int
  declare @maxLengthInfoUrl as int
  declare @result as nvarchar(max)

  -- Set variables
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitleLong = N'-,.,'',0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitleShort = N'-,.,'',0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitPublishDate = N' ,-,/,0,1,2,3,4,5,6,7,8,9,:,.'
  set @omitInfoUrl = N'-,.,/,%,?,=,&,0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,],_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitActionStatus = N'0,1,2,3,4,5,6,7,8,9'
  set @maxLengthOptionMode = 255
  set @maxLengthTitleLong = 255
  set @maxLengthTitleShort = 255
  set @maxLengthPublishDate = 255
  set @maxLengthActionStatus = 255
  set @result = ''

  -- Check if parameter is not null
  if @optionMode is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @optionMode = dbo.omitcharacters(@optionMode, @omitOptionMode)

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
  if @titlelong is not null
    begin
      -- Omit characters
      set @titlelong = dbo.OmitCharacters(@titlelong, @omitTitleLong)

      -- Set character limit
      set @titlelong = trim(substring(@titlelong, 1, @maxLengthTitleLong))

      -- Check if empty string
      if @titlelong = ''
        begin
          -- Set parameter to null if empty string
          set @titlelong = nullif(@titlelong, '')
        end
    end

  -- Check if parameter is not null
  if @titleshort is not null
    begin
      -- Omit characters
      set @titleshort = dbo.OmitCharacters(@titleshort, @omitTitleShort)

      -- Set character limit
      set @titleshort = trim(substring(@titleshort, 1, @maxLengthTitleShort))

      -- Check if empty string
      if @titleshort = ''
        begin
          -- Set parameter to null if empty string
          set @titleshort = nullif(@titleshort, '')
        end
    end

  -- Check if parameter is not null
  if @titleshortold is not null
    begin
      -- Omit characters
      set @titleshortold = dbo.OmitCharacters(@titleshortold, @omitTitleShort)

      -- Set character limit
      set @titleshortold = trim(substring(@titleshortold, 1, @maxLengthTitleShort))

      -- Check if empty string
      if @titleshortold = ''
        begin
          -- Set parameter to null if empty string
          set @titleshortold = nullif(@titleshortold, '')
        end
    end

  -- Check if parameter is not null
  if @publishdate is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @publishdate = dbo.omitcharacters(@publishdate, @omitPublishDate)

      -- Set character limit
      set @publishdate = trim(substring(@publishdate, 1, @maxLengthPublishDate))

      -- Check if the parameter cannot be casted into a date time
      if try_cast(@publishdate as datetime2(6)) is null
        begin
          -- Set the string as empty to be nulled below
          set @publishdate = ''
        end

      -- Check if empty string
      if @publishdate = ''
        begin
          -- Set parameter to null if empty string
          set @publishdate = nullif(@publishdate, '')
        end
    end

  -- Check if parameter is not null
  if @titleshort is not null
    begin
      -- Omit characters
      set @infourl = dbo.OmitCharacters(@infourl, @omitInfoUrl)

      -- Set character limit
      set @infourl = trim(substring(@infourl, 1, @maxLengthInfoUrl))

      -- Check if empty string
      if @infourl = ''
        begin
          -- Set parameter to null if empty string
          set @infourl = nullif(@infourl, '')
        end
    end

  -- Check if parameter is not null
  if @actionstatus is not null
    begin
      -- Omit characters
      set @actionstatus = dbo.OmitCharacters(@actionstatus, @omitActionStatus)

      -- Set character limit
      set @actionstatus = trim(substring(@actionstatus, 1, @maxLengthActionStatus))

      -- Check if empty string
      if @actionstatus = ''
        begin
          -- Set parameter to null if empty string
          set @actionstatus = nullif(@actionstatus, '')
        end
    end

  -- Else check if option mode is insert movie feed
  if @optionMode = 'insertMovieFeed'
    begin
      -- Check if parameters are null
      if @titlelong is not null and @titleshort is not null and @publishdate is not null and @actionstatus is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            mf.titlelong as [titlelong]
            from dbo.MovieFeed mf
            where
            mf.titlelong = @titlelong
            group by mf.titlelong
          )
            begin
              -- Check if year string is greater than 5 and string is a valid year
              if len(@titleshort) > 5 and isdate(substring(@titleshort, len(@titleshort) - 3, len(@titleshort))) = 1
                begin
                  -- Check if record exists
                  if exists
                  (
                    -- Select record
                    select
                    @titlelong as [titlelong]
                    from dbo.ActionStatus ast
                    join dbo.MediaAudioEncode mae on mae.movieInclude in (1) and @titlelong like concat('%', mae.audioencode, '%')
                    left join dbo.MediaDynamicRange mdr on mdr.movieInclude in (1) and @titlelong like concat('%', mdr.dynamicrange, '%')
                    join dbo.MediaResolution mr on mr.movieInclude in (1) and @titlelong like concat('%', mr.resolution, '%')
                    left join dbo.MediaStreamSource mss on mss.movieInclude in (1) and @titlelong like concat('%', mss.streamsource, '%')
                    join dbo.MediaVideoEncode mve on mve.movieInclude in (1) and @titlelong like concat('%', mve.videoencode, '%')
                    where
                    ast.actionnumber = @actionstatus
                  )
                    begin
                      -- Check if record is valid
                      -- Begin the tranaction
                      begin tran
                        -- Begin the try block
                        begin try
                          -- Insert record
                          insert into dbo.MovieFeed
                          (
                            titlelong,
                            titleshort,
                            publish_date,
                            actionstatus,
                            created_date,
                            modified_date
                          )
                          values
                          (
                            @titlelong,
                            lower(@titleshort),
                            cast(@publishdate as datetime2(6)),
                            @actionstatus,
                            cast(getdate() as datetime2(6)),
                            cast(getdate() as datetime2(6))
                          )
                          
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Commit transactional statement
                              commit tran
                            end

                          -- Set message
                          set @result = '{"Status": "Success", "Message": "Record inserted"}'
                        end try
                        -- End try block
                        -- Begin catch block
                        begin catch
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Rollback to the previous state before the transaction was called
                              rollback
                            end

                          -- Set message
                          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                        end catch
                        -- End catch block
                    end
                  else
                    begin
                      -- Set message
                      set @result = '{"Status": "Error", "Message": "Title long does not follow the allowed values"}'
                    end
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Error", "Message": "Title short does not follow the allowed value"}'
                end
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is insert tv feed
  else if @optionMode = 'insertTVFeed'
    begin
      -- Check if parameters are null
      if @titlelong is not null and @titleshort is not null and @publishdate is not null and @actionstatus is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            tf.titlelong as [titlelong]
            from dbo.TVFeed tf
            where
            tf.titlelong = @titlelong
            group by tf.titlelong
          )
            begin
              -- Check if record exist
              if exists
              (
                -- Select record
                select
                @titlelong as [titlelong]
                from dbo.ActionStatus ast
                join dbo.MediaAudioEncode mae on mae.tvInclude in (1) and @titlelong like concat('%', mae.audioencode, '%')
                left join dbo.MediaDynamicRange mdr on mdr.tvInclude in (1) and @titlelong like concat('%', mdr.dynamicrange, '%')
                join dbo.MediaResolution mr on mr.tvInclude in (1) and @titlelong like concat('%', mr.resolution, '%')
                left join dbo.MediaStreamSource mss on mss.tvInclude in (1) and @titlelong like concat('%', mss.streamsource, '%')
                join dbo.MediaVideoEncode mve on mve.tvInclude in (1) and @titlelong like concat('%', mve.videoencode, '%')
                where
                ast.actionnumber = @actionstatus
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      insert into dbo.TVFeed
                      (
                        titlelong,
                        titleshort,
                        publish_date,
                        actionstatus,
                        created_date,
                        modified_date
                      )
                      values
                      (
                        @titlelong,
                        lower(@titleshort),
                        cast(@publishdate as datetime2(6)),
                        @actionstatus,
                        cast(getdate() as datetime2(6)),
                        cast(getdate() as datetime2(6))
                      )
                      
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record inserted"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Error", "Message": "Title long does not follow the allowed values"}'
                end
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update movie feed
  else if @optionMode = 'updateMovieFeed'
    begin
      -- Check if parameters are null
      if @titlelong is not null and @titleshort is not null and @publishdate is not null and @actionstatus is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mf.titlelong as [titlelong]
            from dbo.MovieFeed mf
            where
            mf.titlelong = @titlelong
            group by mf.titlelong
          )
            begin
              -- Check if year string is greater than 5 and string is a valid year
              if len(@titleshort) > 5 and isdate(substring(@titleshort, len(@titleshort) - 3, len(@titleshort))) = 1
                begin
                  -- Check if record exist
                  if exists
                  (
                    -- Select record
                    select
                    ast.actionnumber as [actionnumber]
                    from dbo.ActionStatus ast
                    where
                    ast.actionnumber = @actionstatus
                    group by ast.actionnumber
                  )
                    begin
                      -- Check if record does not exist
                      if not exists
                      (
                        -- Select records
                        select
                        mf.titlelong as [titlelong]
                        from dbo.MovieFeed mf
                        where
                        mf.titlelong = @titlelong and
                        mf.titleshort = @titleshort and
                        mf.publish_date = @publishdate and
                        mf.actionstatus = @actionstatus
                        group by mf.titlelong
                      )
                        begin
                          -- Begin the tranaction
                          begin tran
                            -- Begin the try block
                            begin try
                              -- Insert record
                              update dbo.MovieFeed
                              set
                              titleshort = lower(@titleshort),
                              publish_date = cast(@publishdate as datetime2(6)),
                              actionstatus = @actionstatus,
                              modified_date =  cast(getdate() as datetime2(6))
                              where
                              titlelong = @titlelong
                              
                              -- Check if there is trans count
                              if @@trancount > 0
                                begin
                                  -- Commit transactional statement
                                  commit tran
                                end

                              -- Set message
                              set @result = '{"Status": "Success", "Message": "Record updated"}'
                            end try
                            -- End try block
                            -- Begin catch block
                            begin catch
                              -- Check if there is trans count
                              if @@trancount > 0
                                begin
                                  -- Rollback to the previous state before the transaction was called
                                  rollback
                                end

                              -- Set message
                              set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                            end catch
                            -- End catch block
                        end
                      else
                        begin
                          -- Set message
                          set @result = '{"Status": "Success", "Message": "Record already exists"}'
                        end
                    end
                  else
                    begin
                      -- Set message
                      set @result = '{"Status": "Error", "Message": "Action status value is invalid"}'
                    end
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Error", "Message": "Title short does not follow the allowed value"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update movie title short
  else if @optionMode = 'updateMovieFeedTitleShort'
    begin
      -- Check if parameters are null
      if @titleshort is not null and @titleshortold is not null
        begin
          -- Check if record does not exist
          if not exists
          (
            -- Select record in question
            select
            mf.titleshort as [titleshort]
            from dbo.MovieFeed mf
            where
            mf.titleshort = @titleshort
            group by mf.titleshort
          )
            begin
              -- Check if year string is greater than 5 and string is a valid year
              if len(@titleshort) > 5 and isdate(substring(@titleshort, len(@titleshort) - 3, len(@titleshort))) = 1
                begin
                  -- Check if record exist
                  if exists
                  (
                    -- Select record in question
                    select
                    mf.titleshort as [titleshort]
                    from dbo.MovieFeed mf
                    where
                    mf.titleshort = @titleshortold
                    group by mf.titleshort
                  )
                    begin
                      -- Begin the tranaction
                      begin tran
                        -- Begin the try block
                        begin try
                          -- Insert record
                          update dbo.MovieFeed
                          set
                          titleshort = lower(@titleshort),
                          modified_date = cast(getdate() as datetime2(6))
                          where
                          titleshort = @titleshortold
                          
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Commit transactional statement
                              commit tran
                            end

                          -- Set message
                          set @result = '{"Status": "Success", "Message": "Record(s) updated"}'
                        end try
                        -- End try block
                        -- Begin catch block
                        begin catch
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Rollback to the previous state before the transaction was called
                              rollback
                            end

                          -- Set message
                          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                        end catch
                        -- End catch block
                    end
                  else
                    begin
                      -- Record does not exist
                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record does not exist"}'
                    end
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Error", "Message": "Title short does not follow the allowed value"}'
                end
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record(s) already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title short and title short old were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update movie feed title short action status
  else if @optionMode = 'updateMovieFeedTitleShortActionStatus'
    begin
      -- Check if parameters are null
      if @titleshort is not null and @actionstatus is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mf.titleshort as [titleshort]
            from dbo.MovieFeed mf
            where
            mf.titleshort = @titleshort
            group by mf.titleshort
          )
            begin
              -- Check if record exist
              if exists
              (
                -- Select record
                select
                ast.actionnumber as [actionnumber]
                from dbo.ActionStatus ast
                where
                ast.actionnumber = @actionstatus
                group by ast.actionnumber
              )
                begin
                  -- Check if record does not exists
                  if not exists
                  (
                    -- Select records
                    select
                    mf.titleshort as [titleshort]
                    from dbo.MovieFeed mf
                    where
                    mf.titleshort = @titleshort and
                    mf.actionstatus = @actionstatus
                    group by mf.titleshort
                  )
                    begin
                      -- Begin the tranaction
                      begin tran
                        -- Begin the try block
                        begin try
                          -- Insert record
                          update dbo.MovieFeed
                          set
                          actionstatus = @actionstatus,
                          modified_date = cast(getdate() as datetime2(6))
                          where
                          titleshort = @titleshort
                          
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Commit transactional statement
                              commit tran
                            end

                          -- Set message
                          set @result = '{"Status": "Success", "Message": "Record(s) updated"}'
                        end try
                        -- End try block
                        -- Begin catch block
                        begin catch
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Rollback to the previous state before the transaction was called
                              rollback
                            end

                          -- Set message
                          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                        end catch
                        -- End catch block
                    end
                  else
                    begin
                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record(s) already exist"}'
                    end
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Error", "Message": "Action status value is invalid"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title short and action status were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update tv feed
  else if @optionMode = 'updateTVFeed'
    begin
      -- Check if parameters are null
      if @titlelong is not null and @titleshort is not null and @publishdate is not null and @actionstatus is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            tf.titlelong as [titlelong]
            from dbo.TVFeed tf
            where
            tf.titlelong = @titlelong
            group by tf.titlelong
          )
            begin
              -- Check if record exists
              if exists
              (
                -- Select record
                select
                ast.actionnumber as [actionnumber]
                from dbo.ActionStatus ast
                where
                ast.actionnumber = @actionstatus
                group by ast.actionnumber
              )
                begin
                  -- Check if record does not exist
                  if not exists
                  (
                    -- Select records
                    select
                    tf.titlelong as [titlelong]
                    from dbo.TVFeed tf
                    where
                    tf.titlelong = @titlelong and
                    tf.titleshort = @titleshort and
                    tf.publish_date = @publishdate and
                    tf.actionstatus = @actionstatus
                    group by tf.titlelong
                  )
                    begin
                      -- Begin the tranaction
                      begin tran
                        -- Begin the try block
                        begin try
                          -- Insert record
                          update dbo.TVFeed
                          set
                          titleshort = lower(@titleshort),
                          publish_date = cast(@publishdate as datetime2(6)),
                          actionstatus = @actionstatus,
                          modified_date = cast(getdate() as datetime2(6))
                          where
                          titlelong = @titlelong
                          
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Commit transactional statement
                              commit tran
                            end

                          -- Set message
                          set @result = '{"Status": "Success", "Message": "Record updated"}'
                        end try
                        -- End try block
                        -- Begin catch block
                        begin catch
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Rollback to the previous state before the transaction was called
                              rollback
                            end

                          -- Set message
                          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                        end catch
                        -- End catch block
                    end
                  else
                    begin
                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record already exist"}'
                    end
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Error", "Message": "Action status value is invalid"}'
                end
            end
          else
            begin
                -- Record does not exist
                -- Set message
                set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update tv feed title short
  else if @optionMode = 'updateTVFeedTitleShort'
    begin
      -- Check if parameters are null
      if @titleshort is not null and @titleshortold is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            tf.titleshort as [titleshort]
            from dbo.TVFeed tf
            where
            tf.titleshort = @titleshort
            group by tf.titleshort
          )
            begin
              -- Check if record exist
              if exists
              (
                -- Select record in question
                select
                tf.titleshort as [titleshort]
                from dbo.TVFeed tf
                where
                tf.titleshort = @titleshortold
                group by tf.titleshort
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Insert record
                      update dbo.TVFeed
                      set
                      titleshort = lower(@titleshort),
                      modified_date = cast(getdate() as datetime2(6))
                      where
                      titleshort = @titleshortold
                      
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record(s) updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Record does not exist
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record does not exist"}'
                end
            end
          else
            begin
                -- Record already exist
                -- Set message
                set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title short and title short old were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update tv feed title short action status
  else if @optionMode = 'updateTVFeedTitleShortActionStatus'
    begin
      -- Check if parameters are null
      if @titleshort is not null and @actionstatus is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            tf.titleshort as [titleshort]
            from dbo.TVFeed tf
            where
            tf.titleshort = @titleshort
            group by tf.titleshort
          )
            begin
              -- Check if record exists
              if exists
              (
                -- Select record
                select
                ast.actionnumber as [actionnumber]
                from dbo.ActionStatus ast
                where
                ast.actionnumber = @actionstatus
                group by ast.actionnumber
              )
                begin
                  -- Check if record does not exists
                  if not exists
                  (
                    -- Select records
                    select
                    tf.titleshort as [titleshort]
                    from dbo.TVFeed tf
                    where
                    tf.titleshort = @titleshort and
                    tf.actionstatus = @actionstatus
                    group by tf.titleshort
                  )
                    begin
                      -- Begin the tranaction
                      begin tran
                        -- Begin the try block
                        begin try
                          -- Insert record
                          update dbo.TVFeed
                          set
                          actionstatus = @actionstatus,
                          modified_date = cast(getdate() as datetime2(6))
                          where
                          titleshort = @titleshort
                          
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Commit transactional statement
                              commit tran
                            end

                          -- Set message
                          set @result = '{"Status": "Success", "Message": "Record(s) updated"}'
                        end try
                        -- End try block
                        -- Begin catch block
                        begin catch
                          -- Check if there is trans count
                          if @@trancount > 0
                            begin
                              -- Rollback to the previous state before the transaction was called
                              rollback
                            end

                          -- Set message
                          set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                        end catch
                        -- End catch block
                    end
                  else
                    begin
                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record(s) already exists"}'
                    end
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Error", "Message": "Action status value is invalid"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title short and action status were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete  movie feed
  else if @optionMode = 'deleteMovieFeed'
    begin
      -- Check if parameters are not null
      if @titlelong is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mf.titlelong as [titlelong]
            from dbo.MovieFeed mf
            where
            mf.titlelong = @titlelong
            group by mf.titlelong
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.MovieFeed
                  where
                  titlelong = @titlelong

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete movie feed title short
  else if @optionMode = 'deleteMovieFeedTitleShort'
    begin
      -- Check if parameters are not null
      if @titleshort is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            mf.titleshort as [titleshort]
            from dbo.MovieFeed mf
            where
            mf.titleshort = @titleshort
            group by mf.titleshort
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.MovieFeed
                  where
                  titleshort = @titleshort

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record(s) deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title short was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete tv feed
  else if @optionMode = 'deleteTVFeed'
    begin
      -- Check if parameters are not null
      if @titlelong is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            tf.titlelong as [titlelong]
            from dbo.TVFeed tf
            where
            tf.titlelong = @titlelong
            group by tf.titlelong
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.TVFeed
                  where
                  titlelong = @titlelong

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title long was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Check if option mode is delete tv feed title short
  else if @optionMode = 'deleteTVFeedTitleShort'
    begin
      -- Check if parameters are not null
      if @titleshort is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            tf.titleshort as [titleshort]
            from dbo.TVFeed tf
            where
            tf.titleshort = @titleshort
            group by tf.titleshort
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.TVFeed
                  where
                  titleshort = @titleshort

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record(s) deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title short was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end
end
GO
/****** Object:  StoredProcedure [dbo].[insertupdatedeleteNewsFeed]    Script Date: 2026-07-18 07:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
--       File: insertupdatedeleteNewsFeed
--    Created: 11/05/2020
--    Updated: 11/16/2020
-- Programmer: Cuates
--  Update By: Cuates
--    Purpose: Insert update delete news feed
-- ================================================

-- Procedure Create
create procedure [dbo].[insertupdatedeleteNewsFeed]
  -- Add the parameters for the stored procedure here
  @optionMode nvarchar(max),
  @title nvarchar(max) = null,
  @imageurl nvarchar(max) = null,
  @feedurl nvarchar(max) = null,
  @actualurl nvarchar(max) = null,
  @publishdate nvarchar(max) = null
as
begin
  -- Set nocount on added to prevent extra result sets from interfering with select statements
  set nocount on

  -- Declare variables
  declare @omitOptionMode as nvarchar(max)
  declare @omitTitle as nvarchar(max)
  declare @omitImageurl as nvarchar(max)
  declare @omitFeedurl as nvarchar(max)
  declare @omitActualurl as nvarchar(max)
  declare @omitPublishDate as nvarchar(max)
  declare @maxLengthOptionMode as int
  declare @maxLengthTitle as int
  declare @maxLengthImageurl as int
  declare @maxLengthFeedurl as int
  declare @maxLengthActualurl as int
  declare @maxLengthPublishDate as int
  declare @result as nvarchar(max)

  -- Set variables
  set @omitOptionMode = N'0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
  set @omitTitle = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitImageurl = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitFeedurl = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitActualurl = N'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9, ,!,",#,$,%,&,'',(,),*,+,,,-,.,/,:,;,<,=,>,?,@,[,],^,_,{,|,},~,¡,¢,£,¥,¦,§,¨,©,®,¯,°,±,´,µ,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,Ñ,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,ñ,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,ı,Œ,œ,Š,š,Ÿ,Ž,ž,ƒ,ˆ,ˇ,˘,˙,˚,˛,Γ,Θ,Σ,Φ,Ω,α,δ,ε,π,σ,τ,φ,–,—,‘,’,“,”,•,…,€,™,∂,∆,∏,∑,∙,√,∞,∩,∫,≈,≠,≡,≤,≥'
  set @omitPublishDate = N' ,-,/,0,1,2,3,4,5,6,7,8,9,:,.'
  set @maxLengthOptionMode = 255
  set @maxLengthTitle = 255
  set @maxLengthImageurl = 255
  set @maxLengthFeedurl = 768
  set @maxLengthActualurl = 255
  set @maxLengthPublishDate = 255
  set @result = ''

  -- Check if parameter is not null
  if @optionMode is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @optionMode = dbo.omitcharacters(@optionMode, @omitOptionMode)

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
      set @title = dbo.omitcharacters(@title, @omitTitle)

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
      set @imageurl = dbo.omitcharacters(@imageurl, @omitImageurl)

      -- Set character limit
      set @imageurl = trim(substring(@imageurl, 1, @maxLengthImageurl))

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
      set @feedurl = dbo.omitcharacters(@feedurl, @omitFeedurl)

      -- Set character limit
      set @feedurl = trim(substring(@feedurl, 1, @maxLengthFeedurl))

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
      set @actualurl = dbo.omitcharacters(@actualurl, @omitActualurl)

      -- Set character limit
      set @actualurl = trim(substring(@actualurl, 1, @maxLengthActualurl))

      -- Check if empty string
      if @actualurl = ''
        begin
          -- Set parameter to null if empty string
          set @actualurl = nullif(@actualurl, '')
        end
    end

  -- Check if parameter is not null
  if @publishdate is not null
    begin
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      set @publishdate = dbo.omitcharacters(@publishdate, @omitPublishDate)

      -- Set character limit
      set @publishdate = trim(substring(@publishdate, 1, @maxLengthPublishDate))

      -- Check if the parameter cannot be casted into a date time
      if try_cast(@publishdate as datetime2(6)) is null
        begin
          -- Set the string as empty to be nulled below
          set @publishdate = ''
        end

      -- Check if empty string
      if @publishdate = ''
        begin
          -- Set parameter to null if empty string
          set @publishdate = nullif(@publishdate, '')
        end
    end

  -- Check if option mode is insert news feed
  if @optionMode = 'insertNewsFeed'
    begin
      -- Check if parameters are not null
      if @title is not null and @feedurl is not null and @publishdate is not null
        begin
          -- Check if record exist
          if not exists
          (
            -- Select record in question
            select
            nf.title as [title]
            from dbo.NewsFeed nf
            where
            nf.title = @title
            group by nf.title
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Insert record
                  insert into dbo.NewsFeed
                  (
                    title,
                    imageurl,
                    feedurl,
                    actualurl,
                    publish_date,
                    created_date,
                    modified_date
                  )
                  values
                  (
                    @title,
                    case
                      when trim(@imageurl) = ''
                        then
                          null
                      else
                        @imageurl
                    end,
                    @feedurl,
                    case
                      when trim(@actualurl) = ''
                        then
                          null
                      else
                        @actualurl
                    end,
                    cast(@publishdate as datetime2(6)),
                    cast(getdate() as datetime2(6)),
                    cast(getdate() as datetime2(6))
                  )

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record inserted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record already exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record already exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title, feed url, and or publish date were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is update news feed
  else if @optionMode = 'updateNewsFeed'
    begin
      -- Check if parameters are not null
      if @title is not null and @feedurl is not null and @publishdate is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            nf.title as [title]
            from dbo.NewsFeed nf
            where
            nf.title = @title
            group by nf.title
          )
            begin
              -- Check if record does not exists
              if not exists
              (
                -- Select records
                select
                nf.title as [title]
                from dbo.NewsFeed nf
                where
                nf.title = @title and
                (
                  nf.imageurl = @imageurl or
                  (
                    nf.imageurl is null and
                    @imageurl is null
                  )
                ) and
                nf.feedurl = @feedurl and
                (
                  nf.actualurl = @actualurl or
                  (
                    nf.actualurl is null and
                    @actualurl is null
                  )
                ) and
                nf.publish_date = @publishdate
                group by nf.title
              )
                begin
                  -- Begin the tranaction
                  begin tran
                    -- Begin the try block
                    begin try
                      -- Update record
                      update dbo.NewsFeed
                      set
                      imageurl = (case
                      when trim(@imageurl) = ''
                        then
                          null
                      else
                        @imageurl
                      end),
                      feedurl = @feedurl,
                      actualurl = (case
                      when trim(@actualurl) = ''
                        then
                          null
                      else
                        @actualurl
                      end),
                      publish_date = cast(@publishdate as datetime2(6)),
                      modified_date =  cast(getdate() as datetime2(6))                     
                      where
                      title = @title

                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Commit transactional statement
                          commit tran
                        end

                      -- Set message
                      set @result = '{"Status": "Success", "Message": "Record updated"}'
                    end try
                    -- End try block
                    -- Begin catch block
                    begin catch
                      -- Check if there is trans count
                      if @@trancount > 0
                        begin
                          -- Rollback to the previous state before the transaction was called
                          rollback
                        end

                      -- Set message
                      set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                    end catch
                    -- End catch block
                end
              else
                begin
                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record already exists"}'
                end
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title, feed url, and or publish date were not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end

  -- Else check if option mode is delete news feed
  else if @optionMode = 'deleteNewsFeed'
    begin
      -- Check if parameters are not null
      if @title is not null
        begin
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            nf.title as [title]
            from dbo.NewsFeed nf
            where
            nf.title = @title
            group by nf.title
          )
            begin
              -- Begin the tranaction
              begin tran
                -- Begin the try block
                begin try
                  -- Delete record
                  delete
                  from dbo.NewsFeed
                  where
                  title = @title

                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Commit transactional statement
                      commit tran
                    end

                  -- Set message
                  set @result = '{"Status": "Success", "Message": "Record deleted"}'
                end try
                -- End try block
                -- Begin catch block
                begin catch
                  -- Check if there is trans count
                  if @@trancount > 0
                    begin
                      -- Rollback to the previous state before the transaction was called
                      rollback
                    end

                  -- Set message
                  set @result = concat('{"Status": "Error", "Message": "', cast(error_message() as nvarchar(max)), '"}')
                end catch
                -- End catch block
            end
          else
            begin
              -- Record does not exist
              -- Set message
              set @result = '{"Status": "Success", "Message": "Record does not exist"}'
            end
        end
      else
        begin
          -- Set message
          set @result = '{"Status": "Error", "Message": "Process halted, title was not provided"}'
        end

      -- Select message
      select
      @result as [status]
    end
end
GO
USE [master]
GO
ALTER DATABASE [media] SET  READ_WRITE 
GO
