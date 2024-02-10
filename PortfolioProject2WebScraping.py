# ScriptName:    PortfolioProject2
# Created on:    December 19th, 2023
# Author:        Christian Maxfield Welshinger
# Purpose:       Web scrape a table of countries and their regional and continental information to join to our
#                extinct languages table in MySQL
# Last Update:   December 27th, 2023
# Execution      Jupyter notebooks of the Anaconda distribution of Python was the environment in which this code was written.
#                If the source code changes significantly, this may cause the code to break, but as of December 27th, 2023, 
#                the following code is functional. And of coure the file path will change if you'd like to export the csv onto your computer


# Import librairies needed. This includes requests to get a response from the site to be scraped and returns a response
# object from which we can extract source code in the form of a string with the "text" method.
# Additionally, we need the bs4 library to import beautiful soup to parse the source code into a list
# object, the tag elements of which can then be referenced to extract the table and its data.
# Pandas will be used once we are formatting the data from the site into a dataframe. 

import requests
from bs4 import BeautifulSoup
import pandas as pd

# Save the url of the site to be scraped. This is the site with the country regional and continental data
# With the requests library and get method, pass in the URL and get the requested source code from the website
# One of the attributes of this response object, named 'r', is the source code, which we can see with the 'text'
# method as mentioned above. Another attribute of this object is its status code. Print this code and make sure it's
# "200" -- this means that the response object is valid

url = 'https://statisticstimes.com/geography/countries-by-continents.php'
r = requests.get(url)
print(r.status_code)

# Now make a "soup" -- a parsed document that turns the text attribute of the response object (which is a 
# string, a string of the entire source code), into an object that can referenced with all its tags. Basically, it turns
# the raw source file text back into a document that actually looks like html/css/js code organized and classified
# with all its tags and classes and ids and everything

soup = BeautifulSoup(r.text, 'html')

# There are 3 tables on this webpage. First, find all the objects marked as table in the soup, 
# this brings back a list of the three tables, then choose the third one (this is index 2) -- save as table
table = soup.find_all('table')[2]

# Print the table -- Make sure that you got the right table. Check the 'th' tags, as these are the column names

print(table)

# Begin to extract the column names of the table. Find these using the find all method with the 'th' tag

regionstitles = table.find_all('th')

# Make a lambda expression here that loops through the regionstitles list object. By applying the text
# method, you extract just the column names leaving the th tags and the CSS code accompanying each element 
# in the regionstitles list. This will give a list object containing just the column names. Print to verify
# it is correct

country_regions_titles = [title.text for title in regionstitles]
print(country_regions_titles)


# Now we use the pandas library, calling the DataFrame method on the country_regions_titles list -- make sure
# to set the list as the argument to the columns parameter. This will create a dataframe with the objects
# in this list as the column headers -- save as df object

df = pd.DataFrame(columns = country_regions_titles)

# Each 'tr' tag is a row of the table. By doing a find_all method on the table object with 'tr' as the argument,
# you'll get back a list where each element is a row of data. We're going to use this list to loop through
# and pull the data from the table object into our dataframe
column_data = table.find_all('tr')

# Using a for loop, loop through each element of the column_data list. For each element (row), use find_all
# using the 'td' tag as the argument to extract the row data and put into the row_data variable. 
# Then the row data_data gets inserted into the lamda expression for loop with the text method which extracts
# just the data value and inserts into the each_row list. Then print the list to see how it looks

for row in column_data:
    row_data = row.find_all('td')
    # country_regions_titles =
    each_row =  country_regions_titles = [data.text for data in row_data]
    print(each_row)

# Now we will make the actual dataframe, or table, and we will run a similar loop as above
# First, we noticed the the first list came back empty. This is because there were no 'td' tags in the first 
# row of the column_data list (this is because it contained only the column headers and thus no 'td' tag).
# For indexing the df, we use the current length of the dataframe. So at the first iteration, the length will be 
# zero, so the first row will go into the loc or index 0 of the dataframe (which is the first row) At the second
# iteration, the length will return 1, so the second row will go into dataframe index 1. So row 1 goes with index 0, 
# row 2 goes with index 1, etc. This goes on until the whole list of row elements of the column_data list have been
# iterated

for row in column_data[1:]:
    row_data = row.find_all('td')
    each_row = [data.text for data in row_data]
    length = len(df)
    df.loc[length] = each_row

# The purpose of this web scraping was to get this table into MYSQL to join to our extinct languages data. 
# So we will export the table as a csv. We do not need that first index column, as it will not be meaningful
# in our SQL script. 

df.to_csv('/Users/christianwelshinger/Desktop/CountryRegionsCSV/CountryRegions.csv', index = False)

