/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types, Creating Procedures
*/

-- Maximum number of cases and deaths recorded in a day in India

      SELECT location, isnull((max(convert(int,new_deaths))),0) AS highest_daily_death, max(new_cases) AS highest_daily_case
      FROM CovidDeaths
      WHERE location LIKE 'India'
      GROUP BY location;
   
-- Cumulative total of deaths and cases recorded in India
  --[deaths]

      SELECT location, convert(date,date) AS date,isnull((max(convert(int,new_deaths))),0)AS highest_daily_deaths 
      FROM CovidDeaths
      WHERE location LIKE 'India'
      GROUP BY location,date
      ORDER BY highest_daily_deaths desc;

  --[cases]

      SELECT location, convert(date,date) AS date, max(new_cases) AS highest_daily_cases
      FROM CovidDeaths
      WHERE location LIKE 'India'
      GROUP BY location,date
      ORDER BY highest_daily_cases desc;

-- Maximum number of cases and deaths recorded in a day in the World

	SELECT location, isnull((max(new_cases)),0) AS Total_cases ,isnull((max(convert(int,new_deaths))),0)AS Total_deaths
        FROM CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location
	ORDER BY Total_cases desc,Total_deaths desc;

-- Total number of vaccinations recorded in the World per country

	SELECT distinct(d.location)
		,SUM(convert(int,new_vaccinations)) OVER(PARTITION BY d.location )AS Total_Vaccinations
	FROM CovidDeaths AS d
        JOIN CovidVaccinations AS v 
                  ON d.location = v.location AND d.date = v.date
	WHERE v.new_vaccinations IS NOT NULL AND d.continent IS NOT NULL
	GROUP BY d.location,new_vaccinations
	ORDER BY location;  -- Total_Vaccinations desc(choose any one)

--Looking at the running total number of vaccinations recorded
 
 -- [India]

		SELECT  location,convert(date,date) AS Date,isnull((new_vaccinations),0) AS New_vaccinations,
					isnull((SUM(convert(int,new_vaccinations)) OVER(PARTITION BY location ORDER BY location, date) ),0) AS New_vaccinations_running_total
		FROM  CovidVaccinations 
		WHERE continent IS NOT NULL
			 AND location LIKE 'India'
			 AND new_vaccinations is not null
		ORDER BY 2;

  --[World]

	       SELECT location,date,isnull(new_vaccinations,0) AS New_vaccinations,
		      isnull((SUM(convert(int,new_vaccinations)) OVER(PARTITION BY location ORDER BY date )),0) AS New_vaccinations_running_total
	       FROM  CovidVaccinations  
	       WHERE  continent IS NOT NULL AND new_vaccinations IS NOT NULL
	       GROUP BY location,date,new_vaccinations
	       ORDER BY location,date;

-- Countries with Total Cases, Deaths and Vaccinations count

 	   SELECT location, max(convert(int, total_deaths)) AS Total_deaths,max(cast(total_cases AS int)) AS Total_cases,
				(SELECT SUM(convert(bigint,new_vaccinations)) FROM CovidVaccinations AS v WHERE v.location = d.location) AS Total_vaccinations
	   FROM CovidDeaths AS d
	   WHERE continent IS NOT NULL 
	   GROUP BY location
	   ORDER BY Total_cases desc;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
	--[World]

		SELECT location,convert(date,date) as date,  isnull(total_cases,0)AS Daily_cases, isnull(total_deaths,0) AS Daily_deaths,
			   isnull(((total_deaths/total_cases*100)),0) AS Daily_Death_Percentage
		FROM CovidDeaths 
		WHERE continent IS NOT NULL
		ORDER BY location,date;

	--[India]

		SELECT location,date, isnull(total_cases,0)AS Daily_cases, isnull(total_deaths,0) AS Daily_deaths,
				isnull(((total_deaths/total_cases*100)),0) AS Daily_Death_Percentage
		FROM CovidDeaths 
		WHERE  location in ('United States','india')
		ORDER BY location,date;

-- Total Cases vs Population
-- Shows what percentage of population have infected with Covid in India

	SELECT location,date,total_cases,population,(total_cases/population)* 100 AS Infected_rate
	FROM CovidDeaths
	WHERE location LIKE 'india'
	ORDER BY date;

-- Looking at the infected rate per country 

	SELECT distinct(location),population, SUM(new_cases) AS Total_cases,
               SUM(new_cases)/population *100 AS Infected_rate_cases, isnull((SUM(convert(int,new_deaths))),0) AS total_deaths,
               ISNULL(((SUM(convert(int,new_deaths))/(population)) *100),0) AS Infected_rate_deaths
        FROM CovidDeaths
        WHERE continent IS NOT NULL AND new_cases IS NOT NULL
        GROUP BY location, population
        ORDER BY location;

