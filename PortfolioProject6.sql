# ScriptName:	PortfolioProject6
# Created on:	January 3rd, 2024
# Author:		Christian Maxfield Welshinger
# Purpose:	    This is relatively short project, the purpose of which is to prepare the raw data taken from kaggle organize it
#				in such a way as to import it first into Excel, then ultimately into the Oracle SQL Developer virtual machine. Extraneous columns will be
#				identified and removed, data will be unioned together, blank values will be identified and changed to 
#				null. Additionally, text value will be given single quotes, so they can be transferred into a csv file
# 				that can be imported into Excel, then from excel the insert statements can be easily generated, then
#				those insert statements can be copied into the Oracle virtual machine to recreate the tables.
# Last Update:	January 14, 2024
# Execution		Data can be imported from Kaggle and script can be directly run with MYSQL using the table names of "dallastxpumpkins"
#               and "LACAPumpkins". The original dataset on Kaggle is called "A Year of Pumpkin Prices"


create schema PortfolioProject6;

use PortfolioProject6;

# import Dallas and Los Angeles data

# take a look at the dallas data

select * from dallastxpumpkins;

select * from LACAPumpkins;

# We notice that there are a number of blank columns, and we also have columns for Low Price and High Price,
# but we also see Mostly Low and Mostly High -- the original data source did not explain what that is, and it 
# looks to be similar to Low price and high price, let's check

select * from dallastxpumpkins
where `Low Price` != `Mostly Low`;

select * from dallastxpumpkins
where `High Price` != `Mostly High`;

select * from LACApumpkins
where `Low Price` != `Mostly Low`;

select * from LACApumpkins
where `High Price` != `Mostly High`;

# Except for one record, they are the same. Even where they are different, they only differ slightly. We'll
# therefore exclude those columns as well

# We're going to create a new table that only includes columns that actually have values, and rename most of the columns with
# shorter names easier to reference


# We'll bring in pumpkin sales data from Dallas and Los Angeles into a single table. We'll check to make sure that the columns are all the same
# before we do a union

# We'll use a data dictionary view to make the comparison


create view dallascolumns 
as
select column_name as Dallas from information_schema.columns
where table_name = 'dallastxpumpkins'
;

select * from dallascolumns;

create view lacolumns 
as
select column_name as LA from information_schema.columns
where table_name = 'LACAPumpkins';

# if the columns are all the same, then we can do a union all, then group by, and if they have the same
# number (2), then the columns are all the same

with columns as
(
select dallas as columnnames from dallascolumns
union all
select * from lacolumns
)
select columnnames, count(columnnames) 
from columns
group by columnnames
having count(columnnames) != 2;

# No rows returned, therefore columns are all the same, so we can do a union all

create table USAPumpkins
as
select * from dallastxpumpkins
union all
select * from LACAPumpkins;

# A fair amount of columns are missing values. We will remake the table without them, and rename the columns
create table USAPumpkins2
as
select `Commodity Name` as Commodity, `City Name` as City, Package as PackageType, Variety, Date as DateOfSale, `Low Price` as LowPrice,
 `High Price` as HighPrice, Origin, `Item Size` as SizeOfPumpkin
 from usapumpkins
;

# Now we'll check for null or blank string values

select * from USAPumpkins2
 where commodity is null or commodity = '';
 
  select * from USAPumpkins2
 where City is null or City = '';
 
  select * from USAPumpkins2
 where PackageType is null or PackageType = '';
 
  select * from USAPumpkins2
 where Variety is null or Variety = '';
 
  select * from USAPumpkins2
 where DateOfSale is null or DateOfSale = '';
 
  select * from USAPumpkins2
 where LowPrice is null or LowPrice = '';
 
  select * from USAPumpkins2
 where HighPrice is null or HighPrice = '';
 
  select * from USAPumpkins2
 where Origin is null or Origin = '';
 
 select * from USAPumpkins2
 where SizeOfPumpkin is null or SizeOfPumpkin = '';

# We found some empty strings, as well as zero values for some of the pumpkins in the 
# price columns. We'll add null values in before transferring to CSV. That way we can more accurately read the file into excel, and 
# generate the insert statements to copy into the Oracle virtual machine.

SET SQL_SAFE_UPDATES = 0;

update usapumpkins2
set Variety = NULL
where Variety = '';

update usapumpkins2
set LowPrice = NULL
where LowPrice = 0;

update usapumpkins2
set HighPrice = NULL
where HighPrice = 0;

update usapumpkins2
set SizeOfPumpkin = NULL
where SizeOfPumpkin = '';

# All of the text fields are strings, and need to have single quotes added to them in order
# to be transferred directly into an insert statement for our virtual machine to read.

create table PumpkinsWithQuotes
as
select concat(" ' ", commodity, " ' " ) as Commodity, 
concat(" ' ", City, " ' " ) as City,
concat(" ' ", PackageType, " ' " ) as PackageType,
concat(" ' ", Variety, " ' " ) as Variety,
concat(" ' ", DateOfSale, " ' " ) as DateOfSale,
LowPrice,
HighPrice,
concat(" ' ", Origin, " ' " ) as Origin,
concat(" ' ", SizeOfPumpkin, " ' " ) as SizeOfPumpkin
from usapumpkins2;

# Run query to verify and export to csv for importation into excel. In excel, add the column with the formula
# generating insert statements for each row.
# Use the following formula to transform the excel row values into SQL insert statements: 
#   "INSERT INTO USPumpkins VALUES (" & A2 & ", " & B2 & ", " & C2 & ", " & D2 & ", " & E2 & ", " & F2 & ", " & G2 & ", " & H2 & ", " & I2 & ");"
#   Copy the values from the spreadsheet into a plain text editor, then copy into a word procesor to find and replace quotations (If need be)
