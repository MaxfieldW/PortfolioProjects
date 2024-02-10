# ScriptName:    PortfolioProject3
# Created on:    October 15th, 2023
# Author:        Christian Maxfield Welshinger
# Purpose:       The purpose of this program is to distribute rows of data from one single table
#                into various other tables, evenly distributing the rows by number and by size (size in this case
#                is represented by a credit limit) -- More specifically, each row of the original table represents a client to be called,
#                and each client has an allowed credit limit. We have 5 employees that make calls to these clients.
#                Each day, new clients are populated in the table, and those clients are distributed evenly to the 
#                5 agents that make the calls. The clients are apportioned to the agents in such a way that each agent
#                receives the same number of calls, and a comparable total sum of credit limits (in other words, one
#                particular agent is not calling clients that are significantly bigger accounts than any other agent).
#                The number of agents could easily be changed by changing the indexing initialized before the program.
# Last Update:   December 28th, 2023
# Execution      Jupyter notebooks of the Anaconda distribution of Python was the environment in which this code was written.
#                The program is flexible in that it can work with any number of rows, but a dummy table is provided in the
#                code so that is completely runable as is                

# Import the necessary libraries. Numpy is being used to convert lists into arrays and to generate ranges, while
# pandas is used once the arrays are assembled and can be turned into a dataframe

import numpy as np
import pandas as pd

# For this example, we will have 5 agents. We will create an array for each agent
# with dummy values for each list comprising the array

Agent1 = np.array([[1, 'b' ,3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3], [1,'b',3], [1,'b',3]])
Agent2 =  np.array([[1, 'b' ,3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3], [1,'b',3], [1,'b',3]])
Agent3 =  np.array([[1, 'b' ,3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3], [1,'b',3]])
Agent4 = np.array([[1, 'b' ,3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3], [1,'b',3]])
Agent5 =  np.array([[1, 'b' ,3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3],[1,'b',3], [1,'b',3]])

# The program works off of a series of indices used to iterate through the elements of the list containing
# the agent, the list containing the indices, and the list containing the dummy rows to be changed out with the real values
# Create the counter variables (representing index numbers) index lists, the list of the indices, and the list of the agents

IndexNumber = 0
IndexOfIndex = 0
ArrayCounter = 0

index0 = [0,1,2,3,4]
index1 = [1,2,3,4,0]
index2 = [2,3,4,0,1]
index3 = [3,4,0,1,2]
index4 = [4,0,1,2,3]

indices = [index0, index1, index2, index3, index4]

agents = [Agent1, Agent2, Agent3, Agent4, Agent5]

# Now create the dataframe with the clients to call. Normally this would be uploaded as a CSV, but in order to make the
# program runable autonamously, I have included the following dataframe to work with the program. In order for the program
# to work, the credit limits must be either in ascending or descending order, which is the case with the dataframe given here,
# but if this were used with some other CSV file, an "order by credit limit" operation would need to be performed first

columns = ['Activation_Case_ID', 'Business_Name', 'Credit_Limit']

callRows = np.array([[38947,"Bob’s Banking Solutions", 25000],[64884, "Larry’s Laundromat",24000],[84950, "Sam's Salon",23000],[84549,'Wendy’s Windows',22000],[29244,"Mike’s Milkshakes",21000],
          [48303,"Bobby’s Briskets",20000],[93837,"Cindy’s Sandwiches",19000],[73494,"Craig’s Candles",18000],[48493,"Billy’s Bison Burgers",17000],[34849,"Will’s Wall Washing",16000],
          [57493,"Zach’s Xylophones",15000],[57993,"Kevin’s Concrete",14000],[47473,"James’ Jelly and Jam", 13000], [33849, "George’s Jump Ropes",12000],[57483,"Micky’s Milling",11000],
          [44940,"Rodney’s Rockclimbing",10000],[46483,"Liam’s Library",9000],[38394,"Rocky’s Ribeyes and Steaks",8000],[57584,"Maddie’s Mall",7000],[58930,"Jackson’s Jelly Beans",6000],
          [28393,"Wilson’s Wagons",5000],[57584,"Jeff’s Jewelry",4000],[38394,"Mark’s Mining Gear",3000],[48493,"Sally’s Saddles",2000],[38393,"Caleb’s Cornbreads",1000], 
                     [38356,"Cassie's Crackers",500], [34534,"Billy's Bakes Goods",300]])  

# Create an array with a list going from zero to the maximum number of rows (this is the number of list elements
# in the callRows array) 
 
