# ScriptName:	PortfolioProject4
# Created on:	December 21st, 2023
# Author:		Christian Maxfield Welshinger
# Purpose:	    The main purpose of this project is to separate the records of the extinct languages
#               table into unique pairings of Langauge and Country (at present the country column contains multiple values in a single cell)
#               The table that is generated from this split will then be used to generate a visualization
# Last Update:	December 29th, 2023
# Execution		Data can be imported from Kaggle and script can be directly run with MYSQL using the table name of "exlang"
#               The original dataset on Kaggle is called "Extinct Languages" -- Additionally, you will need a table, which here
#               I have named "Numbers" with one column, spanning the values of 1 to 29 inclusive. This table could be hard-coded
#               or generated, for example, with a function in excel and imported into MySQL as CSV or JSON.             


# Set the schema

use PortfolioProject4;

# Take a look at original data imported from Kaggle

select * from exlang;

# How many unique langauges do we have to start with?

select count(*) from exlang;

# 2722 -- We will use this info later

# The majority of these columns will not be used, but we will create a new table with the columns we 
# want. One column we do need though is the language name column. We'll rename this for easier reference
# in our queries

alter table exlang
rename column `Name in English` to Language;

# In order for the main function of this program to work,
# we need to figure out which row in the countries column has the most values ( i.e. which language has the most countries).
# We will do that by finding which row has the most commas for the countries column
# (every value is separated by a comma, for example, a value of 3 would mean there are 4 values in the cell for example, a,b,c,d)

# Use the char_length function to find the difference between the values with and without commas. This will tell you
# how many countries there are. (Number of Countries) = (Number of Commas) + 1

select language, countries, 
(CHAR_LENGTH(Countries) - CHAR_LENGTH(REPLACE(Countries, ',', ''))) + 1 as Number_Of_Countries
from exlang;

#This looks correct, so we will now find the maximum value using a common table expression

WITH CountryCount as
(
select language, countries, 
(CHAR_LENGTH(Countries) - CHAR_LENGTH(REPLACE(Countries, ',', ''))) + 1 as Number_Of_Countries
from exlang
)
select max(Number_Of_Countries)
from CountryCount;

# 29 is the maximum number of countries where a single language is spoken in this table. If we are curious
# as to what language that is and which countries are associated, a simple where clause in our previous query will yield that info

WITH CountryCount as
(
select language, countries, 
(CHAR_LENGTH(Countries) - CHAR_LENGTH(REPLACE(Countries, ',', ''))) + 1 as Number_Of_Countries
from exlang
)
select *
from CountryCount
where Number_Of_Countries = 29;

# A quick glance shows that this is Romani, and it is spoken all over eastern, southern, and even western and northern Europe.

# Our function requires a join to a table with one column, each row a value ranging from 1 to the maximum value of countries
# So we need a table with one column, with rows that go from 1 to 29

# This is our numbers table

select * from numbers;

# Now create the table that we are going to use in our join. This is the table referenced above, it is the 
# original table including only the two columns of interest, Language name and country

create table LangCountries as
select Language, Countries
from exlang;

# Now we run our join that gives us a table where there is a unique pairing between langauge and country
# We no longer have the country cells containing multiple values, we have a unique row for every pairing 
# of language and where that language is spoken. Make this query into a table

create table LangCountryUniquePairs
as
select language,
SUBSTRING_INDEX(SUBSTRING_INDEX(LangCountries.Countries, ',', numbers.n), ',', -1) country
from numbers inner join LangCountries
on  CHAR_LENGTH(LangCountries.Countries) - CHAR_LENGTH(REPLACE(LangCountries.Countries, ',', '')) >= numbers.n-1
;

# We know that there are 2722 unique languages in our original table. 
# Did our query to separate the countries end up losing any languages? Let's check

SELECT count(distinct language) from LangCountryUniquePairs;

# It looks like we lost a few languages. Using a WHERE NOT IN statement, we can find which ones

select * from exlang
where language not in 
(SELECT distinct language from LangCountryUniquePairs);

# They appear to all be there. Does the original table have duplicate langauges?

select count(language) from exlang;

select count(distinct language) from exlang;

# It looks like 7 languages are duplicated. Which ones?
# One way to do this is by using a group by and having clause

select language, count(id) as duplicates
from exlang
group by language
having duplicates > 1;

# We can see that we have seven languages that are duplicated. Let's take a look at them

SELECT * FROM exlang
where language = 'Boro' OR language = 'Aka' OR language = 'Wari' OR language = 'Karo' 
OR language = 'Koro' OR language = 'Yuki' OR language = 'Pyu'
ORDER BY language;

