--
-- PostgreSQL database dump
--


-- Dumped from database version 15.18 (Debian 15.18-1.pgdg13+1)
-- Dumped by pg_dump version 15.18 (Debian 15.18-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: extractcontrolmediafeed(text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extractcontrolmediafeed(optionmode text DEFAULT NULL::text, actionnumber text DEFAULT NULL::text, actiondescription text DEFAULT NULL::text, audioencode text DEFAULT NULL::text, dynamicrange text DEFAULT NULL::text, resolution text DEFAULT NULL::text, streamsource text DEFAULT NULL::text, streamdescription text DEFAULT NULL::text, videoencode text DEFAULT NULL::text, "limit" text DEFAULT NULL::text, sort text DEFAULT NULL::text) RETURNS TABLE(actionnumberreturn text, actiondescriptionreturn text, audioencodereturn text, dynamicrangereturn text, resolutionreturn text, streamsourcereturn text, streamdescriptionreturn text, videoencodereturn text, movieincludereturn text, tvincludereturn text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitActionNumber text := '[^0-9]';
  declare omitActionDescription text := '[^a-zA-Z]';
  declare omitMediaAudioEncode text := '[^a-zA-Z0-9.\-]';
  declare omitMediaDynamicRange text := '[^a-zA-Z]';
  declare omitMediaResolution text := '[^a-zA-Z0-9]';
  declare omitMediaStreamSource text := '[^a-zA-Z]';
  declare omitMediaStreamDescription text := '[^a-zA-Z]';
  declare omitMediaVideoEncode text := '[^a-zA-Z0-9]';
  declare omitLimit text := '[^0-9\-]';
  declare omitSort text := '[^a-zA-Z]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthActionNumber int := 255;
  declare maxLengthActionDescription int := 255;
  declare maxLengthMediaAudioEncode int := 100;
  declare maxLengthMediaDynamicRange int := 100;
  declare maxLengthMediaResolution int := 100;
  declare maxLengthMediaStreamSource int := 100;
  declare maxLengthMediaStreamDescription int := 100;
  declare maxLengthMediaVideoEncode int := 100;
  declare maxLengthSort int := 255;
  declare lowerLimit int := 1;
  declare upperLimit int := 100;
  declare defaultLimit int := 25;
  declare dSQL text := '';
  declare dSQLWhere text := '';
  declare countInput int := 0;

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actionnumber is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actionnumber := regexp_replace(regexp_replace(actionnumber, omitActionNumber, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actionnumber := trim(substring(actionnumber, 1, maxLengthActionNumber));

      -- Check if empty string
      if actionnumber = '' then
        -- Set parameter to null if empty string
        actionnumber := nullif(actionnumber, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actiondescription is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actiondescription := regexp_replace(regexp_replace(actiondescription, omitActionDescription, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actiondescription := trim(substring(actiondescription, 1, maxLengthActionDescription));

      -- Check if empty string
      if actiondescription = '' then
        -- Set parameter to null if empty string
        actiondescription := nullif(actiondescription, '');
      end if;
    end if;

    -- Check if parameter is not null
    if audioencode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      audioencode := regexp_replace(regexp_replace(audioencode, omitMediaAudioEncode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      audioencode := trim(substring(audioencode, 1, maxLengthMediaAudioEncode));

      -- Check if empty string
      if audioencode = '' then
        -- Set parameter to null if empty string
        audioencode := nullif(audioencode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if dynamicrange is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      dynamicrange := regexp_replace(regexp_replace(dynamicrange, omitMediaDynamicRange, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      dynamicrange := trim(substring(dynamicrange, 1, maxLengthMediaDynamicRange));

      -- Check if empty string
      if dynamicrange = '' then
        -- Set parameter to null if empty string
        dynamicrange := nullif(dynamicrange, '');
      end if;
    end if;

    -- Check if parameter is not null
    if resolution is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      resolution := regexp_replace(regexp_replace(resolution, omitMediaResolution, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      resolution := trim(substring(resolution, 1, maxLengthMediaResolution));

      -- Check if empty string
      if resolution = '' then
        -- Set parameter to null if empty string
        resolution := nullif(resolution, '');
      end if;
    end if;

    -- Check if parameter is not null
    if streamsource is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      streamsource := regexp_replace(regexp_replace(streamsource, omitMediaStreamSource, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      streamsource := trim(substring(streamsource, 1, maxLengthMediaStreamSource));

      -- Check if empty string
      if streamsource = '' then
        -- Set parameter to null if empty string
        streamsource := nullif(streamsource, '');
      end if;
    end if;

    -- Check if parameter is not null
    if streamdescription is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      streamdescription := regexp_replace(regexp_replace(streamdescription, omitMediaStreamDescription, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      streamdescription := trim(substring(streamdescription, 1, maxLengthMediaStreamDescription));

      -- Check if empty string
      if streamdescription = '' then
        -- Set parameter to null if empty string
        streamdescription := nullif(streamdescription, '');
      end if;
    end if;

    -- Check if parameter is not null
    if videoencode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      videoencode := regexp_replace(regexp_replace(videoencode, omitMediaVideoEncode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      videoencode := trim(substring(videoencode, 1, maxLengthMediaVideoEncode));

      -- Check if empty string
      if videoencode = '' then
        -- Set parameter to null if empty string
        videoencode := nullif(videoencode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if "limit" is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      "limit" := regexp_replace(regexp_replace("limit", omitLimit, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      "limit" := trim("limit");

      -- Check if empty string
      if "limit" = '' then
        -- Set parameter to null if empty string
        "limit" := nullif("limit", '');
      end if;
    end if;

    -- Check if parameter is not null
    if sort is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      sort := regexp_replace(regexp_replace(sort, omitSort, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      sort := trim(substring(sort, 1, maxLengthSort));

      -- Check if empty string
      if sort = '' then
        -- Set parameter to null if empty string
        sort := nullif(sort, '');
      end if;
    end if;

    -- Check if option mode is extract action status
    if optionMode = 'extractActionStatus' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      cast(ast.actionnumber as text),
      cast(ast.actiondescription as text),
      '''',
      '''',
      '''',
      '''',
      '''',
      '''',
      '''',
      ''''
      from actionstatus ast';

      -- Check if where clause is given
      if actionnumber is not null then
        -- Set variable
        dSQLWhere := concat('ast.actionnumber = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if actiondescription is not null then
        -- Check if dynamic SQL is not empty
        if trim(dSQLWhere) <> trim('') then
          -- Include the next filter into the where clause
          dSQLWhere := concat(dSQLWhere, ' and ast.actiondescription = $', countInput);

          -- Increment counter
          countInput := countInput + 1;
        else
          -- Include the next filter into the where clause
          dSQLWhere := concat('ast.actiondescription = $', countInput);

          -- Increment counter
          countInput := countInput + 1;
        end if;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by ast.actionnumber ', sort, ', ast.actiondescription ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if actionnumber is not null and actiondescription is null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(actionnumber as int), cast("limit" as int);
      elseif actionnumber is null and actiondescription is not null then
        -- Else if execute one parameter and not the other statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(actiondescription as text), cast("limit" as int);
      elseif actionnumber is not null and actiondescription is not null then
        -- Else if execute all parameters statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(actionnumber as int), cast(actiondescription as text), cast("limit" as int);
      else
        -- Else execute default statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;

    -- Else check if option mode is extract media audio encode
    elseif optionMode = 'extractMediaAudioEncode' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      else
        -- Set limit to user input
        "limit" := "limit";
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      else
        -- Set sort to user input
        sort := sort;
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      '''',
      '''',
      cast(mae.audioencode as text),
      '''',
      '''',
      '''',
      '''',
      '''',
      cast(mae.movieInclude as text),
      cast(mae.tvInclude as text)
      from mediaaudioencode mae';

      -- Check if where clause is given
      if audioencode is not null then
        -- Set variable
        dSQLWhere := concat('mae.audioencode = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by mae.audioencode ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if audioencode is not null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(audioencode as citext), cast("limit" as int);
      else
        -- Else execute default statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;

    -- Else check if option mode is delete temp tv
    elseif optionMode = 'extractMediaDynamicRange' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      else
        -- Set limit to user input
        "limit" := "limit";
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      else
        -- Set sort to user input
        sort := sort;
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      '''',
      '''',
      '''',
      cast(mdr.dynamicrange as text),
      '''',
      '''',
      '''',
      '''',
      cast(mdr.movieInclude as text),
      cast(mdr.tvInclude as text)
      from mediadynamicrange mdr';

      -- Check if where clause is given
      if dynamicrange is not null then
        -- Set variable
        dSQLWhere := concat('mdr.dynamicrange = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by mdr.dynamicrange ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if dynamicrange is not null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(dynamicrange as citext), cast("limit" as int);
      else
        -- Else execute default statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;

    -- Else check if option mode is extract media resolution
    elseif optionMode = 'extractMediaResolution' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      else
        -- Set limit to user input
        "limit" := "limit";
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      else
        -- Set sort to user input
        sort := sort;
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      '''',
      '''',
      '''',
      '''',
      cast(mr.resolution as text),
      '''',
      '''',
      '''',
      cast(mr.movieInclude as text),
      cast(mr.tvInclude as text)
      from mediaresolution mr';

      -- Check if where clause is given
      if resolution is not null then
        -- Set variable
        dSQLWhere := concat('mr.resolution = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by mr.resolution ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if resolution is not null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(resolution as citext), cast("limit" as int);
      else
        -- Else execute default statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;

    -- Else check if option mode is extract media stream source
    elseif optionMode = 'extractMediaStreamSource' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      else
        -- Set limit to user input
        "limit" := "limit";
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      else
        -- Set sort to user input
        sort := sort;
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      '''',
      '''',
      '''',
      '''',
      '''',
      cast(mss.streamsource as text),
      cast(mss.streamdescription as text),
      '''',
      cast(mss.movieInclude as text),
      cast(mss.tvInclude as text)
      from mediastreamsource mss';

      -- Check if where clause is given
      if streamsource is not null then
        -- Set variable
        dSQLWhere := concat('mss.streamsource = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if streamdescription is not null then
        -- Check if dynamic SQL is not empty
        if trim(dSQLWhere) <> trim('') then
          -- Include the next filter into the where clause
          dSQLWhere := concat(dSQLWhere, ' and mss.streamdescription = $', countInput);
        else
          -- Include the next filter into the where clause
          dSQLWhere := concat('mss.streamdescription = $', countInput);
        end if;

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by mss.streamsource ', sort, ', mss.streamdescription ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if streamsource is not null and streamdescription is null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(streamsource as citext), cast("limit" as int);
      elseif streamsource is null and streamdescription is not null then
        -- Else if execute one parameter and not the other statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(streamdescription as citext), cast("limit" as int);
      elseif streamsource is not null and streamdescription is not null then
        -- Else if execute all parameters statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(streamsource as citext), cast(streamdescription as citext), cast("limit" as int);
      else
        -- Else execute default statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;

    -- Else check if option mode is extract media video encode
    elseif optionMode = 'extractMediaVideoEncode' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      else
        -- Set limit to user input
        "limit" := "limit";
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      else
        -- Set sort to user input
        sort := sort;
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      '''',
      '''',
      '''',
      '''',
      '''',
      '''',
      '''',
      cast(mve.videoencode as text),
      cast(mve.movieInclude as text),
      cast(mve.tvInclude as text)
      from mediavideoencode mve';

      -- Check if where clause is given
      if videoencode is not null then
        -- Set variable
        dSQLWhere := concat('mve.videoencode = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by mve.videoencode ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if videoencode is not null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(videoencode as citext), cast("limit" as int);
      else
        -- Else execute default statement
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;
    end if;
  end; $_$;


--
-- Name: extractmediafeed(text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extractmediafeed(optionmode text DEFAULT NULL::text, titlelong text DEFAULT NULL::text, titleshort text DEFAULT NULL::text, actionstatus text DEFAULT NULL::text, "limit" text DEFAULT NULL::text, sort text DEFAULT NULL::text) RETURNS TABLE(titlelongreturn text, titleshortreturn text, infourlreturn text, publishdatereturn text, actionstatusreturn text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitleLong text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitTitleShort text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitInfoUrl text := '[^a-zA-Z0-9:\-./%?=&]';
  declare omitActionStatus text := '[^0-9]';
  declare omitLimit text := '[^0-9\-]';
  declare omitSort text := '[^a-zA-Z]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthTitleLong int := 255;
  declare maxLengthTitleShort int := 255;
  declare maxLengthInfoUrl int := 8000;
  declare maxLengthActionStatus int := 255;
  declare maxLengthSort int := 255;
  declare lowerLimit int := 1;
  declare upperLimit int := 100;
  declare defaultLimit int := 25;
  declare dSQL text := '';
  declare dSQLWhere text := '';
  declare countInput int := 0;

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titlelong is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titlelong := regexp_replace(regexp_replace(titlelong, omitTitleLong, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titlelong := trim(substring(titlelong, 1, maxLengthTitleLong));

      -- Check if empty string
      if titlelong = '' then
        -- Set parameter to null if empty string
        titlelong := nullif(titlelong, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titleshort is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titleshort := regexp_replace(regexp_replace(titleshort, omitTitleShort, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titleshort := trim(substring(titleshort, 1, maxLengthTitleShort));

      -- Check if empty string
      if titleshort = '' then
        -- Set parameter to null if empty string
        titleshort := nullif(titleshort, '');
      end if;
    end if;
	
	-- -- Check if parameter is not null
    -- if infourl is not null then
      -- -- Omit characters, multi space to single space, and trim leading and trailing spaces
      -- infourl := regexp_replace(regexp_replace(infourl, omitInfoUrl, ' '), '[ ]{2,}', ' ');

      -- -- Set character limit
      -- infourl := trim(substring(infourl, 1, maxLengthInfoUrl));

      -- -- Check if empty string
      -- if infourl = '' then
        -- -- Set parameter to null if empty string
        -- infourl := nullif(infourl, '');
      -- end if;
    -- end if;

    -- Check if parameter is not null
    if actionstatus is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actionstatus := regexp_replace(regexp_replace(actionstatus, omitActionStatus, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actionstatus := trim(substring(actionstatus, 1, maxLengthActionStatus));

      -- Check if empty string
      if actionstatus = '' then
        -- Set parameter to null if empty string
        actionstatus := nullif(actionstatus, '');
      end if;
    end if;

    -- Check if parameter is not null
    if "limit" is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      "limit" := regexp_replace(regexp_replace("limit", omitLimit, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      "limit" := trim("limit");

      -- Check if empty string
      if "limit" = '' then
        -- Set parameter to null if empty string
        "limit" := nullif("limit", '');
      end if;
    end if;

    -- Check if parameter is not null
    if sort is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      sort := regexp_replace(regexp_replace(sort, omitSort, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      sort := trim(substring(sort, 1, maxLengthSort));

      -- Check if empty string
      if sort = '' then
        -- Set parameter to null if empty string
        sort := nullif(sort, '');
      end if;
    end if;

    -- Else check if option mode is extract movie feed
    if optionMode = 'extractMovieFeed' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      else
        -- Set limit to user input
        "limit" := "limit";
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      else
        -- Set sort to user input
        sort := sort;
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      cast(mf.titlelong as text),
      cast(mf.titleshort as text),
	  cast(mf.info_url as text),
      cast(to_char(mf.publish_date, ''YYYY-MM-DD HH24:MI:SS.US'') as text),
      cast(mf.actionstatus as text)
      from moviefeed mf';

      -- Check if where clause is given
      if titlelong is not null then
        -- Set variable
        dSQLWhere := concat('mf.titlelong = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if titleshort is not null then
        -- Check if dynamic SQL is not empty
        if trim(dSQLWhere) <> trim('') then
          -- Include the next filter into the where clause
          dSQLWhere := concat(dSQLWhere, ' and mf.titleshort = $', countInput);
        else
          -- Include the next filter into the where clause
          dSQLWhere := concat('mf.titleshort = $', countInput);
        end if;

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if actionstatus is not null then
        -- Check if dynamic SQL is not empty
        if trim(dSQLWhere) <> trim('') then
          -- Include the next filter into the where clause
          dSQLWhere := concat(dSQLWhere, ' and mf.actionstatus = $', countInput);
        else
          -- Include the next filter into the where clause
          dSQLWhere := concat('mf.actionstatus = $', countInput);
        end if;

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by mf.publish_date ', sort, ', mf.titlelong ', sort, ', mf.titleshort ', sort, ', mf.actionstatus ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if titlelong is not null and titleshort is null and actionstatus is null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching YNN
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast("limit" as int);
      elseif titlelong is not null and titleshort is not null and actionstatus is null then
        -- Else if execute one parameter and not the other statement YYN
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast(titleshort as citext), cast("limit" as int);
      elseif titlelong is not null and titleshort is null and actionstatus is not null then
        -- Else if execute one parameter and not the other statement YNY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast(actionstatus as int), cast("limit" as int);
      elseif titlelong is null and titleshort is not null and actionstatus is null then
        -- Else if execute one parameter and not the other statement NYN
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titleshort as citext), cast("limit" as int);
      elseif titlelong is null and titleshort is not null and actionstatus is not null then
        -- Else if execute one parameter and not the other statement NYY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titleshort as citext), cast(actionstatus as int), cast("limit" as int);
      elseif titlelong is null and titleshort is null and actionstatus is not null then
        -- Else if execute all parameters statement NNY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(actionstatus as int), cast("limit" as int);
      elseif titlelong is not null and titleshort is not null and actionstatus is not null then
        -- Else if execute all parameters statement YYY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast(titleshort as citext), cast(actionstatus as int), cast("limit" as int);
      else
        -- Else execute default statement NNN
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;

    -- Else check if option mode is extract tv feed
    elseif optionMode = 'extractTVFeed' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      else
        -- Set limit to user input
        "limit" := "limit";
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      else
        -- Set sort to user input
        sort := sort;
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      cast(tvf.titlelong as text),
      cast(tvf.titleshort as text),
	  cast(tvf.info_url as text),
      cast(to_char(tvf.publish_date, ''YYYY-MM-DD HH24:MI:SS.US'') as text),
      cast(tvf.actionstatus as text)
      from tvfeed tvf';

      -- Check if where clause is given
      if titlelong is not null then
        -- Set variable
        dSQLWhere := concat('tvf.titlelong = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if titleshort is not null then
        -- Check if dynamic SQL is not empty
        if trim(dSQLWhere) <> trim('') then
          -- Include the next filter into the where clause
          dSQLWhere := concat(dSQLWhere, ' and tvf.titleshort = $', countInput);
        else
          -- Include the next filter into the where clause
          dSQLWhere := concat('tvf.titleshort = $', countInput);
        end if;

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if actionstatus is not null then
        -- Check if dynamic SQL is not empty
        if trim(dSQLWhere) <> trim('') then
          -- Include the next filter into the where clause
          dSQLWhere := concat(dSQLWhere, ' and tvf.actionstatus = $', countInput);
        else
          -- Include the next filter into the where clause
          dSQLWhere := concat('tvf.actionstatus = $', countInput);
        end if;

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by tvf.publish_date ', sort, ', tvf.titlelong ', sort, ', tvf.titleshort ', sort, ', tvf.actionstatus ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if titlelong is not null and titleshort is null and actionstatus is null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching YNN
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast("limit" as int);
      elseif titlelong is not null and titleshort is not null and actionstatus is null then
        -- Else if execute one parameter and not the other statement YYN
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast(titleshort as citext), cast("limit" as int);
      elseif titlelong is not null and titleshort is null and actionstatus is not null then
        -- Else if execute one parameter and not the other statement YNY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast(actionstatus as int), cast("limit" as int);
      elseif titlelong is null and titleshort is not null and actionstatus is null then
        -- Else if execute one parameter and not the other statement NYN
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titleshort as citext), cast("limit" as int);
      elseif titlelong is null and titleshort is not null and actionstatus is not null then
        -- Else if execute one parameter and not the other statement NYY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titleshort as citext), cast(actionstatus as int), cast("limit" as int);
      elseif titlelong is null and titleshort is null and actionstatus is not null then
        -- Else if execute all parameters statement NNY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(actionstatus as int), cast("limit" as int);
      elseif titlelong is not null and titleshort is not null and actionstatus is not null then
        -- Else if execute all parameters statement YYY
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(titlelong as citext), cast(titleshort as citext), cast(actionstatus as int), cast("limit" as int);
      else
        -- Else execute default statement NNN
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;
    end if;
  end; $_$;


--
-- Name: extractnewsfeed(text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extractnewsfeed(optionmode text DEFAULT NULL::text, title text DEFAULT NULL::text, imageurl text DEFAULT NULL::text, feedurl text DEFAULT NULL::text, actualurl text DEFAULT NULL::text, "limit" text DEFAULT NULL::text, sort text DEFAULT NULL::text) RETURNS TABLE(titlereturn text, imageurlreturn text, feedurlreturn text, actualurlreturn text, publishdatereturn text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitle text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitImageURL text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitFeedURL text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitActualURL text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitLimit text := '[^0-9\-]';
  declare omitSort text := '[^a-zA-Z]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthTitle int := 255;
  declare maxLengthImageURL int := 255;
  declare maxLengthFeedURL int := 768;
  declare maxLengthActualURL int := 255;
  declare maxLengthSort int := 255;
  declare lowerLimit int := 1;
  declare upperLimit int := 100;
  declare defaultLimit int := 25;
  declare dSQL text := '';
  declare dSQLWhere text := '';
  declare countInput int := 0;

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if title is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      title := regexp_replace(regexp_replace(title, omitTitle, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      title := trim(substring(title, 1, maxLengthTitle));

      -- Check if empty string
      if title = '' then
        -- Set parameter to null if empty string
        title := nullif(title, '');
      end if;
    end if;

    -- Check if parameter is not null
    if imageurl is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      imageurl := regexp_replace(regexp_replace(imageurl, omitImageURL, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      imageurl := trim(substring(imageurl, 1, maxLengthImageURL));

      -- Check if empty string
      if imageurl = '' then
        -- Set parameter to null if empty string
        imageurl := nullif(imageurl, '');
      end if;
    end if;

    -- Check if parameter is not null
    if feedurl is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      feedurl := regexp_replace(regexp_replace(feedurl, omitFeedURL, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      feedurl := trim(substring(feedurl, 1, maxLengthFeedURL));

      -- Check if empty string
      if feedurl = '' then
          -- Set parameter to null if empty string
          feedurl := nullif(feedurl, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actualurl is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actualurl := regexp_replace(regexp_replace(actualurl, omitActualURL, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actualurl := trim(substring(actualurl, 1, maxLengthActualURL));

      -- Check if empty string
      if actualurl = '' then
        -- Set parameter to null if empty string
        actualurl := nullif(actualurl, '');
      end if;
    end if;

    -- Check if parameter is not null
    if "limit" is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      "limit" := regexp_replace(regexp_replace("limit", omitLimit, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      "limit" := trim("limit");

      -- Check if empty string
      if "limit" = '' then
        -- Set parameter to null if empty string
        "limit" := nullif("limit", '');
      end if;
    end if;

    -- Check if parameter is not null
    if sort is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      sort := regexp_replace(regexp_replace(sort, omitSort, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      sort := trim(substring(sort, 1, maxLengthSort));

      -- Check if empty string
      if sort = '' then
        -- Set parameter to null if empty string
        sort := nullif(sort, '');
      end if;
    end if;

    -- Check if option mode extract news feed
    if optionMode = 'extractNewsFeed' then
      -- Increment counter
      countInput := countInput + 1;

      -- Check if limit is given
      if "limit" is null or cast("limit" as int) not between lowerLimit and upperLimit then
        -- Set limit to default number
        "limit" := defaultLimit;
      end if;

      -- Check if sort is given
      if sort is null or lower(sort) not in ('desc', 'asc') then
        -- Set sort to default sorting
        sort := 'asc';
      end if;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      dSQL :=
      'select
      cast(nf.title as text),
      cast(nf.imageurl as text),
      cast(nf.feedurl as text),
      cast(nf.actualurl as text),
      cast(to_char(nf.publish_date, ''YYYY-MM-DD HH24:MI:SS.US'') as text)
      from newsfeed nf';

      -- Check if where clause is given
      if title is not null then
        -- Set variable
        dSQLWhere := concat('nf.title = $', countInput);

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if imageurl is not null then
        -- Check if value is string null
        if lower(imageurl) = 'null' then
          -- Check if dynamic SQL is not empty
          if trim(dSQLWhere) <> trim('') then
            -- Include the next filter into the where clause
            dSQLWhere := concat(dSQLWhere, ' and nf.imageurl is null');
          else
            -- Include the next filter into the where clause
            dSQLWhere := 'nf.imageurl is null';
          end if;
        else
          if trim(dSQLWhere ) <> trim('') then
            -- Include the next filter into the where clause
            dSQLWhere := concat(dSQLWhere, ' and nf.imageurl = $', countInput);
          else
            -- Include the next filter into the where clause
            dSQLWhere := concat('nf.imageurl = $', countInput);
          end if;

          -- Increment counter
          countInput := countInput + 1;
        end if;
      end if;

      -- Check if where clause is given
      if feedurl is not null then
        -- Check if dynamic SQL is not empty
        if trim(dSQLWhere) <> trim('') then
          -- Include the next filter into the where clause
          dSQLWhere := concat(dSQLWhere, ' and nf.feedurl = $', countInput);
        else
          -- Include the next filter into the where clause
          dSQLWhere := concat('nf.feedurl = $', countInput);
        end if;

        -- Increment counter
        countInput := countInput + 1;
      end if;

      -- Check if where clause is given
      if actualurl is not null then
        -- Check if value is string null
        if lower(actualurl) = 'null' then
          -- Check if dynamic SQL is not empty
          if trim(dSQLWhere) <> trim('') then
            -- Include the next filter into the where clause
            dSQLWhere := concat(dSQLWhere, ' and nf.actualurl is null');
          else
            -- Include the next filter into the where clause
            dSQLWhere := 'nf.actualurl is null';
          end if;
        else
          if trim(dSQLWhere ) <> trim('') then
            -- Include the next filter into the where clause
            dSQLWhere := concat(dSQLWhere, ' and nf.actualurl = $', countInput);
          else
            -- Include the next filter into the where clause
            dSQLWhere := concat('nf.actualurl = $', countInput);
          end if;

          -- Increment counter
          countInput := countInput + 1;
        end if;
      end if;

      -- Check if dynamic SQL is not empty
      if trim(dSQLWhere) <> trim('') then
        -- Include the where clause
        dSQLWhere := concat(' where ', dSQLWhere);
      end if;

      -- Set the dynamic string with the where clause and sort option
      dSQL := concat(dSQL, dSQLWhere, ' order by nf.publish_date ', sort, ', nf.title ', sort, ', nf.imageurl ', sort, ', nf.feedurl ', sort, ', nf.actualurl ', sort, ' limit $', countInput);

      -- Increment counter
      countInput := countInput + 1;

      -- Check if parameters were set
      if title is not null and imageurl is null and feedurl is null and actualurl is null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching YNNN
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(title as citext), cast("limit" as int);
      elseif title is not null and imageurl is not null and feedurl is null and actualurl is null then
        -- Check if column is not equal to null
        if imageurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYNN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(imageurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYNN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast("limit" as int);
        end if;

      elseif title is not null and imageurl is not null and feedurl is not null and actualurl is null then
        -- Check if column is not equal to null
        if imageurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYYN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(imageurl as citext), cast(feedurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYYN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(feedurl as citext), cast("limit" as int);
        end if;
      elseif title is not null and imageurl is not null and feedurl is null and actualurl is not null then
        -- Check if column is not equal to null
        if imageurl <> 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(imageurl as citext), cast(actualurl as citext), cast("limit" as int);
        elseif imageurl = 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(actualurl as citext), cast("limit" as int);
        elseif imageurl <> 'null' and actualurl = 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(imageurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast("limit" as int);
        end if;
      elseif title is not null and imageurl is null and feedurl is not null and actualurl is not null then
        -- Check if column is not equal to null
        if actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YNYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(feedurl as citext), cast(actualurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching YNYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(feedurl as citext), cast("limit" as int);
        end if;
      elseif title is not null and imageurl is null and feedurl is not null and actualurl is null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching YNYN
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(title as citext), cast(feedurl as citext), cast("limit" as int);
      elseif title is not null and imageurl is null and feedurl is null and actualurl is not null then
        -- Check if column is not equal to null
        if actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YNNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(actualurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching YNNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast("limit" as int);
        end if;
      elseif title is null and imageurl is not null and feedurl is not null and actualurl is not null then
        -- Check if column is not equal to null
        if imageurl <> 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(imageurl as citext), cast(feedurl as citext), cast(actualurl as citext), cast("limit" as int);
        elseif imageurl = 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(feedurl as citext), cast(actualurl as citext), cast("limit" as int);
        elseif imageurl <> 'null' and actualurl = 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(imageurl as citext), cast(feedurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(feedurl as citext), cast("limit" as int);
        end if;
      elseif title is null and imageurl is not null and feedurl is not null and actualurl is null then
        -- Check if column is not equal to null
        if imageurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYYN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(imageurl as citext), cast(feedurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYYN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(feedurl as citext), cast("limit" as int);
        end if;
      elseif title is null and imageurl is not null and feedurl is null and actualurl is not null then
        -- Check if column is not equal to null
        if imageurl <> 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(imageurl as citext), cast(actualurl as citext), cast("limit" as int);
        elseif imageurl = 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(actualurl as citext), cast("limit" as int);
        elseif imageurl <> 'null' and actualurl = 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(imageurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast("limit" as int);
        end if;

      elseif title is null and imageurl is null and feedurl is not null and actualurl is not null then
        -- Check if column is not equal to null
        if actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NNYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(feedurl as citext), cast(actualurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching NNYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(feedurl as citext), cast("limit" as int);
        end if;

      elseif title is null and imageurl is not null and feedurl is null and actualurl is null then
        -- Check if column is not equal to null
        if imageurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYNN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(imageurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching NYNN
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast("limit" as int);
        end if;

      elseif title is null and imageurl is null and feedurl is not null and actualurl is null then
        -- Important Note: Parameterizated values need to match the placeholders they are matching NNYN
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast(feedurl as citext), cast("limit" as int);

      elseif title is null and imageurl is null and feedurl is null and actualurl is not null then
        -- Check if column is not equal to null
        if actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching NNNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(actualurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching NNNY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast("limit" as int);
        end if;

      elseif title is not null and imageurl is not null and feedurl is not null and actualurl is not null then
        -- Check if column is not equal to null
        if imageurl <> 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(imageurl as citext), cast(feedurl as citext), cast(actualurl as citext), cast("limit" as int);
        elseif imageurl = 'null' and actualurl <> 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(feedurl as citext), cast(actualurl as citext), cast("limit" as int);
        elseif imageurl <> 'null' and actualurl = 'null' then
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(imageurl as citext), cast(feedurl as citext), cast("limit" as int);
        else
          -- Important Note: Parameterizated values need to match the placeholders they are matching YYYY
          -- Execute dynamic statement with the parameterized values
          -- Return dynamic sql
          return query execute format(
          '%s',
          dSQL
          ) using cast(title as citext), cast(feedurl as citext), cast("limit" as int);
        end if;

      else
        -- Else execute default statement NNNN
        -- Important Note: Parameterizated values need to match the placeholders they are matching
        -- Execute dynamic statement with the parameterized values
        -- Return dynamic sql
        return query execute format(
        '%s',
        dSQL
        ) using cast("limit" as int);
      end if;
    end if;
  end; $_$;


--
-- Name: insertupdatedeletebulkmediafeed(text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.insertupdatedeletebulkmediafeed(IN optionmode text, IN titlelong text DEFAULT NULL::text, IN titleshort text DEFAULT NULL::text, IN publishdate text DEFAULT NULL::text, IN infourl text DEFAULT NULL::text, INOUT status text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare and set variable
  declare yearString text := '';
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitleLong text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitTitleShort text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitPublishDate text := '[^0-9\-:./ ]';
  declare omitInfoUrl text := '[^a-zA-Z0-9:\-./%?=&]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthTitleLong int := 255;
  declare maxLengthTitleShort int := 255;
  declare maxLengthPublishDate int := 255;
  declare maxLengthInfoUrl int := 8000;
  declare titlelongstring text := titlelong;
  declare titleshortstring text := titleshort;
  declare publishdatestring text := publishDate;
  declare infourlstring text := infourl;
  declare code text := '00000';
  declare msg text := '';
  declare result text := '';

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titlelongstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titlelongstring := regexp_replace(regexp_replace(titlelongstring, omitTitleLong, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titlelongstring := trim(substring(titlelongstring, 1, maxLengthTitleLong));

      -- Check if empty string
      if titlelongstring = '' then
        -- Set parameter to null if empty string
        titlelongstring := nullif(titlelongstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titleshortstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titleshortstring := regexp_replace(regexp_replace(titleshortstring, omitTitleShort, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titleshortstring := trim(substring(titleshortstring, 1, maxLengthTitleShort));

      -- Check if empty string
      if titleshortstring = '' then
        -- Set parameter to null if empty string
        titleshortstring := nullif(titleshortstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if publishdatestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      publishdatestring := regexp_replace(regexp_replace(publishdatestring, omitPublishDate, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      publishdatestring := trim(substring(publishdatestring, 1, maxLengthPublishDate));

      -- Check if the parameter cannot be casted into a date time
      if to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS') is null then
        -- Set the string as empty to be nulled below
        publishdatestring := '';
      end if;

      -- Check if empty string
      if publishdatestring = '' then
        -- Set parameter to null if empty string
        publishdatestring := nullif(publishdatestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if infourlstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      infourlstring := regexp_replace(regexp_replace(infourlstring, omitInfoUrl, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      infourlstring := trim(substring(infourlstring, 1, maxLengthInfoUrl));

      -- Check if empty string
      if infourlstring = '' then
        -- Set parameter to null if empty string
        infourlstring := nullif(infourlstring, '');
      end if;
    end if;

    -- Check if option mode is delete temp movie
    if optionMode = 'deleteTempMovie' then
      -- Begin begin/except
      begin
        -- Delete records
        delete
        from moviefeedtemp;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is delete temp tv
    elseif optionMode = 'deleteTempTV' then
      -- Begin begin/except
      begin
        -- Delete records
        delete
        from tvfeedtemp;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";

    -- Check if option mode is insert temp movie
    elseif optionMode = 'insertTempMovie' then
      -- Check if parameters are not null
      if titlelongstring is not null and titleshortstring is not null and publishdatestring is not null then
        -- Begin begin/except
        begin
          -- Insert record
          insert into moviefeedtemp
          (
            titlelong,
            titleshort,
		    info_url,
            publish_date,
            created_date
          )
          values
          (
            titlelongstring,
            lower(titleshortstring),
		    infourlstring,
            publishdatestring,
            cast(current_timestamp as timestamp)
          );

          -- Set message
          result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
        exception when others then
          -- Caught exception error
          -- Get diagnostics information
          get stacked diagnostics code = returned_sqlstate, msg = message_text;

          -- Set message
          result := concat('{"Status": "Error", "Message": "', msg, '"}');
        -- End begin/except
        end;
      else
        -- Set message
        set result = '{"Status": "Error", "Message": "Process halted, titlelong, titleshort, and or publish date were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is insert temp tv
    elseif optionMode = 'insertTempTV' then
      -- Check if parameters are not null
      if titlelongstring is not null and titleshortstring is not null and publishdatestring is not null then
        -- Begin begin/except
        begin
          -- Insert record
          insert into tvfeedtemp
          (
            titlelong,
            titleshort,
		    info_url,
            publish_date,
            created_date
          )
          values
          (
            titlelongstring,
            lower(titleshortstring),
		    infourlstring,
            publishdatestring,
            cast(current_timestamp as timestamp)
          );

          -- Set message
          result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
        exception when others then
          -- Caught exception error
          -- Get diagnostics information
          get stacked diagnostics code = returned_sqlstate, msg = message_text;

          -- Set message
          result := concat('{"Status": "Error", "Message": "', msg, '"}');
        -- End begin/except
        end;
      else
        -- Set message
        set result = '{"Status": "Error", "Message": "Process halted, titlelong, titleshort, and or publish date were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update bulk movie
    elseif optionMode = 'updateBulkMovie' then
      -- Begin begin/except
      begin
        -- Set variable
        yearString :=
        case
          when to_char(current_timestamp + interval '0 month', 'MM') <= '03'
            then
              concat(to_char(current_timestamp + interval '-1 year', 'YYYY'), '|', to_char(current_timestamp + interval '0 year', 'YYYY'))
          else
            to_char(current_timestamp + interval '0 year', 'YYYY')
        end;

        -- Remove duplicate records based on group by
        with subMovieDetails as
        (
          -- Select unique records
          select
          cast(trim(substring(regexp_replace(regexp_replace(mft.titlelong, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as citext) as titlelong,
          cast(trim(substring(regexp_replace(regexp_replace(mft.titleshort, omitTitleShort, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleShort)) as citext) as titleshort,
		  cast(trim(substring(regexp_replace(regexp_replace(mft.info_url, omitInfoUrl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthInfoUrl)) as citext) as info_url,
          trim(substring(regexp_replace(regexp_replace(mft.publish_date, omitPublishDate, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthPublishDate)) as publish_date
          from moviefeedtemp mft
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
          left join moviefeed mf on mf.titlelong = smd.titlelong
          left join moviefeed mfas on mfas.titleshort = smd.titleshort
          join mediaaudioencode mae on mae.movieInclude in ('1') and smd.titlelong ilike concat('%', mae.audioencode, '%')
          left join mediadynamicrange mdr on mdr.movieInclude in ('1') and smd.titlelong ilike concat('%', mdr.dynamicrange, '%')
          join mediaresolution mr on mr.movieInclude in ('1') and smd.titlelong ilike concat('%', mr.resolution, '%')
          left join mediastreamsource mss on mss.movieInclude in ('1') and smd.titlelong ilike concat('%', mss.streamsource, '%')
          join mediavideoencode mve on mve.movieInclude in ('1') and smd.titlelong ilike concat('%', mve.videoencode, '%')
          inner join (select smdii.titlelong, max(smdii.publish_date) as publish_date from subMovieDetails smdii group by smdii.titlelong) as smdi on smdi.titlelong = smd.titlelong and smdi.publish_date = smd.publish_date
          where
          mfas.actionstatus not in (1) and
          mf.mfID is not null and
          (
            (
              yearString ilike '%|%' and
              (
                smd.titlelong ilike concat('%', substring(yearString, 1, 4), '%') or
                smd.titlelong ilike concat('%', substring(yearString, 6, 9), '%')
              )
            ) or
            (
              smd.titlelong ilike concat('%', substring(yearString, 1, 4), '%')
            )
          )
          group by smd.titlelong, smd.titleshort, smd.info_url, smd.publish_date, mfas.actionstatus, mf.mfID
        )

        -- Update records
        update moviefeed
        set
		info_url = md.info_url,
        publish_date = cast(md.publish_date as timestamp),
        modified_date = cast(current_timestamp as timestamp)
        from movieDetails md
        where
        md.mfID = moviefeed.mfID;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update bulk tv
    elseif optionMode = 'updateBulkTV' then
      -- Begin begin/except
      begin
        -- Remove duplicate records based on group by
        with subTVDetails as
        (
          -- Select unique records
          select
          cast(trim(substring(regexp_replace(regexp_replace(tft.titlelong, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as citext) as titlelong,
          cast(trim(substring(regexp_replace(regexp_replace(tft.titleshort, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as citext) as titleshort,
		  cast(trim(substring(regexp_replace(regexp_replace(tft.info_url, omitInfoUrl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthInfoUrl)) as citext) as info_url,
          trim(substring(regexp_replace(regexp_replace(tft.publish_date, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as publish_date
          from tvfeedtemp tft
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
          left join tvfeed tf on tf.titlelong = std.titlelong
          left join tvfeed tfas on tfas.titleshort = std.titleshort
          join mediaaudioencode mae on mae.tvInclude in ('1') and std.titlelong ilike concat('%', mae.audioencode, '%')
          left join mediadynamicrange mdr on mdr.tvInclude in ('1') and std.titlelong ilike concat('%', mdr.dynamicrange, '%')
          join mediaresolution mr on mr.tvInclude in ('1') and std.titlelong ilike concat('%', mr.resolution, '%')
          left join mediastreamsource mss on mss.tvInclude in ('1') and std.titlelong ilike concat('%', mss.streamsource, '%')
          join mediavideoencode mve on mve.tvInclude in ('1') and std.titlelong ilike concat('%', mve.videoencode, '%')
          inner join (select stdii.titlelong, max(stdii.publish_date) as publish_date from subTVDetails stdii group by stdii.titlelong) as stdi on stdi.titlelong = std.titlelong and stdi.publish_date = std.publish_date
          where
          tfas.actionstatus not in (1) and
          tf.tfID is not null
          group by std.titlelong, std.titleshort, std.info_url, std.publish_date, tfas.actionstatus, tf.tfID
        )

        -- Update records
        update tvfeed
        set
		info_url = td.info_url,
        publish_date = cast(td.publish_date as timestamp),
        modified_date = cast(current_timestamp as timestamp)
        from tvDetails td
        where
        td.tfID = tvfeed.tfID;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert bulk movie
    elseif optionMode = 'insertBulkMovie' then
      -- Begin begin/except
      begin
        -- Set variable
        yearString :=
        case
          when to_char(current_timestamp + interval '0 month', 'MM') <= '03'
            then
              concat(to_char(current_timestamp + interval '-1 year', 'YYYY'), '|', to_char(current_timestamp + interval '0 year', 'YYYY'))
          else
            to_char(current_timestamp + interval '0 year', 'YYYY')
        end;

        -- Insert records
        insert into moviefeed
        (
          titlelong,
          titleshort,
		  info_url,
          publish_date,
          actionstatus,
          created_date,
          modified_date
        )

        -- Remove duplicate records based on group by
        with subMovieDetails as
        (
          -- Select unique records
          select
          cast(trim(substring(regexp_replace(regexp_replace(mft.titlelong, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as citext) as titlelong,
          cast(trim(substring(regexp_replace(regexp_replace(mft.titleshort, omitTitleShort, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleShort)) as citext) as titleshort,
		  cast(trim(substring(regexp_replace(regexp_replace(mft.info_url, omitInfoUrl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthInfoUrl)) as citext) as info_url,
          trim(substring(regexp_replace(regexp_replace(mft.publish_date, omitPublishDate, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthPublishDate)) as publish_date
          from moviefeedtemp mft
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
          left join moviefeed mf on mf.titlelong = smd.titlelong
          left join moviefeed mfas on mfas.titleshort = smd.titleshort
          join mediaaudioencode mae on mae.movieInclude in ('1') and smd.titlelong ilike concat('%', mae.audioencode, '%')
          left join mediadynamicrange mdr on mdr.movieInclude in ('1') and smd.titlelong ilike concat('%', mdr.dynamicrange, '%')
          join mediaresolution mr on mr.movieInclude in ('1') and smd.titlelong ilike concat('%', mr.resolution, '%')
          left join mediastreamsource mss on mss.movieInclude in ('1') and smd.titlelong ilike concat('%', mss.streamsource, '%')
          join mediavideoencode mve on mve.movieInclude in ('1') and smd.titlelong ilike concat('%', mve.videoencode, '%')
          inner join (select smdii.titlelong, max(smdii.publish_date) as publish_date from subMovieDetails smdii group by smdii.titlelong) as smdi on smdi.titlelong = smd.titlelong and smdi.publish_date = smd.publish_date
          where
          (
            mfas.actionstatus not in (1) or
            mfas.actionstatus is null
          ) and
          mf.mfID is null and
          (
            (
              yearString ilike '%|%' and
              (
                smd.titlelong ilike concat('%', substring(yearString, 1, 4), '%') or
                smd.titlelong ilike concat('%', substring(yearString, 6, 9), '%')
              )
            ) or
            (
              smd.titlelong ilike concat('%', substring(yearString, 1, 4), '%')
            )
          )
          group by smd.titlelong, smd.titleshort, smd.info_url, smd.publish_date, mfas.actionstatus, mf.mfID
        )

        -- Select records
        select
        md.titlelong,
        md.titleshort,
		md.info_url,
        cast(md.publish_date as timestamp),
        case
          when md.actionstatus is null
            then
              0
          else
            md.actionstatus
        end,
        cast(current_timestamp as timestamp),
        cast(current_timestamp as timestamp)
        from movieDetails md
        group by md.titlelong, md.titleshort, md.info_url, md.publish_date, md.actionstatus;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert bulk tv
    elseif optionMode = 'insertBulkTV' then
      -- Begin begin/except
      begin
        -- Insert records
        insert into tvfeed
        (
          titlelong,
          titleshort,
		  info_url,
          publish_date,
          actionstatus,
          created_date,
          modified_date
        )

        -- Remove duplicate records based on group by
        with subTVDetails as
        (
          -- Select unique records
          select
          cast(trim(substring(regexp_replace(regexp_replace(tft.titlelong, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as citext) as titlelong,
          cast(trim(substring(regexp_replace(regexp_replace(tft.titleshort, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as citext) as titleshort,
		  cast(trim(substring(regexp_replace(regexp_replace(tft.info_url, omitInfoUrl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthInfoUrl)) as citext) as info_url,
          trim(substring(regexp_replace(regexp_replace(tft.publish_date, omitTitleLong, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitleLong)) as publish_date
          from tvfeedtemp tft
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
          left join tvfeed tf on tf.titlelong = std.titlelong
          left join tvfeed tfas on tfas.titleshort = std.titleshort
          join mediaaudioencode mae on mae.tvInclude in ('1') and std.titlelong ilike concat('%', mae.audioencode, '%')
          left join mediadynamicrange mdr on mdr.tvInclude in ('1') and std.titlelong ilike concat('%', mdr.dynamicrange, '%')
          join mediaresolution mr on mr.tvInclude in ('1') and std.titlelong ilike concat('%', mr.resolution, '%')
          left join mediastreamsource mss on mss.tvInclude in ('1') and std.titlelong ilike concat('%', mss.streamsource, '%')
          join mediavideoencode mve on mve.tvInclude in ('1') and std.titlelong ilike concat('%', mve.videoencode, '%')
          inner join (select stdii.titlelong, max(stdii.publish_date) as publish_date from subTVDetails stdii group by stdii.titlelong) as stdi on stdi.titlelong = std.titlelong and stdi.publish_date = std.publish_date
          where
          (
            tfas.actionstatus not in (1) or
            tfas.actionstatus is null
          ) and
          tf.tfID is null
          group by std.titlelong, std.titleshort, std.info_url, std.publish_date, tfas.actionstatus, tf.tfID
        )

        -- Select records
        select
        td.titlelong,
        td.titleshort,
		td.info_url,
        cast(td.publish_date as timestamp),
        case
          when td.actionstatus is null
            then
              0
          else
            td.actionstatus
        end,
        cast(current_timestamp as timestamp),
        cast(current_timestamp as timestamp)
        from tvDetails td
        group by td.titlelong, td.titleshort, td.info_url, td.publish_date, td.actionstatus;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";
    end if;
  end; $_$;


--
-- Name: insertupdatedeletebulknewsfeed(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.insertupdatedeletebulknewsfeed(IN optionmode text, IN title text DEFAULT NULL::text, IN imageurl text DEFAULT NULL::text, IN feedurl text DEFAULT NULL::text, IN actualurl text DEFAULT NULL::text, IN publishdate text DEFAULT NULL::text, INOUT status text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare and set variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitle text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitImageurl text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitFeedurl text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitActualurl text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitPublishDate text := '[^0-9\-:./ ]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthTitle int := 255;
  declare maxLengthImageurl int := 255;
  declare maxLengthFeedurl int := 768;
  declare maxLengthActualurl int := 255;
  declare maxLengthPublishDate int := 255;
  declare titlestring text := title;
  declare imageurlstring text := imageurl;
  declare feedurlstring text := feedurl;
  declare actualurlstring text := actualurl;
  declare publishdatestring text := publishdate;
  declare code text := '00000';
  declare msg text := '';
  declare result text := '';

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' ', 'g'), '[ ]{2,}', ' ', 'g');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titlestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titlestring := regexp_replace(regexp_replace(titlestring, omitTitle, ' ', 'g'), '[ ]{2,}', ' ', 'g');

      -- Set character limit
      titlestring := trim(substring(titlestring, 1, maxLengthTitle));

      -- Check if empty string
      if titlestring = '' then
        -- Set parameter to null if empty string
        titlestring := nullif(titlestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if imageurlstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      imageurlstring := regexp_replace(regexp_replace(imageurlstring, omitImageurl, ' ', 'g'), '[ ]{2,}', ' ', 'g');

      -- Set character limit
      imageurlstring := trim(substring(imageurlstring, 1, maxLengthImageurl));

      -- Check if empty string
      if imageurlstring = '' then
        -- Set parameter to null if empty string
        imageurlstring := nullif(imageurlstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if feedurlstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      feedurlstring := regexp_replace(regexp_replace(feedurlstring, omitFeedurl, ' ', 'g'), '[ ]{2,}', ' ', 'g');

      -- Set character limit
      feedurlstring := trim(substring(feedurlstring, 1, maxLengthFeedurl));

      -- Check if empty string
      if feedurlstring = '' then
        -- Set parameter to null if empty string
        feedurlstring := nullif(feedurlstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actualurlstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actualurlstring := regexp_replace(regexp_replace(actualurlstring, omitActualurl, ' ', 'g'), '[ ]{2,}', ' ', 'g');

      -- Set character limit
      actualurlstring := trim(substring(actualurlstring, 1, maxLengthActualurl));

      -- Check if empty string
      if actualurlstring = '' then
        -- Set parameter to null if empty string
        actualurlstring := nullif(actualurlstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if publishdatestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      publishdatestring := regexp_replace(regexp_replace(publishdatestring, omitPublishDate, ' ', 'g'), '[ ]{2,}', ' ', 'g');

      -- Set character limit
      publishdatestring := trim(substring(publishdatestring, 1, maxLengthPublishDate));

      -- Check if the parameter cannot be casted into a date time
      if to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS') is null then
        -- Set the string as empty to be nulled below
        publishdatestring := '';
      end if;

      -- Check if empty string
      if publishdatestring = '' then
        -- Set parameter to null if empty string
        publishdatestring := nullif(publishdatestring, '');
      end if;
    end if;

    -- Check if option mode is delete temp news
    if optionMode = 'deleteTempNews' then
      -- Begin begin/except
      begin
        -- Delete records
        delete
        from newsfeedtemp;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";

    -- Check if option mode is insert temp news
    elseif optionMode = 'insertTempNews' then
      -- Check if parameters are not null
      if titlestring is not null and publishdatestring is not null then
        -- Begin begin/except
        begin
          -- Insert record
          insert into newsfeedtemp
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
            titlestring,
            case
              when imageurlstring is null or trim(imageurlstring) = ''
                then
                  null
              else
                imageurlstring
            end,
            feedurlstring,
            case
              when actualurlstring is null or trim(actualurlstring) = ''
                then
                  null
              else
                actualurlstring
            end,
            publishdatestring,
            cast(current_timestamp as timestamp)
          );

          -- Set message
          result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
        exception when others then
          -- Caught exception error
          -- Get diagnostics information
          get stacked diagnostics code = returned_sqlstate, msg = message_text;

          -- Set message
          result := concat('{"Status": "Error", "Message": "', msg, '"}');
        -- End begin/except
        end;
      else
        -- Else a parameter was not given
        -- Set message
        result := concat('{"Status": "Error", "Message": "Process halted, title and or publish date were not provided"}');
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update bulk news
    elseif optionMode = 'updateBulkNews' then
      -- Begin begin/except
      begin
        -- Remove duplicate records based on group by
        with subNewsDetails as
        (
          -- Select unique records
          select
          cast(trim(substring(regexp_replace(regexp_replace(nft.title, omitTitle, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitle)) as citext) as title,
          cast(trim(substring(regexp_replace(regexp_replace(nft.imageurl, omitImageurl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthImageurl)) as citext) as imageurl,
          cast(trim(substring(regexp_replace(regexp_replace(nft.feedurl, omitFeedurl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthFeedurl)) as citext) as feedurl,
          cast(trim(substring(regexp_replace(regexp_replace(nft.actualurl, omitActualurl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthActualurl)) as citext) as actualurl,
          trim(substring(regexp_replace(regexp_replace(nft.publish_date, omitPublishDate, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthPublishDate)) as publish_date
          from newsfeedtemp nft
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
            cast(nft.publish_date as timestamp) >= current_timestamp + interval '-1 hour' and
            cast(nft.publish_date as timestamp) <= current_timestamp + interval '0 hour'
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
          left join newsfeed nf on nf.title = snd.title
          inner join (select sndii.title, max(sndii.publish_date) as publish_date from subNewsDetails sndii group by sndii.title) as sndi on sndi.title = snd.title and sndi.publish_date = snd.publish_date
          where
          nf.nfID is not null
          group by snd.title, snd.imageurl, snd.feedurl, snd.actualurl, snd.publish_date, nf.nfID
        )

        -- Update records
        update newsfeed
        set
        imageurl =
        case
          when trim(nd.imageurl) = ''
            then
              null
          else
            nd.imageurl
        end,
        feedurl = nd.feedurl,
        actualurl =
        case
          when trim(nd.actualurl) = ''
            then
              null
          else
            nd.actualurl
        end,
        publish_date = cast(nd.publish_date as timestamp),
        modified_date = cast(current_timestamp as timestamp)
        from newsDetails nd
        where
        nd.nfID = newsfeed.nfID;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert bulk news
    elseif optionMode = 'insertBulkNews' then
      -- Begin begin/except
      begin
        -- Insert records
        insert into newsfeed
        (
          title,
          imageurl,
          feedurl,
          actualurl,
          publish_date,
          created_date,
          modified_date
        )

        -- Remove duplicate records based on group by
        with subNewsDetails as
        (
          -- Select unique records
          select
          cast(trim(substring(regexp_replace(regexp_replace(nft.title, omitTitle, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthTitle)) as citext) as title,
          cast(trim(substring(regexp_replace(regexp_replace(nft.imageurl, omitImageurl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthImageurl)) as citext) as imageurl,
          cast(trim(substring(regexp_replace(regexp_replace(nft.feedurl, omitFeedurl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthFeedurl)) as citext) as feedurl,
          cast(trim(substring(regexp_replace(regexp_replace(nft.actualurl, omitActualurl, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthActualurl)) as citext) as actualurl,
          trim(substring(regexp_replace(regexp_replace(nft.publish_date, omitPublishDate, ' ', 'g'), '[ ]{2,}', ' ', 'g'), 1, maxLengthPublishDate)) as publish_date
          from newsfeedtemp nft
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
          --   cast(nft.publish_date as timestamp) >= current_timestamp + interval '-1 hour' and
          --   cast(nft.publish_date as timestamp) <= current_timestamp + interval '0 hour'
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
          left join newsfeed nf on nf.title = snd.title
          inner join (select sndii.title, max(sndii.publish_date) as publish_date from subNewsDetails sndii group by sndii.title) as sndi on sndi.title = snd.title and sndi.publish_date = snd.publish_date
          where
          nf.nfID is null
          group by snd.title, snd.imageurl, snd.feedurl, snd.actualurl, snd.publish_date, nf.nfID
        )

        -- Select records
        select
        nd.title,
        case
          when trim(nd.imageurl) = ''
            then
              null
          else
            nd.imageurl
        end,
        nd.feedurl,
        case
          when trim(nd.actualurl) = ''
            then
              null
          else
            nd.actualurl
        end,
        cast(nd.publish_date as timestamp),
        cast(current_timestamp as timestamp),
        cast(current_timestamp as timestamp)
        from newsDetails nd
        group by nd.title, nd.imageurl, nd.feedurl, nd.actualurl, nd.publish_date;

        -- Set message
        result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
      exception when others then
        -- Caught exception error
        -- Get diagnostics information
        get stacked diagnostics code = returned_sqlstate, msg = message_text;

        -- Set message
        result := concat('{"Status": "Error", "Message": "', msg, '"}');
      -- End begin/except
      end;

      -- Select message
      select
      result into "status";
    end if;
  end; $_$;


--
-- Name: insertupdatedeletecontrolmediafeed(text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.insertupdatedeletecontrolmediafeed(IN optionmode text DEFAULT NULL::text, IN actionnumber text DEFAULT NULL::text, IN actiondescription text DEFAULT NULL::text, IN audioencode text DEFAULT NULL::text, IN dynamicrange text DEFAULT NULL::text, IN resolution text DEFAULT NULL::text, IN streamsource text DEFAULT NULL::text, IN streamdescription text DEFAULT NULL::text, IN videoencode text DEFAULT NULL::text, IN movieinclude text DEFAULT NULL::text, IN tvinclude text DEFAULT NULL::text, INOUT status text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
  -- Declare variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitActionNumber text := '[^0-9]';
  declare omitActionDescription text := '[^a-zA-Z]';
  declare omitMediaAudioEncode text := '[^a-zA-Z0-9.\-]';
  declare omitMediaDynamicRange text := '[^a-zA-Z]';
  declare omitMediaResolution text := '[^a-zA-Z0-9]';
  declare omitMediaStreamSource text := '[^a-zA-Z]';
  declare omitMediaStreamDescription text := '[^a-zA-Z]';
  declare omitMediaVideoEncode text := '[^a-zA-Z0-9]';
  declare omitMovieInclude text := '[^01]';
  declare omitTVInclude text := '[^01]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthActionNumber int := 255;
  declare maxLengthActionDescription int := 255;
  declare maxLengthMediaAudioEncode int := 100;
  declare maxLengthMediaDynamicRange int := 100;
  declare maxLengthMediaResolution int := 100;
  declare maxLengthMediaStreamSource int := 100;
  declare maxLengthMediaStreamDescription int := 100;
  declare maxLengthMediaVideoEncode int := 100;
  declare maxLengthMovieInclude int := 1;
  declare maxLengthTVInclude int := 1;
  declare actionnumberstring text := actionnumber;
  declare actiondescriptionstring text := actiondescription;
  declare audioencodestring text := audioencode;
  declare dynamicrangestring text := dynamicrange;
  declare resolutionstring text := resolution;
  declare streamsourcestring text := streamsource;
  declare streamdescriptionstring text := streamdescription;
  declare videoencodestring text := videoencode;
  declare movieincludestring text := movieinclude;
  declare tvincludestring text := tvinclude;
  declare code text := '00000';
  declare msg text := '';
  declare result text := '';

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actionnumberstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actionnumberstring := regexp_replace(regexp_replace(actionnumberstring, omitActionNumber, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actionnumberstring := trim(substring(actionnumberstring, 1, maxLengthActionNumber));

      -- Check if empty string
      if actionnumberstring = '' then
        -- Set parameter to null if empty string
        actionnumberstring := nullif(actionnumberstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actiondescriptionstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actiondescriptionstring := regexp_replace(regexp_replace(actiondescriptionstring, omitActionDescription, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actiondescriptionstring := trim(substring(actiondescriptionstring, 1, maxLengthActionDescription));

      -- Check if empty string
      if actiondescriptionstring = '' then
        -- Set parameter to null if empty string
        actiondescriptionstring := nullif(actiondescriptionstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if audioencodestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      audioencodestring := regexp_replace(regexp_replace(audioencodestring, omitMediaAudioEncode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      audioencodestring := trim(substring(audioencodestring, 1, maxLengthMediaAudioEncode));

      -- Check if empty string
      if audioencodestring = '' then
        -- Set parameter to null if empty string
        audioencodestring := nullif(audioencodestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if dynamicrangestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      dynamicrangestring := regexp_replace(regexp_replace(dynamicrangestring, omitMediaDynamicRange, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      dynamicrangestring := trim(substring(dynamicrangestring, 1, maxLengthMediaDynamicRange));

      -- Check if empty string
      if dynamicrangestring = '' then
        -- Set parameter to null if empty string
        dynamicrangestring := nullif(dynamicrangestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if resolutionstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      resolutionstring := regexp_replace(regexp_replace(resolutionstring, omitMediaResolution, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      resolutionstring := trim(substring(resolutionstring, 1, maxLengthMediaResolution));

      -- Check if empty string
      if resolutionstring = '' then
        -- Set parameter to null if empty string
        resolutionstring := nullif(resolutionstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if streamsourcestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      streamsourcestring := regexp_replace(regexp_replace(streamsourcestring, omitMediaStreamSource, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      streamsourcestring := trim(substring(streamsourcestring, 1, maxLengthMediaStreamSource));

      -- Check if empty string
      if streamsourcestring = '' then
        -- Set parameter to null if empty string
        streamsourcestring := nullif(streamsourcestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if streamdescriptionstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      streamdescriptionstring := regexp_replace(regexp_replace(streamdescriptionstring, omitMediaStreamDescription, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      streamdescriptionstring := trim(substring(streamdescriptionstring, 1, maxLengthMediaStreamDescription));

      -- Check if empty string
      if streamdescriptionstring = '' then
        -- Set parameter to null if empty string
        streamdescriptionstring := nullif(streamdescriptionstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if videoencodestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      videoencodestring := regexp_replace(regexp_replace(videoencodestring, omitMediaVideoEncode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      videoencodestring := trim(substring(videoencodestring, 1, maxLengthMediaVideoEncode));

      -- Check if empty string
      if videoencodestring = '' then
        -- Set parameter to null if empty string
        videoencodestring := nullif(videoencodestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if movieincludestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      movieincludestring := regexp_replace(regexp_replace(movieincludestring, omitMovieInclude, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      movieincludestring := trim(substring(movieincludestring, 1, maxLengthMovieInclude));

      -- Check if empty string
      if movieincludestring = '' then
        -- Set parameter to null if empty string
        movieincludestring := nullif(movieincludestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if tvincludestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      tvincludestring := regexp_replace(regexp_replace(tvincludestring, omitTVInclude, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      tvincludestring := trim(substring(tvincludestring, 1, maxLengthTVInclude));

      -- Check if empty string
      if tvincludestring = '' then
        -- Set parameter to null if empty string
        tvincludestring := nullif(tvincludestring, '');
      end if;
    end if;

    -- Check if option mode is insert action status
    if optionMode = 'insertActionStatus' then
      -- Check if parameters are null
      if actionnumberstring is not null and actiondescriptionstring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          ast.actionnumber
          from actionstatus ast
          where
          ast.actionnumber = cast(actionnumberstring as int)
          group by ast.actionnumber
        ) then
          -- Begin begin/except
          begin
            -- Insert record
            insert into actionstatus
            (
              actionnumber,
              actiondescription,
              created_date,
              modified_date
            )
            values
            (
              cast(actionnumberstring as int),
              cast(actiondescriptionstring as text),
              cast(current_timestamp as timestamp),
              cast(current_timestamp as timestamp)
            );

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, action number and action description were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert media audio encode
    elseif optionMode = 'insertMediaAudioEncode' then
      -- Check if parameters are null
      if audioencodestring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          mae.audioencode
          from mediaaudioencode mae
          where
          mae.audioencode = audioencodestring
          group by mae.audioencode
        ) then
          -- Begin begin/except
          begin
            -- Insert record
            insert into mediaaudioencode
            (
              audioencode,
              movieInclude,
              tvInclude,
              created_date,
              modified_date
            )
            values
            (
              cast(audioencodestring as citext),
              cast(movieincludestring as smallint),
              cast(tvincludestring as smallint),
              cast(current_timestamp as timestamp),
              cast(current_timestamp as timestamp)
            );

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, audio encode, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert media dynamic range
    elseif optionMode = 'insertMediaDynamicRange' then
      -- Check if parameters are null
      if dynamicrangestring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          mdr.dynamicrange
          from mediadynamicrange mdr
          where
          mdr.dynamicrange = dynamicrangestring
          group by mdr.dynamicrange
        ) then
          -- Begin begin/except
          begin
            -- Insert record
            insert into mediadynamicrange
            (
              dynamicrange,
              movieInclude,
              tvInclude,
              created_date,
              modified_date
            )
            values
            (
              cast(dynamicrangestring as citext),
              cast(movieincludestring as smallint),
              cast(tvincludestring as smallint),
              cast(current_timestamp as timestamp),
              cast(current_timestamp as timestamp)
            );

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
            -- Record already exist
            -- Set message
            result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, dynamic range, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert media resolution
    elseif optionMode = 'insertMediaResolution' then
      -- Check if parameters are null
      if resolutionstring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          mr.resolution
          from mediaresolution mr
          where
          mr.resolution = resolutionstring
          group by mr.resolution
        ) then
          -- Begin begin/except
          begin
            -- Insert record
            insert into mediaresolution
            (
              resolution,
              movieInclude,
              tvInclude,
              created_date,
              modified_date
            )
            values
            (
              cast(resolutionstring as citext),
              cast(movieincludestring as smallint),
              cast(tvincludestring as smallint),
              cast(current_timestamp as timestamp),
              cast(current_timestamp as timestamp)
            );

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, resolution, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert media stream source
    elseif optionMode = 'insertMediaStreamSource' then
      -- Check if parameters are null
      if streamsourcestring is not null and streamdescriptionstring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          mss.streamsource
          from mediastreamsource mss
          where
          mss.streamsource = streamsourcestring
          group by mss.streamsource
        ) then
          -- Begin begin/except
          begin
            -- Insert record
            insert into mediastreamsource
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
              cast(streamsourcestring as citext),
              cast(streamdescriptionstring as citext),
              cast(movieincludestring as smallint),
              cast(tvincludestring as smallint),
              cast(current_timestamp as timestamp),
              cast(current_timestamp as timestamp)
            );

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, stream source, stream description, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert media video encode
    elseif optionMode = 'insertMediaVideoEncode' then
      -- Check if parameters are null
      if videoencodestring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          mve.videoencode
          from mediavideoencode mve
          where
          mve.videoencode = videoencodestring
          group by mve.videoencode
        ) then
          -- Begin begin/except
          begin
            -- Insert record
            insert into mediavideoencode
            (
              videoencode,
              movieInclude,
              tvInclude,
              created_date,
              modified_date
            )
            values
            (
              cast(videoencodestring as citext),
              cast(movieincludestring as smallint),
              cast(tvincludestring as smallint),
              cast(current_timestamp as timestamp),
              cast(current_timestamp as timestamp)
            );

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, video encode, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update action status
    elseif optionMode = 'updateActionStatus' then
      -- Check if parameters are null
      if actionnumberstring is not null and actiondescriptionstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          ast.actionnumber
          from actionstatus ast
          where
          ast.actionnumber = cast(actionnumberstring as int)
          group by ast.actionnumber
        ) then
          -- Check if record does not exists
          if not exists
          (
            -- Select records
            select
            ast.actionnumber
            from actionstatus ast
            where
            ast.actionnumber = cast(actionnumberstring as int) and
            ast.actiondescription = actiondescriptionstring
            group by ast.actionnumber
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update actionstatus
              set
              actiondescription = cast(actiondescriptionstring as text),
              modified_date = cast(current_timestamp as timestamp)
              where
              actionstatus.actionnumber = cast(actionnumberstring as int);

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Success", "Message": "Record already exists"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, action number and action description were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update media audio encode
    elseif optionMode = 'updateMediaAudioEncode' then
      -- Check if parameters are null
      if audioencodestring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mae.audioencode
          from mediaaudioencode mae
          where
          mae.audioencode = audioencodestring
          group by mae.audioencode
        ) then
          -- Check if record does not exists
          if not exists
          (
            -- Select records
            select
            mae.audioencode
            from mediaaudioencode mae
            where
            mae.audioencode = audioencodestring and
            mae.movieinclude = cast(movieincludestring as smallint) and
            mae.tvinclude = cast(tvincludestring as smallint)
            group by mae.audioencode
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update mediaaudioencode
              set
              movieInclude = cast(movieincludestring as smallint),
              tvInclude = cast(tvincludestring as smallint),
              modified_date = cast(current_timestamp as timestamp)
              where
              mediaaudioencode.audioencode = audioencodestring;

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Success", "Message": "Record already exists"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, audio encode, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update media dynamic range
    elseif optionMode = 'updateMediaDynamicRange' then
      -- Check if parameters are null
      if dynamicrangestring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mdr.dynamicrange
          from mediadynamicrange mdr
          where
          mdr.dynamicrange = dynamicrangestring
          group by mdr.dynamicrange
        ) then
          -- Check if record does not exists
          if not exists
          (
            -- Select records
            select
            mdr.dynamicrange
            from mediadynamicrange mdr
            where
            mdr.dynamicrange = dynamicrangestring and
            mdr.movieinclude = cast(movieincludestring as smallint) and
            mdr.tvinclude = cast(tvincludestring as smallint)
            group by mdr.dynamicrange
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update mediadynamicrange
              set
              movieInclude = cast(movieincludestring as smallint),
              tvInclude = cast(tvincludestring as smallint),
              modified_date = cast(current_timestamp as timestamp)
              where
              mediadynamicrange.dynamicrange = dynamicrangestring;

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Success", "Message": "Record already exists"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, dynamic range, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update media resolution
    elseif optionMode = 'updateMediaResolution' then
      -- Check if parameters are null
      if resolutionstring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mr.resolution
          from mediaresolution mr
          where
          mr.resolution = resolutionstring
          group by mr.resolution
        ) then
          -- Check if record does not exists
          if not exists
          (
            -- Select records
            select
            mr.resolution
            from mediaresolution mr
            where
            mr.resolution = resolutionstring and
            mr.movieinclude = cast(movieincludestring as smallint) and
            mr.tvinclude = cast(tvincludestring as smallint)
            group by mr.resolution
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update mediaresolution
              set
              movieInclude = cast(movieincludestring as smallint),
              tvInclude = cast(tvincludestring as smallint),
              modified_date = cast(current_timestamp as timestamp)
              where
              mediaresolution.resolution = resolutionstring;

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Success", "Message": "Record already exists"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, resolution, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update media stream source
    elseif optionMode = 'updateMediaStreamSource' then
      -- Check if parameters are null
      if streamsourcestring is not null and streamdescriptionstring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mss.streamsource
          from mediastreamsource mss
          where
          mss.streamsource = streamsourcestring
          group by mss.streamsource
        ) then
          -- Check if record does not exists
          if not exists
          (
            -- Select records
            select
            mss.streamsource
            from mediastreamsource mss
            where
            mss.streamsource = streamsourcestring and
            mss.streamdescription = streamdescriptionstring and
            mss.movieinclude = cast(movieincludestring as smallint) and
            mss.tvinclude = cast(tvincludestring as smallint)
            group by mss.streamsource
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update mediastreamsource
              set
              streamdescription = cast(streamdescriptionstring as citext),
              movieInclude = cast(movieincludestring as smallint),
              tvInclude = cast(tvincludestring as smallint),
              modified_date = cast(current_timestamp as timestamp)
              where
              mediastreamsource.streamsource = cast(streamsourcestring as citext);

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Success", "Message": "Record already exists"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, stream source, stream description, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update media video encode
    elseif optionMode = 'updateMediaVideoEncode' then
      -- Check if parameters are null
      if videoencodestring is not null and movieincludestring is not null and tvincludestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mve.videoencode
          from mediavideoencode mve
          where
          mve.videoencode = videoencodestring
          group by mve.videoencode
        ) then
          -- Check if record does not exists
          if not exists
          (
            -- Select records
            select
            mve.videoencode
            from mediavideoencode mve
            where
            mve.videoencode = videoencodestring and
            mve.movieInclude = cast(movieincludestring as smallint) and
            mve.tvInclude = cast(tvincludestring as smallint)
            group by mve.videoencode
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update mediavideoencode
              set
              movieInclude = cast(movieincludestring as smallint),
              tvInclude = cast(tvincludestring as smallint),
              modified_date = cast(current_timestamp as timestamp)
              where
              mediavideoencode.videoencode = cast(videoencodestring as citext);

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Success", "Message": "Record already exists"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, video encode, movie include, and tv include were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is delete action status
    elseif optionMode = 'deleteActionStatus' then
      -- Check if parameters are not null
      if actionnumberstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          ast.actionnumber
          from actionstatus ast
          where
          ast.actionnumber = cast(actionnumberstring as int)
          group by ast.actionnumber
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from actionstatus ast
            where
            ast.actionnumber = cast(actionnumberstring as int);

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, action number was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete media audio encode
    elseif optionMode = 'deleteMediaAudioEncode' then
      -- Check if parameters are not null
      if audioencodestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mae.audioencode
          from mediaaudioencode mae
          where
          mae.audioencode = audioencodestring
          group by mae.audioencode
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from mediaaudioencode mae
            where
            mae.audioencode = cast(audioencodestring as citext);

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, audio encode was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete media dynamic range
    elseif optionMode = 'deleteMediaDynamicRange' then
      -- Check if parameters are not null
      if dynamicrangestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mdr.dynamicrange
          from mediadynamicrange mdr
          where
          mdr.dynamicrange = dynamicrangestring
          group by mdr.dynamicrange
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from mediadynamicrange mdr
            where
            mdr.dynamicrange = cast(dynamicrangestring as citext);

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, dynamic range was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete media resolution
    elseif optionMode = 'deleteMediaResolution' then
      -- Check if parameters are not null
      if resolutionstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mr.resolution
          from mediaresolution mr
          where
          mr.resolution = resolutionstring
          group by mr.resolution
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from mediaresolution mr
            where
            mr.resolution = cast(resolutionstring as citext);

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, resolution was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete media stream source
    elseif optionMode = 'deleteMediaStreamSource' then
      -- Check if parameters are not null
      if streamsourcestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mss.streamsource
          from mediastreamsource mss
          where
          mss.streamsource = streamsourcestring
          group by mss.streamsource
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from mediastreamsource mss
            where
            mss.streamsource = cast(streamsourcestring as citext);

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, stream source was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete media video encode
    elseif optionMode = 'deleteMediaVideoEncode' then
      -- Check if parameters are not null
      if videoencodestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mve.videoencode
          from mediavideoencode mve
          where
          mve.videoencode = videoencodestring
          group by mve.videoencode
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from mediavideoencode mve
            where
            mve.videoencode = cast(videoencodestring as citext);

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, video encode was not provided"}';
      end if;

      -- Select message
      select
      result into "status";
    end if;
  end; $$;


--
-- Name: insertupdatedeletemediafeed(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.insertupdatedeletemediafeed(IN optionmode text DEFAULT NULL::text, IN titlelong text DEFAULT NULL::text, IN titleshort text DEFAULT NULL::text, IN titleshortold text DEFAULT NULL::text, IN publishdate text DEFAULT NULL::text, IN actionstatus text DEFAULT NULL::text, INOUT status text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitleLong text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitTitleShort text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitPublishDate text := '[^0-9\-/:. ]';
  declare omitActionStatus text := '[^0-9]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthTitleLong int := 255;
  declare maxLengthTitleShort int := 255;
  declare maxLengthPublishDate int := 255;
  declare maxLengthActionStatus int := 255;
  declare titlelongstring text := titlelong;
  declare titleshortstring text := titleshort;
  declare titleshortoldstring text := titleshortold;
  declare publishdatestring text := publishdate;
  declare actionstatusstring text := actionstatus;
  declare code text := '00000';
  declare msg text := '';
  declare result text := '';

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titlelongstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titlelongstring := regexp_replace(regexp_replace(titlelongstring, omitTitleLong, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titlelongstring := trim(substring(titlelongstring, 1, maxLengthTitleLong));

      -- Check if empty string
      if titlelongstring = '' then
        -- Set parameter to null if empty string
        titlelongstring := nullif(titlelongstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titleshortstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titleshortstring := regexp_replace(regexp_replace(titleshortstring, omitTitleShort, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titleshortstring := trim(substring(titleshortstring, 1, maxLengthTitleShort));

      -- Check if empty string
      if titleshortstring = '' then
        -- Set parameter to null if empty string
        titleshortstring := nullif(titleshortstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titleshortoldstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titleshortoldstring := regexp_replace(regexp_replace(titleshortoldstring, omitTitleShort, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titleshortoldstring := trim(substring(titleshortoldstring, 1, maxLengthTitleShort));

      -- Check if empty string
      if titleshortoldstring = '' then
        -- Set parameter to null if empty string
        titleshortoldstring := nullif(titleshortoldstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if publishdatestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      publishdatestring := regexp_replace(regexp_replace(publishdatestring, omitPublishDate, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      publishdatestring := trim(substring(publishdatestring, 1, maxLengthPublishDate));

      -- Check if the parameter cannot be casted into a date time
      if to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS') is null then
        -- Set the string as empty to be nulled below
        publishdatestring := '';
      end if;

      -- Check if empty string
      if publishdatestring = '' then
        -- Set parameter to null if empty string
        publishdatestring := nullif(publishdatestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actionstatusstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actionstatusstring := regexp_replace(regexp_replace(actionstatusstring, omitActionStatus, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actionstatusstring := trim(substring(actionstatusstring, 1, maxLengthActionStatus));

      -- Check if empty string
      if actionstatusstring = '' then
        -- Set parameter to null if empty string
        actionstatusstring := nullif(actionstatusstring, '');
      end if;
    end if;

    -- Else check if option mode is insert movie feed
    if optionMode = 'insertMovieFeed' then
      -- Check if parameters are null
      if titlelongstring is not null and titleshortstring is not null and publishdatestring is not null and actionstatusstring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          mf.titlelong
          from moviefeed mf
          where
          mf.titlelong = titlelongstring
          group by mf.titlelong
        ) then
          -- Check if year string is greater than 5 and string is a valid year
          if length(titleshortstring) > 5 and to_timestamp(substring(titleshortstring, length(titleshortstring) - 3, length(titleshortstring)), 'YYYY') is not null then
            -- Check if record exists
            if exists
            (
              -- Select record
              select
              titlelongstring as titlelong
              from actionstatus ast
              join mediaaudioencode mae on mae.movieInclude in ('1') and titlelongstring ilike concat('%', mae.audioencode, '%')
              left join mediadynamicrange mdr on mdr.movieInclude in ('1') and titlelongstring ilike concat('%', mdr.dynamicrange, '%')
              join mediaresolution mr on mr.movieInclude in ('1') and titlelongstring ilike concat('%', mr.resolution, '%')
              left join mediastreamsource mss on mss.movieInclude in ('1') and titlelongstring ilike concat('%', mss.streamsource, '%')
              join mediavideoencode mve on mve.movieInclude in ('1') and titlelongstring ilike concat('%', mve.videoencode, '%')
              where
              ast.actionnumber = cast(actionstatusstring as int)
            ) then
              -- Begin begin/except
              begin
                -- Insert record
                insert into moviefeed
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
                  lower(titlelongstring),
                  titleshortstring,
                  to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US'),
                  cast(actionstatusstring as int),
                  cast(current_timestamp as timestamp),
                  cast(current_timestamp as timestamp)
                );

                -- Set message
                result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
              exception when others then
                -- Caught exception error
                -- Get diagnostics information
                get stacked diagnostics code = returned_sqlstate, msg = message_text;

                -- Set message
                result := concat('{"Status": "Error", "Message": "', msg, '"}');
              -- End begin/except
              end;
            else
                -- Set message
                result := concat('{"Status": "Error", "Message": "Title long and action status does not follow the allowed values"}');
              end if;
          else
            -- Set message
            result := concat('{"Status": "Error", "Message": "Title short does not follow the allowed value"}');
          end if;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is insert tv feed
    elseif optionMode = 'insertTVFeed' then
      -- Check if parameters are null
      if titlelongstring is not null and titleshortstring is not null and publishdatestring is not null and actionstatusstring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          tf.titlelong
          from tvfeed tf
          where
          tf.titlelong = titlelongstring
          group by tf.titlelong
        ) then
          -- Check if record exists
          if exists
          (
            -- Select record
            select
            titlelongstring as titlelong
            from actionstatus ast
            join mediaaudioencode mae on mae.tvInclude in ('1') and titlelongstring ilike concat('%', mae.audioencode, '%')
            left join mediadynamicrange mdr on mdr.tvInclude in ('1') and titlelongstring ilike concat('%', mdr.dynamicrange, '%')
            join mediaresolution mr on mr.tvInclude in ('1') and titlelongstring ilike concat('%', mr.resolution, '%')
            left join mediastreamsource mss on mss.tvInclude in ('1') and titlelongstring ilike concat('%', mss.streamsource, '%')
            join mediavideoencode mve on mve.tvInclude in ('1') and titlelongstring ilike concat('%', mve.videoencode, '%')
            where
            ast.actionnumber = cast(actionstatusstring as int)
          ) then
            -- Begin begin/except
            begin
              -- Insert record
              insert into tvfeed
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
                lower(titlelongstring),
                titleshortstring,
                to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US'),
                cast(actionstatusstring as int),
                cast(current_timestamp as timestamp),
                cast(current_timestamp as timestamp)
              );

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Error", "Message": "Title long and or action status does not follow the allowed values"}');
          end if;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update movie feed
    elseif optionMode = 'updateMovieFeed' then
      -- Check if parameters are null
      if titlelongstring is not null and titleshortstring is not null and publishdatestring is not null and actionstatusstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mf.titlelong
          from moviefeed mf
          where
          mf.titlelong = titlelongstring
          group by mf.titlelong
        ) then
          -- Check if year string is greater than 5 and string is a valid year
          if length(titleshortstring) > 5 and to_date(substring(titleshortstring, length(titleshortstring) - 3, length(titleshortstring)), 'YYYY') is not null then
            -- Check if record exists
            if exists
            (
              -- Select record
              select
              titlelongstring as titlelong
              from actionstatus ast
              join mediaaudioencode mae on mae.movieInclude in ('1') and titlelongstring ilike concat('%', mae.audioencode, '%')
              left join mediadynamicrange mdr on mdr.movieInclude in ('1') and titlelongstring ilike concat('%', mdr.dynamicrange, '%')
              join mediaresolution mr on mr.movieInclude in ('1') and titlelongstring ilike concat('%', mr.resolution, '%')
              left join mediastreamsource mss on mss.movieInclude in ('1') and titlelongstring ilike concat('%', mss.streamsource, '%')
              join mediavideoencode mve on mve.movieInclude in ('1') and titlelongstring ilike concat('%', mve.videoencode, '%')
              where
              ast.actionnumber = cast(actionstatusstring as int)
            ) then
              -- Check if record does not exists
              if not exists
              (
                -- Select records
                select
                mf.titlelong
                from moviefeed mf
                where
                mf.titlelong = titlelongstring and
                mf.titleshort = titleshortstring and
                mf.publish_date = to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US') and
                mf.actionstatus = cast(actionstatusstring as int)
                group by mf.titlelong
              ) then
                -- Begin begin/except
                begin
                  -- Update record
                  update moviefeed
                  set
                  titleshort = lower(titleshortstring),
                  publish_date = to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US'),
                  actionstatus = cast(actionstatusstring as int),
                  modified_date = cast(current_timestamp as timestamp)
                  where
                  moviefeed.titlelong = titlelongstring;

                  -- Set message
                  result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
                exception when others then
                  -- Caught exception error
                  -- Get diagnostics information
                  get stacked diagnostics code = returned_sqlstate, msg = message_text;

                  -- Set message
                  result := concat('{"Status": "Error", "Message": "', msg, '"}');
                -- End begin/except
                end;
              else
                -- Set message
                result := concat('{"Status": "Success", "Message": "Record already exists"}');
              end if;
            else
              -- Set message
              result := concat('{"Status": "Error", "Message": "Title long and or action status does not follow the allowed values"}');
            end if;
          else
            -- Set message
            result := concat('{"Status": "Error", "Message": "Title short does not follow the allowed value"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update movie title short
    elseif optionMode = 'updateMovieFeedTitleShort' then
      -- Check if parameters are null
      if titleshortstring is not null and titleshortoldstring is not null then
        -- Check if record does not exist
        if not exists
        (
          -- Select record in question
          select
          mf.titleshort
          from moviefeed mf
          where
          mf.titleshort = titleshortstring
          group by mf.titleshort
        ) then
          -- Check if year string is greater than 5 and string is a valid year
          if length(titleshortstring) > 5 and to_date(substring(titleshortstring, length(titleshortstring) - 3, length(titleshortstring)), 'YYYY') is not null then
            -- Check if record exist
            if exists
            (
              -- Select record in question
              select
              mf.titleshort
              from moviefeed mf
              where
              mf.titleshort = titleshortoldstring
              group by mf.titleshort
            ) then
              -- Begin begin/except
              begin
                -- Update record
                update moviefeed
                set
                titleshort = lower(titleshortstring),
                modified_date = cast(current_timestamp as timestamp)
                where
                moviefeed.titleshort = titleshortoldstring;

                -- Set message
                result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
              exception when others then
                -- Caught exception error
                -- Get diagnostics information
                get stacked diagnostics code = returned_sqlstate, msg = message_text;

                -- Set message
                result := concat('{"Status": "Error", "Message": "', msg, '"}');
              -- End begin/except
              end;
            else
              -- Record does not exist
              -- Set message
              result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
            end if;
          else
            -- Set message
            result := concat('{"Status": "Error", "Message": "Title short does not follow the allowed value"}');
          end if;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title short and title short old were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update movie feed title short action status
    elseif optionMode = 'updateMovieFeedTitleShortActionStatus' then
      -- Check if parameters are null
      if titleshortstring is not null and actionstatusstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mf.titleshort
          from moviefeed mf
          where
          mf.titleshort = titleshortstring
          group by mf.titleshort
        ) then
          -- Check if year string is greater than 5 and string is a valid year
          if length(titleshortstring) > 5 and to_date(substring(titleshortstring, length(titleshortstring) - 3, length(titleshortstring)), 'YYYY') is not null then
            -- Check if record exist
            if exists
            (
              -- Select record
              select
              ast.actionnumber as actionnumber
              from actionstatus ast
              where
              ast.actionnumber = cast(actionstatusstring as int)
              group by ast.actionnumber
            ) then
              -- Check if record does not exists
              if not exists
              (
                -- Select records
                select
                mf.titleshort
                from moviefeed mf
                where
                mf.titleshort = titleshortstring and
                mf.actionstatus = cast(actionstatusstring as int)
                group by mf.titleshort
              ) then
                -- Begin begin/except
                begin
                  -- Update record
                  update moviefeed
                  set
                  actionstatus = cast(actionstatusstring as int),
                  modified_date = cast(current_timestamp as timestamp)
                  where
                  moviefeed.titleshort = titleshortstring;

                  -- Set message
                  result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
                exception when others then
                  -- Caught exception error
                  -- Get diagnostics information
                  get stacked diagnostics code = returned_sqlstate, msg = message_text;

                  -- Set message
                  result := concat('{"Status": "Error", "Message": "', msg, '"}');
                -- End begin/except
                end;
              else
                -- Set message
                result := concat('{"Status": "Success", "Message": "Record already exists"}');
              end if;
            else
              -- Set message
              result := concat('{"Status": "Error", "Message": "Action status value is invalid"}');
            end if;
          else
            -- Set message
            result := concat('{"Status": "Error", "Message": "Title short does not follow the allowed value"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title short and action status were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update tv feed
    elseif optionMode = 'updateTVFeed' then
      -- Check if parameters are null
      if titlelongstring is not null and titleshortstring is not null and publishdatestring is not null and actionstatusstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          tf.titlelong
          from tvfeed tf
          where
          tf.titlelong = titlelongstring
          group by tf.titlelong
        ) then
          -- Check if record exists
          if exists
          (
            -- Select record
            select
            titlelongstring as titlelong
            from actionstatus ast
            join mediaaudioencode mae on mae.tvInclude in ('1') and titlelongstring ilike concat('%', mae.audioencode, '%')
            left join mediadynamicrange mdr on mdr.tvInclude in ('1') and titlelongstring ilike concat('%', mdr.dynamicrange, '%')
            join mediaresolution mr on mr.tvInclude in ('1') and titlelongstring ilike concat('%', mr.resolution, '%')
            left join mediastreamsource mss on mss.tvInclude in ('1') and titlelongstring ilike concat('%', mss.streamsource, '%')
            join mediavideoencode mve on mve.tvInclude in ('1') and titlelongstring ilike concat('%', mve.videoencode, '%')
            where
            ast.actionnumber = cast(actionstatusstring as int)
          ) then
            -- Check if record does not exists
            if not exists
            (
              -- Select records
              select
              tf.titlelong
              from tvfeed tf
              where
              tf.titlelong = titlelongstring and
              tf.titleshort = titleshortstring and
              tf.publish_date = to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US') and
              tf.actionstatus = cast(actionstatusstring as int)
              group by tf.titlelong
            ) then
              -- Begin begin/except
              begin
                -- Update record
                update tvfeed
                set
                titleshort = lower(titleshortstring),
                publish_date = to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US'),
                actionstatus = cast(actionstatusstring as int),
                modified_date = cast(current_timestamp as timestamp)
                where
                tvfeed.titlelong = titlelongstring;

                -- Set message
                result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
              exception when others then
                -- Caught exception error
                -- Get diagnostics information
                get stacked diagnostics code = returned_sqlstate, msg = message_text;

                -- Set message
                result := concat('{"Status": "Error", "Message": "', msg, '"}');
              -- End begin/except
              end;
            else
              -- Set message
              result := concat('{"Status": "Success", "Message": "Record already exists"}');
            end if;
          else
            -- Set message
            result := concat('{"Status": "Error", "Message": "Title long and or action status does not follow the allowed values"}');
          end if;
        else
            -- Record does not exist
            -- Set message
            result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title long, title short, publish date, and action status were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update tv feed title short
    elseif optionMode = 'updateTVFeedTitleShort' then
      -- Check if parameters are null
      if titleshortstring is not null and titleshortoldstring is not null then
        -- Check if record exist
        if not exists
        (
          -- Select record in question
          select
          tf.titleshort
          from tvfeed tf
          where
          tf.titleshort = titleshortstring
          group by tf.titleshort
        ) then
          -- Check if record exist
          if exists
          (
            -- Select record in question
            select
            tf.titleshort
            from tvfeed tf
            where
            tf.titleshort = titleshortoldstring
            group by tf.titleshort
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update tvfeed
              set
              titleshort = lower(titleshortstring),
              modified_date = cast(current_timestamp as timestamp)
              where
              tvfeed.titleshort = titleshortoldstring;

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Record does not exist
            -- Set message
            result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
          end if;
        else
          -- Record already exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) already exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title short and title short old were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Else check if option mode is update tv feed title short action status
    elseif optionMode = 'updateTVFeedTitleShortActionStatus' then
      -- Check if parameters are null
      if titleshortstring is not null and actionstatusstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          tf.titleshort
          from tvfeed tf
          where
          tf.titleshort = titleshortstring
          group by tf.titleshort
        ) then
          -- Check if record exist
          if exists
          (
            -- Select record
            select
            ast.actionnumber as actionnumber
            from actionstatus ast
            where
            ast.actionnumber = cast(actionstatusstring as int)
            group by ast.actionnumber
          ) then
            -- Check if record does not exists
            if not exists
            (
              -- Select records
              select
              tf.titleshort
              from tvfeed tf
              where
              tf.titleshort = titleshortstring and
              tf.actionstatus = cast(actionstatusstring as int)
              group by tf.titleshort
            ) then
              -- Begin begin/except
              begin
                -- Update record
                update tvfeed
                set
                actionstatus = cast(actionstatusstring as int),
                modified_date = cast(current_timestamp as timestamp)
                where
                tvfeed.titleshort = titleshortstring;

                -- Set message
                result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
              exception when others then
                -- Caught exception error
                -- Get diagnostics information
                get stacked diagnostics code = returned_sqlstate, msg = message_text;

                -- Set message
                result := concat('{"Status": "Error", "Message": "', msg, '"}');
              -- End begin/except
              end;
            else
              -- Set message
              result := concat('{"Status": "Success", "Message": "Record already exists"}');
            end if;
          else
            -- Set message
            result := concat('{"Status": "Error", "Message": "Action status value is invalid"}');
          end if;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title short and action status were not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete  movie feed title long
    elseif optionMode = 'deleteMovieFeed' then
      -- Check if parameters are not null
      if titlelongstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mf.titlelong
          from moviefeed mf
          where
          mf.titlelong = titlelongstring
          group by mf.titlelong
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from moviefeed mf
            where
            mf.titlelong = titlelongstring;

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title long was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete movie feed title short
    elseif optionMode = 'deleteMovieFeedTitleShort' then
      -- Check if parameters are not null
      if titleshortstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          mf.titleshort
          from moviefeed mf
          where
          mf.titleshort = titleshortstring
          group by mf.titleshort
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from moviefeed mf
            where
            mf.titleshort = titleshortstring;

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title short was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete tv feed title long
    elseif optionMode = 'deleteTVFeed' then
      -- Check if parameters are not null
      if titlelongstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          tf.titlelong
          from tvfeed tf
          where
          tf.titlelong = titlelongstring
          group by tf.titlelong
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from tvfeed tf
            where
            tf.titlelong = titlelongstring;

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title long was not provided"}';
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete tv feed title short
    elseif optionMode = 'deleteTVFeedTitleShort' then
      -- Check if parameters are not null
      if titleshortstring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          tf.titleshort
          from tvfeed tf
          where
          tf.titleshort = titleshortstring
          group by tf.titleshort
        ) then
          -- Begin begin/except
          begin
            -- Delete record
            delete
            from tvfeed tf
            where
            tf.titleshort = titleshortstring;

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Record does not exist
          -- Set message
          result := '{"Status": "Success", "Message": "Record(s) does not exist"}';
        end if;
      else
        -- Set message
        result := '{"Status": "Error", "Message": "Process halted, title short was not provided"}';
      end if;

      -- Select message
      select
      result into "status";
    end if;
  end; $_$;


--
-- Name: insertupdatedeletenewsfeed(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.insertupdatedeletenewsfeed(IN optionmode text DEFAULT NULL::text, IN title text DEFAULT NULL::text, IN imageurl text DEFAULT NULL::text, IN feedurl text DEFAULT NULL::text, IN actualurl text DEFAULT NULL::text, IN publishdate text DEFAULT NULL::text, INOUT status text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare variable
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitle text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitImageURL text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitFeedURL text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitActualURL text := '[^a-zA-Z0-9 !"\#$%&''()*+,\-./:;<=>?@\[\\\]^_ΓÇÿ{|}~┬í┬ó┬ú┬Ñ┬ª┬º┬¿┬⌐┬«┬»┬░┬▒┬┤┬╡┬┐├Ç├ü├é├â├ä├à├å├ç├ê├ë├è├ï├î├ì├Ä├Å├É├æ├Æ├ô├ö├ò├û├ù├ÿ├Ö├Ü├¢├£├¥├₧├ƒ├á├í├ó├ú├ñ├Ñ├ª├º├¿├⌐├¬├½├¼├¡├«├»├░├▒├▓├│├┤├╡├╢├╖├╕├╣├║├╗├╝├╜├╛├┐─▒┼Æ┼ô┼á┼í┼╕┼╜┼╛╞Æ╦å╦ç╦ÿ╦Ö╦Ü╦¢╬ô╬ÿ╬ú╬ª╬⌐╬▒╬┤╬╡╧Ç╧â╧ä╧åΓÇôΓÇöΓÇÿΓÇÖΓÇ£ΓÇ¥ΓÇóΓÇªΓé¼ΓäóΓêéΓêåΓêÅΓêæΓêÖΓêÜΓê₧Γê⌐Γê½ΓëêΓëáΓëíΓëñΓëÑ]';
  declare omitPublishDate text := '[^0-9\-:./ ]';
  declare maxLengthOptionMode int := 255;
  declare maxLengthTitle int := 255;
  declare maxLengthImageURL int := 255;
  declare maxLengthFeedURL int := 768;
  declare maxLengthActualURL int := 255;
  declare maxLengthPublishDate int := 255;
  declare titlestring text := title;
  declare imageurlstring text := imageurl;
  declare feedurlstring text := feedurl;
  declare actualurlstring text := actualurl;
  declare publishdatestring text := publishdate;
  declare code text := '00000';
  declare msg text := '';
  declare result text := '';

  begin
    -- Check if parameter is not null
    if optionMode is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      optionMode := regexp_replace(regexp_replace(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      optionMode := trim(substring(optionMode, 1, maxLengthOptionMode));

      -- Check if empty string
      if optionMode = '' then
        -- Set parameter to null if empty string
        optionMode := nullif(optionMode, '');
      end if;
    end if;

    -- Check if parameter is not null
    if titlestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      titlestring := regexp_replace(regexp_replace(titlestring, omitTitle, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      titlestring := trim(substring(titlestring, 1, maxLengthTitle));

      -- Check if empty string
      if titlestring = '' then
        -- Set parameter to null if empty string
        titlestring := nullif(titlestring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if imageurlstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      imageurlstring := regexp_replace(regexp_replace(imageurlstring, omitImageURL, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      imageurlstring := trim(substring(imageurlstring, 1, maxLengthImageURL));

      -- Check if empty string
      if imageurlstring = '' then
        -- Set parameter to null if empty string
        imageurlstring := nullif(imageurlstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if feedurlstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      feedurlstring := regexp_replace(regexp_replace(feedurlstring, omitFeedURL, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      feedurlstring := trim(substring(feedurlstring, 1, maxLengthFeedURL));

      -- Check if empty string
      if feedurlstring = '' then
        -- Set parameter to null if empty string
        feedurlstring := nullif(feedurlstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if actualurlstring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      actualurlstring := regexp_replace(regexp_replace(actualurlstring, omitActualURL, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      actualurlstring := trim(substring(actualurlstring, 1, maxLengthActualURL));

      -- Check if empty string
      if actualurlstring = '' then
        -- Set parameter to null if empty string
        actualurlstring := nullif(actualurlstring, '');
      end if;
    end if;

    -- Check if parameter is not null
    if publishdatestring is not null then
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      publishdatestring := regexp_replace(regexp_replace(publishdatestring, omitPublishDate, ' '), '[ ]{2,}', ' ');

      -- Set character limit
      publishdatestring := trim(substring(publishdatestring, 1, maxLengthPublishDate));

      -- Check if the parameter cannot be casted into a date time
      if to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS') is null then
        -- Set the string as empty to be nulled below
        publishdatestring := '';
      end if;

      -- Check if empty string
      if publishdatestring = '' then
        -- Set parameter to null if empty string
        publishdatestring := nullif(publishdatestring, '');
      end if;
    end if;

    -- Check if option mode is insert news feed
    if optionMode = 'insertNewsFeed' then
      -- Check if parameters are not null
      if titlestring is not null and feedurlstring is not null and publishdatestring is not null then
        -- Check if record does not exist
        if not exists
        (
          -- Select record in question
          select
          nf.title
          from newsfeed nf
          where
          nf.title = titlestring
          group by nf.title
        ) then
          -- Begin begin/except
          begin
            -- Insert record
            insert into newsfeed
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
              titlestring,
              case
                when trim(imageurlstring) = ''
                  then
                    null
                else
                  imageurlstring
              end,
              feedurlstring,
              case
                when trim(actualurlstring) = ''
                  then
                    null
                else
                  actualurlstring
              end,
              to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US'),
              cast(current_timestamp as timestamp),
              cast(current_timestamp as timestamp)
            );

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) inserted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Else a record exist
          -- Set message
          result := concat('{"Status": "Success", "Message": "Record exist"}');
        end if;
      else
        -- Else a parameter was not given
        -- Set message
        result := concat('{"Status": "Error", "Message": "Process halted, title, feed url, and or publish date were not provided"}');
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is update news feed
    elseif optionMode = 'updateNewsFeed' then
      -- Check if parameters are not null
      if titlestring is not null and feedurlstring is not null and publishdatestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          nf.title
          from newsfeed nf
          where
          nf.title = titlestring
          group by nf.title
        ) then
          -- Check if record does not exists
          if not exists
          (
            -- Select records
            select
            nf.title
            from newsfeed nf
            where
            nf.title = titlestring and
            (
              nf.imageurl = imageurlstring or
              (
                nf.imageurl is null and
                imageurlstring is null
              )
            ) and
            nf.feedurl = feedurlstring and
            (
              nf.actualurl = actualurlstring or
              (
                nf.actualurl is null and
                actualurlstring is null
              )
            ) and
            nf.publish_date = to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US')
            group by nf.title
          ) then
            -- Begin begin/except
            begin
              -- Update record
              update newsfeed
              set
              imageurl = (case
                  when trim(imageurlstring) = ''
                    then
                      null
                  else
                    imageurlstring
                end
              ),
              feedurl = feedurlstring,
              actualurl = (case
                  when trim(actualurlstring) = ''
                    then
                      null
                  else
                    actualurlstring
                end
              ),
              publish_date = to_timestamp(publishdatestring, 'YYYY-MM-DD HH24:MI:SS.US'),
              modified_date = cast(current_timestamp as timestamp)
              where
              newsfeed.title = titlestring;

              -- Set message
              result := concat('{"Status": "Success", "Message": "Record(s) updated"}');
            exception when others then
              -- Caught exception error
              -- Get diagnostics information
              get stacked diagnostics code = returned_sqlstate, msg = message_text;

              -- Set message
              result := concat('{"Status": "Error", "Message": "', msg, '"}');
            -- End begin/except
            end;
          else
            -- Set message
            result := concat('{"Status": "Success", "Message": "Record already exists"}');
          end if;
        else
          -- Else a record exist
          -- Set message
          result := concat('{"Status": "Error", "Message": "Record does not exist"}');
        end if;
      else
        -- Else a parameter was not given
        -- Set message
        result := concat('{"Status": "Error", "Message": "Process halted, title, feed url, and or publish date were not provided"}');
      end if;

      -- Select message
      select
      result into "status";

    -- Check if option mode is delete news feed
    elseif optionMode = 'deleteNewsFeed' then
      -- Check if parameters are not null
      if titlestring is not null then
        -- Check if record exist
        if exists
        (
          -- Select record in question
          select
          nf.title
          from newsfeed nf
          where
          nf.title = titlestring
          group by nf.title
        ) then
          -- Begin begin/except
          begin
            -- Delete records
            delete
            from newsfeed nf
            where
            nf.title = titlestring;

            -- Set message
            result := concat('{"Status": "Success", "Message": "Record(s) deleted"}');
          exception when others then
            -- Caught exception error
            -- Get diagnostics information
            get stacked diagnostics code = returned_sqlstate, msg = message_text;

            -- Set message
            result := concat('{"Status": "Error", "Message": "', msg, '"}');
          -- End begin/except
          end;
        else
          -- Else a record does not exist
          -- Set message
          result := concat('{"Status": "Success", "Message": "Record does not exist"}');
        end if;
      else
        -- Else a parameter was not given
        -- Set message
        result := concat('{"Status": "Error", "Message": "Process halted, title was not provided"}');
      end if;

      -- Select message
      select
      result into "status";
    end if;
  end; $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: actionstatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.actionstatus (
    asid bigint NOT NULL,
    actionnumber integer NOT NULL,
    actiondescription character varying(255) NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: actionstatus_asid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actionstatus_asid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actionstatus_asid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.actionstatus_asid_seq OWNED BY public.actionstatus.asid;


--
-- Name: mediaaudioencode; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mediaaudioencode (
    maeid bigint NOT NULL,
    audioencode public.citext NOT NULL,
    movieinclude smallint DEFAULT 0 NOT NULL,
    tvinclude smallint DEFAULT 0 NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mediaaudioencode_maeid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mediaaudioencode_maeid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mediaaudioencode_maeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mediaaudioencode_maeid_seq OWNED BY public.mediaaudioencode.maeid;


--
-- Name: mediadynamicrange; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mediadynamicrange (
    mdrid bigint NOT NULL,
    dynamicrange public.citext NOT NULL,
    movieinclude smallint DEFAULT 0 NOT NULL,
    tvinclude smallint DEFAULT 0 NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mediadynamicrange_mdrid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mediadynamicrange_mdrid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mediadynamicrange_mdrid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mediadynamicrange_mdrid_seq OWNED BY public.mediadynamicrange.mdrid;


--
-- Name: mediaresolution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mediaresolution (
    mrid bigint NOT NULL,
    resolution public.citext NOT NULL,
    movieinclude smallint DEFAULT 0 NOT NULL,
    tvinclude smallint DEFAULT 0 NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mediaresolution_mrid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mediaresolution_mrid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mediaresolution_mrid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mediaresolution_mrid_seq OWNED BY public.mediaresolution.mrid;


--
-- Name: mediastreamsource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mediastreamsource (
    mssid bigint NOT NULL,
    streamsource public.citext NOT NULL,
    streamdescription public.citext NOT NULL,
    movieinclude smallint DEFAULT 0 NOT NULL,
    tvinclude smallint DEFAULT 0 NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mediastreamsource_mssid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mediastreamsource_mssid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mediastreamsource_mssid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mediastreamsource_mssid_seq OWNED BY public.mediastreamsource.mssid;


--
-- Name: mediavideoencode; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mediavideoencode (
    mveid bigint NOT NULL,
    videoencode public.citext NOT NULL,
    movieinclude smallint DEFAULT 0 NOT NULL,
    tvinclude smallint DEFAULT 0 NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mediavideoencode_mveid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mediavideoencode_mveid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mediavideoencode_mveid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mediavideoencode_mveid_seq OWNED BY public.mediavideoencode.mveid;


--
-- Name: moviefeed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moviefeed (
    mfid bigint NOT NULL,
    titlelong public.citext NOT NULL,
    titleshort public.citext NOT NULL,
    publish_date timestamp without time zone NOT NULL,
    actionstatus integer NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    info_url public.citext
);


--
-- Name: moviefeed_mfid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.moviefeed_mfid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moviefeed_mfid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.moviefeed_mfid_seq OWNED BY public.moviefeed.mfid;


--
-- Name: moviefeedtemp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moviefeedtemp (
    titlelong public.citext,
    titleshort public.citext,
    publish_date character varying(255) DEFAULT NULL::character varying,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    info_url public.citext
);


--
-- Name: newsfeed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.newsfeed (
    nfid bigint NOT NULL,
    title public.citext NOT NULL,
    imageurl public.citext,
    feedurl public.citext NOT NULL,
    actualurl public.citext,
    publish_date timestamp without time zone NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: newsfeed_nfid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.newsfeed_nfid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: newsfeed_nfid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.newsfeed_nfid_seq OWNED BY public.newsfeed.nfid;


--
-- Name: newsfeedtemp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.newsfeedtemp (
    title public.citext,
    imageurl public.citext,
    feedurl public.citext,
    actualurl public.citext,
    publish_date text,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: tvfeed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tvfeed (
    tfid bigint NOT NULL,
    titlelong public.citext NOT NULL,
    titleshort public.citext NOT NULL,
    publish_date timestamp without time zone NOT NULL,
    actionstatus integer NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    info_url public.citext
);


--
-- Name: tvfeed_tfid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tvfeed_tfid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tvfeed_tfid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tvfeed_tfid_seq OWNED BY public.tvfeed.tfid;


--
-- Name: tvfeedtemp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tvfeedtemp (
    titlelong public.citext,
    titleshort public.citext,
    publish_date character varying(255) DEFAULT NULL::character varying,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    info_url public.citext
);


--
-- Name: actionstatus asid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actionstatus ALTER COLUMN asid SET DEFAULT nextval('public.actionstatus_asid_seq'::regclass);


--
-- Name: mediaaudioencode maeid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediaaudioencode ALTER COLUMN maeid SET DEFAULT nextval('public.mediaaudioencode_maeid_seq'::regclass);


--
-- Name: mediadynamicrange mdrid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediadynamicrange ALTER COLUMN mdrid SET DEFAULT nextval('public.mediadynamicrange_mdrid_seq'::regclass);


--
-- Name: mediaresolution mrid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediaresolution ALTER COLUMN mrid SET DEFAULT nextval('public.mediaresolution_mrid_seq'::regclass);


--
-- Name: mediastreamsource mssid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediastreamsource ALTER COLUMN mssid SET DEFAULT nextval('public.mediastreamsource_mssid_seq'::regclass);


--
-- Name: mediavideoencode mveid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediavideoencode ALTER COLUMN mveid SET DEFAULT nextval('public.mediavideoencode_mveid_seq'::regclass);


--
-- Name: moviefeed mfid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moviefeed ALTER COLUMN mfid SET DEFAULT nextval('public.moviefeed_mfid_seq'::regclass);


--
-- Name: newsfeed nfid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsfeed ALTER COLUMN nfid SET DEFAULT nextval('public.newsfeed_nfid_seq'::regclass);


--
-- Name: tvfeed tfid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tvfeed ALTER COLUMN tfid SET DEFAULT nextval('public.tvfeed_tfid_seq'::regclass);


--
-- Name: actionstatus pk_actionstatus_actionnumber; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actionstatus
    ADD CONSTRAINT pk_actionstatus_actionnumber PRIMARY KEY (actionnumber);


--
-- Name: mediaaudioencode pk_mediaaudioencode_audioencode; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediaaudioencode
    ADD CONSTRAINT pk_mediaaudioencode_audioencode PRIMARY KEY (audioencode);


--
-- Name: mediadynamicrange pk_mediadynamicrange_dynamicrange; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediadynamicrange
    ADD CONSTRAINT pk_mediadynamicrange_dynamicrange PRIMARY KEY (dynamicrange);


--
-- Name: mediaresolution pk_mediaresolution_resolution; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediaresolution
    ADD CONSTRAINT pk_mediaresolution_resolution PRIMARY KEY (resolution);


--
-- Name: mediastreamsource pk_mediastreamsource_streamsource; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediastreamsource
    ADD CONSTRAINT pk_mediastreamsource_streamsource PRIMARY KEY (streamsource);


--
-- Name: mediavideoencode pk_mediavideoencode_videoencode; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediavideoencode
    ADD CONSTRAINT pk_mediavideoencode_videoencode PRIMARY KEY (videoencode);


--
-- Name: moviefeed pk_moviefeed_titlelong; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moviefeed
    ADD CONSTRAINT pk_moviefeed_titlelong PRIMARY KEY (titlelong);


--
-- Name: newsfeed pk_newsfeed_title; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsfeed
    ADD CONSTRAINT pk_newsfeed_title PRIMARY KEY (title);


--
-- Name: tvfeed pk_tvfeed_titlelong; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tvfeed
    ADD CONSTRAINT pk_tvfeed_titlelong PRIMARY KEY (titlelong);


--
-- Name: ix_moviefeed_titleshort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_moviefeed_titleshort ON public.moviefeed USING btree (titleshort);


--
-- Name: ix_tvfeed_titleshort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tvfeed_titleshort ON public.tvfeed USING btree (titleshort);


--
-- Name: uqix_actionstatus_actionnumber; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uqix_actionstatus_actionnumber ON public.actionstatus USING btree (actionnumber);


--
-- Name: uqix_mediaaudioencode_audioencode; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uqix_mediaaudioencode_audioencode ON public.mediaaudioencode USING btree (audioencode);


--
-- Name: uqix_mediadynamicrange_dynamicrange; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uqix_mediadynamicrange_dynamicrange ON public.mediadynamicrange USING btree (dynamicrange);


--
-- Name: uqix_mediaresolution_resolution; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uqix_mediaresolution_resolution ON public.mediaresolution USING btree (resolution);


--
-- Name: uqix_mediastreamsource_streamsource; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uqix_mediastreamsource_streamsource ON public.mediastreamsource USING btree (streamsource);


--
-- Name: uqix_mediavideoencode_videoencode; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uqix_mediavideoencode_videoencode ON public.mediavideoencode USING btree (videoencode);


--
-- PostgreSQL database dump complete
--




