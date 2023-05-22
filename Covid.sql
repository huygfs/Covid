USE COVID

SELECT *
FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3,4
--SELECT *
--FROM CovidVaccinations$
--WHERE continent IS NOT NULL
--ORDER BY 3,4

--SELECT DATA THAT WE ARE GOING TO BE USING

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2

ALTER TABLE CovidDeaths$
ALTER COLUMN total_deaths FLOAT
ALTER TABLE CovidDeaths$
ALTER COLUMN total_cases FLOAT
ALTER TABLE CovidDeaths$
ALTER COLUMN new_deaths INT
ALTER TABLE CovidVaccinations$
ALTER COLUMN new_vaccinations INT
ALTER TABLE CovidDeaths$
ALTER COLUMN date DATE

-- LOOKING AT TOTAL CASES VS TOTAL DEATHS
-- SHOWS LIKELIHOOD OF DYING IN VIETNAM
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathsCasesPercentage
FROM CovidDeaths$
WHERE location = 'Vietnam'
ORDER BY 2

-- LOOKING AT TOTAL CASES VS POPULATION
-- SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID
SELECT location,date,population,total_cases, (total_cases/population)*100 AS InfectionsPercentage
FROM CovidDeaths$
WHERE location = 'Vietnam'
ORDER BY 2

-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location,population,MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS InfectionPercentage
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY InfectionPercentage DESC

--SHOW COUNTRIES WITH TOTAL DEATH COUNT
SELECT location,MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--SHOWS CONTINENT WITH TOTAL DEATH COUNT
SELECT continent, MAX(total_deaths) AS TotalDeathContinentCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathContinentCount DESC


-- GLOBAL NUMBERS

SELECT date,SUM(new_cases) AS NewCasesTotal, SUM(new_deaths) AS NewDeathsTotal,
(CASE
	WHEN SUM(new_cases) IS NULL OR SUM(new_cases) = 0 OR SUM(new_deaths) IS NULL THEN NULL
	ELSE (SUM(new_deaths)/SUM(new_cases))*100 
END) AS DeathPercentage
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY DATE
ORDER BY 1


-- lOOKING AT TOTAL POPULATION VS VACCINATIONS
SELECT D.continent,D.location,D.date,D.population,V.new_vaccinations
,SUM(
(CASE
	WHEN V.new_vaccinations IS NULL THEN 0
	ELSE V.new_vaccinations
END)) OVER (PARTITION BY D.location ORDER BY D.location,D.date)
AS RollingPeopleVaccinated
FROM
(
	SELECT continent, location,date,population
	FROM CovidDeaths$
	WHERE continent IS NOT NULL
) D
JOIN 
(
	SELECT location,date,new_vaccinations
	FROM CovidVaccinations$
) V
ON D.location = V.location
AND D.date = D.date
ORDER BY 2,3

-- USE CTE = COMMON TABLE EXPRESSION
WITH POPVSVAC(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(SELECT TOP 1000000 D.continent,D.location,D.date,D.population,V.new_vaccinations
,SUM(
(CASE
	WHEN V.new_vaccinations IS NULL THEN 0
	ELSE V.new_vaccinations
END)) OVER (PARTITION BY D.location ORDER BY D.location,D.date)
AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths$ D
JOIN CovidVaccinations$ V
ON D.location = V.location
AND D.date = D.date
WHERE D.continent IS NOT NULL
-- BECAUSE THE TABLE HAS OVER 2 MILLIONS ROWS
AND V.new_vaccinations IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM POPVSVAC

-- CREATE VIEW FOR LATER VISUALIZATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT D.continent,D.location,D.date,D.population,V.new_vaccinations
,SUM(
(CASE
	WHEN V.new_vaccinations IS NULL THEN 0
	ELSE V.new_vaccinations
END)) OVER (PARTITION BY D.location ORDER BY D.location,D.date)
AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths$ D
JOIN CovidVaccinations$ V
ON D.location = V.location
AND D.date = D.date
WHERE D.continent IS NOT NULL