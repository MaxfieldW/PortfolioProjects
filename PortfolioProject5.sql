# ScriptName:	PortfolioProject5
# Created on:	December 31st, 2023
# Author:		Christian Maxfield Welshinger
# Purpose:	    Create tables that can be exported to Tableau Public and made into a dashboard consisting of a world map and other 
#               data visualizations. While being distinct from PortfoliProject4,
#               this project does build off some of the queries that were tested and tables created in that project.
#               Additionally, some of the tables created in PortfolioProject1 will be referenced to join our
#               continental and regional data
# Last Update:	January 2, 2024
# Execution		Data can be imported from Kaggle and script can be directly run with MYSQL using the table name of "exlang"
#               The original dataset on Kaggle is called "Extinct Languages" -- Additionally, you will need a table, which here
#               I have named "Numbers" with one column, spanning the values of 1 to 29 inclusive. There are a number of 
#               tables referenced or reused from projects 1 and 4. The tables generated here can be 
#               exported to Tableau for visualization.

# Create the schema used to store tables for this project. This is slightly anecdotal, but
# this project is 5_2 as this project required two iterations, and was complex enough to require maintining the 
# the first one, but 5_2 is the final project


create schema PortfolioProject5;

# set the schema as the working portfolio

use PortfolioProject5_2;

# First, we're going to copy over the corrected exlang table from PortfolioProject1

create table exlangCorrected
as
select * from PortfolioProject1.exlang;

# We'll rename the "LanguageName" column to "Language" for easier reference

alter table exlangcorrected
rename column LanguageName to Language;

# For our join to work correctly, there needs to be a value in the countries column for each language. Let's make sure
# that there are no null values or blank strings

select * from exlangCorrected
where countries is null;

select * from exlangCorrected
where countries = '';

# Boro has a null value for country. This will cause a problem in our joins. 
# We'll use the latitude and longitude data to figure out what value should go in countries

select latitude, longitude from exlangcorrected
where id = 1680;

# Using Google Maps, we find that it should read "Ethiopia" -- we will fix that value now

# As we've seen in prior projects, this allows us to update values

SET SQL_SAFE_UPDATES = 0;

UPDATE exlangcorrected
set countries = "Ethiopa" where id = 1680;

# Additionally, we need to figure out what the country code should be. We'll find that with the 
# country regions table

# We'll first create it as a copy from PortfolioProject1

create table countryregions
as
select * from PortfolioProject1.countryregions;

 Select * from countryregions
 where Country = 'Ethiopia';
 
 # We see that the alpha code should read 'ETH' -- This needs to be corrected for our join to occur properly

UPDATE exlangcorrected
set CountryCodesAlpha3 = "ETH" where id = 1680;

# Copy over our numbers table for the join from Project 4

create table numbers
as
select * from PortfolioProject4.numbers;

# Create the table with the split countries column. Unlike project 4, we will include the language ID in this 
# table. This will allow us to join the continent and regions data to this table

create table IDLangCountry
as

with idlangcount as
(
select ID, Language, countries
from exlangcorrected
)
select ID, Language,
SUBSTRING_INDEX(SUBSTRING_INDEX(idlangcount.Countries, ',', numbers.n), ',', -1) Country
from numbers inner join idlangcount
on  CHAR_LENGTH(idlangcount.Countries) - CHAR_LENGTH(REPLACE(idlangcount.Countries, ',', '')) >= numbers.n-1
;

# Check that the table looks correct

select * from idlangcountry;

# Our countries column has blank spaces at the beginning. This may cause an issue when we import into Tableau. We'll
# fix that now, and we'll also rename the table to reflect what visualization this table will be used for

create table LanguagesByCountry
as
select ID, Language, trim(Country) as Country
from idlangcountry;

# See how many distinct countries we have in our original table. This is possible to do now that we have split the rows
# into separate records

select count(distinct country) from LanguagesByCountry;

# Run a few tests to make sure it is correct. There should be 29 countries where Romani is spoken, as seen in prior projects.

select count(*) from LanguagesByCountry
where language = 'Romani';

# Additionally, we know that there should be 2722 distinct languages. We will count the IDs, because as we saw
# in PortfolioProject4, 7 langauges have the same name as another 7 languages (their associated countries led us 
# to be confident that they were in fact distinct langauges that simply had the same name, they were thus not duplicates
# and should therefore be kept)

select count(distinct id) from LanguagesByCountry;

# Now we'll create our table for visualizing languages by continent. We'll include a few other columns
# in case they become useful for other visualizations. We need the unique
#  langauge values for this (for this visualization we don't need the complete split data, because 
#  we're not grouping by country.

CREATE TABLE LanguageByContinent 
AS
select ID, Language, Countries, e.CountryCodesAlpha3, Region, Continent, EndangermentLevel, RemainingSpeakers
from exlangcorrected e
join
countryregions c
on (substr(e.CountryCodesAlpha3, 1, 3) = c.ISO);

# Verify that all languages are present

select count(*) from LanguageByContinent;

# Create a table summarizing the data totaling the total languages, total tables, total extinct languages, 
# and total endangered languages. We will use subqueries in the select statement to pull data from 
# the exlangcorrected table as well

CREATE TABLE TotalsTable
as
select count(distinct id) as TotalLanguages, (select count(distinct country) from LanguagesByCountry) as TotalCountries, 
(select count(id) from exlangcorrected
where endangermentlevel = 'Extinct') as ExtinctLangauges, (select count(id) from exlangcorrected where endangermentlevel != 'Extinct') as EndangeredLanguages
from LanguageByContinent;

# Now simply run a select all on three table to export them to JSON for import into Tableau. We will rename the 
# LanguageByContinent table to LanguagesByContinent to stick with the plural grammar 

rename table LanguageByContinent to LanguagesByContinent;

select * from LanguagesByContinent;

select * from LanguagesByCountry;

select * from TotalsTable;

# Please view the Tableau Visualization at the following URL: 

# 				https://public.tableau.com/app/profile/max.welshinger/viz/ExtinctEndangeredLanguages_17040753381050/Dashboard1?publish=yes



