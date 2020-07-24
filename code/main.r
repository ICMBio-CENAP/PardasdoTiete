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
library(dplyr)
library(units)
library(terra)    
library(igraph)
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
library(dbscan)
library(googledrive)
Sys.getenv("GDAL_DATA")

source("./code/data importer.r")
source("./code/envpreparator (function).r")
source("./code/maxenter.r")
source("./code/predictor.r")
source("./code/sigma calculator.r")
source("./code/zoner.r")
source("./code/app preparer.r")
source("./code/quota organizer.r")
source("./code/ranker.r")
source("./code/corridor creator.r")
source("./code/pather.r")
source("./code/avgdistance calculator.r")
source("./code/corridor designer.r")
source("./code/price calculator.r")
source("./code/presentation code/shinyapp/app preparer.r")
source("./code/package preparator.r")

experiment.folder <- "./experiment007"
res<-30

## Load QGIS and gdal variables, also run two code lines to activate grass7 modules on qgis

qgis.folder <- "C:/Program Files/QGIS 3.4"
Sys.setenv(GDAL_DATA = paste0(qgis.folder, "/share/gdal"))
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
produce.gpkg            <- FALSE
produce.models          <- FALSE
organize.cota           <- FALSE
organize.app            <- FALSE
produce.studystack      <- FALSE
predict.models          <- FALSE
produce.actual          <- FALSE
produce.ranks           <- FALSE
produce.refranks        <- FALSE
produce.futurestack     <- FALSE
produce.actualfuture    <- TRUE
produce.futureranks     <- TRUE
produce.futurerefranks  <- TRUE
produce.corridors       <- TRUE
select.corridors        <- TRUE
calculate.price         <- TRUE
produce.futurecorridors <- TRUE
select.futurecorridors  <- TRUE
produce.futureranks     <- TRUE
deploy.app              <- TRUE


##### PREPARE HABITAT SELECTION MODEL #####


if(produce.gpkg) { 
    data.importer(pointfile  =  paste0(experiment.folder,"/dataderived/Pardas_do_Tiete_todos_individuos.csv"),
                  metafile   =  "./raw/data 29.06.20/Processed/metadata.csv", 
                  outfile    =  paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"),
                  tempdir    =  paste0(experiment.folder,"/mapsderived/observedstack"),
                  res = res,
                  crs= 102033,
                  qgis.folder = "C:/Program Files/QGIS 3.4"
                  )
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


sigma <- sigma.calculator( infile= paste0(experiment.folder,"/dataderived/pardas_tiete_all_individuals.gpkg"))

##### END HABITAT SELECTION MODELLING #####





##### ORGANIZE RESERVE DATA FROM AES TIETE #####

if(organize.cota) {
    quota.organizer( forestmap   = paste0(experiment.folder,"/mapsderived/studyarea/forestmap.gpkg"),
                     quotafolder = paste0(experiment.folder, "/mapsderived/quotas")
    )
}
if(organize.app) {
    app.preparer( appfolder = "./raw/maps/APPs" ,
                  forestmap = paste0(experiment.folder,"/mapsderived/studyarea/forestmap.gpkg"),
                  select.uhe= c("BAR","BAB","NAV","IBI", "PRO"),
                  select.situation = c("RESTAURADA","EM RESTAURACAO","A RESTAURAR","Area umida","Remanescente"),
                  outfile = paste0(experiment.folder, "/mapsderived/quotas/apps_sea.gpkg")
                  )
}

##### END RESERVE DATA ORGANIZING #####









##### SECTION FOR AES DESAPROPRIATION ZONE #####

### Results for present forest cover ###

if(produce.studystack ) {
    envpreparator( buffergeo = st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp") %>% st_transform(crs=102033),
               tempdir   =   paste0(experiment.folder, "/mapsderived/studyarea"),
               finalrds  = paste0(experiment.folder,"/mapsderived/studyarea/experiment007map.rds"),
               res=res,
               overwrite.gb = TRUE,
               baseproj = 102033, 
               qgis.folder  = "C:/Program Files/QGIS 3.4"
)
print("completed study stack")
}

if(predict.models) {
    predictor(mapdir = paste0(experiment.folder,"/mapsderived/studyarea"),
              model  = paste0(experiment.folder, "/dataderived/maxentmodel.rds"),
              outfile = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
              cost = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentcost.tif")    
    )

}
if(produce.actual) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas_sea_fixed.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/currentquality")
           )
}

