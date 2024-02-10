# ScriptName:	PortfolioProject7
# Created on:	January 10th, 2024
# Author:		Christian Maxfield Welshinger
# Purpose:	    This is a data imputation project. The purpose of this project is to determine the best guess for each
#				of the null values in our data set. Additionally, we will need to add a primary key in order to easily
#				reference certain records, and a sequence will be used for this. This code was written in Oracle SQL Developer
# Last Update:	January 19th, 2024
# Execution		The data for this project was the project of project 6, which had to do with the organizatio of the raw data
#				into a form that was importable by the oracle sql developer virtual machine. This project can easily be read
#				and understood without referencing project 6, but if you wish to be able to run this code, it would be necessary
#				to start there. That project is included in this portfolio.

-- First we'll make sure that our transfer of the rows from the excel file are correct and
-- we have the same number of records

SELECT * FROM uspumpkins;

SELECT count(*) FROM uspumpkins;

-- We don't need the commodity column, it's not adding anything to our data

alter table uspumpkins
drop column commodity;

-- We'll add the ID column first, populate it with the sequence, then make it the primary key -- we have to put
-- the primary key constraint on last because our column otherwise would have null values. 

alter table uspumpkins
add ID int;

-- now we'll create a sequence

create sequence pumpkin_id_seq;

-- add unique values to the id column of the uspumpkins table using the sequence

update uspumpkins
set id = pumpkin_id_seq.nextval ;

-- let's reorder the columns of the table, and get rid of extra space in strings from any varchar data. This was how the data
-- was copied in from Excel and it will be hard to reference it with the extranneous spaces

rename uspumpkins to uspumpkins2;

create view reorderedTrimmed
as
select id, trim(city) city,  trim(variety) variety, trim(datesold) datesold, lowprice, highprice, 
trim(sizeofpumpkin) sizeofpumpkin, trim(origin) origin, trim(packagetype) packagetype
from 
uspumpkins2;

create table USpumpkins
as
select * from reorderedTrimmed;

-- now we'll add the primary key constraint to the ID column

alter table uspumpkins
add constraint pumpkin_pk
primary key (id);

-- Next, we'll start the process of imputation

-- We need to clearly distinguish what values are null

select * from uspumpkins
where variety is null;

-- Variety is null for 3 Dallas pumpkins values

select * from uspumpkins
where lowprice is null order by packagetype;

-- High price and lowprice is null for 14 los angeles rows. There are 4 24 inch bin cinderella med-lge pumpkins.
-- There are 6 24 inch bin fairytale pumpkins. And then there are 4 36 inch cinderella med-lge pumpkins

select * from uspumpkins
where sizeofpumpkin is null order by packagetype;

-- Size of pumpkin is missing for 24 rows. 3 dallas 24 inch bin pie types, 6 LA 24 inch bin fairytales, 3 LA
-- 35 lb carton pie types, 6 LA miniature pumpkins, 3 dallas 36 inch bin pie types, 1 la 36 inch bin big mac type,
-- then 2 Dallas 50 lb sacks pie type


-- We'll run a few tests to see which factor is the greatest predictor of size of pumpkin -- Packagetype, variety, or 
-- average price


-- First, we will guess the missing variety values for the Dallas pumpkin sales

-- Pumpkins sold to Dallas in 24 inch bins that are between 160 and 225 and originate from texas are a large size
-- are null -- we'll see if we can guess what that might be

select * from uspumpkins
where city = 'DALLAS'
and packagetype = '24 inch bins' 
and LowPrice >= 150
and HighPrice <= 235
and Origin = 'TEXAS'
and SizeOfPumpkin = 'lge';

-- It looks like it could be either a Howden, or a Fairtale, but is most likely a howden type variety given the low price value

-- Let's make one more query, without factoring in the package size and origin

select * from uspumpkins
where city = 'DALLAS'
and LowPrice >= 150
and HighPrice <= 235
and SizeOfPumpkin = 'lge';


-- This data further confirms that It is probably a Howden Type

update uspumpkins
set variety = 'HOWDEN TYPE'
where id in (1,2,3);

-- Now let's try to find the missing price data
-- High price and lowprice is null for 14 los angeles rows. There are 4 24 inch bin cinderella med-lge pumpkins.
-- There are 6 24 inch bin fairytale pumpkins. And then there are 4 36 inch cinderella med-lge pumpkins

-- With the data that we do have, find the average lowprice and average highprice for Cinderalla pumpkins
-- sold in 24 inch bins

select round(avg(lowprice)),  round(avg(highprice)) from uspumpkins
where 
packagetype = '24 inch bins' and Variety = 'CINDERELLA' 
;

