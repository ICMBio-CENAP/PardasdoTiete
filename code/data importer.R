# ---
# title: Organization of Cougar and Jaguar GPS movement data
# author: Bernardo Niebuhr <bernardo_brandaum@yahoo.com.br>
#         Jorge Menezes    <jorgefernandosaraiva@gmail.com> 
# date: CENAP-ICMBio/Pro-Carnivoros, Atibaia, SP, Brazil, June 2019
# 
# ---

## Simplified Importer tool:
 ## Intent: This is a short, automated version of the file 00_organize_data_2018_06_d23.R
 ## whose purpose is to read the several csv files that have animal locations
 ## and  return a single csv files with standartized columns.        
 ## It also performs small data wrangling operations: formatting timestamps to POSIXct format,
 ## eliminating fixes before the capture of the individual, and order locations by time.
 
 ## Input: a directory with several csv files, along with a metadata.csv a column Tag_ID 
 ## with the ID of each animal, a release.date column and a name column. Other information on the
 ## may be added but it is not necessary.

 ## Output: A Geopackage with data of all animals, along with a ID and timestamp columns.


data.importer <-  function(pointfile, metafile, outfile, tempdir, res, qgis.folder, crs =NULL) {

    #FOR DEBUG:
    #pointfile <- "experiment007/dataderived/Pardas_do_Tiete_todos_individuos.csv"
    #metafile  <- "raw/data 29.06.20/Processed/metadata.csv"
    #crs <- 102033
    #outfile <- "experiment007/dataderived/pardas_tiete_all_individuals.gpkg"

    ### Loading dependencies
    if(is.null(crs)) {
        crs <- '+proj=aea +lat_1=-2 +lat_2=-22 +lat_0=-12 +lon_0=-54 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs'
    }

    # Load capture and release
    meta.data <- read.csv(metafile, stringsAsFactors =F)
    meta.data <- meta.data[,c("Release.day.utc","Name")]
    meta.data$Release.day.utc <- as.POSIXct(meta.data$Release.day.utc, format="%m/%d/%Y")

    # Load csv file with all locations
    fixes <- read.csv(pointfile,stringsAsFactors =F,row.names=1)
    fixes$timestamp <- as.POSIXct(fixes$timestamp, format = "%Y-%m-%d  %H:%M:%S", tz="GMT")
    
    # Read the state of São Paulo
    SP <- getData(name = "GADM",country = "BRA",level=1) %>% st_as_sf() %>% filter(HASC_1=="BR.SP")


    ## Eliminate any points that can be considered "wrong":
    # Points without X or Y
    # Points with equal X, Y and timestamp
    # Points with HDOP>5 (indicate a low quality fix)
    # Points before the release date of the animal.
    # Points outside the state of São Paulo 
    # (Some of the latter are actual locations but we only have environmental data for SP)

    fixes.clean <- fixes %>% 
            left_join(meta.data, by=c("name"="Name")) %>%
            filter(timestamp >= Release.day.utc, !is.na(X), !is.na(Y), hDOP < 5) %>%
            distinct(X,Y,timestamp, name, .keep_all=T) %>%
            dplyr::select( - Release.day.utc) %>%
            st_as_sf(coords= c("X","Y"), crs=4326) %>%
            st_join(SP[,"geometry"], left=F)

    ### Transform to Albers Equal area and add coordinates as a column

    fixes.geo <- fixes.clean %>%
                 st_transform(crs=crs) %>%
                 mutate(Longitude  = st_coordinates(.)[,1], Latitude = st_coordinates(.)[,2]) 
                
    st_write(fixes.geo, dsn=outfile, delete_dsn=T)

    ### creates the maps for extracting ssf values             
    st_buffer(fixes.geo, 20000) %>% 
    st_union() %>% 
    st_intersection(st_transform(SP, crs=crs)) %>%
    envpreparator(finalrds = "observedstack.rds", 
                  tempdir= tempdir, res= res, baseproj = crs,
                  qgis.folder = qgis.folder
                  )
    print("Generated gpkg with jaguar data!")
}

























