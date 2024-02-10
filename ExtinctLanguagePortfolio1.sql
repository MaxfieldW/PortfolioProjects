# ScriptName:	PortfolioProject1
# Created on:	December 18th, 2023
# Author:		Christian Maxfield Welshinger
# Purpose:	    Analyze and clean data pertaining to extinct and endangered languages around the world
# Last Update:	December 26th, 2023
# Execution		Data can be imported from Kaggle and script can be directly run with MYSQL using the table name of "exlang"
#               The original dataset on Kaggle is called "Extinct Languages"
#               The regional and continental data can be imported with the code from PortfolioProject2 in Python

# Set working schema to PortfolioProject1

USE PortfolioProject1;


# Take a look at what columns we have, and how many languages we are dealing with. Get an initial
# idea of the quality and dimensions of the data we are working with

select * from exlang;
select count(*) from exlang;

# Rename columns with spaces to make them easier to query. Drop columns that irrelevant to this particular analysis

ALTER TABLE exlang
RENAME COLUMN `Name in English` TO LanguageName;

ALTER TABLE exlang
RENAME COLUMN `Description of the location` TO LocationDescription;

ALTER TABLE exlang
RENAME COLUMN `ISO639-3 codes` TO ISO6393;

ALTER TABLE exlang
RENAME COLUMN `Degree of endangerment` TO EndangermentLevel;

ALTER TABLE exlang
RENAME COLUMN `Number of speakers` TO RemainingSpeakers;

ALTER TABLE exlang
DROP `Name in French`;

ALTER TABLE exlang
DROP `Name in Spanish`;

ALTER TABLE exlang
DROP Sources;

ALTER TABLE exlang
DROP `Alternate names`;

ALTER TABLE exlang
DROP `Name in the language`;

ALTER TABLE exlang 
RENAME COLUMN `Country codes alpha 3` TO CountryCodesAlpha3;

# Make ID the primary key of the exlang column. This is necessary in order to correct the Belarus country code later on

ALTER TABLE exlang
ADD PRIMARY KEY(ID);

# This will allow us to update values using a non primary key column in the where clause
SET SQL_SAFE_UPDATES = 0;

# We see that the Change RemainingSpeakers column from text to a numeric data type so that our code will correctly operate on this column

ALTER TABLE exlang
modify column RemainingSpeakers int;

# We have run into an error because while some langauges are coded as "0" others are "NONE" We must first convert none to 0

update exlang
set RemainingSpeakers = "0"
where RemainingSpeakers = "NONE";

# Now we can change the data type

ALTER TABLE exlang
modify column RemainingSpeakers int;

# Verify all changes have been made correctly and we are left with the data that we want to work with

select * from exlang;

# We notice that this data includes information about dialects as well
# Let's find the extinct/endangered dialects and languages related to Germany, England, and France

# England may be under a few different names -- We'll try 'England' first
select * from exlang
where countries like '%England%';

# No results rturned. We'll try Britain next
select * from exlang
where countries like '%Britain%';

# Now that we have found the langauges associated with England, or more broadly, Great Britain, we can run our query

select * from exlang
where Countries LIKE '%Germany%' or Countries LIKE '%France%' or  Countries LIKE '%Britain%'
order by Countries;

# Extinct/endangered languages specific to a grouping of neighboring countries

select * from exlang
where Countries LIKE '%India%' and Countries LIKE '%Nepal%';

# Total number of languages by level of endangerement 

select EndangermentLevel, count(ID)
from exlang
group by EndangermentLevel;

# NOTE --- One thing we notice with this data is that each language can be associated with one or more
# countries. This makes sense given the fact that each individual record is a distinct language, and a language
# can be spoken in one more countries. This will present a number of challenges throughout this project, as
# we would like to join this data to a table allowing us to group langauges together by continent and region.
# The countryregions table is what we will join this on to. This table is related to the web scraping Python project
# of this portfolio

# Join the two table, exlang and countryregions, to bring in regional and continental data on each language

select LanguageName, Countries, Country, e.CountryCodesAlpha3, c.ISO, Region, Continent 
from exlang e
join
countryregions c
on (substr(e.CountryCodesAlpha3, 1, 3) = c.ISO)
;

# It appears that Belarus was incorrectly coded or is out of date in the exlang table. 
# ISO-3 code for Belarus is BLR, not BRB (which is Barbados)

# look for Barbados in the countries column.

select * from exlang
where Countries LIKE '%Barbados%';

# There are no endangered languages associated with Barbados. Therefore, BRB, the country
# code for Barbados, should not be in the Alpha list at all. Let's look for it in the exlang table

