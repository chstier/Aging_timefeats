### This script plots scatterplots for the correlation between real age and predicted age values
### Christina Stier, 2023

## R version 4.2.2 (2022-10-31)
## RStudio 2023.3.0.386 for macOS

rm(list = ls())

## load packages
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
install.packages("tune")
install.packages("tidyverse")
install.packages("tidymodels")
install.packages("pak")
pak::pak("tidymodels/tidymodels")

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
library(tidyverse)    # Load tidyverse for dplyr and tidyr
library(tidymodels)   # For ML mastery 
tidymodels_prefer()   # To resolve common conflicts

# set working directory
setwd("~/PLS_results/")

# get regular age
load("~/sciebo/Age/R_camcan/datasets/coh_img_data_absmean_global_allcohorts.Rda")

# change format of a few variables
all_imcoh$age = as.numeric(all_imcoh$age)
y = all_imcoh$age

################## Load all prediction accuracies and select feature
p = readMat('~/sciebo/Features_age/data/pls_av_full_10k_5c_hctsa_r50_stratf.mat')
yhat = as.data.frame(array(unlist(p$av.yhat), dim = c(350, 5961))) # with all: 5987 

# read labels
file = '~/sciebo/Features_age/labels_selectedfeatures_basic.csv'
labels = read.table(file,sep=";", header = TRUE)
labels = as.data.frame(labels)

which(labels$Name == 'AC_11')
which(labels$ID == '113') # ID

# ggplot
data = as.data.frame(cbind(y, yhat))
feat = labels$Name[94]
variable = "94"
title = "Autocorrelation at time-delay 36 ms" # 

# Using prediction line - colored
g = ggplot(data, aes(x = y, y = V94)) + geom_point(colour="#C24949", alpha = 0.7, show.legend = NA) + labs(y="Predicted age", x="Age") + geom_abline(lty = 2)
g = g + scale_x_continuous(breaks=c(20,30,40,50,60,70,80,90,100))
g = g + scale_y_continuous(breaks=c(20,30,40,50,60,70,80,90,100))
g = g + coord_obs_pred(ratio = 1, xlim = NULL, ylim = NULL, expand = TRUE, clip = "on")
g = g + theme(text = element_text(size = 22), legend.title = element_blank(), panel.background = element_rect(fill = "white", colour = "grey50"), plot.margin=unit(c(0.5,0.5,0.5,0.5), "cm"))	
g = g + ggtitle(title)

ggsave(file=paste("Age_predicted_", feat, "_red.png", sep=""), plot=g, dpi = 300, limitsize = TRUE, width = 8, height = 8)       
       


