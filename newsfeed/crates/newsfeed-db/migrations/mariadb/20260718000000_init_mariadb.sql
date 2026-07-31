CREATE TABLE IF NOT EXISTS newsfeed (
    title TEXT,
    imageurl TEXT,
    feedurl TEXT,
    actualurl TEXT,
    publishdate TEXT,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    modified_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER ;;



CREATE PROCEDURE `extractnewsfeed`(
    IN optionMode TEXT,
    IN title TEXT,
    IN imageurl TEXT,
    IN feedurl TEXT,
    IN actualurl TEXT,
    IN `limit` TEXT,
    IN sort TEXT
)
BEGIN
    DECLARE omitOptionMode TEXT;
    DECLARE omitTitle TEXT;
    DECLARE omitImageURL TEXT;
    DECLARE omitFeedURL TEXT;
    DECLARE omitActualURL TEXT;
    DECLARE omitLimit TEXT;
    DECLARE omitSort TEXT;
    DECLARE maxLengthOptionMode INT;
    DECLARE maxLengthTitle INT;
    DECLARE maxLengthImageURL INT;
    DECLARE maxLengthFeedURL INT;
    DECLARE maxLengthActualURL INT;
    DECLARE maxLengthSort INT;
    DECLARE lowerLimit INT;
    DECLARE upperLimit INT;
    DECLARE defaultLimit INT;
    DECLARE successcode VARCHAR(5);

    SET omitOptionMode = '[^a-zA-Z]';
    SET omitTitle = '[^a-zA-Z0-9 !"\#$%&\'()*+,\-./:;<=>?@\[\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
    SET omitImageURL = '[^a-zA-Z0-9 !"\#$%&\'()*+,\-./:;<=>?@\[\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
    SET omitFeedURL = '[^a-zA-Z0-9 !"\#$%&\'()*+,\-./:;<=>?@\[\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
    SET omitActualURL = '[^a-zA-Z0-9 !"\#$%&\'()*+,\-./:;<=>?@\[\\]^_‘{|}~¡¢£¥¦§¨©®¯°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿıŒœŠšŸŽžƒˆˇ˘˙˚˛ΓΘΣΦΩαδεπστφ–—‘’“”•…€™∂∆∏∑∙√∞∩∫≈≠≡≤≥]';
    SET omitLimit = '[^0-9\-]';
    SET omitSort = '[^a-zA-Z]';
    SET maxLengthOptionMode = 255;
    SET maxLengthTitle = 255;
    SET maxLengthImageURL = 255;
    SET maxLengthFeedURL = 768;
    SET maxLengthActualURL = 255;
    SET maxLengthSort = 255;
    SET lowerLimit = 1;
    SET upperLimit = 100;
    SET defaultLimit = 25;
    SET successcode = '00000';
    SET @dSQL = '';
    SET @dSQLWhere = '';
    SET @title = null;
    SET @imageurl = null;
    SET @feedurl = null;
    SET @actualurl = null;
    SET @`limit` = null;
    SET @sort = null;

    -- Check if parameter is not null
    IF optionMode IS NOT NULL THEN
      -- Omit characters, multi space to single space, and trim leading and trailing spaces
      SET optionMode = REGEXP_REPLACE(REGEXP_REPLACE(optionMode, omitOptionMode, ' '), '[ ]{2,}', ' ');
      -- Set character limit
      SET optionMode = TRIM(SUBSTRING(optionMode, 1, maxLengthOptionMode));
      -- Check if empty string
      IF optionMode = '' THEN
        -- Set parameter to null if empty string
        SET optionMode = NULLIF(optionMode, '');
      END IF;
    END IF;

    -- Check if parameter is not null
    IF title IS NOT NULL THEN
      SET title = REGEXP_REPLACE(REGEXP_REPLACE(title, omitTitle, ' '), '[ ]{2,}', ' ');
      SET title = TRIM(SUBSTRING(title, 1, maxLengthTitle));
      IF title = '' THEN
        SET title = NULLIF(title, '');
      END IF;
    END IF;

    -- Check if parameter is not null
    IF imageurl IS NOT NULL THEN
      SET imageurl = REGEXP_REPLACE(REGEXP_REPLACE(imageurl, omitImageURL, ' '), '[ ]{2,}', ' ');
      SET imageurl = TRIM(SUBSTRING(imageurl, 1, maxLengthImageURL));
      IF imageurl = '' THEN
        SET imageurl = NULLIF(imageurl, '');
      END IF;
    END IF;

    -- Check if parameter is not null
    IF feedurl IS NOT NULL THEN
      SET feedurl = REGEXP_REPLACE(REGEXP_REPLACE(feedurl, omitFeedURL, ' '), '[ ]{2,}', ' ');
      SET feedurl = TRIM(SUBSTRING(feedurl, 1, maxLengthFeedURL));
      IF feedurl = '' THEN
          SET feedurl = NULLIF(feedurl, '');
      END IF;
    END IF;

    -- Check if parameter is not null
    IF actualurl IS NOT NULL THEN
      SET actualurl = REGEXP_REPLACE(REGEXP_REPLACE(actualurl, omitActualURL, ' '), '[ ]{2,}', ' ');
      SET actualurl = TRIM(SUBSTRING(actualurl, 1, maxLengthActualURL));
      IF actualurl = '' THEN
        SET actualurl = NULLIF(actualurl, '');
      END IF;
    END IF;

    -- Check if parameter is not null
    IF `limit` IS NOT NULL THEN
      SET `limit` = REGEXP_REPLACE(REGEXP_REPLACE(`limit`, omitLimit, ' '), '[ ]{2,}', ' ');
      SET `limit` = TRIM(`limit`);
      IF `limit` = '' THEN
        SET `limit` = NULLIF(`limit`, '');
      END IF;
    END IF;

    -- Check if parameter is not null
    IF sort IS NOT NULL THEN
      SET sort = REGEXP_REPLACE(REGEXP_REPLACE(sort, omitSort, ' '), '[ ]{2,}', ' ');
      SET sort = TRIM(SUBSTRING(sort, 1, maxLengthSort));
      IF sort = '' THEN
        SET sort = NULLIF(sort, '');
      END IF;
    END IF;

    -- Check if option mode extract news feed
    IF optionMode = 'extractNewsFeed' THEN
      -- Check if limit is given
      IF `limit` IS NULL OR CAST(`limit` AS SIGNED) NOT BETWEEN lowerLimit AND upperLimit THEN
        -- Set limit to default number
        SET @`limit` = defaultLimit;
      ELSE
        -- Set limit to user input
        SET @`limit` = CAST(`limit` AS SIGNED);
      END IF;

      -- Check if sort is given
      IF sort IS NULL OR LOWER(sort) NOT IN ('desc', 'asc') THEN
        -- Set sort to default sorting
        SET @sort = 'asc';
      ELSE
        -- Set sort to user input
        SET @sort = sort;
      END IF;

      -- Select records for processing using the dynamic sql builder containing parameters
      -- Utilize the parentheses for the top portion
      SET @dSQL =
      'select
      nf.title as `Title`,
      nf.imageurl as `Image URL`,
      nf.feedurl as `Feed URL`,
      nf.actualurl as `Acutal URL`,
      date_format(nf.publishdate, ''%Y-%m-%d %H:%i:%s.%f'') as `Publish Date`
      from newsfeed nf';

      -- Check if where clause is given
      IF title IS NOT NULL THEN
        -- Set variable
        SET @dSQLWhere = 'nf.title = ?';
        SET @title = title;
      END IF;

      -- Check if where clause is given
      IF imageurl IS NOT NULL THEN
        -- Check if value is string null
        IF LOWER(imageurl) = 'null' THEN
          -- Check if dynamic SQL is not empty
          IF TRIM(@dSQLWhere) <> '' THEN
            -- Include the next filter into the where clause
            SET @dSQLWhere = CONCAT(@dSQLWhere, ' AND nf.imageurl is null');
          ELSE
            -- Include the next filter into the where clause
            SET @dSQLWhere = 'nf.imageurl is null';
          END IF;
        ELSE
          IF TRIM(@dSQLWhere) <> '' THEN
            -- Include the next filter into the where clause
            SET @dSQLWhere = CONCAT(@dSQLWhere, ' AND nf.imageurl = ?');
          ELSE
            -- Include the next filter into the where clause
            SET @dSQLWhere = 'nf.imageurl = ?';
          END IF;

          -- Set variable
          SET @imageurl = imageurl;
        END IF;
      END IF;

      -- Check if where clause is given
      IF feedurl IS NOT NULL THEN
        -- Check if dynamic SQL is not empty
        IF TRIM(@dSQLWhere) <> '' THEN
          -- Include the next filter into the where clause
          SET @dSQLWhere = CONCAT(@dSQLWhere, ' AND nf.feedurl = ?');
        ELSE
          -- Include the next filter into the where clause
          SET @dSQLWhere = 'nf.feedurl = ?';
        END IF;

        -- Set variable
        SET @feedurl = feedurl;
      END IF;

      -- Check if where clause is given
      IF actualurl IS NOT NULL THEN
        -- Check if value is string null
        IF LOWER(actualurl) = 'null' THEN
          -- Check if dynamic SQL is not empty
          IF TRIM(@dSQLWhere) <> '' THEN
            -- Include the next filter into the where clause
            SET @dSQLWhere = CONCAT(@dSQLWhere, ' AND nf.actualurl is null');
          ELSE
            -- Include the next filter into the where clause
            SET @dSQLWhere = 'nf.actualurl is null';
          END IF;
        ELSE
          IF TRIM(@dSQLWhere) <> '' THEN
            -- Include the next filter into the where clause
            SET @dSQLWhere = CONCAT(@dSQLWhere, ' AND nf.actualurl = ?');
          ELSE
            -- Include the next filter into the where clause
            SET @dSQLWhere = 'nf.actualurl = ?';
          END IF;

          -- Set variable
          SET @actualurl = actualurl;
        END IF;
      END IF;

      -- Check if dynamic SQL is not empty
      IF TRIM(@dSQLWhere) <> '' THEN
        -- Include the where clause
        SET @dSQLWhere = CONCAT(' WHERE ', @dSQLWhere);
      END IF;

      -- Set the dynamic string with the where clause and sort option
      IF @sort = 'desc' THEN
        SET @dSQL = CONCAT(@dSQL, @dSQLWhere, ' order by nf.publishdate desc, nf.title desc, nf.imageurl desc, nf.feedurl desc, nf.actualurl desc limit ?');
      ELSE
        SET @dSQL = CONCAT(@dSQL, @dSQLWhere, ' order by nf.publishdate asc, nf.title asc, nf.imageurl asc, nf.feedurl asc, nf.actualurl asc limit ?');
      END IF;

      -- Prepare the statement
      PREPARE queryStatement FROM @dSQL;

      -- Check if parameters were set
      IF @title IS NOT NULL AND @imageurl IS NULL AND @feedurl IS NULL AND @actualurl IS NULL THEN
        EXECUTE queryStatement USING @title, @`limit`;
      ELSEIF @title IS NOT NULL AND @imageurl IS NOT NULL AND @feedurl IS NULL AND @actualurl IS NULL THEN
        IF imageurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @imageurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @title, @`limit`;
        END IF;
      ELSEIF @title IS NOT NULL AND @imageurl IS NOT NULL AND @feedurl IS NOT NULL AND @actualurl IS NULL THEN
        IF imageurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @imageurl, @feedurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @title, @feedurl, @`limit`;
        END IF;
      ELSEIF @title IS NOT NULL AND @imageurl IS NOT NULL AND @feedurl IS NULL AND @actualurl IS NOT NULL THEN
        IF imageurl <> 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @imageurl, @actualurl, @`limit`;
        ELSEIF imageurl = 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @actualurl, @`limit`;
        ELSEIF imageurl <> 'null' AND actualurl = 'null' THEN
          EXECUTE queryStatement USING @title, @imageurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @title, @`limit`;
        END IF;
      ELSEIF @title IS NOT NULL AND @imageurl IS NULL AND @feedurl IS NOT NULL AND @actualurl IS NOT NULL THEN
        IF actualurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @feedurl, @actualurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @title, @feedurl, @`limit`;
        END IF;
      ELSEIF @title IS NOT NULL AND @imageurl IS NULL AND @feedurl IS NOT NULL AND @actualurl IS NULL THEN
        EXECUTE queryStatement USING @title, @feedurl, @`limit`;
      ELSEIF @title IS NOT NULL AND @imageurl IS NULL AND @feedurl IS NULL AND @actualurl IS NOT NULL THEN
        IF actualurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @actualurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @title, @`limit`;
        END IF;
      ELSEIF @title IS NULL AND @imageurl IS NOT NULL AND @feedurl IS NOT NULL AND @actualurl IS NOT NULL THEN
        IF imageurl <> 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @imageurl, @feedurl, @actualurl, @`limit`;
        ELSEIF imageurl = 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @feedurl, @actualurl, @`limit`;
        ELSEIF imageurl <> 'null' AND actualurl = 'null' THEN
          EXECUTE queryStatement USING @imageurl, @feedurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @feedurl, @`limit`;
        END IF;
      ELSEIF @title IS NULL AND @imageurl IS NOT NULL AND @feedurl IS NOT NULL AND @actualurl IS NULL THEN
        IF imageurl <> 'null' THEN
          EXECUTE queryStatement USING @imageurl, @feedurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @feedurl, @`limit`;
        END IF;
      ELSEIF @title IS NULL AND @imageurl IS NOT NULL AND @feedurl IS NULL AND @actualurl IS NOT NULL THEN
        IF imageurl <> 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @imageurl, @actualurl, @`limit`;
        ELSEIF imageurl = 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @actualurl, @`limit`;
        ELSEIF imageurl <> 'null' AND actualurl = 'null' THEN
          EXECUTE queryStatement USING @imageurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @`limit`;
        END IF;
      ELSEIF @title IS NULL AND @imageurl IS NULL AND @feedurl IS NOT NULL AND @actualurl IS NOT NULL THEN
        IF actualurl <> 'null' THEN
          EXECUTE queryStatement USING @feedurl, @actualurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @feedurl, @`limit`;
        END IF;
      ELSEIF @title IS NULL AND @imageurl IS NOT NULL AND @feedurl IS NULL AND @actualurl IS NULL THEN
        IF imageurl <> 'null' THEN
          EXECUTE queryStatement USING @imageurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @`limit`;
        END IF;
      ELSEIF @title IS NULL AND @imageurl IS NULL AND @feedurl IS NOT NULL AND @actualurl IS NULL THEN
        EXECUTE queryStatement USING @feedurl, @`limit`;
      ELSEIF @title IS NULL AND @imageurl IS NULL AND @feedurl IS NULL AND @actualurl IS NOT NULL THEN
        IF actualurl <> 'null' THEN
          EXECUTE queryStatement USING @actualurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @`limit`;
        END IF;
      ELSEIF @title IS NOT NULL AND @imageurl IS NOT NULL AND @feedurl IS NOT NULL AND @actualurl IS NOT NULL THEN
        IF imageurl <> 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @imageurl, @feedurl, @actualurl, @`limit`;
        ELSEIF imageurl = 'null' AND actualurl <> 'null' THEN
          EXECUTE queryStatement USING @title, @feedurl, @actualurl, @`limit`;
        ELSEIF imageurl <> 'null' AND actualurl = 'null' THEN
          EXECUTE queryStatement USING @title, @imageurl, @feedurl, @`limit`;
        ELSE
          EXECUTE queryStatement USING @title, @feedurl, @`limit`;
        END IF;
      ELSE
        EXECUTE queryStatement USING @`limit`;
      END IF;
    END IF;
END;;


CREATE PROCEDURE `cud_bulk_json_newsfeed`(
    IN optionMode TEXT,
    IN payload JSON
)
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_bulk_results (status TEXT);
    TRUNCATE TABLE temp_bulk_results;

    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_parsed_input (
        title TEXT,
        image_url TEXT,
        feed_url TEXT,
        actual_url TEXT,
        publish_date TEXT
    );
    TRUNCATE TABLE tmp_parsed_input;

    INSERT INTO tmp_parsed_input
    SELECT title, image_url, feed_url, actual_url, publish_date 
    FROM JSON_TABLE(
        payload,
        '$[*]' COLUMNS(
            title TEXT PATH '$.title',
            image_url TEXT PATH '$.image_url',
            feed_url TEXT PATH '$.feed_url',
            actual_url TEXT PATH '$.actual_url',
            publish_date TEXT PATH '$.publish_date'
        )
    ) AS jt
    WHERE title IS NOT NULL AND title != ''
      AND feed_url IS NOT NULL AND feed_url != ''
      AND publish_date IS NOT NULL AND publish_date != '';

    IF optionMode = 'insertFeed' OR optionMode = 'insertNewsFeed' THEN
        -- Generate statuses before insert
        INSERT INTO temp_bulk_results (status)
        SELECT JSON_OBJECT(
            'Status', IF(n.title IS NOT NULL, 'Skipped', 'Success'),
            'Message', IF(n.title IS NOT NULL, 'SKIPPED_EXISTS', 'Record(s) inserted')
        )
        FROM tmp_parsed_input t
        LEFT JOIN newsfeed n ON t.title = n.title;

        -- Insert new records
        INSERT INTO newsfeed (title, imageurl, feedurl, actualurl, publishdate, created_date, modified_date)
        SELECT t.title, NULLIF(TRIM(t.image_url), ''), t.feed_url, NULLIF(TRIM(t.actual_url), ''), t.publish_date, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM tmp_parsed_input t
        WHERE NOT EXISTS (SELECT 1 FROM newsfeed n WHERE n.title = t.title);

    ELSEIF optionMode = 'updateFeed' OR optionMode = 'updateNewsFeed' THEN
        -- Generate statuses before update
        INSERT INTO temp_bulk_results (status)
        SELECT JSON_OBJECT(
            'Status', CASE 
                WHEN n.title IS NULL THEN 'Skipped'
                WHEN n.imageurl <=> NULLIF(TRIM(t.image_url), '') AND n.feedurl <=> t.feed_url AND n.actualurl <=> NULLIF(TRIM(t.actual_url), '') AND n.publishdate <=> t.publish_date THEN 'Skipped'
                ELSE 'Success'
            END,
            'Message', CASE
                WHEN n.title IS NULL THEN 'SKIPPED_NOT_FOUND'
                WHEN n.imageurl <=> NULLIF(TRIM(t.image_url), '') AND n.feedurl <=> t.feed_url AND n.actualurl <=> NULLIF(TRIM(t.actual_url), '') AND n.publishdate <=> t.publish_date THEN 'SKIPPED_EXISTS'
                ELSE 'Record(s) updated'
            END
        )
        FROM tmp_parsed_input t
        LEFT JOIN newsfeed n ON t.title = n.title;

        -- Update existing records
        UPDATE newsfeed n
        INNER JOIN tmp_parsed_input t ON n.title = t.title
        SET n.imageurl = NULLIF(TRIM(t.image_url), ''),
            n.feedurl = t.feed_url,
            n.actualurl = NULLIF(TRIM(t.actual_url), ''),
            n.publishdate = t.publish_date,
            n.modified_date = CURRENT_TIMESTAMP
        WHERE NOT (n.imageurl <=> NULLIF(TRIM(t.image_url), '') AND n.feedurl <=> t.feed_url AND n.actualurl <=> NULLIF(TRIM(t.actual_url), '') AND n.publishdate <=> t.publish_date);

    ELSEIF optionMode = 'deleteFeed' OR optionMode = 'deleteNewsFeed' THEN
        -- Generate statuses before delete
        INSERT INTO temp_bulk_results (status)
        SELECT JSON_OBJECT(
            'Status', IF(n.title IS NOT NULL, 'Success', 'Skipped'),
            'Message', IF(n.title IS NOT NULL, 'Record(s) deleted', 'SKIPPED_NOT_FOUND')
        )
        FROM tmp_parsed_input t
        LEFT JOIN newsfeed n ON t.title = n.title;

        -- Delete records
        DELETE n FROM newsfeed n
        INNER JOIN tmp_parsed_input t ON n.title = t.title;

    ELSE
        INSERT INTO temp_bulk_results VALUES ('{"Status": "Error", "Message": "Invalid optionMode"}');
    END IF;

    SELECT CONCAT('[', IFNULL(GROUP_CONCAT(status SEPARATOR ','), ''), ']') AS `status` FROM temp_bulk_results;
END;;

DELIMITER ;
