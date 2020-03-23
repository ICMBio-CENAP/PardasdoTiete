# ---
# title:  Maxent predictor for jaguar quality
# author: Jorge Menezes    <jorgefernandosaraiva@gmail.com> 
# date: CENAP-ICMBio/Pro-Carnivoros, Atibaia, SP, Brazil, June 2019
# 
# ---

# Intent: This is an alternative to calculate the quality of the environment
# as an alternative to the SSF functions, with more accuracy. We used maxent 
# and predict functions from package dismo.

# Input: A Geopackage with all the individuals locations, and two directories with maps
# one with study area (for prediction), and another with observed area stacks (for training) 

# Output: An quality map around the study area.

maxenter <- function(data, obsdir, studydir, modelfile = NULL, evalfile, outfile, nc) {

# Read data, and select some locations to be the train and test dataset.
presences <- st_read(data)
presences$test <- sample(0:1,nrow(presences), prob =c(0.8,0.2), replace=T)
    

# Read observed stack
obsstack  <- stack(list.files(obsdir,pattern="tif$",full.names=T))

# Since there are a lot of NA space in the raster stack I feel I should make sure random
# pseudo-absences fall in a valid area. For that I will use random points with a mask
# Absences are also classified in test and training as is the data.

mask <- subs(obsstack$landuse,data.frame(0,NA),subsWithNA=FALSE)
absences      <- randomPoints(mask, 10000,p= st_coordinates(presences))
absences.test <- sample(0:1,nrow(absences), prob =c(0.8,0.2), replace=T)


# Run maxent model
model <- maxent(obsstack, st_coordinates(presences[presences$test==0,]), absences = absences[absences.test==0,], factors="landuse")
saveRDS(model, file = modelfile)
# Evaluate the model
presence.testquali <- predict(model, as.data.frame(raster::extract(obsstack, st_coordinates(presences[presences$test==1,])))  )
absence.testquali  <- predict(model, as.data.frame(raster::extract(obsstack, absences[absences.test==1,]))  )
auc.test <- evaluate(presence.testquali,absence.testquali)
saveRDS(auc.test, file = evalfile)

# Read study area mapstack
studystack <-  stack(list.files(studydir,pattern="tif$",full.names=T))
model <-readRDS("./experiment004/dataderived/maxentmodelfuture.rds")
names(studystack)

# FOR DEBUG:
#studystack <-  crop(studystack, extent(500000,501000,-1250000,-1245000))
test <- predict(studystack,model, filename="./experiment004/mapsderived/qualityfuture/maxentpredictiontest.tif")

# Use predict with clusterR to speed up process
beginCluster(nc)
clusterR(studystack, predict, args = list(model = model), filename = outfile )
endCluster()

return(outfile)
}