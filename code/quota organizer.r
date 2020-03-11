# ---
# title:  Quota organizer for zone production
# author: Jorge Menezes    <jorgefernandosaraiva@gmail.com> 
# date: CENAP-ICMBio/Pro-Carnivoros, Atibaia, SP, Brazil, March 2020
# 
# ---

# Intent: This is a code to receive the AES tiete quota map and make them uniform across
# different power plants. The maps we received (.\raw\cotas) include maps that are not
# part of the study area. In addition some of the maps are presented as lines, while 
# other are polygons. Since our code assumes polygons we will turn lines into polygons
# by creating an enclosed polygon and them removing the water parts.

# Input: A series of kmz files.

# Output: A single geodatabase with organize data


# Function to convert kmz file to kml (just unzip it)
kmler <- function(infile,outfolder) {
    unzipped <- unzip(infile, exdir=tempdir(), overwrite=T)
    kmlname <-  strtrim( basename(infile), nchar(basename(infile))-4)
    kmlname <- paste0(outfolder, "/", kmlname, ".kml")
    file.copy(unzipped, kmlname)
    return(kmlname)
    }

#load files, convert to kml read it on R.
files <- list.files("./raw/maps/cotas", pattern ="kmz$", full.names = T )
kml <- lapply(files, kmler, outfolder = "./experiment004/mapsderived/quotas")
shapes <- lapply(kml, st_read)
shapes <- lapply(shapes, "[",c(1,3)) # remove uncessary description column

# get which files are linestring
geom.types <-  lapply(shapes, st_geometry_type)
geom.types <-  sapply(geom.types, unique)
linestrings <- shapes[which(geom.types == "MULTILINESTRING")]
linestrings <- lapply(linestrings, st_union)
polygons <- lapply(linestrings, st_polygonize)

