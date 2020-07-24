#' ---
#' title: 'Product package assembler '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This function copies the files mentioned in the Final report to a folder and uploads this
# folder to Google drive 


# Input:  
# folder: path to the experiment folder
# outfolder: path to the external folder


package.assembler <- function(folder,outfolder) {

    # FOR DEBUG:
    #folder <- "./experiment007"
    #outfolder <- "./experiment007/product package"
    # basemaps
    md   <- paste0(folder,"/mapsderived/qualitypredictions/maxentprediction.tif")
    mdb  <- paste0(folder,"/mapsderived/futurequality/qualityblurred2.sdat")
    mdf  <- paste0(folder,"/mapsderived/qualitypredictions/maxentpredictionfuture.tif")
    mdfb <- paste0(folder,"/mapsderived/futurequalitytotal/qualityblurred2.sdat")

    #Scenario I  - desapropriation zone, current
    op <- paste0(folder,"/mapsderived/currentquality/optimalplaces.tif")
    opa<- paste0(folder,"/mapsderived/currentquality/optimalrankadd.tif")
    opr<- paste0(folder,"/mapsderived/currentquality/optimalref.tif")

    #Scenario II -  desapropriation zone, future
    opf <- paste0(folder,"/mapsderived/futurequality/optimalplaces.tif")
    opaf<- paste0(folder,"/mapsderived/futurequality/optimalrankadd.tif")
    oprf<- paste0(folder,"/mapsderived/futurequality/optimalref.tif")

    # Scenario III - study area, current
    ops <- paste0(folder,"/mapsderived/currentqualitytotal/optimalpriced.gpkg")
    opas<- paste0(folder,"/mapsderived/currentqualitytotal/optimalrankadd.tif")
    oprs<- paste0(folder,"/mapsderived/currentqualitytotal/optimalref.tif")

    # Scenario IV - study area, future
    opsf <- paste0(folder,"/mapsderived/futurequalitytotal/optimalpricedfuture.gpkg")
    opasf<- paste0(folder,"/mapsderived/futurequalitytotal/optimalrankadd.tif")
    oprsf<- paste0(folder,"/mapsderived/futurequalitytotal/optimalref.tif")

    # new filenames 
    nfiles <- c(
        "/mapasbase/Produto A - qualidade.tif",
        "/mapasbase/Produto B - qualidade embassada.tif",
        "/mapasbase/Produto C - qualidade depois reflorestamento.tif",
        "/mapasbase/Produto D - qualidade depois reflorestamento embassada.tif",
        "/cenarioI/Produto E - reservas cenario I.tif",
        "/cenarioI/Produto F - rank reservas cenario I.tif",
        "/cenarioI/Produto G - rank reflorestamento cenario I.tif",
        "/cenarioII/Produto H - reservas cenario II.tif",
        "/cenarioII/Produto I - rank reservas cenario II.tif",
        "/cenarioII/Produto J - rank reflorestamento cenario II.tif",
        "/cenarioIII/Produto K - reservas cenario III.gpkg",
        "/cenarioIII/Produto L - rank reservas cenario III.tif",
        "/cenarioIII/Produto M - rank reflorestamento cenario III.tif",
        "/cenarioIV/Produto N - reservas cenario IV.gpkg",
        "/cenarioIV/Produto O - rank reservas cenario IV.tif",
        "/cenarioIV/Produto P - rank reflorestamento cenario IV.tif"
    )
    nfiles <- paste0(outfolder,nfiles)

    ## Read all files, convert to WGS84 and save it as a compressed tif

    files <- c(md,mdb,mdf,mdfb,op,opa,opr,opf,opaf,oprf,ops,opas,oprs,opsf,opasf,oprsf)
    is.raster <- grepl(".tif$|.sdat$",files)

    rasterOptions(maxmemory=2e+09,chunksize=1e+06)
    rasters <- lapply( files[is.raster], raster)
    projects<- mapply(projectRaster, 
                        from=rasters, 
                        filename = nfiles[is.raster],
                        crs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs",
                        MoreArgs  = list(options="COMPRESS=LZW")
                    )

    for( a in 1:sum(!is.raster)) {
        l1 <- st_read(files[!is.raster][a],layer="reserves")
        l2 <- st_read(files[!is.raster][a],layer="corridors")
        l1p <- st_transform(l1,crs=4326)
        l2p <- st_transform(l2,crs=4326)
        st_write(l1p,dsn=nfiles[!is.raster][a],layer="reserves")
        st_write(l2p,dsn=nfiles[!is.raster][a],layer="corridors")
    }


    ## upload information to R google drive
    drive_folder_upload(outfolder)
}
drive_folder_upload <- function(infolder) {
    #
    dirs <- list.dirs(infolder,full.names=F)
    dirs <- dirs[-1]
    dirs <- dirs[order(stri_count(dirs,fixed="/"))]
    dirs <- paste0(basename(infolder), "/",dirs)
    dirs <- c(basename(infolder),dirs)
    
    mapply(drive_mkdir, name=basename(dirs), path=replace(dirname(dirs),1,"") )

    files <- list.files(folder,recursive=T)
    files.complete <- list.files(folder,recursive=T,full.names=T)
    mapply(drive_upload, files.complete, files)
}   