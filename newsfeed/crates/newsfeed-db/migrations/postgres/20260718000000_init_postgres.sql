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
-- Name: extractnewsfeed(text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extractnewsfeed(optionmode text DEFAULT NULL::text, title text DEFAULT NULL::text, imageurl text DEFAULT NULL::text, feedurl text DEFAULT NULL::text, actualurl text DEFAULT NULL::text, "limit" text DEFAULT NULL::text, sort text DEFAULT NULL::text) RETURNS TABLE(titlereturn text, imageurlreturn text, feedurlreturn text, actualurlreturn text, publishdatereturn text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitle varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitImageURL varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitFeedURL varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitActualURL varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
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
-- Name: insertupdatedeletebulknewsfeed(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.insertupdatedeletebulknewsfeed(IN optionmode text, IN title text DEFAULT NULL::text, IN imageurl text DEFAULT NULL::text, IN feedurl text DEFAULT NULL::text, IN actualurl text DEFAULT NULL::text, IN publishdate text DEFAULT NULL::text, INOUT status text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare and set variables
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitle varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitImageurl varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitFeedurl varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitActualurl varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
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
-- Name: insertupdatedeletenewsfeed(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.insertupdatedeletenewsfeed(IN optionmode text DEFAULT NULL::text, IN title text DEFAULT NULL::text, IN imageurl text DEFAULT NULL::text, IN feedurl text DEFAULT NULL::text, IN actualurl text DEFAULT NULL::text, IN publishdate text DEFAULT NULL::text, INOUT status text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $_$
  -- Declare variable
  declare omitOptionMode text := '[^a-zA-Z]';
  declare omitTitle varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitImageURL varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitFeedURL varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
  declare omitActualURL varchar(255) := '[^a-zA-Z0-9 !\"\\#$%&''()*+,\-./:;<=>?@\[\\\\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
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
-- Name: newsfeed nfid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsfeed ALTER COLUMN nfid SET DEFAULT nextval('public.newsfeed_nfid_seq'::regclass);

--
-- Name: newsfeed pk_newsfeed_title; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsfeed
    ADD CONSTRAINT pk_newsfeed_title PRIMARY KEY (title);
