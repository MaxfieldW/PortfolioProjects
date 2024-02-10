# ScriptName:	PortfolioProject8
# Created on:	January 17th, 2024
# Author:		Christian Maxfield Welshinger
# Purpose:	    Utilize PL/SQL to generate reports and run DML operations on pumpkins sales data.
#               The project starts with standard SQL to do some final cleanup and create a table for joins to be used in the
#               PL/SQL Code. The rest of the project includes programs using anonymous blocks, loops, functions, procedures, 
# 				cursors, records, and various types of composite data types, including varrays, nested tables, and associative arrays
# Last Update:	February 6th, 2024
# Execution		The original Data set, "A Year of Pumpkin Prices" can be imported from Kaggle. Preliminary work of preparing the data
#               for importation into the Oracle sql developer virtual machine has been conducted previously to this program,
#               as can be viewed in projects titled "Data Cleaning and Transformation in SQL" and "Data Imputation in SQL" of this portfolio.

-- We'll start by renaming columns

create table uspumpkinsrenamed
as
select id as Sale_ID, city, variety, lowprice as Low_Price, highprice as High_Price, sizeofpumpkin as Pumpkin_Size,
origin, packagetype as Package_Type, datesold as Date_Sold from uspumpkins;

drop table uspumpkins;

create table uspumpkins as
select * from uspumpkinsrenamed;

-- Some of the varieties have the word "type" in them and some do not. The word "type" is unecessary and we'll remove it here

update table uspumpkins
set variety = replace(variety, 'TYPE', '');

-- As we'll be working working variables and collections, one thing we will check is the data type of 
-- each column

desc uspumpkins;

-- Date_Sold is currently a varchar variable, let's change the Date_Sold column to a date data type

alter table uspumpkins
add dateofsale date;

update uspumpkins
set dateofsale = to_date(datesold, 'MM/DD/YY');

alter table uspumpkins
drop column datesold;

alter table uspumpkins
rename column dateofsale to datesold;

-- Create table of the latin names of the varieties we have, so that we can use some joins in our further queries

 create table PumpkinLatinNames
 (Variety varchar2(15),
  Latin_Names varchar2(20));
  
  insert all
  into PumpkinLatinNames  values ('Cinderella', 'Cucurbita Maxima')
  into PumpkinLatinNames  values ('Howden', 'Cucurbita Pepo')
  into PumpkinLatinNames  values ('Howden White', 'Cucurbita Pepo')
  into PumpkinLatinNames  values ('Big Mack', 'Cucurbita Maxima')
  into PumpkinLatinNames  values ('Fairytale', 'Cucurbita Moschata')
  into PumpkinLatinNames  values ('Pie', 'Cucurbita Pepo')
  select * from dual;

-- Here is a simple PL/SQL block that prints the average low price of the howden variety pumpkin

declare
 v_name varchar2(50);
 v_lowprice uspumpkins.low_price%type;
begin
 select variety, avg(low_price) 
 into v_name, v_lowprice
 from uspumpkins
 group by variety
 having variety = 'HOWDEN';
 dbms_output.put_line('The average low price of '|| v_name || ' is : ' || v_lowprice);
end;


-- The following will generate an output that uses a record that draws data from two different tables. 
-- The block takes a pumpkin order id and returns the variety of the pumpkin, the date sold and place it was sold, and it
-- gives the latin name for the variety

declare
 type t_pump is record (sale_id number , variety varchar2(20), city varchar2(20),
 date_sold date, latin_names pumpkinlatinnames.latin_names%type);
 
r_pump t_pump;

begin
select sale_id, variety, city, date_sold 
into r_pump.sale_id, r_pump.variety, r_pump.city, r_pump.date_sold
from uspumpkins
where sale_id = '70';
select latin_names 
into r_pump.latin_names
from pumpkinlatinnames
where upper(variety) = upper(r_pump.variety);
dbms_output.put_line('The ' || r_pump.variety || ' variety of pumpkin was sold on ' || r_pump.date_sold || ' in the city of '
|| r_pump.city || '. Its Latin name is ' || r_pump.latin_names || '.');
end;

-- The following are a few examples of inserting and updating rows in a table with a record. We'll use a record
-- to insert rows from our uspumpkins table into other tables

create table CaliforniaPumpkins
as
select * from uspumpkins
where 1 = 2;

