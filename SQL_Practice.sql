SELECT DISTINCT TITLE FROM movies WHERE imdb_rating >= 9;
SELECT * FROM MOVIES WHERE IMDB_RATING >= 7.5 AND IMDB_RATING <=8;
SELECT * FROM MOVIES WHERE IMDB_RATING BETWEEN 7 AND 9;
SELECT * FROM MOVIES WHERE release_year = 2021 OR release_year = 2022;
SELECT * FROM movies WHERE release_year IN(2018,2019,2020);
SELECT * FROM MOVIES WHERE IMDB_RATING IS NULL;
SELECT * FROM MOVIES WHERE IMDB_RATING IS NOT NULL;

SELECT * FROM MOVIES 
ORDER BY IMDB_RATING;

SELECT * FROM MOVIES 
ORDER BY IMDB_RATING DESC LIMIT 5;

SELECT * FROM MOVIES 
ORDER BY IMDB_RATING DESC LIMIT 5 offset 1; -- index starts with 0,1,2,3...  offset ignore the rows specified 

select max(imdb_rating) from movies;

SELECT ROUND(AVG(IMDB_RATING),2) AS AVEG_RATING, -- CANNOT USE SPACE IN ALIAS
		ROUND(max(IMDB_RATING),2) AS MAX_RATING,
        ROUND(min(IMDB_RATING),2) AS MIN_RATING
FROM MOVIES;

SELECT industry,COUNT(*) FROM movies
group by INDUSTRY;

SELECT STUDIO,COUNT(*) AS NO_OF_MOVIES
 FROM movies
group by STUDIO
ORDER BY NO_OF_MOVIES DESC;

SELECT industry,
	   COUNT(*) AS CNT,
       ROUND(avg(IMDB_RATING),2) AS AVG_RATING
FROM movies
group by INDUSTRY
ORDER BY AVG_RATING DESC;

SELECT STUDIO,  COUNT(*) AS CNT, ROUND(avg(IMDB_RATING),2) AS AVG_RATING
FROM movies
WHERE STUDIO != ""
group by STUDIO
ORDER BY AVG_RATING DESC;

SELECT RELEASE_YEAR, COUNT(*) AS CNT
FROM movies
GROUP BY RELEASE_YEAR
ORDER BY release_year DESC;

SELECT RELEASE_YEAR, COUNT(*) AS CNT
FROM movies
GROUP BY RELEASE_YEAR
HAVING CNT > 2  -- COULUMN NAME SPECIFYING IN HAVING SHOULD BE PRESENT IN ABOVE SELECT CLAUSE
ORDER BY CNT DESC;

SELECT *, YEAR(curdate())-BIRTH_YEAR AS AGE
FROM ACTORS
ORDER BY AGE DESC;

SELECT *, 
CASE
	WHEN UNIT ="BILLIONS" THEN REVENUE*1000
    WHEN UNIT ="THOUSAND" THEN REVENUE/1000
    ELSE REVENUE
END                            -- THIS WORKS AS SINGLE COLUMN
AS REVENUE_USD 
FROM FINANCIALS;

SELECT M.TITLE,L.NAME
FROM MOVIES M
LEFT JOIN LANGUAGES L 
ON M.LANGUAGE_ID = L.LANGUAGE_ID;

SELECT M.TITLE,L.NAME
FROM MOVIES M
LEFT JOIN LANGUAGES L 
ON M.LANGUAGE_ID = L.LANGUAGE_ID
HAVING NAME = "TELUGU";


SELECT COUNT(*), L.NAME
FROM MOVIES M
LEFT JOIN LANGUAGES L 
ON M.LANGUAGE_ID = L.LANGUAGE_ID
group by NAME;  -- GRP BY SHOULD BE GENERALLY USED WITH AGGREGATE COLUMN IF NOT THEN ALL COLUMN 
				-- SPECIFIED IN THE SELECT CLAUSE SHOULD BE PRESENT IN THE GROUP BY 


SELECT M.MOVIE_ID,TITLE,BUDGET,REVENUE,CURRENCY,UNIT,
		CASE
			WHEN UNIT = "Thousands" THEN ROUND((REVENUE-BUDGET)/1000,2)
            WHEN UNIT = "Billions" THEN ROUND((REVENUE-BUDGET)*1000,2)
			ELSE ROUND(REVENUE-BUDGET,2)
        END AS PROFIT
FROM MOVIES M
JOIN FINANCIALS F
ON M.MOVIE_ID = F.MOVIE_ID;

## GROUP_CONCAT

SELECT M.TITLE,  group_concat(A.NAME SEPARATOR " | ") AS ACTORS_NAME
FROM MOVIES M
JOIN MOVIE_ACTOR MA
ON M.MOVIE_ID = MA.MOVIE_ID
JOIN ACTORS A
ON MA.ACTOR_ID = A.ACTOR_ID
GROUP BY M.TITLE;

SELECT A.NAME , group_concat(M.TITLE SEPARATOR " | ") AS MOVIES_NAME,
		COUNT(M.TITLE) AS MOVIES_COUNT
FROM ACTORS A
JOIN MOVIE_ACTOR MA
ON A.ACTOR_ID = MA.ACTOR_ID
JOIN MOVIES M
ON MA.MOVIE_ID = M.MOVIE_ID
GROUP BY A.NAME
ORDER BY MOVIES_COUNT DESC;

-- SUBQUERY

SELECT * FROM movies
WHERE IMDB_RATING = (SELECT MAX(IMDB_RATING) FROM MOVIES);

