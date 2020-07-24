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

# Input: A series of kml files.

# Output: A single geodatabase with organized data.


quota.organizer <- function(forestmap, quotafolder) {

# Read crs from forest map
crs <- st_crs(st_read(forestmap))$proj4string

# grab forestmap parent folder
forestfolder <- dirname(forestmap)

# extract water polygons from forestmap and fix geometries
run_qgis("native:extractbyattribute", 
         INPUT = forestmap,
         FIELD = "CLASSE_USO",
         OPERATOR = 0,
         VALUE = "agua",
         OUTPUT = paste0(forestfolder,"/onlywater.gpkg")
)
run_qgis("native:fixgeometries",
         INPUT =  paste0(forestfolder,"/onlywater.gpkg"),
         OUTPUT = paste0(forestfolder,"/onlywaterfixed.gpkg")
)


# load IBI and PROV reserves
fullpolys  <- list.files( quotafolder, pattern ="Poly.gpkg$", full.names = T )
fullpolys  <- lapply(fullpolys, st_read)
fullpolys  <- lapply(fullpolys, st_transform, crs=crs)
fullpolys  <- mapply(st_write, obj = fullpolys, dsn = paste0(quotafolder,"/proj", c("IBI.gpkg", "PROV.gpkg") ))

# Calculate differences between them and the water polygon.
run_qgis("native:difference",
                        INPUT =   paste0(quotafolder,"/projIBI.gpkg"),
                        OVERLAY = paste0(forestfolder,"/onlywaterfixed onlypoly.gpkg"),
                        OUTPUT =  paste0(quotafolder,"/shoreIBI.gpkg")
)
run_qgis("native:difference",
                        INPUT =   paste0(quotafolder,"/projPROV.gpkg"),
                        OVERLAY = paste0(forestfolder,"/onlywaterfixed onlypoly.gpkg"),
                        OUTPUT =  paste0(quotafolder,"/shorePROV.gpkg")
)

# Merge all polygons within the study area  and there are effective app
# in a single geodatabase
files <- paste0(quotafolder,c(
"/AES_BAR_desap.kml",
"/AES_BAB_desap.kml",
"/AES_NAV_area_servidao.kml",
"/shoreIBI.gpkg",
"/shorePROV.gpkg"
))
shapes <- lapply(files, st_read)
shapes <- lapply(shapes, st_geometry)
shapes <- lapply(shapes, st_transform, crs=crs)
shapesgeom <- do.call(c,shapes)
dam <- rep(c("BAR", "BAB", "NAV", "IBI", "PRO"),
            times=sapply(shapes,length))
shapescomplete <- st_zm(st_sf(dam=dam,geometry=shapesgeom))
shapescomplete <- st_collection_extract(shapescomplete, "POLYGON")
shapescomplete <- st_cast(shapescomplete, "POLYGON")
shapescomplete <- st_make_valid(shapescomplete)
shapescomplete <- shapescomplete[unclass(st_area(shapescomplete))>5,]

st_write(shapescomplete, paste0(quotafolder,"/quotas_sea.gpkg") )
return( paste0(quotafolder,"/quotas_sea.gpkg") )

}