declare
 r_cal uspumpkins%rowtype;
begin
 select * into r_cal from uspumpkins where sale_id = 1;
 r_cal.ORIGIN := 'CALIFORNIA';
 insert into CaliforniaPumpkins values r_cal;
end;

declare
 r_cal uspumpkins%rowtype;
begin
 select * into r_cal from uspumpkins where id = 1;
 r_cal.ORIGIN := 'MICHIGAN';
 UPDATE CaliforniaPumpkins SET ROW = r_cal where id =  1;
end;

-- Here we'll use an associative arrays with records to run a report that gives the variety and sale date of 
-- of sale IDs 100 through 110

declare
 type p_list is table of uspumpkins%rowtype
 index by pls_integer;
  pumps p_list;
  idx uspumpkins.sale_id%type; 
begin
for x in 100..110 loop
  select * into pumps(x)
  from uspumpkins where sale_id = x;
  end loop;
  idx := pumps.first;
  while idx is not null loop
   dbms_output.put_line('The ' || pumps(idx).variety || ' pumpkin was sold on ' ||  pumps(idx).date_sold );
   idx := pumps.next(idx);
  end loop;
end;

-- Here we will use own row type with an associative array with a for loop to print
-- out the variety, origin, and sale id of the pumpkins sales with ids ranging from 100 to 110

declare
type p_type is record (variety uspumpkins.variety%type, origin uspumpkins.origin%type, sale_id uspumpkins.sale_id%type);
 type p_list is table of p_type
 index by pls_integer;
  pumps p_list;
  idx uspumpkins.sale_id%type;
begin
for x in 100..110 loop
  select variety, origin, sale_id into pumps(x)
  from uspumpkins where sale_id = x;
  end loop;
  idx := pumps.first;
  while idx is not null loop
   dbms_output.put_line('The ' || pumps(idx).variety || ' variety of pumpkin from ' 
   || pumps(idx).origin || ' was sold with sale id ' ||  pumps(idx).sale_id );
   idx := pumps.next(idx);
  end loop;
end;


-- We're going to use make a varray within a table so that each record will have a cell that will include
-- the low price and the high price column names and values for each pumpkin sale
-- Let's imagine that we also may want to add an average price value later on. With a varray we cannot add another row to our
-- collections, but if we use a nested table, then we will be able to add more values after the fact

create or replace type p_price as object (p_type varchar2(50), p_value number);

create or replace type n_prices as table of p_price;

create table pumpkins_with_prices3 (sale_id number, variety varchar2(50), price_range n_prices) 
nested table price_range store as prices_table;

select * from pumpkins_with_prices;
                              
insert into pumpkins_with_prices3 values  (10 , 'Fairytale' , n_prices( 
                                                p_price('LowPrice', 50),
                                                 p_price('HighPrice', 100))
                                                 );
                                                 
                                    
                                                            
insert into pumpkins_with_prices3
values (10, 'Fairytale', n_prices( 
                                p_price('Low_Price', 200),
                                p_price('High_Price', 300))
                                );
                                
-- Because we now have nested table, we can put as many rows into our composite table as we want. We'll just add a third one here

insert into pumpkins_with_prices3
values (10, 'Fairytale', n_prices( 
                                p_price('Low_Price', 200),
                                p_price('High_Price', 300),
                                p_price('Average_Price', 250))
                                );
   -- we'll add another row with a unique ID                             
        insert into pumpkins_with_prices3
values (11, 'Fairytale', n_prices( 
                                p_price('Low_Price', 200),
                                p_price('High_Price', 300),
                                p_price('Average_Price', 250))
                                );

-- let's say we want to update the values of that last insert

update pumpkins_with_prices3
set price_range = n_prices(p_price('Low_Price', 300),
                                p_price('High_Price', 400),
                                p_price('Average_Price', 350))
                                where sale_id = 11;

  -- in order to better see our table, we'll use the table function on our composite data type column                             

select p.sale_id, p.variety, r.p_type, r.p_value
from pumpkins_with_prices3 p,
table(p.price_range) r ;

-- Let's say that we wanted to add a value to our composite data type without updating the whole composite table, so not
-- updating the whole record. We can do that in the following way. We'll add a value for a difference to show the diffrence
-- between the min and max value

declare
 p_pump n_prices;