-- SUBQUERIES RETURING LIST OF VALUES

SELECT * FROM MOVIES 
WHERE IMDB_RATING IN
((SELECT MAX(IMDB_RATING) FROM MOVIES),(SELECT MIN(IMDB_RATING) FROM MOVIES));

-- SUBQUERY RETURNS TABLE

SELECT *, YEAR(current_date())-BIRTH_YEAR AS AGE
FROM ACTORS 
HAVING AGE > 70 AND AGE < 85;

SELECT * FROM
(SELECT NAME, YEAR(current_date())-BIRTH_YEAR AS AGE
FROM ACTORS ) AS ACTORS_AGE
WHERE AGE > 65;

# SELECT ALL MOVIES WHOSE RATING IS GRETAER THAN "ANY " OF THE MARVEL MOVIES

SELECT * FROM MOVIES WHERE IMDB_RATING > 
(SELECT MIN(IMDB_RATING) FROM MOVIES WHERE STUDIO = "MARVEL STUDIOS");

 # SAME AS BELOW  
 
SELECT * FROM MOVIES WHERE IMDB_RATING > ANY
(SELECT IMDB_RATING FROM MOVIES WHERE STUDIO = "MARVEL STUDIOS");

# SELECT MOVIES WHOSE RATING IS GREATER THAN ALL MARVEL MOVIES
SELECT * FROM MOVIES WHERE IMDB_RATING > ALL
(SELECT IMDB_RATING FROM MOVIES WHERE STUDIO = "MARVEL STUDIOS");

#  SELECT ACTOR ID, NAME AND COUNT OF MMOVIES

SELECT A.ACTOR_ID, A.NAME, COUNT(*) AS CNT
FROM MOVIE_ACTOR MA
JOIN ACTORS A
ON MA.ACTOR_ID = A.ACTOR_ID
GROUP BY ACTOR_ID
ORDER BY CNT DESC;

# USING CO-RELATED SUBQEURY 

 # EG: 
 SELECT COUNT(*) FROM MOVIE_ACTOR WHERE ACTOR_ID = 51;
 
 
SELECT ACTOR_ID, NAME, 
(SELECT COUNT(*) FROM MOVIE_ACTOR WHERE ACTOR_ID = ACTORS.ACTOR_ID) AS CNT
FROM ACTORS
order by CNT DESC;

# SELECT MOVIES MIN AND MAX YEAR

SELECT TITLE,RELEASE_YEAR 
FROM MOVIES 
WHERE RELEASE_YEAR IN
((SELECT MAX(RELEASE_YEAR) FROM MOVIES), (SELECT MIN(RELEASE_YEAR) FROM MOVIES))
ORDER BY RELEASE_YEAR DESC;

# MOVIES WITH RATING HIGHER THAN AVERAGE

SELECT * FROM MOVIES WHERE IMDB_RATING > (SELECT AVG(IMDB_RATING) FROM MOVIES);


# CTE - COMMON TABLE EXPRESSION -- INTERVIEW QUETSION

# SAME Eg AS ABOVE - GET ALL ACTORS WHOS AGE IS BETWEEN THAN 65 AND 85

WITH ACTORS_AGE AS (
					SELECT 
                    NAME AS ACTOR_NAME,
                    YEAR(CURDATE())-BIRTH_YEAR AS AGE
                    FROM ACTORS
					)
SELECT ACTOR_NAME, AGE
FROM ACTORS_AGE
WHERE AGE BETWEEN 65 AND 85;

# ALSO CAN BE WRITTEN AS

WITH ACTORS_AGE (ACTOR_NAME,AGE) AS (
					SELECT 
                    NAME AS X,
                    YEAR(CURDATE())-BIRTH_YEAR AS Y
                    FROM ACTORS
					)
SELECT ACTOR_NAME, AGE
FROM ACTORS_AGE
WHERE AGE BETWEEN 65 AND 85;

# Eg 2 -- WITH CREATES TEMPARORY TABLE X AND Y

WITH TEMP_X AS (
				SELECT *,
					   ((REVENUE-BUDGET)*100)/BUDGET AS PCT_PROFIT
				FROM FINANCIALS
                ),
	 TEMP_Y AS (
					SELECT * FROM MOVIES
					WHERE IMDB_RATING < (SELECT AVG(IMDB_RATING) FROM MOVIES)
				)
SELECT TEMP_X.MOVIE_ID,PCT_PROFIT,TEMP_Y.TITLE,TEMP_Y.IMDB_RATING
FROM TEMP_X
JOIN TEMP_Y
ON TEMP_X.MOVIE_ID = TEMP_Y.MOVIE_ID
WHERE PCT_PROFIT >= 500;

-- WITH TABLE1 AS (  )
-- 	 TABLE2 AS (  )
-- SELECT C1,C2,C3 ETC 
-- FROM TABLE1
-- JOIN TABLE2
-- ON 

# STUDY RECURSIVE QUERIES ---GOOGLE FOR MORE


SELECT * FROM MOVIES;

INSERT INTO MOVIES
(TITLE,INDUSTRY,LANGUAGE_ID)
VALUES ("KGF 3","BOLLYWOOD",2);

DELETE FROM MOVIES WHERE MOVIE_ID = '141';

UPDATE MOVIES               # ALWAYS MENTION WHERE CLAUSE
SET INDUSTRY = "Bollywood",
	STUDIO = "Hombale Films"
WHERE MOVIE_ID = 143;
	