# The question is, are these all different langauges, some of which having the same name, or are
# there any actual duplicates?

# It looks as though they are different languages given where they are spoken. The only questionable
# one is "Aka", becuase both are spoken in India, but the first one is also spoken in Sudan, and 
# thier alternate names are completely different. So for now, we will assume that they really are different
# languages that simply share the same name

# Do a test to see if we got all 29 countries for Romani

select countries from exlang
where Language = 'Romani';

select count(country) from LangCountryUniquePairs
where Language = 'Romani';

# Now we will do a general test to see if the query worked to get all the countries. We do this by comparing
# the country column of the query that has the join and the char length and substring_index functions by doing a group by and the 
# CountryCount query we used above as a CTE 

CREATE TEMPORARY TABLE IF NOT EXISTS TestTable AS

with UniquePairsRegrouped
as
(
select language, count(country) as TotalCountries
from LangCountryUniquePairs
group by language
)

select UniquePairsRegrouped.language, UniquePairsRegrouped.TotalCountries,
 e.Number_Of_Countries, e.countries
from UniquePairsRegrouped
join
(
select language, countries, 
(CHAR_LENGTH(Countries) - CHAR_LENGTH(REPLACE(Countries, ',', ''))) + 1 as Number_Of_Countries
from exlang
) e
on UniquePairsRegrouped.language = e.language;


# Test to see if the original number of countries for each langauge matches up with the table we made with the 
# JoinCharlength query, select from the temp table where the two columns do not equal each other

select * from TestTable
where TotalCountries != Number_Of_Countries;

# The duplicate names will have to be renamed in order for the join to be correct. We'll add a '2' at the end of the 
# second ones

SELECT * FROM exlang
where language = 'Boro' OR language = 'Aka' OR language = 'Wari' OR language = 'Karo' 
OR language = 'Koro' OR language = 'Yuki' OR language = 'Pyu'
ORDER BY language;

# We will recreate tables with the languages renamed. This will allow us to go back and forth between the original
# data and the data that has the updated names
# We will use "dif" as short for "differentiated"

create table exlangdif
as
Select * from exlang;

# This will allow us to update values

SET SQL_SAFE_UPDATES = 0;

update exlangdif
set language = 'Aka2'
where ID = 1690;

update exlangdif
set language = 'Boro2'
where ID = 1680;

update exlangdif
set language = 'Karo2'
where ID = 1683;

update exlangdif
set language = 'Koro2'
where ID = 2723;

update exlangdif
set language = 'Pyu2'
where ID = 2123;

update exlangdif
set language = 'Wari2'
where ID = 2577;

update exlangdif
set language = 'Yuki2'
where ID = 849;

# Now that the languages have been differentiated, we can rerun the following queries and test

select language, countries, 
(CHAR_LENGTH(Countries) - CHAR_LENGTH(REPLACE(Countries, ',', ''))) + 1 as Number_Of_Countries
from exlangdif;

create table LangCountriesDif as
select Language, Countries
from exlangdif;

select * from LangCountriesDif;

create table LangCountryUniquePairsDif
as
select language,
SUBSTRING_INDEX(SUBSTRING_INDEX(LangCountriesDif.Countries, ',', numbers.n), ',', -1) country
from numbers inner join LangCountriesDif
on  CHAR_LENGTH(LangCountriesDif.Countries) - CHAR_LENGTH(REPLACE(LangCountriesDif.Countries, ',', '')) >= numbers.n-1
;

# We know that there are 2722 unique languages. Let's check to make sure that our differentiation took care of that

SELECT count(distinct language) from LangCountryUniquePairsDif;

# Now we will rurun our general test to see if all language/country pairs have been retained

CREATE TEMPORARY TABLE IF NOT EXISTS TestTableDif AS

with UniquePairsRegrouped
as
(
select language, count(country) as TotalCountries
from LangCountryUniquePairsDif
group by language
)

select UniquePairsRegrouped.language, UniquePairsRegrouped.TotalCountries,
 e.Number_Of_Countries, e.countries
from UniquePairsRegrouped
join
(
select language, countries, 
(CHAR_LENGTH(Countries) - CHAR_LENGTH(REPLACE(Countries, ',', ''))) + 1 as Number_Of_Countries
from exlangdif
) e
on UniquePairsRegrouped.language = e.language;

select * from TestTableDif;

select * from TestTableDif
where TotalCountries != Number_Of_Countries;

# So we know we have all languages with all of their countries in the LangCountryUniquePairsDif table
# This is the table we will export to Tableu for visualization.