select * from exlang
where CountryCodesAlpha3
 LIKE '%BRB%';
 
 # We see that all 4 instances of BRB are incorrectly referring to Belarus. Let's fix that so our join will be correct
 
 UPDATE exlang
 set CountryCodesAlpha3 = 'BLR, LTU, POL, RUS, UKR'
 WHERE ID = 335;
 
 UPDATE exlang
 set CountryCodesAlpha3 = 'ALB, DEU, AUT, BLR, BIH, BGR, HRV, EST, FIN, FRA, GRC, HUN, ITA, LVA, LTU, MKD, NLD, POL, ROU, GBR, RUS, SVK, SVN, CHE, CZE, TUR, UKR, SRB, MNE'
 WHERE ID = 405;
 
  UPDATE exlang
 set CountryCodesAlpha3 = 'BLR, LTU, POL, RUS, UKR'
 WHERE ID = 335;
 
  UPDATE exlang
 set CountryCodesAlpha3 = 'DEU, AUT, BLR, BEL, DNK, EST, FIN, FRA, HUN, ITA, LVA, LTU, LUX, MDA, NOR, NLD, POL, ROU, GBR, RUS, SVK, SWE, CHE, CZE, UKR'
 WHERE ID = 428;
 
 UPDATE exlang
 set CountryCodesAlpha3 = 'BLR, POL, UKR'
 WHERE ID = 1523;
 
 # Check to make sure update has been successful
 select * from exlang
where Countries
 LIKE '%Belarus%';

# Now let's make this into a table

CREATE TABLE LanguageRegions AS
 select LanguageName, Countries, Country, e.CountryCodesAlpha3, c.ISO, Region, Continent, EndangermentLevel
from exlang e
join
countryregions c
on (substr(e.CountryCodesAlpha3, 1, 3) = c.ISO)
;

# Double check to make sure that are LanguageRegions table has all the language of our exlang table 
# and that we didn't lose any in the join

# Number of languages we started with
select count(*) from Exlang;

# Number of languages we now have
select count(*) from LanguageRegions;

# It looks like we lost 9 languages in the join
# Check to see that we got all 2722 languages in the first part of our join

Select count(substr(CountryCodesAlpha3, 1, 3)) from exlang;

# We can perform a query with a "NOT IN" statement in our WHERE clause to find which ones we lost

Select substr(CountryCodesAlpha3, 1, 3) as alpha from exlang
WHERE  substr(CountryCodesAlpha3, 1, 3)NOT IN (select ISO from CountryRegions);

# Let's take a close look at what these langauges are and where they are/were spoken

Select * from exlang
WHERE  substr(CountryCodesAlpha3, 1, 3) NOT IN (select ISO from CountryRegions);

# Most are in the Democratic Republic of Congo, and a few are in Angola.

# Let's see if these countries are in our countryregions table

Select * from CountryRegions
where country like '%Democratic%';

Select * from CountryRegions
where country like '%Angola%';

# They are both there. We need to fix the values in our exlang table to update them to be able to join them to the countryregions table

Select * from exlang
where countries like "%Democratic%";

# We see that for all languages but one, the only country in the CountryCodesAlpha3 Column is the DRC (Democratic Republic of the Congo).
# We see that in the original data in the exlang table, the DRC is coded as "ZAI" whereas the correct country code is "COD"
# So those we can fix in the following manner with a subquery: 

select * from exlang
where CountryCodesAlpha3 = 'ZAI';

UPDATE exlang
set CountryCodesAlpha3 = 
		(select ISO from countryregions
		where Country = "Democratic Republic of the Congo")
where Countries = "Democratic Republic of the Congo";

# Now before we move on to fixing Angola, we need to fix the Language that had both the DRC and Sudan

Select * from exlang 
where Countries like "%Democratic Republic of the Congo%";

# We see that it is Boguru, ID 64

UPDATE exlang
set CountryCodesAlpha3 = "COD, SDN"
where ID = 64;

# Although it's not preventing our join from happening correctly, let's fix the DRC for the Yulu language while we notice that it's also coded as ZAI

UPDATE exlang
set CountryCodesAlpha3 = "CAF, COD, SDN"
where ID = 1739;

# Now all the languages associated with the DRC should be fixed. Let's check

Select * from exlang 
where Countries like "%Democratic Republic of the Congo%";

# Next, we will fix Angola. Let's first figure out the incorrect and correct country code

Select * from exlang 
where Countries like "%Angola%";

Select * from countryregions
where Country like "%Angola%";

# The reason we were unable to make the join is that Angola was incorrectly coded as ANG. It needs to be AGO
# Again we will fix with a subquery

UPDATE exlang
set CountryCodesAlpha3 = 
	(select iso from countryregions
	where country = "Angola") 
where countries = "Angola";


# Now let's drop and recreate the joined table

drop table LanguageRegions;

CREATE TABLE LanguageRegions AS
 select LanguageName, Countries, Country, e.CountryCodesAlpha3, c.ISO, Region, Continent, EndangermentLevel, RemainingSpeakers
from exlang e
join
countryregions c
on (substr(e.CountryCodesAlpha3, 1, 3) = c.ISO);

# Now let's compare as before

select count(*) from Exlang;

select count(*) from LanguageRegions;

# Now all languages have been included

# Now let's group by region and and see how many languages there are for each region