begin
select price_range into p_pump from pumpkins_with_prices3
where sale_id = 11;
p_pump.extend;
p_pump(4) := p_price('Difference', 100);
update pumpkins_with_prices3 set price_range = p_pump where sale_id = 11;
end;

-- Now we'll use a cursor to  to iterate through
-- a set of records, printing out the values stored in our variables with other text as the cursor iterates.

declare
 cursor c_pumps is select p.sale_id, p.variety, l.latin_names from uspumpkins p
                            join pumpkinlatinnames l on p.variety = l.variety
                            where sale_id between 1 and 5;
 v_id uspumpkins.sale_id%type;
 v_variety uspumpkins.variety%type;
 v_latin pumpkinlatinnames.latin_names%type;
begin
open c_pumps;
fetch c_pumps into v_id, v_variety, v_latin;
dbms_output.put_line('Sale ID ' || v_id || ' is of the ' || v_variety || ' variety of pumpkin, and its latin name is ' || v_latin);
fetch c_pumps into v_id, v_variety, v_latin;
dbms_output.put_line('Sale ID ' || v_id || ' is of the ' || v_variety || ' variety of pumpkin, and its latin name is ' || v_latin);
fetch c_pumps into v_id, v_variety, v_latin;
dbms_output.put_line('Sale ID ' || v_id || ' is of the ' || v_variety || ' variety of pumpkin, and its latin name is ' || v_latin);
fetch c_pumps into v_id, v_variety, v_latin;
dbms_output.put_line('Sale ID ' || v_id || ' is of the ' || v_variety || ' variety of pumpkin, and its latin name is ' || v_latin);
fetch c_pumps into v_id, v_variety, v_latin;
dbms_output.put_line('Sale ID ' || v_id || ' is of the ' || v_variety || ' variety of pumpkin, and its latin name is ' || v_latin);
close c_pumps;
end;
 
-- Here we are using a cursor with records to print the sale ID and Variety of each pumpkin sale

declare
 type r_emp is record ( v_id uspumpkins.sale_id%type, v_variety uspumpkins.variety%type);
 v_pump r_emp;
 cursor c_pumps is select sale_id, variety from uspumpkins;                         
begin
open c_pumps;
fetch c_pumps into v_pump;
dbms_output.put_line('Sale ID ' || v_pump.v_id || ' is of the ' || v_pump.v_variety || ' variety of pumpkin');
close c_pumps;
end;

-- We can also do this with the rowtype with the cursor

declare
 v_pump uspumpkins%rowtype;
 cursor c_pumps is select sale_id, variety from uspumpkins;                         
begin
open c_pumps;
fetch c_pumps into v_pump.sale_id, v_pump.variety;
dbms_output.put_line('Sale ID ' || v_pump.sale_id || ' is of the ' || v_pump.variety || ' variety of pumpkin');
close c_pumps;
end;

-- Now we'll create a record with the cursor rowtype


declare
 cursor c_pumps is select sale_id, variety from uspumpkins; 
 v_pump c_pumps%rowtype;
begin
open c_pumps;
fetch c_pumps into v_pump.sale_id, v_pump.variety;
dbms_output.put_line('Sale ID ' || v_pump.sale_id || ' is of the ' || v_pump.variety || ' variety of pumpkin');
close c_pumps;
end;

-- Here we'll use a cursor to loop through and print the sale id and variety of the first 99 pumpkin orders.

declare
 cursor c_pumps is select * from uspumpkins where sale_id < 100;
  v_pumps c_pumps%rowtype;
begin
 open c_pumps;
 loop
  fetch c_pumps into v_pumps;
  exit when c_pumps%notfound;
  dbms_output.put_line('Sale ID ' || v_pumps.sale_id || ' was of the '|| v_pumps.variety || ' variety');
 end loop;
  close c_pumps;
end;

-- For loop with cursor to select the first 99 orders, and print the id and variety of the first 6

declare
 cursor c_pumps is select * from uspumpkins where sale_id < 100;
  v_pumps c_pumps%rowtype;
begin
 open c_pumps;
 for i in 1..6 loop
 fetch c_pumps into v_pumps;
  dbms_output.put_line('Sale ID ' || v_pumps.sale_id || ' was of the '|| v_pumps.variety || ' variety');
 end loop;
  close c_pumps;
end;

-- Here we have the same report generated as above, but we use a for in loop directly with the cursor to 
-- avoid the need of creating a record

