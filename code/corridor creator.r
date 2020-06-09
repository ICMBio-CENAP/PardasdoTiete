#' ---
#' title: 'Path calculator '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This function takes a map of the selected areas, and another map indicating the quality for the jaguars. 
# It tries to calculate reserves clusters, which area reserves whose centroids are less than one day away
# from a jaguar walking on a straight line. The least cost path between these clusters is then calculated.

# Input:  

# optimal: a binary raster file with 1 for pixels selected for reserves 0
# for non selected
# cost : a raster with a valuerepresenting how hard it is for the animal to transverse 
# the environment. It is the opposite of the quality. Must be positive though.
# outfile: The filepath for a geodatabase containing the leastcost paths for corridors.

# Output:
# AA geopackage with the best corridors selects, as represented by lines.

# get_args_man("grass7:r.drain")

corridor.creator <-  function(optimal, cost, pythonbat, script, outdir, outfile) {
cost <- normalizePath(cost)

# Create area polygons
optimal  <- raster(optimal)
areas    <- rasterToPolygons(optimal,fun = function(x){x==1},n=8,dissolve=T)
areas_sf <- st_as_sf(areas)
areas_sf <- st_cast(areas_sf, "POLYGON")


# Get centroids and create clusters
cents <- st_centroid(areas_sf)
cent_dists <- dist(st_coordinates(cents))
cluster_id <- dbscan(cent_dists, eps=7200, minPts=1)$cluster
clusters  <- unique(cluster_id)
areas_sf   <- cbind(areas_sf, cluster_id)
#browser()


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

    bat    <- shQuote(pythonbat)
	script <- shQuote(normalizePath(script))
    outdir <- shQuote(normalizePath(outdir))
    map    <- shQuote(cost)


    allpaths[[a]]<-system(paste(bat,script,cost,origin,dests,outdir), intern=T)[2]

}

# Remove temporary files
listremove <- list.files(outdir, pattern="(tif$|tfw$|xml$)",full.names=T)
file.remove(listremove)

# Read all shape files
paths <- lapply(allpaths,st_read)

# Associate information with original cluster and destination cluster
for(a in 1:length(paths)) {
    paths[[a]] <- cbind(paths[[a]],cluster_org=a, cluster_dest= cluster_id[paths[[a]]$cat])
}

paths <- do.call(rbind,paths)
#outfile="./experiment005/mapsderived/currentqualitytotal/corridors/corridors.gpkg"
st_write(paths,dsn=outfile)

}