-- Global numbers

        SELECT  SUM(new_cases)AS Total_cases,SUM(convert(int,new_deaths)) AS Total_deaths
               ,SUM(convert(int,new_deaths)) /SUM(new_cases)*100 AS Global_infection_rate
        FROM CovidDeaths
        WHERE continent IS NOT NULL;

--Looking at the Death percentage per country

        SELECT  distinct(location),isnull((SUM(new_cases)),0)AS Total_cases,isnull((SUM(convert(int,new_deaths))),0) AS Total_deaths
               ,isnull((SUM(convert(int,new_deaths)) /SUM(new_cases)*100),0) AS Death_rate
        FROM CovidDeaths
        WHERE continent IS NOT NULL 
        GROUP BY location
        ORDER BY Total_cases desc;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
	--[India]

	SELECT d.location,d.population,convert(date,d.date) as date,v.new_vaccinations 
			   ,SUM(convert(int ,v.new_vaccinations))OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS Running_Total_new_vaccinations,
			   SUM(convert(int,v.new_vaccinations))OVER(PARTITION BY d.location ORDER BY d.location,d.date)/population *100 AS Vaccinations_rate
	FROM (SELECT location, date, new_vaccinations FROM CovidVaccinations) AS v
			 JOIN CovidDeaths AS d
			 ON d.date = v.date AND d.location = v.location
	WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL
			  AND d.location LIKE '%india%'
	ORDER BY d.location, d.date; 

	--[World]

		SELECT d.location,d.population,d.date,v.new_vaccinations 
		 	   ,SUM(convert(int ,v.new_vaccinations))OVER (PARTITION BY d.location order by d.location,d.date) as Running_Total_new_vaccinations,
			   SUM(convert(int,v.new_vaccinations))OVER(PARTITION BY d.location order by d.location,d.date)/population *100 as Vaccinations_rate
		FROM (select location, date, new_vaccinations from CovidVaccinations) as v
			JOIN CovidDeaths as d
			ON d.date = v.date AND d.location = v.location
		WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL
		ORDER BY d.location, d.date; 

-- Total Tests vs Vaccinations
-- Shows covid tests percentage against poulation

        WITH tests AS (
		SELECT d.location,d.date,(d.population) ,SUM(convert(int,new_tests))OVER (PARTITION BY d.location ORDER BY d.date) AS total_tests
		FROM CovidVaccinations AS v  right JOIN CovidDeaths AS d ON v.location = d.location AND v.date = d.date
 		WHERE d.continent IS NOT NULL AND new_tests IS NOT NULL
 		GROUP BY d.location,population,d.date,new_tests
		)

		  SELECT *,isnull((total_tests/population*100 ),0)AS Test_percentage
		  FROM tests
		  ORDER BY location;

-- Total test percentage against population in India

	   WITH tests AS (
		   SELECT distinct(d.location),d.population ,SUM(convert(int,new_tests))OVER() AS Total_test
		   FROM CovidVaccinations AS v  RIGHT JOIN CovidDeaths AS d ON v.location = d.location AND v.date = d.date
		   WHERE d.location LIKE 'india'
		   GROUP BY d.location,new_tests,population
	   )
		 SELECT *,total_test/population*100 AS Test_percentage
		 FROM tests;

-- Created a view to store average and aggregate number of cases,deaths,vaccines and tests per country

	IF EXISTS(SELECT * FROM sys.views WHERE NAME = 'CovidData')
	DROP VIEW CovidData
	GO
	CREATE VIEW  dbo.CovidData AS (
	SELECT  d.location,population,
			isnull((SUM(cast(new_cases as int))),0) AS Total_cases,
			coalesce((AVG(cast(new_cases as int))),0) AS Avg_cases,
			isnull((SUM(convert(int,new_deaths))),0) AS Total_deaths,
			isnull((AVG(convert(int,new_deaths))),0) AS Avg_deaths,
			coalesce((SUM(convert(int,new_vaccinations))),0) AS Total_vaccines,
			isnull((AVG(convert(int,new_vaccinations))),0) AS Avg_vaccines,
			isnull((SUM(convert(int,new_tests))),0) AS Total_tests,
			coalesce((AVG(convert(int,new_tests))),0) AS Avg_tests,
			 isnull((SUM(new_cases)/population *100),0) AS Infected_rate
			,isnull((SUM(convert(int,new_deaths)) /SUM(new_cases)*100),0) AS Death_percentage
	FROM [dbo].[CovidDeaths] AS d JOIN [dbo].[CovidVaccinations] AS v
	ON d.location = v.location and d.date = v.date
	WHERE d.continent is not null-- and new_cases is not null--and d.location like 'india'
	GROUP BY d.location,population
	)
	GO

	SELECT * FROM CovidData ORDER BY Total_cases DESC;	

