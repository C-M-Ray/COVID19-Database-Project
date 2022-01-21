use covid_world;

#1
Select distinct country
from isocode
where continent = "Asia";

#2
select distinct country
from cases
where country in
	(select country 
    from isocode
    where continent in ("Asia", "Europe"))
and 
total_cases > 10
and
date = "2020-04-01";

#3
select distinct country
from cases
where country in
	(select country 
    from isocode
    where continent = "Africa")
and 
total_cases < 10000
and
date between "2020-04-01" and "2020-04-20";

#4
select distinct country , sum(total_tests) as sumtests
from tests
group by country
having sumtests = 0;

#5
Select year(date), monthname(date), sum(new_cases) 
from cases
where country in (
select country 
from isocode
where continent != '')
group by year(date), month(date)
order by year(date), month(date);

#6
SELECT c1.continent, year(c2.date) as year, month(c2.date) as month, sum(new_cases) as "new cases"
FROM isocode c1, cases c2
WHERE c1.country = c2.country
AND c1.continent != ""
group by continent, year(date), month(date)
order by continent, year(date) asc, month(date); 

#7
SELECT distinct country
from response
where country in("Austria","Belgium","Bulgaria","Croatia","Cyprus",
"Czechia","Denmark","Estonia","Finland","France","Germany","Greece",
"Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg","Malta","Netherlands",
"Poland","Portugal","Romania","Slovakia","Slovenia","Spain","Sweden")
AND 
Response_measure LIKE ("%mask%");

#8
CREATE TABLE qn8 
  (date DATE UNIQUE, 
    counter INT
);

DELIMITER $$ 
CREATE PROCEDURE CountMask( 
 IN startDate DATE, 
 IN endDate DATE) 
BEGIN 
  WHILE startDate <= endDate DO
    SET @counter = 0;
    SELECT count(*) INTO @counter
            FROM response
            WHERE country in ("Austria","Belgium","Bulgaria","Croatia",
            "Cyprus","Czechia","Denmark","Estonia","Finland","France",
            "Germany","Greece","Hungary","Ireland","Italy","Latvia",
            "Lithuania","Luxembourg","Malta","Netherlands","Poland",
            "Portugal","Romania","Slovakia","Slovenia","Spain","Sweden")
            AND startDate >= date_start
            AND startDate <= date_end
            AND response_measure = "MasksMandatory";
        INSERT INTO qn8(date, counter) VALUES (startDate, @counter); 
    SET startDate = DATE_ADD(startDate, interval 1 day);
  END WHILE;
END $$
DELIMITER ;

## find earliest start date of MasksMandatory
SELECT MIN(date_start) as earliest_start
FROM response
WHERE country in (select country where country in("Austria","Belgium",
"Bulgaria","Croatia","Cyprus","Czechia","Denmark","Estonia","Finland",
"France","Germany","Greece","Hungary","Ireland","Italy","Latvia",
"Lithuania","Luxembourg","Malta","Netherlands","Poland","Portugal",
"Romania","Slovakia","Slovenia","Spain","Sweden"))
AND response_measure = "MasksMandatory"; 

## find latest end date of MaskMandatory
SELECT MAX(date_end) as latest_end
FROM response
WHERE country in (select country where country in("Austria","Belgium",
"Bulgaria","Croatia","Cyprus","Czechia","Denmark","Estonia","Finland",
"France","Germany","Greece","Hungary","Ireland","Italy","Latvia",
"Lithuania","Luxembourg","Malta","Netherlands","Poland","Portugal",
"Romania","Slovakia","Slovenia","Spain","Sweden"))
AND response_measure = "MasksMandatory"; 

## range: 2020-03-12 to 2020-08-07
CALL CountMask('2020-03-12', '2020-08-07');

	SELECT  *
	FROM qn8
	WHERE counter in (
		SELECT max(counter)
		FROM qn8);

#9
CREATE TABLE qn9(
	dates DATE UNIQUE,
	europe INT,
	north_america INT);

DELIMITER $$

CREATE PROCEDURE CountNewCases(	
	IN startDate DATE,
	IN endDate DATE)
BEGIN
	WHILE startDate<=endDate DO
		SET @cases_eu = 0;
        SELECT sum(new_cases) INTO @cases_eu
			FROM cases
			WHERE date = startDate
			AND country in (SELECT country FROM isocode 
            where country in 
            (select country from isocode where continent = "Europe"));
		SET @cases_NA = 0;
		SELECT sum(new_cases) INTO @cases_na
			FROM cases
			WHERE date = startDate
			AND country in (SELECT country FROM isocode 
            where country in (select country from isocode 
            where continent = "North America"));
        INSERT INTO qn9 (dates, europe, north_america) 
        VALUES (startDate, @cases_eu, @cases_na);
        SET startDate = date_add(startDate, interval 1 day);
	END WHILE;
