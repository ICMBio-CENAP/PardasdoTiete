#' ---
#' title: 'Home range calculator '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This script takes a all animal locations and calculates the autocorrelated
# kernel home range (AKDE) for the individuals that show a home range.
# we ouput the 95% isolines and animal area 


# Input:  

# A geopackage withe the location of all individuals

# Output:
# A geopackage with the isolines of 95% kernel estimation, and their
# value of area


homerange.calculator <-  function(infile, outfile) {

    #FOR DEBUG:
    #locs <- st_read("./experiment006/dataderived/pardas_tiete_all_individuals.gpkg")

    locs <- st_read(infile)

    # convert to ctmm file format

    locs.ctmm <-  st_transform(locs,crs=4326)
    locs.ctmm[,c("Longitude","Latitude")] <- st_coordinates(locs.ctmm)
    locs.ctmm <- st_drop_geometry(locs.ctmm)

    colnames(locs.ctmm) <- c("individual.local.identifier", "timestamp","location.long","location.lat") 
    locs.ctmm <- locs.ctmm[!duplicated(locs.ctmm$timestamp),]
    locs.ctmm <- locs.ctmm[order(locs.ctmm$individual.local.identifier,locs.ctmm$timestamp),]
    locs.tel <- as.telemetry(locs.ctmm, timeformat="%Y-%m-%d %H:%M:%S",timezone="")

    # Make variogram graphs for analysis
    layout(matrix(1:(length(locs.tel)+length(locs.tel)%%2),2))
    mapply(function(x,y) plot(variogram(x),main=y), locs.tel,names(locs.tel) )
    exclude <- readline("Select Animals to exclude. Type their names separated by comma no spaces:")
    exclude <- strsplit(exclude,",")[[1]]


    # Excluding Araçatuba,Mineiro and Pepira for lacking asymtote.
    locs.tel.hr <- locs.tel[!(names(locs.tel) %in% exclude)]
    
    # get guesses value
    guesses <-lapply(locs.tel.hr,ctmm.guess)

    # Run variogram model
    best.models <- mapply(ctmm.select, locs.tel.hr, guesses, SIMPLIFY=FALSE)

    #Calculate home ranges with it
    homeranges  <- mapply(akde,locs.tel.hr,best.models, SIMPLIFY=FALSE)
    homeranges.spdf <-  lapply(homeranges,SpatialPolygonsDataFrame.UD)

    #Convert to sf
    homeranges.sf <- lapply(homeranges.spdf,st_as_sf)
    homeranges.sf <- mapply(cbind, homeranges.sf, animal= names(guesses) )
    homeranges.sf <- do.call(rbind,homeranges.sf)
    homeranges.sf <- st_transform(homeranges.sf,crs=st_crs(infile))

    # Add areas estimates
    areas <- c(sapply(homeranges, function(x) c(summary(testhr)$CI) ))
    homeranges.sf <- cbind(homeranges.sf,areas)

    st_write(homeranges.sf,dsn=outfile)

}

homerange.calculator(infile  = "./experiment006/dataderived/pardas_tiete_all_individuals.gpkg",
                     outfile = "./experiment006/dataderived/homeranges.gpkg"
)