# Create the dataframe with the callRows array as the table data, the clientRows as the number of rows, and columns
# as the column name

# View table to make sure it is correct

clientRows = np.arange(0,len(callRows)) 

ClientsToCall = pd.DataFrame(callRows, clientRows, columns)

ClientsToCall

# Now that the variables have been initialized, and the dataframe created, the program can be run
# The program starts with a for loop, iterating through a range going from zero to the indexed value 
# of the last row of the ClientstoCall table
# The i iterator value is used in the iloc method with the table to extract the row and input it into the 
# designated array for the designated agent (the designation is determined by the current index values)
# After each iteration when a list has been added to an agent array, there are two if statements. First,
# if the IndexofIndex (which controls the index number within each index, numbered 0 through 4) equals 4, then it is
# set to -1, and IndexNumber is increased and ArrayCounter is increased (this is because when IndexOfIndex
# equals 4, this implies that each agent has been given a client, and it is time to loop back through,
# changing the assignment order so as to keep the credit limits distributed as fairly as possible).
# For the second if statement, if the IndexNumber is greater than 4 (which implies that all indexing configurations
# have been used) then it must be set back to zero. These differing indexing orders are what is used to 
# to evenly distribute the cases as long as the credit limit is in ascending or descending order, as mentioned above.
# Finally, the IndexOfIndex is always incremented. This is because on every iteration, we are giving a row
# to a different agent (one unique agent per iteration)

for i in range(len(ClientsToCall)):
    
    agents[indices[IndexNumber][IndexOfIndex]][[ArrayCounter]] = ClientsToCall.iloc[[i]]
    
    if IndexOfIndex == 4:
        IndexOfIndex = -1
        IndexNumber += 1
        ArrayCounter += 1
        
    
    if IndexNumber > 4:
        IndexNumber = 0
        
        
    IndexOfIndex += 1
    

# Now that the lists from the original table have all been added to the agent arrays, these arrays can
# be turned into a dataframe for each agent.

# First, we have to determine an arbitrarily high number of rows to accord to each dataframe. Basically, we just
# need to make sure that there are more rows than will ever be given by the function (having too many rows is not
# a problem, as we will see later, too few though will make it so that not all the lists from the array can be made into rows)

# Then create the dataframes. As before, we call the Dataframe method, passing in the array with the lists
# which, again, represent the rows. Then the arbitrarily high number of rows are inserted, and then the column names
# (which are the same as the original dataframe, so we can reuse the columns list)

agent_rows = np.arange(1, 8)

Agent1_Accounts_to_Call = pd.DataFrame(Agent1, agent_rows, columns)

Agent2_Accounts_to_Call = pd.DataFrame(Agent2, agent_rows, columns)

Agent3_Accounts_to_Call = pd.DataFrame(Agent3, agent_rows, columns)

Agent4_Accounts_to_Call = pd.DataFrame(Agent4, agent_rows, columns)

Agent5_Accounts_to_Call = pd.DataFrame(Agent5, agent_rows, columns)

# The dataframes are almost ready. Now we have to trim off the extra dummy rows. The reason 
# we have these is that in the real world, the number of clients to call would be different every day
# In this example, we just have a static hard-coded table, but the purpose of this program is that it can be
# used with new CSV files with differing numbers of rows (representing different numbers of clients to call)

# We will use the drop method to eliminate the rows where "Business_Name" is still 'b' -- A value of 'b'
# for this column implies that the original dummy list was never replaced by a real list from the original table

# Then print each dataframe for each agent once the extraneous rows have been removed

df = Agent1_Accounts_to_Call
Agent1_Accounts_to_Call = df.drop(df[df.Business_Name == 'b'].index)

print(Agent1_Accounts_to_Call)

df = Agent2_Accounts_to_Call
Agent2_Accounts_to_Call = df.drop(df[df.Business_Name == 'b'].index)

print(Agent2_Accounts_to_Call)

df = Agent3_Accounts_to_Call
Agent3_Accounts_to_Call = df.drop(df[df.Business_Name == 'b'].index)

print(Agent3_Accounts_to_Call)

df = Agent4_Accounts_to_Call
Agent4_Accounts_to_Call = df.drop(df[df.Business_Name == 'b'].index)

print(Agent4_Accounts_to_Call)

df = Agent5_Accounts_to_Call
Agent5_Accounts_to_Call = df.drop(df[df.Business_Name == 'b'].index)

print(Agent5_Accounts_to_Call)