END $$
DELIMITER ;

# Call the procedure
CALL CountNewCases("2020-07-01", "2020-07-06");
CALL CountNewCases("2020-07-25", "2020-08-01"); 

SELECT * 
FROM qn9;

#10
CREATE TABLE qn10(
	country VARCHAR(45), 
    date DATE,
    consecdayswith0cases INT, 
    new_cases INT, 
    total_cases INT); 

INSERT INTO qn10(country, consecdayswith0cases, date, new_cases, total_cases)
	(SELECT distinct(cases.country) as country, 
			(CASE WHEN new_cases = 0 THEN @flatten:= @flatten +1
				ELSE @flatten := 0 END) as consecdayswith0cases, 
			date, 
            new_cases, 
            total_cases
	FROM cases
	WHERE total_cases > 50);

SELECT distinct country 
FROM qn10
WHERE consecdayswith0cases >= 14
AND country not in ("World")
ORDER BY country;

#11
CREATE VIEW flatten_days AS
	(SELECT distinct country, date
	FROM qn10
	WHERE consecdayswith0cases >= 14
	AND country not in ("World")
	GROUP BY country, date
	ORDER BY country);

CREATE VIEW rolling_sum AS
	(SELECT x.*,
		   sum(sum_new) over(partition by country order by country, 
           date rows between 6 preceding and current row) as roll_sum
	FROM (SELECT country, date, sum(new_cases) as sum_new
		  FROM cases
		  GROUP BY country, date) x);

SELECT distinct b.country
FROM rolling_sum a, flatten_days b
WHERE a.country = b.country
AND a.date >= b.date
AND a.roll_sum > 50;

#12
## changes for retail and recreation
SELECT country, max(abs(retail_and_recreation_percent_change_from_baseline)) as max_retail
FROM countrycode
NATURAL JOIN baseline 
WHERE sub_region_1 = ''
GROUP BY country
ORDER BY max_retail DESC
LIMIT 3; 

## changes for grocery and pharmacy
SELECT country, max(abs(grocery_and_pharmacy_percent_change_from_baseline)) as max_grocery
FROM countrycode
NATURAL JOIN baseline 
WHERE sub_region_1 = ''
GROUP BY country
ORDER BY max_grocery DESC
LIMIT 3; 

## changes for parks
SELECT country, max(abs(parks_percent_change_from_baseline)) as max_parks
FROM countrycode
NATURAL JOIN baseline 
WHERE sub_region_1 = ''
GROUP BY country
ORDER BY max_parks DESC
LIMIT 3; 

## changes for transit stations
SELECT country, max(abs(transit_stations_percent_change_from_baseline)) as max_transit
FROM countrycode
NATURAL JOIN baseline 
WHERE sub_region_1 = ''
GROUP BY country
ORDER BY max_transit DESC
LIMIT 3; 

## changes for workplaces
SELECT country, max(abs(workplaces_percent_change_from_baseline)) as max_workplaces
FROM countrycode
NATURAL JOIN baseline 
WHERE sub_region_1 = ''
GROUP BY country
ORDER BY max_workplaces DESC
LIMIT 3; 

## changes for residential
SELECT country, max(abs(residential_percent_change_from_baseline)) as max_residential
FROM countrycode
NATURAL JOIN baseline 
WHERE sub_region_1 = ''
GROUP BY country
ORDER BY max_residential DESC
LIMIT 3; 

# 13 
# find D-day
CREATE VIEW `dday` AS
	(SELECT country, MIN(date) as min_date
	FROM cases
	WHERE total_cases > 20000
	GROUP BY country
    ORDER BY country);

## D-day for indonesia
SELECT *
FROM `dday` 
WHERE country = "Indonesia";

SELECT country, sub_region_1, sub_region_2, metro_area, date,
		retail_and_recreation_percent_change_from_baseline as retail_change, 
		grocery_and_pharmacy_percent_change_from_baseline as grocery_change, 
		workplaces_percent_change_from_baseline as workplaces_change
FROM countrycode
NATURAL JOIN baseline
NATURAL JOIN `dday`
WHERE  date >= min_date
AND sub_region_1 = ''
AND country = "Indonesia"
AND country_region_code = "ID";