declare
 cursor c_pumps is select * from uspumpkins where sale_id < 100;
begin
 for i in c_pumps loop
  dbms_output.put_line('Sale ID ' || i.sale_id || ' was of the '|| i.variety || ' variety');
 end loop;
end;

-- The same report could even be generated without a cursor, referencing the select statement directly

begin
 for i in (select * from uspumpkins where sale_id < 100) loop
  dbms_output.put_line('Sale ID ' || i.sale_id || ' was of the '|| i.variety || ' variety');
 end loop;
end;

-- Here we have cursors with parameters such that a user could input the place of origin for each pumpkin order, and get
-- the sale ids for each of those sales with the given origin. The example here has Mexico, but it could be used for any of the
-- origins in the data

declare
 cursor c_pumps (p_origin varchar2) is select sale_id, variety, origin
                                            from uspumpkins
                                            where origin = p_origin;
v_pumps c_pumps%rowtype;

begin
 open c_pumps('MEXICO');
 fetch c_pumps into v_pumps;
 dbms_output.put_line('The sales with pumpkins that came from ' || v_pumps.origin || ' are : ' );
 close c_pumps;
 open c_pumps('MEXICO');
  loop
   fetch c_pumps into v_pumps;
   exit when c_pumps%notfound;
   dbms_output.put_line(v_pumps.sale_id );
  end loop;
  close c_pumps;
end;

-- Now we'll use bind variables for the parameters -- This will prompt to enter a value for the origin.

declare
 cursor c_pumps (p_origin varchar2) is select sale_id, variety, origin
                                            from uspumpkins
                                            where origin = p_origin;
v_pumps c_pumps%rowtype;

begin
 open c_pumps(:b_origin);
 fetch c_pumps into v_pumps;
 dbms_output.put_line('The sales with pumpkins that came from ' || v_pumps.origin || ' are : ' );
 close c_pumps;
 open c_pumps(:b_origin);
  loop
   fetch c_pumps into v_pumps;
   exit when c_pumps%notfound;
   dbms_output.put_line(v_pumps.sale_id);
  end loop;
  close c_pumps;
end;

-- Now we'll use the bind variables to bring up the orders and the code will prompt for two origins. We'll also use
-- a for loop here

declare
 cursor c_pumps (p_origin varchar2) is select sale_id, variety, origin
                                            from uspumpkins
                                            where origin = p_origin;
v_pumps c_pumps%rowtype;

begin
 open c_pumps(:b_origin);
 fetch c_pumps into v_pumps;
 dbms_output.put_line('The sales with pumpkins that came from ' || v_pumps.origin || ' are : ' );
 close c_pumps;
 open c_pumps(:b_origin);
  loop
   fetch c_pumps into v_pumps;
   exit when c_pumps%notfound;
   dbms_output.put_line(v_pumps.sale_id );
  end loop;
  close c_pumps;
  
  open c_pumps(:b_origin2);
 fetch c_pumps into v_pumps;
 dbms_output.put_line('The sales with pumpkins that came from ' || v_pumps.origin || ' are : ' );
 close c_pumps;
 
  for i in c_pumps(:b_origin2) loop
   dbms_output.put_line(i.sale_id );
  end loop;
end;

-- Now we'll use a single cursor with more than 1 parameter. This program will take a city where the order was sold, and the place
-- and the place of origin (where the pumpkins came from)

declare
 cursor c_pumps (p_city varchar2, p_origin varchar2) is select sale_id, city, origin
                                            from uspumpkins
                                            where city = p_city
                                            and origin = p_origin;
v_pumps c_pumps%rowtype;

begin
  for i in c_pumps('DALLAS', 'MISSOURI') loop
   dbms_output.put_line('Sale ID ' || i.sale_id || ' was sold in ' || i.city || ' and the pumpkins came from ' || i.origin );
  end loop;
  dbms_output.put_line('-' );
  for i in c_pumps('DALLAS', 'MICHIGAN') loop
   dbms_output.put_line('Sale ID ' || i.sale_id || ' was sold in ' || i.city || ' and the pumpkins came from ' || i.origin );
  end loop;
end;

-- Now we'll run some DML operations using PL/SQL. We'll make a dummy table to do updates on with a cursor

create table pump_dummy
as
select * from uspumpkins;

