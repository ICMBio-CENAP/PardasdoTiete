# Script to generate pictures for December/2019 trimestral report #


# Load dependencies
library(sf)
library(ggplot2)
library(lubridate)
library(openxlsx)
library(dplyr)

locs <- st_read("./experiment007/dataderived/pardas_tiete_all_individuals.gpkg")
metadata<- read.csv("./raw/data 29.06.20/Processed/metadata.csv", stringsAsFactors =F)


# Table 1: Duration, sex, beggining of sample, end of sample, and  sample size for each animal

table1 <- data.frame(
  Nome  = names,
  Sexo  = metadata$Sex[match(names, metadata$Name)],
  begin = aggregate(locs$timestamp, list(locs$name), min)[,2], 
  end   = aggregate(locs$timestamp, list(locs$name), max)[,2] 
)
table1 <- cbind(table1, duration = round(table1$end-table1$begin) )


write.xlsx(table1,file="./presentations/Final report 2020/table1.xlsx")

## Figure 1: Period of collar activity from all the animals
names <- rev(names(sort(tapply(locs$timestamp,locs$name,max))))
ggplot(locs,aes(x=timestamp, y=name,col=name)) + 
  geom_point()+
  theme_bw() +
  scale_x_datetime(date_minor_breaks="6 months")+
  scale_y_discrete(limits = names )+
  xlab("tempo")+
  ylab("Nome do Animal")



## Figure 2: Plotting animal locations on top of a map of the São paulo and of the study area
gg_color_hue <- function(n) {
  hues = seq(15, 375, length = n + 1)
  hcl(h = hues, l = 65, c = 100)[1:n]
}

boundaries<- readRDS("./raw/maps/limites politicos/base gdam nivel 2.rds")
boundaries<- boundaries[boundaries$NAME_1=="São Paulo",]
boundsp <- st_union(boundaries)
studyarea <- st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp") %>% st_transform(crs=4326)
plot(boundaries$geometry,border="gray50",lty=1)
plot(boundsp,lwd=2,add=T)
plot(studyarea$geometry, lwd=2,lty=2,add=T)
plot(locs["name"] %>% st_transform(crs=4326),pch=16,pal=gg_color_hue(length(unique(locs$name))),add=T)
legend("topright",legend=sort(unique(locs$name)),fill=gg_color_hue(length(unique(locs$name))))


# Table 2: Daily distance walked
dayinds <- st_coordinates(locs) %>% as.data.frame %>% split( list(locs$name,date(locs$timestamp)))
dayinds <- dayinds[sapply(dayinds,nrow)>0]

distanceday <- numeric(length=length(dayinds))
for( a in 1:length(dayinds)) {
    dists<- dist(dayinds[[a]])
    dists<- as.matrix(dists)
    dists<- dists[-nrow(dists),-1]
    dists.cum <- sum(diag(dists))
    distanceday[a] <- dists.cum
}
indsofday <- strsplit( names(dayinds), "\\.")
indsofday <- sapply(indsofday,"[[",1)
summ <- tapply(distanceday,indsofday, summary)
summ <- do.call(rbind, summ)
summ <- as.data.frame(summ)
summ <- cbind(ID = metadata$ID[match(rownames(summ),metadata$Name)], Nome = rownames(summ), summ[,-4] )
summ <- summ[order(summ$ID),]
write.xlsx(summ,file="./presentations/Relatorio trimestral 2019_12/table2.xlsx")


# Figure 5: Percent contribution of each variable in maxent with nice label names
experiment004\dataderived\maxentmodel.rds
model <- readRDS("./experiment004/dataderived/maxentmodel.rds")
plot(model,main="contribuição da váriavel",xlab="porcentagem",
labels=rev(c("açucar 5000m","floresta 100m","floresta 5000m", "açucar 2500m", "proximidade agua",
"floresta 500m", "proximidade estradas","açucar 500m", "pastagem 5000m","log proximidade estradas","pastagem 100m",
"floresta 2500m","pastagem 500m","pastagem 2500m", "uso da terra", "açucar 100m","log proximidade agua",
"presença agua","presença estrada","constante"))
)

# Figure 6: Prediction map 
library(raster)
library(sf)
crs <- '+proj=aea +lat_1=-2 +lat_2=-22 +lat_0=-12 +lon_0=-54 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs'

predmap <- raster("./experiment004/mapsderived/qualitypredictions/maxentprediction.tif")
studyarea <- st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp") %>% st_transform(crs=crs)
plot(predmap,col = gray.colors(10, start = 0.3, end = 0.9, gamma = 2.2, alpha = NULL),axes=FALSE,box=FALSE)
plot(studyarea$geometry,add=T,col=NA,lwd=2)

# Figure 7: Prediction map  blurred
library(raster)
predmap <- raster("./experiment004/mapsderived/currentquality/qualityblurred.sdat")
plot(predmap,col = gray.colors(10, start = 0.3, end = 0.9, gamma = 2.2, alpha = NULL),axes=FALSE,box=FALSE)


# Figure 8: Predicted optimal regions
# Done in QGIS

# Figure 12: Prediction map averaged by municipality
library(raster)
library(sf)
crs <- '+proj=aea +lat_1=-2 +lat_2=-22 +lat_0=-12 +lon_0=-54 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs'

predmap <- raster("./experiment003/mapsderived/qualitypredictions/meanquality.tif")
studyarea <- st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp") %>% st_transform(crs=crs)
boundaries<- readRDS("./raw/maps/limites politicos/base gdam nivel 2.rds") %>% st_transform(crs=crs)
boundaries<- boundaries[boundaries$NAME_1=="São Paulo",]
rel.boundaries <- st_intersection(boundaries,studyarea)
rel.boundaries <- as_Spatial(st_zm(rel.boundaries))
rel.boundaries <- extract(predmap,rel.boundaries,fun=mean,sp=T)
rel.boundaries <- st_as_sf(rel.boundaries)
plot(rel.boundaries["meanquality"],key.pos=1,main=NULL)
values <- as.data.frame(rel.boundaries[,c("NAME_2","meanquality")])[,-3]
values <- head(values[order(values$meanquality,decreasing=T),],10)