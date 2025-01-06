CREATE database VC;

USE VC;

SELECT * FROM investments_vc;

SELECT COUNT(*) FROM investments_vc;

-- Create a staging table

CREATE TABLE investments_vc_staging
LIKE investments_vc;

INSERT INTO investments_vc_staging
SELECT * FROM investments_vc;

SELECT * FROM investments_vc_staging;

SELECT COUNT(*) FROM investments_vc_staging;

-- Data Cleaning

-- Duplicates

WITH CTE AS 
( SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY name , homepage_url,permalink) as row_num
 FROM investments_vc_staging
 )
 SELECT * 
FROM CTE 
WHERE row_num>1;

SELECT * FROM investments_vc_staging;

-- Standardlize the Data

UPDATE investments_vc_staging
SET permalink = REPLACE(permalink, '/organization/', '');

UPDATE investments_vc_staging
SET funding_total_usd = REPLACE(funding_total_usd, ',', '');

UPDATE investments_vc_staging
SET funding_total_usd = '0'
WHERE funding_total_usd = ' -   ';

SELECT funding_total_usd FROM investments_vc_staging;

ALTER TABLE investments_vc_staging
MODIFY column funding_total_usd double;

SELECT founded_at FROM investments_vc_staging;

SELECT COUNT(*) FROM investments_vc_staging
WHERE founded_at = '';

UPDATE investments_vc_staging
SET founded_at = '2000-01-01'
WHERE founded_at='';

UPDATE investments_vc_staging
SET founded_at = str_to_date(founded_at,'%Y-%m-%d');

ALTER table investments_vc_staging
MODIFY column founded_at date; 

UPDATE investments_vc_staging
SET founded_at = NULL
WHERE founded_at='2000-01-01';

SELECT * FROM investments_vc_staging;

UPDATE investments_vc_staging
SET first_funding_at = str_to_date(first_funding_at,'%Y-%m-%d');

ALTER table investments_vc_staging
MODIFY column first_funding_at date; 

UPDATE investments_vc_staging
SET last_funding_at = str_to_date(last_funding_at,'%Y-%m-%d');

ALTER table investments_vc_staging
MODIFY column last_funding_at date; 

UPDATE investments_vc_staging
SET MARKET = 'OTHER'
WHERE MARKET='';

UPDATE investments_vc_staging
SET market = TRIM(market);

UPDATE investments_vc_staging
SET state_code = 'OUT OF USA'
WHERE state_code='';


-- Removing columns that will not be used in the meantime 

ALTER table investments_vc_staging
DROP column post_ipo_equity, 
DROP column post_ipo_debt,
DROP column product_crowdfunding,
DROP column secondary_market;



-- EDA



-- What startups were funded the most In order?
SELECT name, funding_total_usd
FROM investments_vc_staging
ORDER BY funding_total_usd DESC;

-- What markets got funded the most?
SELECT market, SUM(funding_total_usd) as total_fund
FROM investments_vc_staging
GROUP BY market
ORDER BY total_fund DESC;

-- How many startups are in each sector ?
SELECT market, COUNT(name) as num_of_startups
FROM investments_vc_staging
GROUP BY market
ORDER BY num DESC;

-- How many startups in each sector and how much each sector got funded?
SELECT market, SUM(funding_total_usd) as total_fund,  COUNT(name) as num_of_startups
FROM investments_vc_staging
GROUP BY market
ORDER BY total_fund DESC;
 -- Biotechnology  Clean Technology  Software 

 -- Top 5 startups funded in Biotech sector
SELECT name, funding_total_usd
FROM investments_vc_staging
WHERE market = ' Software '
ORDER BY funding_total_usd DESC
LIMIT 5;

-- Top 5 startups funded in Biotech sector
SELECT name, funding_total_usd
FROM investments_vc_staging
WHERE market = 'Clean Technology'
ORDER BY funding_total_usd   DESC
LIMIT 5;

-- Top 5 startups funded in Software sector
SELECT name, funding_total_usd
FROM investments_vc_staging
WHERE market = 'Software'
ORDER BY funding_total_usd   DESC
LIMIT 5;

-- Top 5 startups funded in All sectors
SELECT name, market, funding_total_usd
FROM investments_vc_staging
ORDER BY funding_total_usd   DESC
LIMIT 5;

SELECT * FROM investments_vc_staging;

-- How many closed startups in each sector and how much each sector lost funded money as the business was closed?
SELECT market, SUM(funding_total_usd) as total_fund,  COUNT(name) as num_of_startups
FROM investments_vc_staging
WHERE status='closed'
GROUP BY market
ORDER BY total_fund DESC;

-- Top 5 closed startups funded in All sectors
SELECT name, market, funding_total_usd
FROM investments_vc_staging
WHERE status='closed'
ORDER BY funding_total_usd DESC
LIMIT 5;

-- Top countries with the most funded closed startups
SELECT country_code, market, SUM(funding_total_usd) as total_fund,  COUNT(name) as num_of_startups
FROM investments_vc_staging
WHERE status='closed'
GROUP BY Country_code, market
ORDER BY total_fund DESC;

-- Top states in USA that their startups got funded the most
SELECT state_code, SUM(funding_total_usd) as total_fund
FROM investments_vc_staging
GROUP BY state_code
ORDER BY total_fund DESC;

-- Top years that got the most funded money
SELECT YEAR(first_funding_at), SUM(funding_total_usd) as total_fund
FROM investments_vc_staging
GROUP BY YEAR(first_funding_at)
ORDER BY total_fund DESC;

-- Startups that got the most fund in 2010
SELECT name, market, funding_total_usd
FROM investments_vc_staging
WHERE YEAR(first_funding_at)=2010
ORDER BY funding_total_usd DESC;

-- Top companies that got funded in the ROUND A and the rest of their total fund
SELECT name, market, round_A, funding_total_usd, (funding_total_usd - round_A) As how_much_fund_they_got_after_round_A
FROM investments_vc_staging 
WHERE round_A != ''
ORDER BY round_A DESC;
