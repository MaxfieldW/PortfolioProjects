# 
# Script Name: Two Sample T-Test for River Oxygen Levels
# Created on:  02/01/2024
# Author:      Christian (Max) Welshinger
# Purpose:     Determine if the reduction in dissolved oxygen in river water
#              is significant or not

# Input values of upstream and downstream samples

Upstream <- c(5.2, 4.8, 5.1, 5.0, 4.9, 4.8, 5.0, 4.7, 4.7, 5.0, 4.6, 5.2, 5.0,
              4.9, 4.7)

Downstream <- c(3.2, 3.4, 3.7, 3.9, 3.6, 3.8, 3.9, 3.6, 4.1, 3.3, 4.5, 3.7, 3.9,
                3.8, 3.7)

# find n of the downstream data and assign to variable

n_Upstream <- length(Upstream)

# find n of the upstream data and assign to variable

n_Downstream <- length(Downstream)

# We'll make a table of the sample values

upVec <- rep('Upstream', each = n_Upstream)

downVec <- rep('Downstream', each = n_Downstream)

Oxygen_Content <- c(Upstream, Downstream)
Location <- c(upVec, downVec)

RiverDataTable <- data.frame(Oxygen_Content, Location)

# Load in in ggplot2 for generating boxplot
library(ggplot2)
# create a side-by-side boxplot of the two data sets

ggplot(RiverDataTable, aes(Location, y = Oxygen_Content)) +
  geom_boxplot() + labs(title = 'Concentration of Dissolved Oxygen') + 
  theme_bw()

# From the boxplots, we see that there is clearly a difference in 
# the data between the two sample. To start with, the upper outlier in the 
# downstream data is still below the lowest value in the upstream data. 
# The sets are both only slightly skewed, as the median for the upstream data 
# is slightly higher than the middle of the IQR, while the median of the 
# downstream water is slightly lower than the middle of the IQR.

# calculate the mean of the upstream data and assign to variable

mean_Upstream <- mean(Upstream)

# calculate the mean of the downstream data and assign to variable

mean_Downstream <- mean(Downstream)


# find the difference of the two means and assign to variable. We'll
# subtract the upstream from the downstream to get a negative -- This
# is because our hypthosesis test will centered around -0.5, because
# we already assume the oxygen is decreased, but we want to know if
# it's significantly different from -0.5

DifferenceOfMeans <-mean_Downstream - mean_Upstream

# find the variance of the upstream data and assign to variable

var_Upstream <- var(Upstream)

# find the variance of the downstream data and assign to variable

var_Downstream <- var(Downstream)


# We need to determine which two sample t-test to perform, a Welch's t-test,
# or a regular t-test. In other words, we need to determine if we can assume
# that the variances between the two samples are the same. We'll do that by
# dividing the greater of the two by the lesser, and seeing if the result
# is less than 4

var_Downstream/var_Upstream

# So we'll use pooled variance since the proportion between the greater and lesser
# variance is less than 4

PooledVariance <- ((n_Downstream-1) * var_Downstream + 
                   (n_Upstream-1) * var_Upstream) /
  (n_Downstream + n_Upstream - 2)

# calculate the t-statistic manually using the formula

tstat <- (DifferenceOfMeans + 0.5) / 
  (sqrt(PooledVariance * (1/n_Upstream + 1/n_Downstream)))

# Use the qt function to get the critial value for a two-tailed t-distribution
# with 99 percent confidence interval and 28 degrees of freedom

CriticalT <- qt(0.995, df = 28)

# calculate the margin of error and assign to variable

MOE <- CriticalT * sqrt(PooledVariance * (1/n_Upstream + 1/n_Downstream))

# calculate the left side of the confidence interval

CILeft <- DifferenceOfMeans - MOE

# calculate the right side of the confidence interval

CIRight <- DifferenceOfMeans + MOE

#code for getting R to do the t test for you

t.test(Downstream, Upstream, paired = FALSE, alternative = "two.sided",
       mu = -0.5, conf.level = 0.99, var.equal = TRUE )


# a) The data  provide sufficient evidence to reject the null
# hypothesis, meaning that there is sufficient evidence to show that there
# is a significant reduction in the amount of dissolved oxygen in the
# river water as a result of the discharge. With a critical t value of -2.467,
# we would certainly reject the null hypothesis which states that there is no
# significant decrease of dissolved oxygen in the river water, given that our
# calculated t value is -6.963, well beyond our critical t value.

# d) We are 99% confident that the real difference in dissolved oxygen in PPM
# between the upstream water and the downstream water is between
# -1.431 and -0.902
