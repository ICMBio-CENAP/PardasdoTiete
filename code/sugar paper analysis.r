# ---
# title:  Analysis for manuscript on Sugar cane preference
# author: Jorge Menezes    <jorgefernandosaraiva@gmail.com> 
# # 
# ---

# Intent: This is a run of the maxent analysis for the manuscript on the preference
# of sugar cane by pumas

# Input: A Geopackage with all the individuals locations, and one directory with maps
# and another with observed area stacks (for training and testing) 

# Output: A maxent model with evaluation replicated 10 times.
library(sf)
library(dismo) 
library(ggplot2) 
library(gridExtra)
source("./code/maxenter.r")
experiment.folder <- "./experiment007"
res<-30

# Running the maxent with 100 replicates
    maxenter( data     = paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"),
              obsdir   = paste0(experiment.folder,"/mapsderived/observedstack"),
              modelfile =  "./Sugarcane paper/maxentmodel.rds",
              evalfile = "./Sugarcane paper/maxenteval.rds",
              args = "replicates=100",
              nc = 10   
     )

# Load maxent result
model = readRDS("./Sugarcane paper/maxentmodel.rds")
reps = model@results

# Get contribution for each variable
contribs = reps[grepl("contribution",rownames(reps)),]
contribs = t(contribs)
contribs = contribs[-nrow(contribs),]
sugar_contribs = reps [c( 
    "prop_sugar_100m.contribution",
    "prop_sugar_2500m.contribution",
    "prop_sugar_5000m.contribution",
    "prop_sugar_500m.contribution"
    ),]
sugar_contribs = t(sugar_contribs)
colnames(sugar_contribs) = c(
    "sugar_100m",
    "sugar_2500m",
    "sugar_5000m",
    "sugar_500m"
    )
sugar_contribs = sugar_contribs[,c(1,4,2,3)]


percentiles = t(apply(contribs, 2, quantile, probs=c(0.05/2,1-0.05/2)))
percentiles = cbind(percentiles,mean=apply(contribs, 2, mean))
percentiles = as.data.frame(percentiles)
colnames(percentiles) = c("min","max","mean")
percentiles = cbind(percentiles,name=rownames(percentiles))
percentiles = percentiles[order(percentiles$mean,decreasing=T),]
percentiles$name <- factor(percentiles$name,levels = percentiles$name[order(percentiles$mean,decreasing=T)])

# take percentile as table 1


## Plot effects of sugarcane 5000m
replicates = model@models
niceresponse = function(modellist,var,fancyname=NULL) {
    curves= lapply(modellist, response,var=var,expand=0,xlim=c(0,1)) 
    curves = do.call(rbind,curves)
    curves = cbind(rep(1:100,each=100),curves)
    colnames(curves) = c("replicate","prop.sugar","probability")
    curves = as.data.frame(curves)
    if(is.null(fancyname)) {fancyname=var}
    ggplot(curves,aes(x=prop.sugar,y=probability))+
        geom_line(col="grey50",aes(group=replicate))+
        stat_summary(fun.y="mean",geom="line",col="black",lwd=1)+
        theme_bw()+
        xlab(fancyname)
}
g1=niceresponse(replicates, "prop_sugar_100m", "Proportion of sugar in 100m")
g2=niceresponse(replicates, "prop_sugar_500m", "Proportion of sugar in 500m")
g3=niceresponse(replicates, "prop_sugar_2500m","Proportion of sugar in 2500m")
g4=niceresponse(replicates, "prop_sugar_5000m","Proportion of sugar in 5000m")
grid.arrange(g1,g2,g3,g4,ncol=2,nrow=2)

# Get variation in AUC
eval =  readRDS("./Sugarcane paper/maxenteval.rds")
aucs = sapply(eval,slot,"auc")
percentiles.auc = quantile(aucs, probs = c(0.05/2,1-0.05/2))


## Is the effect of sugarcane correlated with something else?

presences = model@models[[1]]@presence
presences = presences[,-c(1,2,4,19)] # Removing landuse(categorical)
cors  = cor(presences,method="spearman")
cors = cors[c("prop_sugar_100m","prop_sugar_2500m","prop_sugar_5000m","prop_sugar_500m"),]
cors = t(cors)
barplot(cors,beside=T,legend.text=T)