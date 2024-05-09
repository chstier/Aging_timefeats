### This script plots average accuracies of conventional time-series features
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
p = readMat('~/pls_av_full_10k_5c_hctsa_r50_stratf.mat')
acc = array(unlist(p$av.acc), dim = c(1, 5988))
mae = array(unlist(p$av.mae), dim = c(1, 5988))
r2 = array(unlist(p$av.r2), dim = c(1, 5988))

set = as.data.frame(cbind(t(acc), t(mae), t(r2)))
names(set)[1] =  'accuracies'
names(set)[2] =  'errors'
names(set)[3] =  'R^2'

set = set[5962:5988,] # only keep conventional ones 
set = set[1:20,] # exclude additional set (Hjorth parameters etc.)

##### read feature abels
file = '~/sciebo/Features_age/feature_labels_conventional.csv'
labels = read.table(file,sep=";", header = FALSE)
labels = as.data.frame(labels)
labels = labels[1:20,1:6]# exclude the additional ones

# plot accuracies across labels
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
names(data_full)[9] =  'FullName'

save(data_full, file = '~/sciebo/Features_age/data/selected_conventional_pred.RData')
write.csv(data_full, file = '~/sciebo/Features_age/results_all_subjects/pls/PLS_conventional_r50_stratf.csv', row.names = FALSE)

##### Plot accuracy of each single feature based on keywords/feature categories
# get rid of NA-Variable
data_full = na.omit(data_full)
data_full$Keywords = as.factor(data_full$Keywords)
levels(data_full$Keywords)
levels(data_full$Keywords)[1] = "aperiodic-adj. band power" 
levels(data_full$Keywords)[3] = "alpha peak frequency"
levels(data_full$Keywords)[4] = "band power"
levels(data_full$Keywords)[5] = "aperiodic activity"

data_full %>%
  arrange(accuracies) %>%
  mutate(FullName=factor(FullName, levels=FullName)) %>% 
  ggplot(aes(x=FullName, y=accuracies)) +
  geom_segment( aes(x=FullName ,xend=FullName, y=0.09, yend=abs(accuracies)), color="grey") +
  scale_y_continuous(breaks=seq(0.1,0.7,0.1)) +
  geom_line( color="grey") +
  geom_point(shape=21, aes(fill = factor(Keywords)), size=4, show.legend = FALSE) +
  scale_fill_manual(values=c("#a269b3", "#b37d69", "#69b3a2", "#699fb3","#b3a269")) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle = 60, hjust = 1, size = 17), axis.text.y = element_text(size = 17), axis.title.y = element_text(size = 17, margin = margin(t = 0, r = 8, b = 0, l = 0)), axis.title.x = element_text(size = 17), plot.margin = margin(t=1, r=1, b=1, l=2, unit = "cm")) +
  ylab('Prediction accuracies (r)') +
  xlab('Conventional features') 

ggsave('acc_others_10k_5c_sorted_conventional_colored.png', dpi = 300, width = 12, height = 8)

##### Plot based on keywords/feature categories
data_full %>%
  mutate(Keywords = fct_relevel(Keywords,
                                "connectivity", "band power", "aperiodic activity", "aperiodic-adj. band power")) %>% 
  ggplot(aes(x=Keywords, y=accuracies)) +
  geom_segment(aes(x=Keywords ,xend=Keywords, y=0.09, yend=abs(accuracies)), color="grey") +
  scale_y_continuous(breaks=seq(0.1,0.7,0.1)) +
  geom_line(color="grey") +
  geom_point(shape=21, aes(fill = factor(Keywords)), size=4, show.legend = FALSE) +
  scale_fill_manual(values=c("#b37d69", "#699fb3", "#b3a269","#a269b3", "#69b3a2")) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle = 60, hjust = 1, size = 17), axis.text.y = element_text(size = 17), axis.title.y = element_text(size = 17, margin = margin(t = 0, r = 8, b = 0, l = 0)), axis.title.x = element_text(size = 17), plot.margin = margin(t=1, r=2, b=1, l=2, unit = "cm")) +
  ylab('Prediction accuracies (r)') +
  xlab('Categories (conventional features)')
# + ggtitle("5 comp, 15 rep")

ggsave('acc_others_10k_5c_conventional_keyw_colored.png', dpi = 300, width = 6, height = 7)
