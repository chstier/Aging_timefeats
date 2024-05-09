### This script plots the autocorrelation function for specific age groups
### Christina Stier, 2023

## R version 4.2.2 (2022-10-31)
## RStudio 2023.3.0.386 for macOS

rm(list = ls())

install.packages("corrplot")
install.packages("igraph")
install.packages("qgraph")
install.packages("car")
install.packages("compute.es")
install.packages("effects")
install.packages("compute.es")
install.packages("ggplot2")
install.packages("multcomp")
install.packages("pastecs")
install.packages("psych")
install.packages("Hmisc")
install.packages("Rcmdr")
install.packages("splines")
install.packages("gridExtra")
install.packages("grid")	
install.packages("ggpubr")
install.packages("cowplot")
install.packages("optimx")
install.packages("plyr")
install.packages("doBy")
install.packages("boot")
install.packages("lmPerm")
install.packages('R.matlab')
install.packages('abind')
install.packages("devtools")
install.packages("plotrix")
install.packages("gcookbook")
install.packages("hrbrthemes")
install.packages("dplyr")
install.packages("tidyverse")
install.packages("ggseg")
install.packages("extrafont")

# load packages
library(tidyverse)
library(qgraph)
library(corrplot)
library(igraph)
require(igraph)
library(compute.es)
library(effects)
library(multcomp)
library(pastecs)
library(psych)
library(Hmisc)
library(car)
library(grid)
library(gridExtra)
library(ggpubr)
library(cowplot)
library(lme4)
library(optimx)
library(plyr)
library(doBy)
library(boot)
library(lmPerm)
library(R.matlab)
library(plyr)
library(abind)
library(reshape2)
library(tidyr)
library(ggseg)
library(ggplot2)
library(multcomp)
library(devtools)
library(reshape2)
library(tidyr)
library(plyr)
library(gcookbook) 
library(dplyr)
library(tidyr)
library(extrafont)
library(hrbrthemes)

# set working directory
setwd("~/sciebo/Features_age/plots/Features/")

###################################### Plot (AC temporal cortex)
# load AC measures for all subjects
f = readMat(paste('~/sciebo/Features_age/data/', 'data_AC1to40_t4.mat', sep = "")) # or v8
featv = as.data.frame(array(unlist(f$AC.t4), dim = c(350, 40))) # or v8

# sepcify age groups
young = c(rep(0, 100))
middle = c(rep(1, 150))
old = c(rep(2, 100))
age = as.factor(c(young, middle, old))

dat = cbind(featv, age)
av_dat = aggregate(dat[, 1:40], list(dat$age), mean)
names(av_dat)[1] = 'age_group'
names(av_dat)[2:41]= as.character(c(1:40))

# create times for lags
v = (1:40)
ms = (v/300)*1000  
ms = round(ms, digits = 1)
time = rep(ms, each = 3)
time = as.factor(time)

# create long format
data_long <- gather(av_dat, lags, AC, 2:41, factor_key=TRUE)
levels(data_long$age_group) = c("young", "middle", "old")
str(data_long)

data_long = cbind(data_long, time)

# filtered_data <- data_long[data_long$time %in% c(1, 4, 7), ]

d = data_long %>%
  ggplot(aes(fill=age_group, x=time, y=AC)) +
  geom_line() +
  geom_point(shape=21, size=4) +
  scale_color_manual(values = c("young" = "#b37d69", "middle" = "#69b3a2", "old" = "#b3699f")) +
  scale_fill_manual(values = c("young" = "#b37d69", "middle" = "#69b3a2", "old" = "#b3699f")) +
  labs(x = "Time lags (ms)", fill = "group", y = "AC (Schaefer T4, lh)") +   #  AC visual cortex (V8, rh)
  scale_y_continuous(breaks=c(-0.6, -0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8, 1)) +
  scale_x_discrete(breaks = c(3.3, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130)) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.ticks = element_blank(), text = element_text(size = 28), legend.title = element_blank()) +
  ggtitle("Autocorrelation function")

ggsave('AC_allgroups_t4_new.png', plot = d, dpi = 300, width = 15, height = 10) # change filename

###################################### Plot (AC visual cortex)
# load AC measures for all subjects
f = readMat(paste('~/sciebo/Features_age/data/', 'data_AC1to40_v8.mat', sep = "")) # or v8
featv = as.data.frame(array(unlist(f$AC.v8), dim = c(350, 40))) # or v8

# sepcify age groups
young = c(rep(0, 100))
middle = c(rep(1, 150))
old = c(rep(2, 100))
age = as.factor(c(young, middle, old))

dat = cbind(featv, age)
av_dat = aggregate(dat[, 1:40], list(dat$age), mean)
names(av_dat)[1] = 'age_group'
names(av_dat)[2:41]= as.character(c(1:40))

# create times for lags
v = (1:40)
ms = (v/300)*1000  
ms = round(ms, digits = 1)
time = rep(ms, each = 3)
time = as.factor(time)

# create long format
data_long <- gather(av_dat, lags, AC, 2:41, factor_key=TRUE)
levels(data_long$age_group) = c("young", "middle", "old")
str(data_long)

data_long = cbind(data_long, time)


# Plot (AC visual cortex)
d = data_long %>%
  ggplot(aes(fill=age_group, x=time, y=AC)) +
  geom_line() +
  geom_point(shape=21, size=4) +
  scale_color_manual(values = c("young" = "#b37d69", "middle" = "#69b3a2", "old" = "#b3699f")) +
  scale_fill_manual(values = c("young" = "#b37d69", "middle" = "#69b3a2", "old" = "#b3699f")) +
  labs(x = "Time lags (ms)", fill = "group", y = "AC (Schaefer V8, rh)") +   #  change here
  scale_y_continuous(breaks=c(-0.6, -0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8, 1)) +
  scale_x_discrete(breaks = c(3.3, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130)) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.ticks = element_blank(), text = element_text(size = 28), legend.title = element_blank()) +

ggsave('AC_allgroups_v8_new.png', plot = d, dpi = 300, width = 15, height = 10) # change filename
