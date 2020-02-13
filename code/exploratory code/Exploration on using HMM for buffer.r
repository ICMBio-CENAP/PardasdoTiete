## Exploration on using HMM followed by K-means to identify home ranges
# I wonder if there is a more consistent operator for detecting dispersal or
# home range behavior. ARIMA is efficient but breaks frequently leaving many 
# animals unestimatable.
# In addition, we need to input all possible combinations of settling and
# depature, which makes the code less general. I am returning to HMM in hopes
# of finding something better.

# Analysis where not sucessful with full data
# It seems doing the analysis below with the full data does not 
# allow me to discern between resident and dispersal behavior
# (using Piloto as a location). I am resampling data to see
# if we can spot any differences in angle between residency and 
# dispersal behavior.

library(sf)
library(moveHMM)
library(lubridate)
library(amt)


data <- st_read("C:\\Users\\jorge\\Documents\\AssociadoCNAP\\Projeto Pardas do Tiete\\experiment004\\dataderived\\pardas_tiete_all_individuals.gpkg")
crs <- st_crs(data)[[2]]
data <- data[data$Name =="Piloto",]
data <- data[order(data$timestamp),]
data <- mk_track(data, .x = "Longitude", .y = "Latitude", .t = timestamp, 
                      crs = CRS(crs),
                      ID, Name)
data <- track_resample(data, rate = hours(1), tolerance = minutes(10))



data <- st_as_sf(data, coords = c("x_","y_"), crs = crs, remove=F)

dists <- st_distance(data[-1,],data[-nrow(data),],by_element=TRUE)
hist(dists)
angles <- (180/pi)*atan2(diff(data$y_),diff(data$x_))
hist(angles)
hist(abs(angles))
plot(data$x_,data$y_)
plot(data$x_,data$y_,xlim=c(300000,370000),ylim=c(-1210000,-1160000),pch=16,type="b")

plot(abs(angles))

data <- as.data.frame(data)
data <- data[order(data$Name,data$timestamp),]
data <- data[,c("Name","Longitude","Latitude")]
data$Latitude  <-  data$Latitude/1000
data$Longitude <-  data$Longitude/1000
colnames(data) <- c("ID","x","y")
data.prep <- prepData(data, type="UTM")

diag( dist(data.prep[,c("x","y")])



mus = c(100, 50)
sigmas=  c(50, 10)
zeromasses = c(0.3,0.2)
thetas = c(0, pi/4)
kappas= c(0.1, 1)

stepPar1   <- c(mus, sigmas, zeromasses)
anglePar1  <- c(thetas, kappas)

m5 <- fitHMM(data = data.prep[data.prep$ID=="Piloto",], nbStates = 2, stepPar0 = stepPar1, 
             anglePar0 = anglePar1, formula = ~1)
plot(m5)



