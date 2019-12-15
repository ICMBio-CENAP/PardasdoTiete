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

### Loading dependencies
library(tidyverse)
library(lubridate)
library(sf)

meta.data <- read.csv2('./data/locations/meta_data.csv',stringsAsFactors = F)

### Load all csv files in folder.
files2read <- list.files(path = "./data/locations/test datasets", pattern = "pardas_tiete_",full.names=T)#"./data/locations/pardas_tiete_.*.csv")
fix.frames <- lapply(files2read, read.csv, stringsAsFactors = F)
#for debug
fix.frames <- lapply(fix.frames, function(x) x[sample(1:nrow(x), round(nrow(x)/10),0), ] )

###Select relevant columns
fix.frames <- lapply(fix.frames, function(x) select(x, Tag_ID, UTC_Date, UTC_Time, Latitude, Longitude, Name, Sex))


### Combine all individuals in a data.frame.
fixes <- do.call(rbind, fix.frames)

### Use lubridate to generate valid POSIXct
fixes$timestamp <- as.POSIXct(ymd(fixes$UTC_Date) + hms(fixes$UTC_Time))

### Use a left join with meta.data to find releasedates and eliminate animals from it.
# Also arrange by animal and then in cronological order, and eliminate duplicate rows.
fixes <- fixes %>% 
         left_join(meta.data[,c("Tag_ID","release.date.utc")], by="Tag_ID") %>%
         mutate(release.date.utc = as.POSIXct(ymd_hms(release.date.utc))) %>%
         filter( timestamp >= release.date.utc, Latitude > -40) %>%
         arrange(Tag_ID, timestamp) %>%
         distinct() %>%
         select( - release.date.utc)



### creating spatial object and converting it to Albers equal area
crs <- '+proj=aea +lat_1=-2 +lat_2=-22 +lat_0=-12 +lon_0=-54 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs'
fixes.geo <- st_as_sf(fixes, coords = c("Longitude","Latitude"), crs = 4326) %>%
             st_transform(crs=crs) %>%
             mutate(Longitude  = st_coordinates(.)[,1], Latitude = st_coordinates(.)[,2]) 
             
st_write(fixes.geo, dsn="./data/locations/pardas_tiete_all_individuals.gpkg")

### creates the maps for extracting ssf values             
st_buffer(fixes.geo, 20000) %>% st_union() %>% envpreparator(finalrdata = "observedstack.RData", tempdir="./maps/testing", finalfolder="./maps/testing", res=5000)
