update uspumpkins
set lowprice = (select round(avg(lowprice)) from uspumpkins
                where packagetype = '24 inch bins' and Variety = 'CINDERELLA' )
where id in (
            select id from uspumpkins
            where packagetype = '24 inch bins' 
            and Variety = 'CINDERELLA' and lowprice IS NULL
            );

update uspumpkins
set highprice = (select round(avg(highprice)) from uspumpkins
                where packagetype = '24 inch bins' and Variety = 'CINDERELLA' )
where id in (
                select id from uspumpkins
                where packagetype = '24 inch bins' 
                and Variety = 'CINDERELLA' and highprice IS NULL
             );

select round(avg(lowprice)),  round(avg(highprice)) from uspumpkins
where 
packagetype = '24 inch bins' and Variety = 'FAIRYTALE'
;

update uspumpkins
set lowprice = (select round(avg(lowprice)) from uspumpkins
                where 
                packagetype = '24 inch bins' and Variety = 'FAIRYTALE')
where ID in (
            select id from uspumpkins
            where packagetype = '24 inch bins' 
            and Variety = 'FAIRYTALE' and lowprice IS NULL
            );


update uspumpkins
set highprice = (select round(avg(highprice)) from uspumpkins
                where 
                packagetype = '24 inch bins' and Variety = 'FAIRYTALE')
where ID in (   
            select id from uspumpkins
            where packagetype = '24 inch bins' 
            and Variety = 'FAIRYTALE' and highprice IS NULL
            );



select round(avg(lowprice)),  round(avg(highprice)) from uspumpkins
where packagetype = '36 inch bins' and Variety = 'CINDERELLA'
;

update uspumpkins
set lowprice = (select round(avg(lowprice)) from uspumpkins
                where packagetype = '36 inch bins' and Variety = 'CINDERELLA')
where ID in (
             select id from uspumpkins
             where packagetype = '36 inch bins' 
             and Variety = 'CINDERELLA' and lowprice IS NULL
            );

update uspumpkins
set highprice = (select round(avg(highprice)) from uspumpkins
                where packagetype = '36 inch bins' and Variety = 'CINDERELLA')
where ID in (
              select id from uspumpkins
              where packagetype = '36 inch bins' 
              and Variety = 'CINDERELLA' and highprice IS NULL
            );


-- Now we'll try to impute the best guess for the missing size of pumpkins
-- Size of pumpkin is missing for 24 rows. 3 dallas 24 inch bin pie types, 6 LA 24 inch bin fairytales, 3 LA
-- 35 lb carton pie types, 6 LA miniature pumpkins, 3 dallas 36 inch bin pie types, 1 la 36 inch bin big mac type,
-- then 2 Dallas 50 lb sacks pie type

-- We'll run a few tests to see which factor is the greatest predictor of size of pumpkin -- Packagetype, variety, or 
-- price

-- Does the Packagetype predict pumpkin size?

select packagetype, sizeofpumpkin, count(sizeofpumpkin) as CountOfSizes
from uspumpkins
group by packagetype, sizeofpumpkin
order by packagetype, CountOfSizes desc;


-- It looks like bin size or more generally package type is not a predicator of pumpkin size, as there is a fairly even distribution of 
-- pumpkin sizes across the different packagetypes. We would assume that variety is though

create view VarietyAndSize
as
select variety, sizeofpumpkin, count(sizeofpumpkin) as CountOfSizes
from uspumpkins
group by variety, sizeofpumpkin
order by variety, CountOfSizes desc;

-- Variety looks to be a better predictor of size
-- Now we will make a view of overall number of pumpkins sales by variety
-- We'll use this to create a table that gives us the percentage of pumpkin size within a variety, i.e. 40% of Howdens are large, etc.


create view pumpkinsbyvariety
as
select variety, count(id) CountOfPumpkins
from uspumpkins
group by variety;

select * from VarietyAndSize;
select * from pumpkinsbyvariety;

create view PumpkinPercentages
as
select v.variety, v.sizeofpumpkin, v.countofsizes, p.countofpumpkins, round(v.countofsizes/p.countofpumpkins, 2) as percentage
from VarietyAndSize v
join
pumpkinsbyvariety p
on v.variety = p.variety
order by v.variety, percentage desc ;


-- We'll do a case statement with rpad to make it easier to determine visually which varieties are easier to predict

create view PumpkinSizesOrdered
as
select variety, sizeofpumpkin,  case
                                when percentage >= 0.5 then rpad(to_char(percentage), 9, '*')
                                else to_char(percentage)
                                end as PumpkinPercentage
 from PumpkinPercentages
 order by variety, pumpkinpercentage desc;

