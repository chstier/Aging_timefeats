### This script plots original power at source level for specific age groups 
### 
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

library(qgraph)
library(corrplot)
library(igraph)
require(igraph)
library(effects)
library(ggplot2)
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
library(nlme)
library(sjstats)
library(R.matlab)
library(plyr)
library(abind)
library(reshape2)
library(tidyr)
library(devtools)
library(DescTools)
library(tidyr)
library(plyr)

setwd("~/files/freqs/source_lcmv_data")

# get power values for each subject and age group
filenames = Sys.glob("*cohort*_av*_orig*.mat") 

all_cohorts = list()

for ( co in 1:length(filenames)){	
  f_name = filenames[co]
  coh = substring(f_name, 8,8)
  
  if (coh == 'm') {
    
    data = readMat(filenames[co])
    a = array(unlist(data$cohort.pow.avchan), dim = c(60, 150 ))
    dimnames(a) = list('freqs' = 1:60, 'subjects' = 1:150)
    dat = as.data.frame(a)
    
    # reformat data frame
    dat_n = t(dat)
    dat_n = dat_n[,2:60]
    dat_n = dat_n
    
    # loop over frequency bin
    stats_m = list()
    stats_low = list() 
    stats_up = list() 
    
    n = 150 # number of subjects per cohort
    
    for ( f in 1:ncol(dat_n)){
      mean_f = mean(dat_n[,f]) # get mean for each freqbin
      s = sd(dat_n[,f])           # sd for the mean 
      error = qt(0.975,df=n-1)*s/sqrt(n) # get half of confidence interval
      low = mean_f - error
      up = mean_f + error
      
      stats_m[[f]] = mean_f
      stats_low[[f]] =  low
      stats_up[[f]] = up
    }
    
    # concatenate statistical values for all freqs
    mean_allfreq = as.data.frame(do.call(rbind, stats_m))
    low_allfreq = as.data.frame(do.call(rbind, stats_low))
    up_allfreq = as.data.frame(do.call(rbind, stats_up))
    freqs = c(2:60)
    freqs = freqs
    cohort = rep(coh, 59)
    
    allstats_allfreq = cbind(mean_allfreq, low_allfreq, up_allfreq, freqs, cohort)
    names(allstats_allfreq) = c('mean_freq', 'low_freq', 'up_freq', 'freqs', 'cohort')
    
  }
  else # for young and old cohort, which include 100 subjects each
  {
    
    data = readMat(filenames[co])
    a = array(unlist(data$cohort.pow.avchan), dim = c(60, 100 ))
    dimnames(a) = list('freqs' = 1:60, 'subjects' = 1:100 )
    dat = as.data.frame(a)
    # dat_all = reshape(dat, timevar = "subjects", idvar = "freqs", varying = list(1:50),
    #                   v.names = "connectivity", direction = "long")
    
    # reformat data frame
    dat_n = t(dat) 
    dat_n = dat_n[,2:60]
    dat_n = dat_n
    
    # loop over frequency bin
    stats_m = list()
    stats_low = list() 
    stats_up = list() 
    
    n = 100 # number of subjects per cohort
    
    for ( f in 1:ncol(dat_n)){
      mean_f = mean(dat_n[,f]) # get mean for each freqbin
      s = sd(dat_n[,f])           # sd for the mean 
      error = qt(0.975,df=n-1)*s/sqrt(n) # get half of confidence interval
      low = mean_f - error
      up = mean_f + error
      
      stats_m[[f]] = mean_f
      stats_low[[f]] =  low
      stats_up[[f]] = up
    }
    
    # concatenate statistical values for all freqs
    mean_allfreq = as.data.frame(do.call(rbind, stats_m))
    low_allfreq = as.data.frame(do.call(rbind, stats_low))
    up_allfreq = as.data.frame(do.call(rbind, stats_up))
    freqs = c(2:60)
    freqs = freqs
    cohort = rep(coh, 59)
    
    allstats_allfreq = cbind(mean_allfreq, low_allfreq, up_allfreq, freqs, cohort)
    names(allstats_allfreq) = c('mean_freq', 'low_freq', 'up_freq', 'freqs', 'cohort')
    
  }
  
  # save for each cohort
  all_cohorts[[co]] = allstats_allfreq
  
}

# make one file for all cohorts and statistical values
all_cohorts_plot = as.data.frame(do.call(rbind, all_cohorts))

## Averaged power at sources (Schäfer200 resolution)
n = ggplot(data=all_cohorts_plot, aes(x=freqs, y=mean_freq, color = cohort)) +
  geom_line(aes(colour=cohort), size=1.2) + 
  ylim(-0.01,0.2) +
  xlab("Frequency (Hz)") + 
  ylab("Original power (scaled)") +
  scale_color_manual(values=c("#b37d69", "#69b3a2","#b3699f"), # changed colors #b37d69
                     labels=c("young (18-38 y)", "middle (39-68 y)", "old (69-88 y)"),
                     breaks=c("y", "m", "o"), name = "Age group") + 
  scale_fill_manual(values=c("#b37d69", "#69b3a2","#b3699f"), breaks=c("y", "m", "o"), guide="none") +
  scale_x_continuous(breaks = c(10, 20, 30, 40, 50, 60)) +
  theme_pubr(base_size = 18, legend = c(0.8, 0.8)) 

ggsave(file="Age_freqs_power_whiteCI_sourcelcmv_features.png", dpi = 300, limitsize = TRUE, width = 6, height = 6)
