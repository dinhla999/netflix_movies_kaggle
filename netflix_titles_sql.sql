use bootcamp;
DROP TABLE IF EXISTS netflix_titles;

CREATE TABLE netflix_titles (
    show_id NVARCHAR(50) NULL ,
    type NVARCHAR(20) NULL,
    title NVARCHAR(255) NULL,
    director NVARCHAR(255) NULL,
    cast TEXT NULL,
    country NVARCHAR(200) NULL,
    date_added VARCHAR(50) NULL,
    release_year INT NULL,
    rating VARCHAR(20) NULL,
    duration VARCHAR(20) NULL,
    listed_in TEXT,
    description TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/netflix_titles.csv'
INTO TABLE netflix_titles
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


SELECT * FROM netflix_titles
ORDER BY title;

-- checking duplicate show_id
WITH check_id AS (
	SELECT *,
			ROW_NUMBER() OVER(PARTITION BY show_id ORDER BY show_id) AS row_num
	FROM netflix_titles
) 
SELECT * FROM check_id
WHERE row_num > 1; --  no dupclicate show_id

-- Remove duplicate title
START TRANSACTION;

DELETE FROM netflix_titles 
	WHERE show_id IN (
	-- Checking title, type, director, release_year, description are duplicate
	WITH check_title AS (
		SELECT n1.show_id, n1.title, n1.type, n1.director, n1.release_year, n1.description,
				ROW_NUMBER() OVER( PARTITION BY lower(n1.title), n1.director, n1.release_year ORDER BY lower(n1.title)) AS row_num
		FROM netflix_titles n1
	)
	SELECT show_id FROM check_title
	WHERE row_num >1
)	
;
ROLLBACK;
COMMIT; -- COMMIT deleted rows

SELECT * FROM netflix_titles
where cast NOT IN ('')
 ;
 
 -- create new table containing cast for each title
DROP TABLE IF EXISTS nf_cast;
-- Create new table which splitting country from each title
CREATE TABLE nf_cast (
    show_id NVARCHAR(50),
    title NVARCHAR(255) NULL,
    cast TEXT NULL
);

INSERT INTO nf_cast (show_id, title, cast)
SELECT 
    nt.show_id,
    nt.title,
    TRIM(value) AS cast
FROM netflix_titles nt
JOIN JSON_TABLE(
    -- Ensure proper JSON formatting and handle NULLs
	IF(
        nt.cast IS NULL OR nt.cast = '', 
        '["Unknown"]',  -- Handle NULL or empty values
        CONCAT(
            '["', 
            REPLACE(REPLACE(nt.cast, '"', '\\"'), ', ', '","'), 
            '"]'
        )
    ),
    '$[*]' COLUMNS (value VARCHAR(255) PATH '$')
) AS split_cast;

SELECT * FROM nf_cast;
 

 
DROP TABLE IF EXISTS nf_countries;

-- Create new table which splitting country from each title
CREATE TABLE nf_countries (
    show_id NVARCHAR(50),
    title NVARCHAR(255) NULL,
    country TEXT
);

INSERT INTO nf_countries( show_id, title, country)
SELECT 
    nt.show_id,
    nt.title,
    TRIM(value) AS country
FROM netflix_titles nt
JOIN JSON_TABLE(
    -- Ensure valid JSON by handling NULL values
    IFNULL(CONCAT('["', REPLACE(nt.country, ', ', '","'), '"]'), '["Unknown"]'),
    '$[*]' COLUMNS (value VARCHAR(100) PATH '$')
) AS split_countries;

select * from nf_countries;
 
 
 
DROP TABLE IF EXISTS nf_genre;

-- Create new table which splitting country from each title
CREATE TABLE nf_genre (
    show_id NVARCHAR(50),
    title NVARCHAR(255) NULL,
    genre TEXT
);

INSERT INTO nf_genre( show_id, title, genre)
SELECT 
    nt.show_id,
    nt.title,
    TRIM(value) AS genre
FROM netflix_titles nt
JOIN JSON_TABLE(
    -- Ensure valid JSON by handling NULL values
    IFNULL(CONCAT('["', REPLACE(nt.listed_in, ', ', '","'), '"]'), '["Unknown"]'),
    '$[*]' COLUMNS (value VARCHAR(100) PATH '$')
) AS split_genre;

select * from nf_genre;

-- checking distinct values
SELECT DISTINCT rating FROM netflix_titles;

SELECT DISTINCT duration FROM netflix_titles;

SELECT * FROM netflix_titles;
