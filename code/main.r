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


#TODO: investigate varying buffer in envpreparator.
#TODO: make sure we used all data and not just the last semesters of 2019

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
library(amt)
library(rgdal)


source("./code/data importer.r")
source("./code/envpreparator (function).r")
source("./code/maxenter.r")
source("./code/predictor.r")
source("./code/sigma calculator.r")
source("./code/zoner.r")
source("./code/app preparer.r")
source("./code/quota organizer.r")
source("./code/ranker.r")

experiment.folder <- "./experiment005"
res<-30

## Load QGIS and gdal variables, also run two code lines to activate grass7 modules on qgis

qgis.folder <- "C:/Program Files/QGIS 3.4"
Sys.setenv(GDAL_DATA = paste0(qgis.folder, "\\share\\gdal"))
Sys.setenv(PROJ_LIB  = paste0(qgis.folder, "\\share\\proj"))
set_env(qgis.folder)
open_app()


## Important to run grass7 algorithms. Even when it leads to errors
## it allow grass code to work. 
## Discovered in https://gis.stackexchange.com/questions/296502/pyqgis-scripts-outside-of-qgis-gui-running-processing-algorithms-from-grass-prov
py_run_string("from processing.algs.grass7.Grass7Utils import Grass7Utils")
py_run_string("Grass7Utils.checkGrassIsInstalled()")

## This library must be loaded after open_app, because there is a conflict with open_app() from RQGIS3
library(lwgeom)

## add which values to calculate
produce.gpkg         <- TRUE
produce.studystack   <- TRUE
produce.models       <- TRUE
organize.cota        <- TRUE
organize.app         <- TRUE
produce.actual       <- TRUE
produce.ranks        <- TRUE
produce.futurestack  <- TRUE
predict.futuremodels <- TRUE
produce.actualfuture <- TRUE
produce.ranksfuture  <- TRUE


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
               finalrds  = "experiment005map.rds",
               res=res,
               overwrite.gb = TRUE,
               qgis.folder  = "C:/Program Files/QGIS 3.4"
)
print("completed study stack")
}
if(produce.models) {
    maxenter( data     = paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"),
              obsdir   = paste0(experiment.folder,"/mapsderived/observedstack"),
              modelfile = paste0(experiment.folder, "/dataderived/maxentmodel.rds"),
              evalfile = paste0(experiment.folder, "/dataderived/maxenteval.rds"),
              nc = 10   
     )
}
print("maxent complete")
if(predict.models) {
    predictor(mapdir = paste0(experiment.folder,"/mapsderived/studyarea"),
              model  = paste0(experiment.folder, "/dataderived/maxentmodel.rds"),
              outfile = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
              nc =10    
    )

}

if(organize.cota) {
    quota.organizer( forestmap   = paste0(experiment.folder,"/mapsderived/studyarea/forestmap.gpkg"),
                     quotafolder = paste0(experiment.folder, "/mapsderived/quotas")
    )

if(organize.app) {
    app.preparer( appfolder = "./raw/maps/APPs" ,
                  forestmap = paste0(experiment.folder,"/mapsderived/studyarea/forestmap.gpkg"),
                  select.uhe= c("BAR","BAB","NAV","IBI", "PRO"),
                  select.situation = c("RESTAURADA","EM RESTAURACAO","A RESTAURAR","Area umida","Remanescente"),
                  outfile = paste0(experiment.folder, "/mapsderived/quotas/apps.gpkg")
                  )
}

sigma <- sigma.calculator( paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"))


if(produce.actual) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/currentquality")
           )
}

if(produce.ranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/currentquality")
           )
}


## Reforested world scenarios (4 & 5)

# Get future land use
if(produce.futurestack) {
    envpreparator( buffergeo = st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp"),
                   tempdir   =   paste0(experiment.folder, "/mapsderived/futurestack"),
                   finalrds  = "experiment004mapfuture.rds",
                   reforesteddir = paste0(experiment.folder, "/mapsderived/quotas/apps.gpkg"),
                   res=res,
                   overwrite.gb = TRUE,
                   qgis.folder  = "C:/Program Files/QGIS 3.4"
)
}

# Produce second set of predictions
if(predict.futuremodels) {
    predictor(mapdir = paste0(experiment.folder,"/mapsderived/futurestack"),
              model  = paste0(experiment.folder, "/dataderived/maxentmodel.rds"),
              outfile = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
              nc =10    
    )

}

# Finally select reserves on that code
if(produce.actualfuture) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain = paste0(experiment.folder, "/mapsderived/quotas/quotas.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/futurequality")
           )
}

if(produce.futureranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/futurequality")
           )
}