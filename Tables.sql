use covid_world;

############# Creating tables ##############

CREATE TABLE CountryCode SELECT DISTINCT country_region_code, country_region AS country FROM
    global_mobility_report;

CREATE TABLE Cases SELECT location AS country, date, total_cases, new_cases FROM
    `owid-covid-data`;

CREATE TABLE Deaths SELECT location AS country, date, total_deaths, new_deaths FROM
    `owid-covid-data`;

CREATE TABLE Tests SELECT location AS country, date, total_tests, new_tests FROM
    `owid-covid-data`;

CREATE TABLE IsoCode SELECT DISTINCT iso_code, continent, location AS country FROM
    `owid-covid-data`;

CREATE TABLE Response SELECT country, Response_measure, date_start, date_end FROM
    `response_graphs_2020-08-13`;

CREATE TABLE Stringency SELECT location AS country, date, stringency_index FROM
    `owid-covid-data`;

CREATE TABLE TestsUnits SELECT location AS country, date, tests_units FROM
    `owid-covid-data`;

CREATE TABLE TestPerCase SELECT location AS country, date, tests_per_case FROM
    `owid-covid-data`;

CREATE TABLE PositiveRate SELECT location AS country, date, positive_rate FROM
    `owid-covid-data`;

CREATE TABLE Baseline SELECT country_region_code,
    date,
    sub_region_1,
    sub_region_2,
    metro_area,
    iso_3166_2_code,
    census_fips_code,
    retail_and_recreation_percent_change_from_baseline,
    grocery_and_pharmacy_percent_change_from_baseline,
    parks_percent_change_from_baseline,
    transit_stations_percent_change_from_baseline,
    workplaces_percent_change_from_baseline,
    residential_percent_change_from_baseline FROM
    global_mobility_report;
    
############## Data Cleaning ################

#Cleaning cases table
UPDATE cases 
SET 
    total_cases = 0
WHERE
    total_cases = '';
UPDATE cases 
SET 
    new_cases = 0
WHERE
    new_cases = '';

# Cleaning response table
DELETE FROM response 
WHERE
    country = 'Country';
UPDATE response 
SET 
    date_end = '2020-08-01'
WHERE
    date_end = 'NA';
ALTER TABLE response
MODIFY COLUMN date_end date;
ALTER TABLE response
MODIFY COLUMN date_start date;