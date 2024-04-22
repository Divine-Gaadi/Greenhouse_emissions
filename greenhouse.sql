--View the table in the database

Select * From greenhouse_gases;

--Get total CO2 emissions by country for year 2020

SELECT country, sum(co2) AS total_co2
FROM greenhouse_gases
WHERE year = 2020
GROUP BY country;

--Compare CO2 emissions from coal, oil, and gas for all countries in year 2020

SELECT country, coal_co2, oil_co2, gas_co2
FROM greenhouse_gases
WHERE year = 2020;

--Find Top 10 countries with the highest methane emissions 2020

SELECT country, methane
FROM greenhouse_gases
WHERE year = 2020
ORDER BY methane DESC
LIMIT 10;

--Track the change in CO2 emissions for United States over the years

SELECT year, co2
FROM greenhouse_gases
WHERE country = 'United States'
ORDER BY year;

--Track the trend of CO2 emissions from cement production over the years for united States

SELECT 
    year,
    cement_co2
FROM greenhouse_gases
WHERE country = 'United States'
ORDER BY year;

--Aggregate total CO2 emissions from all sources for each country over the years

SELECT country, sum(co2 + coal_co2 + cement_co2 + gas_co2 + oil_co2) AS total_emissions
FROM greenhouse_gases
GROUP BY country;

--List the average annual methane emissions for each country across all available years and round to 3 decimal places

SELECT 
    country,
    Round(AVG(methane),3) AS average_methane
FROM greenhouse_gases
GROUP BY country;

--Find the year with the highest total CO2 emissions for each country

SELECT 
    country,
    year,
    MAX(co2) AS max_co2
FROM greenhouse_gases
GROUP BY country, year;

--Calculate the percentage share of each emission type (coal, oil, gas) relative to total CO2 emissions for each country in year 2020

SELECT 
    country,
    Round((coal_co2 / co2 * 100),2) AS coal_percentage,
    Round((oil_co2 / co2 * 100),2) AS oil_percentage,
    Round((gas_co2 / co2 * 100),2) AS gas_percentage
FROM greenhouse_gases
WHERE year = 2020;

--Identify countries where oil-based CO2 emissions exceed those from coal and gas combined in year 2020

SELECT 
    country,
    oil_co2,
    coal_co2 + gas_co2 AS other_co2
FROM greenhouse_gases
WHERE year = 2020 AND oil_co2 > (coal_co2 + gas_co2);


--Determine the growth rate in CO2 emissions from the previous year for each country

WITH yearly_data AS (
    SELECT
        country,
        year,
        co2,
        LAG(co2, 1) OVER (PARTITION BY country ORDER BY year) AS previous_year_co2
    FROM greenhouse_gases
)
SELECT 
    country,
    year,
    co2,
    previous_year_co2,
    Round(((co2 - previous_year_co2) / previous_year_co2 * 100),2) AS growth_rate
FROM yearly_data
WHERE previous_year_co2 IS NOT NULL;



--PART TWO
--QUERYING THE POPULATION TABLE


--View the Population Table

Select * From Population


--Get population and GDP for all countries for year 2020

SELECT country, population, gdp
FROM population
WHERE year = 2020;


--Find countries with GDP greater than 1 trillion in 2020

SELECT country, gdp
FROM population
WHERE year = 2020 AND gdp > 1000000000000; 


--Find the countries with the highest primary energy consumption in 2020

SELECT country, primary_energy_consumption
FROM population
WHERE year = 2020
ORDER BY primary_energy_consumption DESC
LIMIT 10;


--Track the change in GDP for United States over the years

SELECT year, gdp
FROM population
WHERE country = 'United States'
ORDER BY year;


--Calculate the GDP per capita for each country in 2020

SELECT country, (gdp / population) AS gdp_per_capita
FROM population
WHERE year = 2020;


--Calculate the average annual population growth for each country between two specific years