select Region, count(Languagename) AS NumberOfLanguages
from LanguageRegions
group by Region;

# We see that there is only one language associated with the Caribbean. What language is it?

select * from LanguageRegions
where Region = 'Caribbean';

# Island Carib is the name of the language, of the island of Dominica

# Languages with under 10,000 speakers not including the extinct languages

select * from LanguageRegions
where remainingspeakers < 10000 and remainingspeakers > 0
order by continent, remainingspeakers desc;

# See how many extinct/endangered languages there are by Continent and Endangerment Level

select continent, endangermentlevel, count(languagename)
from languageregions
group by continent, endangermentlevel
order by 1, 2;

# How many different endangerment levels do we have?

select distinct endangermentlevel
from languageregions;

# We have 5 different levels. Let's simply the data by not having 3 different levels of endangered, so we wanted to regroup these into only 3 levels:
# Vulnerable, Endangered, Extinct. This can be accomplished with a case statement. We'll save this as a view

create view EndangermentRefactored
as
select  LanguageName, Countries, ISO, Region, Continent, RemainingSpeakers,
case
	when endangermentlevel = 'Critically endangered' then 'Endangered'
	when endangermentlevel = 'Severely endangered' then 'Endangered'
	when endangermentlevel = 'Extinct' then 'Extinct'
	when endangermentlevel = 'Definitely endangered' then 'Endangered'
	when endangermentlevel = 'Vulnerable' then 'Vulnerable'
end
as LevelOfEndangerment
from languageregions;

# Now rerun the query to group by continent and level of endangerment. Save as view

create view ContinentalRefactoredTotals
as
select continent, LevelOfEndangerment, count(languagename)
from EndangermentRefactored
group by continent, LevelOfEndangerment
order by 1, 2;

# Let's say that we want to see a table with with each language and the average number of speakers corresponding to the endangerment level
# of each particular language. This can be accomplished with a correlated subquery

select languagename, countries, EndangermentLevel, RemainingSpeakers,
		(select ceil(avg(RemainingSpeakers)) from exlang
		where  EndangermentLevel = e.EndangermentLevel)
 from exlang e;

# Show continents and regions with the 5 highest amount of endangered languages

Select Continent, Region, count(languagename) as NumberOfLanguages
from languageregions
group by Continent, Region
order by NumberOfLanguages desc
limit 5;

#Find a percentage by continent of all different levels of endangerment using a common table expression and join it to the ContinentTotals view. Make this into its own table
# First create view of total langauges extinct/endangered by continent

create view ContinentTotals as

select continent, count(languagename) TotalLanguages
from languageregions
group by continent;

create table EndangermentPercentage
as
with ContinentEndangerment as
(
select continent, EndangermentLevel, count(languagename) as NumberOfLanguages
from languageregions
group by continent, EndangermentLevel
)

select ce.continent, ce.EndangermentLevel, ce.NumberOfLanguages,
 ct.TotalLanguages, (ce.NumberOfLanguages / ct.TotalLanguages) as PercentageOfTotal

from ContinentTotals ct
join
ContinentEndangerment ce
on
ct.continent = ce.continent
order by 1,2;

# Verify that the percentage total adds up to one for each continent by doing a sum/partition by operation
# We will do a rolling total so that if there is an error, it will be more obvious where the error is

select *, sum(PercentageOfTotal) over(partition by continent order by EndangermentLevel) as RollingTotal
 from EndangermentPercentage;
 
 # Now that we know that the numbers are correct, we could make the PercentageOfTotal column look a bit more readable and make it
 # into a view with the following code:
 
 create view EndangermentPercentageByContinent
 as
 Select *, concat(round(PercentageOfTotal * 100, 2), "%") as PercentageOfLevelByContinent
 from endangermentpercentage;
 
 #Put in a view that compares number of languages above and below the equator
 
 CREATE VIEW AboveEquator
 as
 select * from exlang
 where latitude > 0;
 
 CREATE VIEW BelowEquator
 as
  select * from exlang
 where latitude < 0;
  
  # We see many more languages in the Northern Hemisphere table than in the Southern Hemisphere table.
  # Is this simply due to a large difference in population or is there some other factor to explore?
  # Around 850 million people live in Southern Hemisphere, while 6.4 billion live in the Northern Hemisphere
  # Let's calculate a ratio and generate a table
 
 # First create table
 
 create table Hemispheres
 (NameOfHemisphere varchar(20),
 Population long);
 
 insert into Hemispheres
 values ('Northern Hemisphere', 6400000000), ('Southern Hemisphere', 850000000);

 
   select count(*)/
   (select population from hemispheres where nameofhemisphere = 'Northern Hemisphere' ) AS NorthHemProportion
   from aboveequator;
   
     select count(*)/
     (select population from hemispheres where nameofhemisphere = 'Southern Hemisphere' ) AS SouthHemProportion
   from belowequator;
   
   # We see from the two proportions that they are fairly comparable. So the difference in langauges is probably
   # simply due to the large disparity in population between the northern and southern hemispheres
   
