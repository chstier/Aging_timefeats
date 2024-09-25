### This script plots accuracies of conventional time-series features (Lasso-results)
### Christina Stier, 2024

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
library(tidyverse)    # Load tidyverse for dplyr and tidyr
library(tidymodels)   # For ML mastery 

##### set path
setwd('~/lasso')

##### get PLS results
p = readMat('~/Lasso_50rep_conv_av_transf.mat')
acc = as.numeric(p$av.acc)
mae = as.numeric(p$av.mae)
r2 = as.numeric(p$av.r2)
y_predicted = unlist(p$av.yhat)
betas_abs = array(unlist(p$reshaped.results), dim = c(19, 214)) 
betas = array(unlist(p$reshaped.notabs), dim = c(19, 214)) 
transfbetas_abs = array(unlist(p$feature.transf.abs), dim = c(19, 214)) 
transfbetas = array(unlist(p$feature.transf.notabs), dim = c(19, 214)) 
n = as.numeric(length(betas_abs[,1]))

set = as.data.frame(cbind(acc, mae, r2))
names(set)[1] =  'accuracies'
names(set)[2] =  'errors'
names(set)[3] =  'R^2'

# take number of parcels that were assigned a weight
np_abs = data.frame()
np_notabs = data.frame()

for (np in 1:n) {
  np_abs[np,1] = sum(betas_abs[np,] != 0)
  np_notabs[np,1] = sum(betas[np,] != 0)
}

# average betas across features
betas_abs_av = apply(betas_abs, 1, mean)
betas_av = apply(betas, 1, mean)

# get regular age
load("~/sciebo/Age/R_camcan/datasets/coh_img_data_absmean_global_allcohorts.Rda")

# change format of a few variables
all_imcoh$age = as.numeric(all_imcoh$age)
y = all_imcoh$age

# predicted age ~ real age
data = as.data.frame(cbind(y, y_predicted))
feat = 'conventional features combined'
#name = paste("Predicted Age (", freqname, ")", sep="") 

# plot y ~ yhat
g = ggplot(data, aes(x = y, y = V2)) + geom_point(colour="#C24949", alpha = 0.7, show.legend = NA) + labs(y="Predicted age", x="Age") + geom_abline(lty = 2)
g = g + scale_x_continuous(breaks=c(20,30,40,50,60,70,80,90,100))
g = g + scale_y_continuous(breaks=c(20,30,40,50,60,70,80,90,100))
g = g + coord_obs_pred(ratio = 1, xlim = NULL, ylim = NULL, expand = TRUE, clip = "on")
g = g + theme(text = element_text(size = 22), legend.title = element_blank(), panel.background = element_rect(fill = "white", colour = "grey50"), plot.margin=unit(c(0.5,0.5,0.5,0.5), "cm"))	
g = g + ggtitle("Conventional features combined")

ggsave(file="Age_predicted_conv_combined.png", plot=g, dpi = 300, limitsize = TRUE, width = 8, height = 8)	

# now plot feature names and parcel weights
##### read feature labels
file = '~/sciebo/Features_age/labels_therest2.csv'
labels = read.table(file,sep=";", header = FALSE)
labels = as.data.frame(labels)
labels = labels[1:20,1:6]# exclude the additional ones
labels[19,] = NaN;
labels = na.omit(labels)

##### use transformed betas instead
# average betas across features
tbetas_abs_av = apply(transfbetas_abs, 1, mean)
tbetas_av = apply(transfbetas, 1, mean)


# combine
data_full = cbind(set, labels, tbetas_abs_av, tbetas_av, np_abs, np_notabs)

names(data_full)[1]= 'accuracies'
names(data_full)[2]= 'errors'
names(data_full)[3]= 'R^2'
names(data_full)[4] =  'ID'
names(data_full)[5] =  'Name'
names(data_full)[6] =  'Label'
names(data_full)[7] =  'Keywords'
names(data_full)[8] =  'CodeString'
names(data_full)[9] =  'FullName'
names(data_full)[10] =  'Av_tbeta_absolute'
names(data_full)[11] =  'Av_tbeta'
names(data_full)[12] =  'N_parcels_abs'
names(data_full)[13] =  'N_parcels'

data_full$Keywords = as.factor(data_full$Keywords)
levels(data_full$Keywords)
levels(data_full$Keywords)[1] = "aperiodic-adj. band power" 
levels(data_full$Keywords)[3] = "alpha peak frequency"
levels(data_full$Keywords)[4] = "band power"
levels(data_full$Keywords)[5] = "aperiodic activity"

data_full %>%
  arrange(Av_tbeta_absolute) %>%
  mutate(FullName=factor(FullName, levels=FullName)) %>% 
  ggplot(aes(x=FullName, y=Av_tbeta_absolute)) +
  geom_segment( aes(x=FullName ,xend=FullName, y=min(Av_tbeta_absolute), yend=Av_tbeta_absolute), color="grey") +
  #scale_y_continuous(breaks=seq(min(Av_tbeta_absolute),0,max(Av_tbeta_absolute))) +
  geom_line( color="grey") +
  geom_point(shape=21, aes(fill = factor(Keywords)), size=4, show.legend = FALSE) +
  scale_fill_manual(values=c("#a269b3", "#b37d69", "#69b3a2", "#699fb3","#b3a269")) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle = 60, hjust = 1, size = 17), axis.text.y = element_text(size = 17), axis.title.y = element_text(size = 17, margin = margin(t = 0, r = 8, b = 0, l = 0)), axis.title.x = element_text(size = 17), plot.margin = margin(t=1, r=1, b=1, l=2, unit = "cm")) +
  ylab('Lasso weights (absolute, transf)') +
  xlab('Conventional features') 

ggsave('lasso_conventional_absolute_transf.png', dpi = 300, width = 12, height = 8)


data_full %>%
  arrange(Av_tbeta) %>%
  mutate(FullName=factor(FullName, levels=FullName)) %>% 
  ggplot(aes(x=FullName, y=Av_tbeta)) +
  geom_segment( aes(x=FullName ,xend=FullName, y=min(Av_tbeta), yend=Av_tbeta), color="grey") +
  #scale_y_continuous(breaks=seq(0.1,0.7,0.1)) +
  geom_line( color="grey") +
  geom_point(shape=21, aes(fill = factor(Keywords)), size=4, show.legend = FALSE) +
  scale_fill_manual(values=c("#a269b3", "#b37d69", "#69b3a2", "#699fb3","#b3a269")) +
  theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle = 60, hjust = 1, size = 17), axis.text.y = element_text(size = 17), axis.title.y = element_text(size = 17, margin = margin(t = 0, r = 8, b = 0, l = 0)), axis.title.x = element_text(size = 17), plot.margin = margin(t=1, r=1, b=1, l=2, unit = "cm")) +
  ylab('Lasso weights (transf)') +
  xlab('Conventional features') 

ggsave('lasso_conventional_transf.png', dpi = 300, width = 12, height = 8)