WITH Yearly_Population AS (
    SELECT country, year, population,
    LAG(population) OVER (PARTITION BY country ORDER BY year) AS previous_year_population
    FROM population
)
SELECT 
    country,
    Round(((population - previous_year_population) / previous_year_population * 100),2) AS average_growth_rate
FROM Yearly_Population
WHERE previous_year_population IS NOT NULL;


--Identify the years when a country’s population declined compared to the previous year

WITH Population_Changes AS (
    SELECT country, year, population,
    LAG(population) OVER (PARTITION BY country ORDER BY year) AS previous_year_population
    FROM population
)
SELECT country, year, population
FROM Population_Changes
WHERE population < previous_year_population;



--PART THREE
--JOINING THE GREENHOUSE_GASES TABLE AND THE POPULATION TABLE

SELECT 
    g.country,
    g.year,
    g.co2,
    g.coal_co2,
    g.cement_co2,
    g.gas_co2,
    g.oil_co2,
    g.methane,
    p.population,
    p.gdp,
    p.primary_energy_consumption
	INTO greenhouse_population
FROM 
    greenhouse_gases g
JOIN 
    population p 
    ON g.country = p.country AND g.year = p.year;
	
	
--View the Joined Table

SELECT * FROM greenhouse_population


--List total CO2 emissions alongside GDP and population for all countries for year 2020

SELECT 
    country, 
    year, 
    co2 AS total_co2_emissions,
    population,
    gdp
FROM greenhouse_population
WHERE year = 2020
ORDER BY co2 DESC;


--Compare methane emissions with total CO2 emissions for each country in the latest available year

SELECT 
    country,
    year,
    methane,
    co2,
    (methane / co2) AS methane_to_co2_ratio
FROM greenhouse_population
WHERE year = 2020;


--Calculate CO2 emissions per capita and GDP per capita for year 2020, ordered by highest CO2 per capita

SELECT 
    country, 
    year,
    co2,
    population,
    gdp,
    (co2 / population) AS co2_per_capita,
    (gdp / population) AS gdp_per_capita
FROM greenhouse_population
WHERE year = 2020
ORDER BY co2_per_capita DESC;


--Identify countries with the highest increase in CO2 emissions compared to the previous year

WITH CO2_Delta AS (
    SELECT 
        country,
        year,
        co2,
        LAG(co2) OVER (PARTITION BY country ORDER BY year) AS previous_year_co2,
        co2 - LAG(co2) OVER (PARTITION BY country ORDER BY year) AS co2_increase
    FROM greenhouse_population
)
SELECT 
    country,
    year,
    co2,
    previous_year_co2,
    co2_increase
FROM CO2_Delta
WHERE co2_increase IS NOT NULL
ORDER BY co2_increase DESC;


--Analyze the correlation between GDP growth and CO2 emissions growth over the past decade

WITH GDP_CO2_Growth AS (
    SELECT 
        country,
        year,
        co2,
        gdp,
        LAG(co2) OVER (PARTITION BY country ORDER BY year) AS prev_co2,
        LAG(gdp) OVER (PARTITION BY country ORDER BY year) AS prev_gdp,
        (co2 - LAG(co2) OVER (PARTITION BY country ORDER BY year)) / LAG(co2) OVER (PARTITION BY country ORDER BY year) * 100 AS co2_growth_percent,
        (gdp - LAG(gdp) OVER (PARTITION BY country ORDER BY year)) / LAG(gdp) OVER (PARTITION BY country ORDER BY year) * 100 AS gdp_growth_percent
    FROM greenhouse_population
    WHERE year >= 2010
)
SELECT 
    country,
    year,
    co2_growth_percent,
    gdp_growth_percent
FROM GDP_CO2_Growth
WHERE prev_co2 IS NOT NULL AND prev_gdp IS NOT NULL
ORDER BY co2_growth_percent DESC, gdp_growth_percent DESC;
