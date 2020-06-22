#' ---
#' title: 'Corridor creator'
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This function takes a map of the selected areas, and another map indicating the quality for the jaguars. 
# It tries to calculate reserves clusters, which are  reserves whose centroids are less than one day away
# from a jaguar walking on a straight line. The least cost path between these clusters is then calculated.

# Input:  

# optimal: a binary raster file with 1 for pixels selected for reserves 0
# for non selected
# cost : a raster with a value representing how hard it is for the animal to transverse 
# the environment. It is the opposite of the quality. Must be positive though.
# existing: existing reserves to be combined with ideal ones in the optimal calculation
# pythonbat: path to pythonfile that can execute pyqgis commands
# script: path to the python script for calculation of the least cost paths.
# outdir: directory for temporary files resulting from pyqgis script.
# outcor: The filepath for a geodatabase containing the leastcost paths for corridors.
# outcent: The filepath for a geodatabase containing the centroids of each reserve, along
# with their cluster association.

# Output:
# AA geopackage with all corridors between clusters.

corridor.creator <-  function(optimal, cost, existing, dist,  pythonbat, script, outdir, outcor,outcent) {
cost <- normalizePath(cost)
bat    <- shQuote(pythonbat)
script <- shQuote(normalizePath(script))
outdirshquote <- shQuote(normalizePath(outdir))
map    <- shQuote(cost)

# Create area polygons
optimal  <- raster(optimal)
areas    <- rasterToPolygons(optimal,fun = function(x){x==1},n=8,dissolve=T)
areas_sf <- st_as_sf(areas)
areas_sf <- st_cast(areas_sf, "POLYGON")

# read existing reserves and add them to expectation
#existing <- st_read(existing)
#areas_sf <- st_union(areas_sf,existing)

# Get centroids and create clusters
cents      <- st_centroid(areas_sf)
cent_dists <- dist(st_coordinates(cents))
cluster_id <- dbscan(cent_dists, eps=dist, minPts=1)$cluster
clusters   <- unique(cluster_id)
cat("found",max(clusters), "reserve clusters \n")
areas_sf   <- cbind(areas_sf, cluster_id)
cents_sf   <- cbind(cents,cluster_id)

# Save areas_sf and cents_sf for future reuse
st_write(areas_sf,dsn=paste0(outdir,"/reservesvect.gpkg"))
st_write(cents_sf,dsn=paste0(outdir,"/reservescent.gpkg"))


# Start path calculations
allpaths <- list()
for(a in 1:length(clusters)) {


    # Save centroids from current clusters and isolate then in a shapefile
    origin <-normalizePath(tempfile(fileext=".shp"))
    st_write(cents[cluster_id==clusters[a],], dsn=origin)
    origin <- shQuote(origin)

    dests <- normalizePath(tempfile(fileext=".shp"))
    st_write(cents[cluster_id!=clusters[a],], dsn=dests)
    dests <- shQuote(dests)


    allpaths[[a]]<-system(paste(bat,script,cost,origin,dests,outdirshquote), intern=T)[2]
    unlink(list.files(pattern="processing_","C:/Users/Jorge/AppData/Local/Temp",full.names=T),recursive=T)
}

# Remove temporary files
listremove <- list.files(outdir, pattern="(tif$|tfw$|xml$)",full.names=T)
file.remove(listremove)

# Read all shape files
allpaths <- list.files(outdir,pattern=".shp",full.names=T)
cost <- rast(cost)
for( a in 1:length(allpaths)) {
    corridors <- vect(allpaths[[a]])
    corridorvalue <- terra::extract(cost,corridors,fun=sum)
    corridorvalue <- c(corridorvalue)
    rm(corridors)
    st_read(allpaths[[a]]) %>% 
    cbind(corridorvalue=corridorvalue) %>% 
    st_write(dsn=outcor,update=T)

}

}