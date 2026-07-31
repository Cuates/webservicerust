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
      dSQL := concat(
        dSQL,
        dSQLWhere,
        CASE
          WHEN lower(sort) = 'desc' THEN ' order by nf.publish_date desc, nf.title desc, nf.imageurl desc, nf.feedurl desc, nf.actualurl desc'
          ELSE ' order by nf.publish_date asc, nf.title asc, nf.imageurl asc, nf.feedurl asc, nf.actualurl asc'
        END,
        ' limit $', countInput
      );

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
-- Name: insertupdatedeletenewsfeed(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--




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

--
-- Name: cud_bulk_json_newsfeed; Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.cud_bulk_json_newsfeed(
    IN optionmode text,
    IN payload json,
    INOUT status text DEFAULT NULL::text
)
LANGUAGE plpgsql
AS $$
DECLARE
    final_status jsonb := '[]'::jsonb;
BEGIN
    IF optionmode = 'insertNewsFeed' THEN
        WITH parsed AS (
            SELECT 
                item->>'title' AS title,
                NULLIF(trim(item->>'image_url'), '') AS imageurl,
                item->>'feed_url' AS feedurl,
                NULLIF(trim(item->>'actual_url'), '') AS actualurl,
                to_timestamp(item->>'publish_date', 'YYYY-MM-DD HH24:MI:SS.US') AS publish_date,
                item
            FROM json_array_elements(payload) AS item
        ), inserted AS (
            INSERT INTO newsfeed (title, imageurl, feedurl, actualurl, publish_date, created_date, modified_date)
            SELECT title, imageurl, feedurl, actualurl, publish_date, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            FROM parsed
            ON CONFLICT (title) DO NOTHING
            RETURNING title
        )
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'Status', CASE WHEN i.title IS NOT NULL THEN 'Success' ELSE 'Skipped' END,
                'Message', CASE WHEN i.title IS NOT NULL THEN 'Record(s) inserted' ELSE 'SKIPPED_EXISTS' END
            )
        ), '[]'::jsonb) INTO final_status
        FROM parsed p
        LEFT JOIN inserted i ON p.title = i.title;

    ELSIF optionmode = 'updateNewsFeed' THEN
        WITH parsed AS (
            SELECT 
                item->>'title' AS title,
                NULLIF(trim(item->>'image_url'), '') AS imageurl,
                item->>'feed_url' AS feedurl,
                NULLIF(trim(item->>'actual_url'), '') AS actualurl,
                to_timestamp(item->>'publish_date', 'YYYY-MM-DD HH24:MI:SS.US') AS publish_date,
                item
            FROM json_array_elements(payload) AS item
        ), updated AS (
            UPDATE newsfeed nf
            SET imageurl = p.imageurl,
                feedurl = p.feedurl,
                actualurl = p.actualurl,
                publish_date = p.publish_date,
                modified_date = CURRENT_TIMESTAMP
            FROM parsed p
            WHERE nf.title = p.title
              AND (
                  nf.imageurl IS DISTINCT FROM p.imageurl OR
                  nf.feedurl IS DISTINCT FROM p.feedurl OR
                  nf.actualurl IS DISTINCT FROM p.actualurl OR
                  nf.publish_date IS DISTINCT FROM p.publish_date
              )
            RETURNING nf.title
        )
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'Status', CASE 
                    WHEN u.title IS NOT NULL THEN 'Success'
                    WHEN nf.title IS NOT NULL THEN 'Skipped'
                    ELSE 'Skipped' 
                END,
                'Message', CASE 
                    WHEN u.title IS NOT NULL THEN 'Record(s) updated'
                    WHEN nf.title IS NOT NULL THEN 'SKIPPED_EXISTS'
                    ELSE 'SKIPPED_NOT_FOUND' 
                END
            )
        ), '[]'::jsonb) INTO final_status
        FROM parsed p
        LEFT JOIN newsfeed nf ON p.title = nf.title
        LEFT JOIN updated u ON p.title = u.title;

    ELSIF optionmode = 'deleteNewsFeed' THEN
        WITH parsed AS (
            SELECT item->>'title' AS title, item
            FROM json_array_elements(payload) AS item
        ), deleted AS (
            DELETE FROM newsfeed nf
            USING parsed p
            WHERE nf.title = p.title
            RETURNING nf.title
        )
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'Status', CASE WHEN d.title IS NOT NULL THEN 'Success' ELSE 'Skipped' END,
                'Message', CASE WHEN d.title IS NOT NULL THEN 'Record(s) deleted' ELSE 'SKIPPED_NOT_FOUND' END
            )
        ), '[]'::jsonb) INTO final_status
        FROM parsed p
        LEFT JOIN deleted d ON p.title = d.title;
    END IF;

    status := final_status::text;
END;
$$;
