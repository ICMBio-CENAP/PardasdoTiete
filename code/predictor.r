# ---
# title:  Maxent predictor for jaguar quality
# author: Jorge Menezes    <jorgefernandosaraiva@gmail.com> 
# date: CENAP-ICMBio/Pro-Carnivoros, Atibaia, SP, Brazil, June 2019
# 
# ---

# Intent: This function returns a spatial map of a prediction based on a maxent model
# and a directory of environmental variable maps

# Input: A directory with a environmental varibles, a maxent model (saved as an rds object), a 
# file path to save the output, and a integer to represent the number of cpu ores used for prediction
# (the more merrier withing the constrains of the computer).

# Output: A spatial model representing the predicted map.

predictor <- function(mapdir, model, outfile, nc) {

studystack <-  stack(list.files(mapdir,pattern="tif$",full.names=T))
model <-readRDS("./experiment004/dataderived/maxentmodelfuture.rds")

# FOR DEBUG:
#studystack <-  crop(studystack, extent(500000,501000,-1250000,-1245000))
#test <- predict(studystack,model, filename="./experiment004/mapsderived/qualityfuture/maxentpredictiontest.tif")

# Use predict with clusterR to speed up process
beginCluster(nc)
clusterR(studystack, predict, args = list(model = model), filename = outfile )
endCluster()

return(outfile)

}