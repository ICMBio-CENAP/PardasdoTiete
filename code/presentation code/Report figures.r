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

# Figure 3: Ploting the effect of each variable in the maxent model
model <- readRDS("./experiment007/dataderived/maxentmodel.rds")
reponse(model)

# Figure 4: Percent contribution of each variable in maxent with nice label names
model <- readRDS("./experiment007/dataderived/maxentmodel.rds")

plot(model,
  main="contribuição da váriavel",
  xlab="porcentagem",
  labels=rev(c("açucar 5000m","floresta 2500m","floresta 5000m", "floresta 100m", "floresta 500m",
    "pastagem 5000m", "proximidade água (log)","uso da terra", "proximidade agua","pastagem 100m",
    "proximidade estradas","pastagem 2500m","açucar 100m","açucar 2500m","açucar 500m","pastagem 500m",
    "presença de água","proximidade estradas (log)","presença de estradas","constante"
    ))
)


# Figure 5: Prediction map 
crs <- 102033
predmap <- raster("./experiment007/mapsderived/qualitypredictions/maxentprediction.tif")
studyarea <- st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp") %>% st_transform(crs=crs)
plot(predmap,col = gray.colors(10, start = 0.3, end = 0.9, gamma = 2.2, alpha = NULL),axes=FALSE,box=FALSE)
plot(studyarea$geometry,add=T,col=NA,lwd=2)


# Figure 7: Prediction map  blurred
predmap <- raster("./experiment007/mapsderived/currentquality/qualityblurred.sdat")
plot(predmap,col = gray.colors(10, start = 0.3, end = 0.9, gamma = 2.2, alpha = NULL),axes=FALSE,box=FALSE)


# Figure 8: Predicted optimal regions
# Done in QGIS
