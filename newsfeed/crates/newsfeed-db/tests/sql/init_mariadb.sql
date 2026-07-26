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

CREATE PROCEDURE `insertupdatedeletenewsfeed`(
    IN optionMode TEXT,
    IN p_title TEXT,
    IN p_imageurl TEXT,
    IN p_feedurl TEXT,
    IN p_actualurl TEXT,
    IN p_publishdate TEXT
)
BEGIN
    DECLARE result TEXT DEFAULT '';
    
    IF optionMode = 'insertFeed' OR optionMode = 'insertNewsFeed' THEN
        IF p_title IS NULL OR TRIM(p_title) = '' OR p_feedurl IS NULL OR TRIM(p_feedurl) = '' OR p_publishdate IS NULL OR TRIM(p_publishdate) = '' THEN
            SET result = '{"Status": "Error", "Message": "Process halted, title, feed url, and or publish date were not provided"}';
        ELSEIF NOT EXISTS (SELECT 1 FROM newsfeed WHERE title = p_title) THEN
            INSERT INTO newsfeed (title, imageurl, feedurl, actualurl, publishdate, created_date, modified_date)
            VALUES (p_title, NULLIF(TRIM(p_imageurl), ''), p_feedurl, NULLIF(TRIM(p_actualurl), ''), p_publishdate, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
            SET result = '{"Status": "Success", "Message": "Record(s) inserted"}';
        ELSE
            SET result = '{"Status": "Success", "Message": "Record exist"}';
        END IF;
    ELSEIF optionMode = 'updateFeed' OR optionMode = 'updateNewsFeed' THEN
        IF p_title IS NULL OR TRIM(p_title) = '' OR p_feedurl IS NULL OR TRIM(p_feedurl) = '' OR p_publishdate IS NULL OR TRIM(p_publishdate) = '' THEN
            SET result = '{"Status": "Error", "Message": "Process halted, title, feed url, and or publish date were not provided"}';
        ELSEIF EXISTS (SELECT 1 FROM newsfeed WHERE title = p_title) THEN
            UPDATE newsfeed
            SET imageurl = NULLIF(TRIM(p_imageurl), ''),
                feedurl = p_feedurl,
                actualurl = NULLIF(TRIM(p_actualurl), ''),
                publishdate = p_publishdate,
                modified_date = CURRENT_TIMESTAMP
            WHERE title = p_title;
            SET result = '{"Status": "Success", "Message": "Record(s) updated"}';
        ELSE
            SET result = '{"Status": "Error", "Message": "Record does not exist"}';
        END IF;
    ELSEIF optionMode = 'deleteFeed' OR optionMode = 'deleteNewsFeed' THEN
        IF p_title IS NULL OR TRIM(p_title) = '' THEN
            SET result = '{"Status": "Error", "Message": "Process halted, title was not provided"}';
        ELSEIF EXISTS (SELECT 1 FROM newsfeed WHERE title = p_title) THEN
            DELETE FROM newsfeed WHERE title = p_title;
            SET result = '{"Status": "Success", "Message": "Record(s) deleted"}';
        ELSE
            SET result = '{"Status": "Success", "Message": "Record does not exist"}';
        END IF;
    ELSE
        SET result = '{"Status": "Error", "Message": "Invalid optionMode"}';
    END IF;

    SELECT result AS `status`;
END;;

CREATE PROCEDURE `extractnewsfeed`(
    IN optionMode TEXT,
    IN p_title TEXT,
    IN p_imageurl TEXT,
    IN p_feedurl TEXT,
    IN p_actualurl TEXT,
    IN p_limit TEXT,
    IN p_sort TEXT
)
BEGIN
    SELECT 
        title AS titlereturn,
        imageurl AS imageurlreturn,
        feedurl AS feedurlreturn,
        actualurl AS actualurlreturn,
        publishdate AS publishdatereturn,
        created_date AS createddatereturn,
        modified_date AS modifieddatereturn
    FROM newsfeed;
END;;

DELIMITER ;