-- Let's say that we need to update the low and high prices of pumpkin sales that were sold in the city of Dallas
-- We'll also use the for update clause. This will lock all the rows
-- that are selected once the cursor has opened our select query, and will stay locked until the update is
-- committed or rolled back. This will lock both tables

declare
 cursor c_pumps is select sale_id, low_price, high_price
                from pump_dummy join pumpkinlatinnames using(variety)
                where city = 'DALLAS';
begin
 for r_pumps in c_pumps loop
  update pump_dummy 
  set low_price = low_price * 1.2
   where sale_id = r_pumps.sale_id;
  update pump_dummy 
  set high_price = high_price * 1.2
   where sale_id =r_pumps.sale_id;
 end loop;
end;
  
  -- If we have a join like this, we can specify that we don't need the joined tables rows locked by adding
  -- a for update of clause
  
declare
 cursor c_pumps is select sale_id, low_price, high_price
                from pump_dummy join pumpkinlatinnames using(variety)
                where city = 'DALLAS' for update of pump_dummy.low_price;
begin
 for r_pumps in c_pumps loop
  update pump_dummy 
  set low_price = low_price * 1.2
   where sale_id = r_pumps.sale_id;
  update pump_dummy 
  set high_price = high_price * 1.2
   where sale_id =r_pumps.sale_id;
 end loop;
end;

-- We can use the rowids instead of the primary key to make the updates using the where current of clause

declare
 cursor c_pumps is select sale_id, low_price, high_price
                from pump_dummy for update;
begin
 for r_pumps in c_pumps loop
  update pump_dummy 
  set low_price = low_price * 1.2
   where current of c_pumps;
  update pump_dummy 
  set high_price = high_price * 1.2
   where current of c_pumps;
 end loop;
end;

 -- Now we'll query from the table with the reference cursor. This will allow our select statements to be dynamic. We'll
 -- use two different queries, one for pumpkins sold in Dallas, the other for pumpkins sold in Los Angeles.

declare
 type t_pumps is ref cursor return uspumpkins%rowtype;
 rc_pumps t_pumps;
 r_pumps uspumpkins%rowtype;
begin
 open rc_pumps for select * from uspumpkins
                            where city = 'DALLAS';
 loop
  fetch rc_pumps into r_pumps;
 exit when rc_pumps%notfound;
 dbms_output.put_line('The sale ID ' || r_pumps.sale_id || ' was for pumpkins that came from ' || r_pumps.origin );
 end loop;
 close rc_pumps;
 
 dbms_output.put_line('-----------');
 
 open rc_pumps for select * from uspumpkins
                             where city = 'LOS ANGELES';
 loop
  fetch rc_pumps into r_pumps;
 exit when rc_pumps%notfound;
 dbms_output.put_line('The sale ID ' || r_pumps.sale_id || ' was for pumpkins that came from ' || r_pumps.origin );
 end loop;
 close rc_pumps;
end;
 
-- We can declare our own record type with the reference cursors as well. We'll also use a join in our query

declare
 type ty_pumps is record (sale_id number, 
                        variety uspumpkins.variety%type, 
                        latin_names pumpkinlatinnames.latin_names%type);
                    
 r_pumps ty_pumps;
 
 type t_pumps is ref cursor return ty_pumps;
 rc_pumps t_pumps;
 
begin
 open rc_pumps for select p.sale_id, p.variety, l.latin_names from uspumpkins p
                           join pumpkin_latin_names l on (p.variety = l.variety);
 loop
  fetch rc_pumps into r_pumps;
 exit when rc_pumps%notfound;
 dbms_output.put_line('The sale ID ' || r_pumps.sale_id || ' was of the ' || r_pumps.variety || 
 ' and its Latin name is ' || r_pumps.latin_names );
 end loop;
 close rc_pumps;
end;
 
-- We can also make this query dynamic making it a weak reference cursor. We do that in the following way:

declare
 type ty_pumps is record (sale_id number, 
                        variety uspumpkins.variety%type, 
                        latin_names pumpkinlatinnames.latin_names%type);
                    
 r_pumps ty_pumps;
 
 type t_pumps is ref cursor;
 rc_pumps t_pumps;
 
 q varchar2(200);
 
begin

