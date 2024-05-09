### This script plots average accuracies of novel time-series features
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

##### set path
setwd('~/Age_predicted_r50_stratf')

##### get PLS results
p = readMat('~/sciebo/Features_age/data/pls_av_full_10k_5c_hctsa_r50_stratf.mat')
acc = array(unlist(p$av.acc), dim = c(1, 5988)) 
mae = array(unlist(p$av.mae), dim = c(1, 5988))
r2 = array(unlist(p$av.r2), dim = c(1, 5988))

set = as.data.frame(cbind(t(acc), t(mae), t(r2)))
names(set)[1] =  'accuracies'
names(set)[2] =  'errors'
names(set)[3] =  'R^2'

set = set[1:5961,] # only keep hctsa features

# read feature labels
file = '~/sciebo/Features_age/labels_selectedfeatures_basic.csv'
labels = read.table(file,sep=";", header = TRUE)
labels = as.data.frame(labels)

# combine
data_full = cbind(set, labels)
names(data_full)[1]= 'accuracies'
names(data_full)[2]= 'errors'
names(data_full)[3]= 'R^2'
names(data_full)[4] =  'ID'
names(data_full)[5] =  'Name'
names(data_full)[6] =  'Label'
names(data_full)[7] =  'Keywords'
names(data_full)[8] =  'CodeString'

save(data_full, file = '~/sciebo/Features_age/data/selected_hctsa_pred.RData')
write.csv(data_full, file = '~/sciebo/Features_age/results_all_subjects/pls/PLS_hctsa_r50_stratf.csv', row.names = FALSE)

##### plot feature names 
data_str = data_full[data_full$accuracies > 0.7,]

s =  ggplot(data_str, aes(x=Name, y=accuracies)) +
  geom_segment( aes(x=Name ,xend=Name, y=0.675, yend=abs(accuracies)), color="grey") +
  geom_line( color="grey") +
  geom_point(shape=21, color="black", fill="#697ab3", size=3) +
  #geom_label() +
  #geom_text(angle = 40) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle = 60, hjust = 1), axis.title.y = element_text(size = 17), axis.title.x = element_text(size = 17)) +
  ylab('Prediction accuracies (r)') +
  xlab('Hctsa+ features') 
# + ggtitle("Prediction accuracies of time-series features > 0.7 (5 comp, 15 rep)")

ggsave('acc_hctsa_10k_5c+.png', plot = s, dpi = 300, width = 15, height = 8)

##### plot keywords 
data_str = data_full[data_full$accuracies > 0.7,]

s =  ggplot(data_str, aes(x=Keywords, y=accuracies)) +
  geom_segment( aes(x=Keywords ,xend=Keywords, y=0.699, yend=abs(accuracies)), color="grey") +
  geom_line( color="grey") +
  scale_y_continuous(breaks=seq(0.7,0.77,0.01)) +
  geom_point(shape=21, color="black", fill="#697ab3", size=3) +
  #geom_label() +
  #geom_text(angle = 40) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle = 60, hjust = 1, size = 17), axis.text.y = element_text(size = 17), axis.title.y = element_text(size = 16, margin = margin(t = 0, r = 8, b = 0, l = 0)), axis.title.x = element_text(size = 16), plot.margin = margin(t=1, r=1, b=1, l=2, unit = "cm")) +
  ylab('Prediction accuracies (r)') +
  xlab('Feature categories (hctsa)') 
# + ggtitle("Prediction accuracies of time-series features > 0.7 (5 comp, 15 rep)")

ggsave('acc_hctsa_10k_5c.png', plot = s, dpi = 300, width = 9, height = 8 )