-- It looks like  variety can pretty well predict size for Cinderella, (jbo), fairytale (jumbo), howden white (jumbo),
-- mixed heirloom (medium) and pie type (medium). If we're missing Howden, well play it safe and go with large, and big mac type 
-- we'll go large as well

-- Now from this view, we'll create another view that shows just the most likely size of pumpkin
-- given the variety. 

create view MajoritySizeByVariety
as
select * from pumpkinsizesordered
where variety = 'BIG MACK TYPE' and sizeofpumpkin = 'lge'
or
pumpkinpercentage like '%*%'
or
variety = 'HOWDEN TYPE' and sizeofpumpkin = 'lge';


-- Now we will create a view that shows the relationship between size of pumpkin and price, finding the min and max low and high 
-- prices, as well as the average low and high prices

create view pricebysize
as
select sizeofpumpkin, round(avg(lowprice), 2) AvgLowPrice , round(avg(highprice), 2) AvgHighPrice, 
min(lowprice) MinimumLowPrice, min(highprice) MinimumHighPrice, max(lowprice) MaximumLowPrice, 
max(highprice) MaximumHighPrice
from uspumpkins
group by sizeofpumpkin
order by AvgLowPrice;

select * from pricebysize;

-- It looks like the price range is too wide and it won't be a good predictor of size 
-- (the max and min values are well outside of the avg price ranges), so we'll stick with variety as our predictor
-- Before we update, we'll take a look at the join of the missing size data and the view with the predicted size by variety

with missingSizes
as
(
select * from uspumpkins
where sizeofpumpkin is null
)
select miss.id, miss.variety, miss.lowprice, miss.highprice, miss.sizeofpumpkin,
maj.* from missingSizes miss
join
majoritysizebyvariety maj
on
miss.variety = maj.variety;

-- We'll do a merge to fix the data

merge into uspumpkins pump
using majoritysizebyvariety maj
on (pump.variety = maj.variety)
when matched then
    update set
            pump.sizeofpumpkin = maj.sizeofpumpkin
            where pump.sizeofpumpkin is null;

select * from uspumpkins;

-- Now all null values have been imputed with a value. The last possible bad data to deal with is pumpkin sales for 1 dollar
-- Additionally, we have ID 183 a sale of large 36 inch bin Big Mack pumpkins selling for a lowprice and high price of 1 dollar. 
-- This is highly unlikely and something about this is probably wrong. Could we reasonably guess what needs to be fixed?

select * from uspumpkins
where lowprice = 1;

-- We have Howden Whites selling in California for a dollar. Let's see what the rest of the data says about that

select * from uspumpkins
where variety = 'HOWDEN WHITE TYPE'
and packagetype = '36 inch bins';

-- It's most likely that those values should be 250 given the other data 

update uspumpkins
set lowprice = (select lowprice from uspumpkins where id = 162)
where id in (select ID from uspumpkins where city = 'LOS ANGELES' 
and variety = 'HOWDEN WHITE TYPE' and lowprice = 1 and highprice = 1 );

select * from uspumpkins
where variety = 'BIG MACK TYPE';

-- Judging from the data we have, and pictures of the Big Mack online, this pumpkin could range wildly in size
-- and in price. It looks like either the price and packaging is wrong, or the size and packing is wrong.
-- It's too hard to tell with what we have, and we're not losing much by deleting it, so that's what we'll
-- do to finish up cleaning our data

delete from uspumpkins
where id = 183;

-- it's unclear if price is a good indicator, especially when we have some batches of pumpkins sold for a dollar.
-- Could that be a mistake?

-- Lastly, we are missing data for for the Los Angeles miniature pumpkins. Let's see if we have any data on that size
-- elsewhere in the table


select SizeOfPumpkin, count(sizeofpumpkin) CountOfSize
from uspumpkins
where  variety = 'MINIATURE'
group by sizeofpumpkin
order by CountOfSize desc;

-- We don't have any data on the miniature, but we can assume they are small. What is the smallest size currently?

select sizeofpumpkin
from uspumpkins
group by sizeofpumpkin;

-- sml is the smallest size. Let's update the minature to sml

update uspumpkins
set sizeofpumpkin = 'sml'
where variety = 'MINIATURE' and sizeofpumpkin is null;


-- This is now where the plsql coding would start

-- here we we are getting the names of the columns from the data dictionary view

select column_name
from user_tab_columns
where table_name = 'USPUMPKINS';