if(produce.ranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas_sea.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/currentquality"),
           outfile = "optimalrankadd.tif"
           )
}
if(produce.refranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentcost.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas_sea.gpkg"),
           maskbyvalue = c(1,4,7), 
           out.folder = paste0(experiment.folder, "/mapsderived/currentquality"),
           outfile = "optimalref.tif"
           )
}


### Results for future forest cover ###

# Get future land use
if(produce.futurestack) {
    envpreparator( buffergeo = st_read("./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp"),
                   tempdir   =   paste0(experiment.folder, "/mapsderived/futurestack"),
                   finalrds  = "experiment007mapfuture.rds",
                   reforesteddir = paste0(experiment.folder, "/mapsderived/quotas/apps_sea.gpkg"),
                   res=res,
                   overwrite.gb = TRUE,
                   baseproj= 102033,
                   qgis.folder  = "C:/Program Files/QGIS 3.4"
)
}

# Produce second set of predictions
if(predict.futuremodels) {
    predictor(mapdir = paste0(experiment.folder,"/mapsderived/futurestack"),
              model  = paste0(experiment.folder, "/dataderived/maxentmodel.rds"),
              outfile = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
              cost = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentcostfuture.tif")    
   
    )

}

# Finally select reserves on that code
if(produce.actualfuture) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg") , 
           constrain = paste0(experiment.folder, "/mapsderived/quotas/quotas_sea_fixed.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/futurequality")
           )
}

if(produce.futureranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas_sea_fixed.gpkg"), 
           out.folder = paste0(experiment.folder, "/mapsderived/futurequality"),
           outfile = "optimalrankadd.tif"
           )
}
if(produce.futurerefranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentcostfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg") , 
           constrain =  paste0(experiment.folder, "/mapsderived/quotas/quotas_sea_fixed.gpkg"), 
           maskbyvalue = c(1,4,7), 
           out.folder = paste0(experiment.folder, "/mapsderived/futurequality"),
           outfile = "optimalref.tif"
           )
}









##### SECTION FOR THE ENTIRE STUDY AREA #####
# THIS CODE RESUSES ENVPREPARATOR() AND PREDICTOR()'S RESULTS FROM PREVIOUS STEPS #
# MAKE SURE TO RUN IT BEFORE THIS SECTION #

### Results for present forest cover ###


if(produce.actual) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg"), 
           constrain = NULL, 
           out.folder = paste0(experiment.folder, "/mapsderived/currentqualitytotal")
           )
}

if(produce.ranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentprediction.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg") , 
           constrain =  NULL, 
           out.folder = paste0(experiment.folder, "/mapsderived/currentqualitytotal"),
           outfile = "optimalrankadd.tif"
           )
}
if(produce.refranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentcost.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps_sea.gpkg") , 
           constrain =  NULL, 
           maskbyvalue = c(1,4,7),
           out.folder = paste0(experiment.folder, "/mapsderived/currentqualitytotal"),
           outfile = "optimalref.tif"
           )
}


if(produce.corridors) {
    corridor.creator( optimal   = paste0(experiment.folder, "/mapsderived/currentqualitytotal/optimalplaces.tif"),
                      cost      = paste0(experiment.folder, "/mapsderived/qualitypredictions/maxentcost.tif"),
                      existing  = paste0(experiment.folder, "/mapsderived/quotas/apps_sea.gpkg"),
                      dist      = 24*sigma,
                      pythonbat = "C:/Program Files/QGIS 3.4/bin/python-qgis.bat",
                      script    = "./code/r.cost wrapper.py",
                      outdir    = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors"),
                      outcor    = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors/corridors.gpkg"),
                      outcent   = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors/cents.gpkg")
    )
}

