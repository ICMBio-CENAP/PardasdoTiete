#### Main script for analysis desiging reserves for pumas in the 
#### Tiete region 

## Intent: This script act as the main function caller for this project
## This structure allow for easily chaging dataset and store different
## versions of the analysis in different functions
## To do so, it does many calls to directions and checking for the existence
## of files 

## Input: none directly, although it carries the assumptions from all its subfunctions
## Ouput: Currently, just the predicted map of Jaguar quality for the study area
## eventually, a set of reserves desings.


# Load dependencies
options(java.parameters = "-Xmx2g" )
library(raster)
library(gdalUtils)
library(dismo)
library(RQGIS3)
library(tidyverse)
library(lubridate)
library(readxl)
library(sf)
library(parallel)
library(stringi)


source("./code/data importer.r")
source("./code/envpreparator (function).r")
source("./code/maxenter.r")
source("./code/sigma calculator.r")
source("./code/zoner.r")

experiment.folder <- "./experiment004"
res<-30


## add which values to calculate
produce.gpkg        <- TRUE
produce.studystack  <- TRUE
produce.models      <- TRUE
produce.actual      <- TRUE

if(produce.gpkg) { 
    data.importer(derivdir   = paste0(experiment.folder,"/dataderived"),
                  rawdir     = paste0("./raw/data 17.12.19"), 
                  tempdir    = paste0(experiment.folder,"/mapsderived/observedstack"),
                  res = res,
                  qgis.folder = "C:/Program Files/QGIS 3.4"
                  )
}
if(produce.studystack ) {
    envpreparator( buffergeo = st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp"),
               tempdir   =   paste0(experiment.folder, "/mapsderived/studyarea"),
               finalrds  = "experiment004map.rds",
               res=res,
               overwrite.gb = TRUE,
               qgis.folder  = "C:/Program Files/QGIS 3.4"
)
}
if(produce.models) {
    maxenter( data     = paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"),
              obsdir   = paste0(experiment.folder,"/mapsderived/observedstack"),
              studydir = paste0(experiment.folder,"/mapsderived/studyarea"),
              modelfile = paste0(experiment.folder, "/dataderived/maxentmodel.rds")
              evalfile = paste0(experiment.folder, "/dataderived/maxenteval.rds"),
              outfile  = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
              nc = 10   
     )
}

sigma <- sigma.calculator( paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"))

# TODO: Get the constrain maps with Guilherme, and check what the classes mean
# in the reserve map.
if(produce.actual) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
           sigma = sigma, 
           reserves = , 
           constrain =, 
           out.folder = 
           )


}

# Get future land use
if(produce.futurestack) {
        envpreparator( buffergeo = st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp"),
               tempdir   =   paste0(experiment.folder, "/mapsderived/futurestack"),
               finalrds  = "experiment004map.rds",
               reforesteddir = "./raw/maps/UHEs"
               res=res,
               overwrite.gb = TRUE,
               qgis.folder  = "C:/Program Files/QGIS 3.4"
)
}

# Produce second set of predictions
if(produce.futuremodels) {
    maxenter( data     = paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"),
              obsdir   = paste0(experiment.folder,"/mapsderived/observedstack"),
              studydir = paste0(experiment.folder,"/mapsderived/futurestack"),
              modelfile = paste0(experiment.folder, "/dataderived/maxentmodelfuture.rds")
              evalfile = paste0(experiment.folder, "/dataderived/maxenteval.rds"),
              outfile  = paste0(experiment.folder,"/mapsderived/qualityfuture/maxentprediction.tif"),
              nc = 10   
     )
}

# Finally select reserves on that code
if(produce.actual) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualityfuture/maxentprediction.tif"),
           sigma = sigma, 
           reserves = , 
           constrain =, 
           out.folder = 
           )


}

# TODO: add a map that  reforests the entire area of the AES tiete, so we can compare potential reforestation efforts with the predict reforestation effort.