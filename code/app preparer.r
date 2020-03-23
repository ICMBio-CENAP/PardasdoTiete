# ---
# title:  Preparer of reflorestation areas
# author: Jorge Menezes    <jorgefernandosaraiva@gmail.com> 
# date: CENAP-ICMBio/Pro-Carnivoros, Atibaia, SP, Brazil, March 2020
# 
# ---

# Intent: This is a code to receive the AES tiete APP maps and select the ones 
# within the study area. Also eliminate features on areas that were discarted 
# from the APP.

# Input: A folder with APP shapefiles

# Output: A single geodatabase with organized data.

app.preparer <- function(appfolder, outfile, select.uhe, select.situation, forestmap) {
    #for debug:
    # appfolder <- "./raw/maps/APPs" 
    # forestmap <- paste0(experiment.folder,"/mapsderived/studyarea/forestmap.gpkg")
    # select.uhe <- c("BAR","BAB","NAV","IBI", "PROJ")
    # select.situation <- c("restaurada","em restauracao","a restaurar","area umida","remanescente")

    # read crs from forestmap
    crs <- st_crs(st_read(forestmap))$proj4string

    # read all maps and convert to the project crs.
    files <-  list.files(appfolder, pattern="shp$",full.names=T)
    shapes <-  lapply(files,st_read, options="ENCONDING=WINDOWS-1252")
    shapesproj <- lapply(shapes, st_transform, crs = crs)
    shapesproj <- lapply(shapesproj, select, c("UHE", contains("SIT"),"geometry"))
    
    # rename columns 
    for( a in 1:length(shapesproj)) {
        colnames(shapesproj[[a]])[1:2] <- c("UHE","situation")
    }

    # combine all shapes and select the ones within the study area
    shapesjoines <- do.call(rbind,shapesproj)

    # Eliminate errors in UTF-8 and remove interrogations and its trailing effect
    shapesjoines$situation <- stri_trans_general( as.character(shapesjoines$situation) , "latin-ascii")
    shapesjoines$situation <- sub("\\s*\\?","",shapesjoines$situation)
    
    
    # select valid app based on the criteria
    shapesjoines <- shapesjoines[ (shapesjoines$UHE %in% select.uhe) & (shapesjoines$situation %in% select.situation), ]

    #drop z values
    shapesjoines <- st_zm(shapesjoines)
    st_write(shapesjoines, dsn = outfile)
    return(outfile)

}