if(select.corridors) {
    corridor.designer(corridors  = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors/corridors.gpkg"),
                      cents      = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors/reservescent.gpkg"),
                      destfile    = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors/corridorssel.gpkg")
    )
}

if(calculate.price) {
    price.calculator(corridors = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors/corridorssel.gpkg"),
                     poly = paste0(experiment.folder, "/mapsderived/currentqualitytotal/corridors/reservesvect.gpkg"),
                     prices = "./raw/price data/SPGADM_priced.gpkg",
                     output = paste0(experiment.folder,"/mapsderived/currentqualitytotal/optimalpriced.gpkg")
    )
}
### Results for future forest cover ###

# Finally select reserves on that code
if(produce.actualfuture) {
    zoner( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain = NULL, 
           out.folder = paste0(experiment.folder, "/mapsderived/futurequalitytotal")
           )
}

if(produce.futureranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain =  NULL, 
           out.folder = paste0(experiment.folder, "/mapsderived/futurequalitytotal"),
           outfile = "optimalrankadd.tif"
           )
}
if(produce.futurerefranks) {
    ranker( quality.map = paste0(experiment.folder,"/mapsderived/qualitypredictions/maxentcostfuture.tif"),
           sigma = sigma, 
           reserves = paste0(experiment.folder,"/mapsderived/quotas/apps.gpkg") , 
           constrain =  NULL, 
           maskbyvalue= c(1,4,7),
           out.folder = paste0(experiment.folder, "/mapsderived/futurequalitytotal"),
           outfile = "optimalref.tif"
           )
}

if(produce.futurecorridors) {
    corridor.creator( optimal   = paste0(experiment.folder, "/mapsderived/futurequalitytotal/optimalplaces.tif"),
                      cost      = paste0(experiment.folder, "/mapsderived/qualitypredictions/maxentcostfuture.tif"),
                      existing  = paste0(experiment.folder, "/mapsderived/quotas/apps.gpkg"),
                      dist      = 24*sigma,
                      pythonbat = "C:/Program Files/QGIS 3.4/bin/python-qgis.bat",
                      script    = "./code/r.cost wrapper.py",
                      outdir    = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors"),
                      outcor    = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors/corridors.gpkg"),
                      outcent   = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors/reservescents.gpkg")
    )
}

if(select.futurecorridors) {
    corridor.designer(corridors   = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors/corridors.gpkg"),
                      cents       = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors/reservescent.gpkg"),
                      destfile    = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors/corridorssel.gpkg")
    )
}

if(calculate.price) {
    price.calculator(corridors = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors/corridorssel.gpkg"),
                     poly = paste0(experiment.folder, "/mapsderived/futurequalitytotal/corridors/reservesvect.gpkg"),
                     prices = "./raw/price data/SPGADM_priced.gpkg",
                     output = paste0(experiment.folder,"/mapsderived/futurequalitytotal/optimalpriced.gpkg")
    )
}


##### DEPLOYING SHINY APP #####
if(deploy.app) {
    apppreparer(mapnow    = paste0(experiment.folder,"/mapsderived/currentqualitytotal/optimalpriced.gpkg"),
                mapfuture = paste0(experiment.folder,"/mapsderived/futurequalitytotal/optimalpriced.gpkg"),
                studyarea = "./raw/maps/area_estudo/area_estudo_SIRGAS2000_UTM22S.shp",
                APPs      = paste0(experiment.folder, "/mapsderived/quotas/apps_sea.gpkg"),
                appfile   = "./code/presentation code/shinyapp/appfiles.gpkg"

    )
    rsconnect::setAccountInfo(name='jfsmenezes', token='987F91EC0A198AA15EEF90EA05AC10F3', secret='')
    rsconnect::deployApp("./code/presentation code/shinyapp")

    package.assembler("./experiment007","./experiment007/product package")

}