q := 'select p.sale_id, p.variety, l.latin_names from uspumpkins p
                           join pumpkin_latin_names l on (p.variety = l.variety)';
                           
 open rc_pumps for q;
 loop
  fetch rc_pumps into r_pumps;
 exit when rc_pumps%notfound;
 dbms_output.put_line('The sale ID ' || r_pumps.sale_id || ' was of the ' || r_pumps.variety || 
 ' and its Latin name is ' || r_pumps.latin_names );
 end loop;
 close rc_pumps;
end;

-- Let's say that we needed a procedure to increase the low price and high price of the sales every year, maybe for inflationary
-- purposes. Hopefully inflation would never be as high as we used in the example! But we'll make it 10 percent for more
-- contrast in the output
 
 create procedure Increase_Prices
 as
 cursor c_pumps is select * from pump_dummy for update;
 v_price_increase number := 1.10;
 v_low_old_price number;
 v_high_old_price number;
begin
 for r_pump in c_pumps loop
 v_low_old_price := r_pump.low_price;
 v_high_old_price := r_pump.high_price;
 r_pump.low_price := r_pump.low_price * v_price_increase;
 r_pump.high_price := r_pump.high_price * v_price_increase;
 update pump_dummy
 set row = r_pump where current of c_pumps;
 dbms_output.put_line(  'The low price for sale id ' || r_pump.sale_id || ' has increased from '
 ||v_low_old_price || ' to ' ||r_pump.low_price   || ' and the high price for sale id ' || r_pump.sale_id || ' has increased from '
 ||v_high_old_price || ' to ' ||r_pump.high_price);
 end loop;
end;

-- Let's say that we want to do the same procedure above, except that we want to be able to specify which pumpkin
-- sales we want to increase. So for example, instead of all the records, we just want to change those with pumpkins
-- that came from a particular state or country, or maybe want to be able to designate what the percentage increase is.
-- Additionally we would like for the procedure to return the number of rows affected 
-- We can do that with a procedure that takes parameters.


 create or replace procedure Increase_Prices(v_price_increase in number, v_origin in varchar2, v_affected_sales out number)
 as
 cursor c_pumps is select * from pump_dummy where origin = v_origin for update;
 v_low_old_price number;
 v_high_old_price number;
begin
v_affected_sales := 0;
 for r_pump in c_pumps loop
 v_low_old_price := r_pump.low_price;
 v_high_old_price := r_pump.high_price;
 r_pump.low_price := r_pump.low_price * v_price_increase;
 r_pump.high_price := r_pump.high_price * v_price_increase;
 update pump_dummy
 set row = r_pump where current of c_pumps;
 dbms_output.put_line(  'The low price for sale id ' || r_pump.sale_id || ' has increased from '
 ||v_low_old_price || ' to ' ||r_pump.low_price   || ' and the high price for sale id ' || r_pump.sale_id || ' has increased from '
 ||v_high_old_price || ' to ' ||r_pump.high_price);
 v_affected_sales :=  v_affected_sales + 1;
 end loop;
end;

-- now we'll run the procedure in a block

declare
 sales_affected number;
begin
Increase_Prices (1.07, 'TEXAS', sales_affected);
dbms_output.put_line('The number of rows affected is ' || sales_affected);
end;

-- we'll create a function that returns the average high price of pumpkin orders from a certain place of origin
-- as inputted by the user

create or replace function get_avg_high_price (p_origin uspumpkins.origin%type) return number as
v_avg number;
begin 
select avg(high_price) into v_avg
from uspumpkins
where origin = p_origin;
return v_avg;
end get_avg_high_price;

-- Now we'll use the function in a begin end block

create or replace function get_avg_high_price (p_origin uspumpkins.origin%type) return number as
v_avg number;
begin 
select round(avg(high_price), 2) into v_avg
from uspumpkins
where origin = p_origin;
return v_avg;
end get_avg_high_price;


-- Now we'll use the function in a begin end block to print the average high price

begin
dbms_output.put_line(get_avg_high_price('MISSOURI'));
end;

-- Here we'll use the function in a select statement to get the average high price by origin of each record

select sale_id, origin, high_price, get_avg_high_price(origin) as avg_origin_high_price 
from uspumpkins;

-- Now we'll use the function in a select statement to get only the rows that have a high price greater than their origin average

select sale_id, origin, high_price, get_avg_high_price(origin) as avg_origin_high_price 
from uspumpkins
where high_price > get_avg_high_price(origin);
