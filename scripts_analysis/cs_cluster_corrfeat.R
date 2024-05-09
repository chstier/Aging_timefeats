### This script creates a distancematrix to plot dependencies between 
### highly predictive features
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
install.packages("pheatmap")

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

library(png)
library(RColorBrewer)
library(pheatmap)

setwd('~/sciebo/Features_age/plots')

#load dataset with features for ~100 features that have accuracy > 0.7
all = readMat('~/sciebo/Features_age/data/selected_features_labels_7.mat')

Array1 <- array(data = c(unlist(all$dat)),
                 dim = c(350, 214, 113))

all_data = list()
for (l in 1:dim(Array1)[1]){
  a = as.data.frame(Array1[l,,])
  all_data[[l]] = a
}

allres = do.call(rbind, all_data)

m = cor(allres)
save(m, file = "Corrmat_acc7.Rdata")

# get the labels
all_labels = c(unlist(all$labels7))  

# now plot distance
d = 1-abs(m)
rownames(d) = all_labels
colnames(d) = all_labels

############################################################ 
# Include Annotations
# Defaults for accuracy 7 and higher

# Get Keywords
keywords = c(unlist(all$groups7))
# Data frame with column annotations.
mat_col <- data.frame(group = keywords)
rownames(mat_col) <- colnames(d)

# List with colors for each annotation.
#mat_colors <- list(group = brewer.pal(13, "Set1"))
mat_colors <- list(group = colorRampPalette(brewer.pal(8, "Set2"))(22))
names(mat_colors$group) <- unique(keywords)

path = "~/sciebo/Features_age/plots"

png(file.path(path, "heatmap_7_annot_try.png"),width = 25, height = 25, units = "in", res = 300)
pheatmap(d,
         clustering_method = "complete",  # Hierarchical clustering method
         cluster_rows = TRUE,  # Cluster rows
         cluster_cols = TRUE,  # Cluster columns
         color = colorRampPalette(brewer.pal(9, "RdBu"))(100),  # Color palette
         annotation_col    = mat_col,
         annotation_colors = mat_colors,
         annotation_legend = FALSE,
         # main = "Distance Matrix for Features with Pred. Accuracy of >0.7",
         cexRow = 15,  # Adjust the row label size
         cexCol = 15,  # Adjust the column label size
         legend = FALSE
         #margins = c(6, 6)  # Adjust the margins
)
dev.off()