--Created a procedure that returns monthy and yearly covid data of countries.

	IF EXISTS(SELECT * FROM SYS.procedures WHERE NAME = 'Covid_data')
	DROP PROC Covid_data
	GO
	CREATE PROC Covid_data (@location_name varchar(50),@month_name varchar(20) = NULL) AS 
	BEGIN
	 IF EXISTS(SELECT * FROM CovidDeaths WHERE location = @location_name)
		BEGIN
		  IF EXISTS(SELECT * FROM CovidDeaths WHERE location = @location_name AND datename(month,date) = @month_name)
			BEGIN
				WITH covid_data AS 
				(
				SELECT distinct SUM(new_cases) OVER(PARTITION BY YEAR(d.DATE),MONTH(d.DATE),d.location ORDER BY d.location)  AS new_cases_monthy,
						isnull((SUM(convert(int,new_deaths)) OVER(PARTITION BY year(d.date),month(d.date),d.location)),0) AS new_deaths_monthy,
						d.location,
						isnull((SUM(convert(int,new_vaccinations)) OVER(PARTITION BY YEAR(d.DATE),MONTH(d.date),d.location ORDER BY d.location)),0) AS new_vaccine_monthy,
						isnull((SUM(convert(int,new_tests)) OVER(PARTITION BY YEAR(d.date),MONTH(d.DATE),d.location ORDER BY d.location)),0) AS new_tests_monthy
						,SUM(new_cases) OVER(PARTITION BY YEAR(d.DATE),d.location ORDER BY d.location)  AS New_cases_Yearly_total,
						SUM(cast(new_deaths AS int)) OVER(PARTITION BY YEAR(d.DATE),d.location ORDER BY d.location)  AS New_deaths_Yearly_total,
						datename(month,d.date) AS nameofmonth,year(d.date) AS years
						,SUM(convert(bigint,new_vaccinations)) OVER(PARTITION BY YEAR(d.DATE),d.LOCATION ORDER BY d.LOCATION)  AS New_vaccine_Yearly_total,
					SUM(cast(new_tests AS bigint)) OVER(PARTITION BY YEAR(d.DATE),d.LOCATION ORDER BY d.LOCATION)  AS New_tests_Yearly_total
				FROM CovidDeaths AS d JOIN CovidVaccinations AS v ON d.location = v.location AND d.date = v.date 
 
				) SELECT location,years,nameofmonth,new_cases_monthy,new_deaths_monthy,new_vaccine_monthy,new_tests_monthy,
													New_cases_Yearly_total,New_deaths_Yearly_total
													,isnull(New_vaccine_Yearly_total,0) AS New_vaccine_Yearly_total ,
													isnull(New_tests_Yearly_total,0) AS New_tests_Yearly_total
				FROM covid_data
				WHERE location = @location_name AND nameofmonth = @month_name OR @month_name IS NULL
				ORDER BY location,years
			END
			ELSE
				BEGIN
				   WITH covid_data AS 
						(
					SELECT distinct SUM(new_cases) OVER(PARTITION BY YEAR(d.DATE),MONTH(d.DATE),d.location ORDER BY d.location)  AS new_cases_monthy
					,coalesce((SUM(new_cases) over(partition by  month(d.date),year(d.date))/population*100),0) as new_case_monthy_percentage,
						isnull((SUM(convert(int,new_deaths)) OVER(PARTITION BY year(d.date),month(d.date),d.location)),0) AS new_deaths_monthy
						,coalesce((SUM(convert(int,new_deaths)) over(partition by  month(d.date),year(d.date))/population*100),0) as death_case_monthy_percentage,				
						isnull((SUM(convert(int,new_vaccinations)) OVER(PARTITION BY YEAR(d.DATE),MONTH(d.date),d.location ORDER BY d.location)),0) AS new_vaccine_monthy,
						isnull((SUM(convert(int,new_tests)) OVER(PARTITION BY YEAR(d.date),MONTH(d.DATE),d.location ORDER BY d.location)),0) AS new_tests_monthy
						,datename(month,d.date) AS nameofmonth,year(d.date) AS years,d.location,datepart(MONTH,d.date) as monthnumber
					FROM CovidDeaths AS d JOIN CovidVaccinations AS v ON d.location = v.location AND d.date = v.date 
					
						)
						SELECT location,years,nameofmonth,new_cases_monthy,new_case_monthy_percentage,new_deaths_monthy,death_case_monthy_percentage
						,new_vaccine_monthy,new_tests_monthy
						FROM covid_data
						where location = @location_name
						order by location,years,monthnumber

					END

			END
	 ELSE
		  BEGIN
			 SELECT @location_name + ' covid data is not available'
		  END
	END;

	Execute Covid_data 'united states','January'
	Execute Covid_data 'india'
