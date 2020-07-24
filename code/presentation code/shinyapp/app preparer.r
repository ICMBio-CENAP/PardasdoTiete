#' ---
#' title: 'App preparer '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This function takes the output of the main code and converts it to
# presentation ready map that can be used in our shinyapp 
# It does operations like format it to  WGS84 latlong and round
# price values to be more reader friendly


# Input:  

# mapnow: a geopackage with two layers , corridors and reserves, each with price attached to their features
# mapfuture: the same as above, but with corridors and reserves predicted for the future
# studyarea: a GIS file representing the study area
# APPs : a GIS file with AES current reserves
# appfolder: the path to the folder where the app is placed


# Output:
# A geopackage with the best corridors selects, as represented by lines.

apppreparer <- function(mapnow, mapfuture, studyarea,APPs, appfile) {

    # Load study area convert it to WGS84, remove altitude data, write it in the folder
    st_read(studyarea)  %>%
    st_zm %>% 
    st_transform(crs=4326) %>%
    st_write(dsn=appfile, layer="studyarea")

    # Load current reserves, project to WGS, round price data and write it in folder
    polys<-st_read(mapnow,layer="reserves") %>% 
    st_transform(crs=4326)

    polys$price <-round(polys$price,2)
    st_write(polys,dsn=appfiles,layer="reservesnow")

    # Same as above with corridors, but also rounding corridor value
    corridors<-st_read(mapnow,layer="corridors") %>%
    st_transform(crs=4326) 

    corridors$corridorvalue <- round(corridors$corridorvalue)
    corridors$price <- round(corridors$price)
    st_write(corridors,dsn=appfile,layer="corridorsnow")

    # Load future reserves
    polysfut <- st_read(mapfuture,layer="reserves") %>% 
    st_transform(crs=4326)
    polysfut$price <-round(polysfut$price,2)
    st_write(polysfut, dsn=appfile, layer="reservesfut")


    corridorsfut<-st_read(mapfuture,layer="corridors") %>%
    st_transform(crs=4326) 
    corridorsfut$corridorvalue <- round(corridorsfut$corridorvalue)
    corridorsfut$price <- round(corridorsfut$price)
    st_write(corridorsfut,dsn=appfuture,layer="corridorsfut")

    st_read(APPs) %>% 
    st_transform(crs=4326) %>%
    st_write(dsn=appfile,layer="apps")

}