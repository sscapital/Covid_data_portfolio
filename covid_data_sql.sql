--Explore Data and its components

select * from public."COVID_DEATHS" limit 5;
select * from public."COVID_VACCINATIONS" limit 100;

--

select "location", "date",total_cases,new_cases, total_deaths,population
from public."COVID_DEATHS"
order by 1,2;

--Total cases vs total deaths

select "location","date",total_cases,total_deaths,
total_deaths/total_cases*100 as PctDeath
from public."COVID_DEATHS"
where "location" like '%States%'
order by 1,2; 

-- Total cases vs population

select "location", "date", total_cases, population,
(total_cases/population)*100 as Pct_Infect_Pop
from "COVID_DEATHS"
where "location" like '%States%'
order by 1,2

--Countries with Highest Infection Rate vs Population

select "location",max(total_cases) as total_cases,max(population) as population,
(max(total_cases)/max(population)*100) as Pct_Infect_Pop
from "COVID_DEATHS"
group by "location",population
order by 4 DESC;

-- Countries with the highest death count per population

select "location",max(cast(total_deaths as int)) as total_deaths
from "COVID_DEATHS"
where continent is not null and total_deaths is not null
group by "location"
order by 2 DESC;

-- by continent
select "location",max(cast(total_deaths as int)) as total_deaths
from "COVID_DEATHS"
where continent is null and 
"location" not in ('World','European Union','International')
group by "location"
order by 2 DESC;

--PctPopInfected

select "location",population, max(total_cases) as total_cases,
coalesce(max((total_cases/population))*100,0) as "PctPopInfected"
from "COVID_DEATHS"
where continent is not null
group by "location","population"
order by 4 desc;
-- Break Down by Continent

SELECT continent, max(total_deaths) as all_deaths
from public."COVID_DEATHS"
where continent is not null
group by continent
order by 2 desc;

--Group by dates

select "date", sum(new_cases) as cases,sum(new_deaths) as deaths,
sum(new_deaths)/nullif(sum(new_cases),0)*100 as "DeathPct"
from "COVID_DEATHS"
group by "date"
order by "date";

--All Cases

select sum(new_cases) as cases,sum(new_deaths) as deaths,
sum(new_deaths)/nullif(sum(new_cases),0)*100 as "DeathPct"
from "COVID_DEATHS"
where continent is not null;

--Join Two Tables

select * from "COVID_DEATHS" cd
full outer join "COVID_VACCINATIONS" cv
on cd."location"=cv."location" and
cd."date"=cv."date";

select cd."location",max(cd.population) as population,max(cv.total_vaccinations) as vaccinations,
max(cv.total_vaccinations)/max(cd.population)*100 as "VacsPct%"
from public."COVID_DEATHS" cd,public."COVID_VACCINATIONS" cv
where cd."location" = cv."location"
and cd."date" = cv."date"
group by cd."location"
order by "VacsPct%" desc;

-- USE CTE

with PopvsVac (Continent, "Location", "Date", Population, NewVaccinations, TotalVacs)
as
(select cd.continent, cd."location", cd."date",cd.population,cv.new_vaccinations,
sum(cv.new_vaccinations) over (partition by cd."location" order by cd."location",
							  cd."date") as total_vacs
from public."COVID_DEATHS" cd
join public."COVID_VACCINATIONS" cv
on cd."location" = cv."location"
and cd."date" = cv."date"
where cd.continent is not null
--order by 2,3;
)
select *,(TotalVacs/Population)*100 as "%PctVacs" from PopvsVac

--TEMP TABLE
drop table if exists "PercentPopulationVaccinated"
create table if not exists "PercentPopulationVaccinated"
(
	Continent varchar(255),
	"Location" varchar(255),
	"Date" timestamp without time zone,
	Population numeric,
	New_Vaccinations numeric,
	TotalVacs numeric)
insert into "PercentPopulationVaccinated"
(
select cd.continent, cd."location", cd."date",cd.population,cv.new_vaccinations,
sum(cv.new_vaccinations) over (partition by cd."location" order by cd."location",
							  cd."date") as total_vacs
from public."COVID_DEATHS" cd
join public."COVID_VACCINATIONS" cv
on cd."location" = cv."location"
and cd."date" = cv."date")
--where cd.continent is not null
--order by 2,3;
select *,(TotalVacs/Population)*100 as "%PctVacs" from "PercentPopulationVaccinated"


--Create a View to store data for visualization

create view "%PopulationVaccinated" as 
select cd.continent, cd."location", cd."date",cd.population,cv.new_vaccinations,
sum(cv.new_vaccinations) over (partition by cd."location" order by cd."location",
							  cd."date") as total_vacs
from public."COVID_DEATHS" cd
join public."COVID_VACCINATIONS" cv
on cd."location" = cv."location"
and cd."date" = cv."date"
where cd.continent is not null
--order by 2,3;



