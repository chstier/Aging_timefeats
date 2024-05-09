### This script plots individual values for alpha peak frequency
### Based on the center of gravity approach
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

# set working directory
setwd("~/sciebo/Features_age/plots/Features/")

# get regular age
load("~/sciebo/Age/R_camcan/datasets/coh_img_data_absmean_global_allcohorts.Rda")

# change format of a few variables
all_imcoh$age = as.numeric(all_imcoh$age)
y = all_imcoh$age

# load center of gravity measures for all subjects
f = readMat(paste('~/sciebo/Features_age/data/', 'data_cog_idx18_68.mat', sep = "")) # 
featv = as.data.frame(array(unlist(f$cog), dim = c(350, 2))) #

data = cbind(y, featv)
names(data)[1] = "age"
names(data)[2] = "cog_pos" 
names(data)[3] = "cog_neg"

###################################### Plot positive parcel

g = ggplot(data, aes(x = age, y = cog_pos)) + geom_point(aes(col="#393939"), alpha = 1) + 
  stat_smooth(method = "lm", formula = y ~ x, se = FALSE, size = 1, color = "#525252") + 
  labs(y="Center of gravity (Hz)", x="Age") +
  scale_color_viridis_d(option = "inferno", guide = FALSE) +
  scale_x_continuous(breaks=c(20,30,40,50,60,70,80)) + 
  theme(text = element_text(size = 23), legend.title = element_blank(), panel.background = element_rect(fill = "white", colour = "grey50"), plot.margin=unit(c(0.5,0.5,0.5,0.5), "cm"))	

ggsave('Cog_pos.png', plot = g, dpi = 300, width = 8, height = 8) # change filename


###################################### Plot negative parcel

g = ggplot(data, aes(x = age, y = cog_neg)) + geom_point(aes(col="#393939"), alpha = 1) + 
  stat_smooth(method = "lm", formula = y ~ x, se = FALSE, size = 1, color = "#525252") + 
  labs(y="Center of gravity (Hz)", x="Age") +
  scale_color_viridis_d(option = "inferno", guide = FALSE) +
  scale_x_continuous(breaks=c(20,30,40,50,60,70,80)) + 
  theme(text = element_text(size = 23), legend.title = element_blank(), panel.background = element_rect(fill = "white", colour = "grey50"), plot.margin=unit(c(0.5,0.5,0.5,0.5), "cm"))	

ggsave('Cog_neg.png', plot = g, dpi = 300, width = 8, height = 8) # change filename
