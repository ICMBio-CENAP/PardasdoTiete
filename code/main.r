#### Main script for analysis desiging reserves for Cougars in the 
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
options(java.parameters = "-Xmx1g" )
library(raster)
library(gdalUtils)
library(dismo)
library(RQGIS3)
library(tidyverse)
library(lubridate)
library(readxl)
library(sf)
library(parallel)
library(amt)
library(stringi)


source("./code/data importer.r")
source("./code/envpreparator (function).r")
source("./code/maxenter.r")


experiment.folder <- "./experiment004"
res<-30


## add which values to calculate
produce.gpkg        <- TRUE
produce.studystack  <- TRUE
produce.models      <- TRUE


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
               finalrds  = "experiment003map.rds",
               res=res,
               overwrite.gb = TRUE,
               qgis.folder  = "C:/Program Files/QGIS 3.4"
)
}
if(produce.models) {
    maxenter( data     = paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"),
              obsdir   = paste0(experiment.folder,"/mapsderived/observedstack"),
              studydir = paste0(experiment.folder,"/mapsderived/studystack"),
              evalfile = paste0(experiment.folder, "/dataderived/maxenteval.rds"),
              outfile  = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction")    
     )
}

