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
        INSERT INTO newsfeed (title, imageurl, feedurl, actualurl, publishdate)
        VALUES (p_title, p_imageurl, p_feedurl, p_actualurl, p_publishdate);
        SET result = '{"Status": "Success", "Message": "Record(s) inserted"}';
    ELSEIF optionMode = 'updateFeed' OR optionMode = 'updateNewsFeed' THEN
        SET result = '{"Status": "Success", "Message": "Record(s) updated"}';
    ELSEIF optionMode = 'deleteFeed' OR optionMode = 'deleteNewsFeed' THEN
        SET result = '{"Status": "Success", "Message": "Record(s) deleted"}';
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
