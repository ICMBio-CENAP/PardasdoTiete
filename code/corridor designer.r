#' ---
#' title: 'Path calculator '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This function takes a map of the selected areas, and another map indicating the quality for the jaguars. 
# Using those it calculates the least cost path between each input areas. After that, it 
# selects a network of corridors that connect all patches, with the lowest cost possible.


# Input:  

# optimal: a binary raster file with 1 for pixels selected for reserves 0
# for non selected
# cost : a raster with a valuerepresenting how hard it is for the animal to transverse 
# the environment. It is the opposite of the quality. Must be positive though.
# outfile: The filepath for a geodatabase containing the leastcost paths for corridors.

# Output:
# AA geopackage with the best corridors selects, as represented by lines.

## TODO: check GDAL DATA ERROR.

 
corridor.designer <-  function(optimal, cost, outfile) {

## for debug:
# opt  <- raster("./experiment005/mapsderived/currentqualitytotal/optimalplaces.tif")
# optc <- crop(opt,extent(532393,536645,-1058463,-1055692))
# pred  <- raster("./experiment005/mapsderived/qualitypredictions/maxentprediction.tif")
# predc <- crop(-pred,extent(532393,536645,-1058463,-1055692),filename="test.tif",overwrite=T)
# optimal <- optc

## Polygonizes the optimal reserves, and uses that information to calculate
## the shortest line between two polygons. The extremities of these lines are used
## as starting and stopping points for the least cost algorithm

# Polygonizes the locations
optimal  <- raster(optimal)
areas    <- rasterToPolygons(optimal,fun = function(x){x==1},n=8,dissolve=T)
areas_sf <- st_as_sf(areas)
areas_sf <- st_cast(areas_sf, "POLYGON")

# Creates a line between each polygon, from the closest vertice.
# Eliminate redudant lines (lines from poly A to poly A, and lines from 
#poly A-> B when B-> A is already on the list)
combs <- t(combn(1:nrow(areas_sf),2))

## for debug:
#write_sf(areas_sf,"areas.gpkg")
#write_sf(lines,"lines.gpkg")

# Split lines in origin and destination taking one of the polygons in the pair
# to be arrival and another destination randomly.


## Loop to find the least path between each reserve
files <- list()
costsucess <- list()
for(a in 1:nrow(combs) ) {

    lines    <- st_nearest_points(areas_sf[combs[a,1],],areas_sf[combs[a,2],]) ## Takes a while, might explode memory
    lines    <- st_sf(geometry=lines, origin = combs[a,1], target = combs[a,2]) 
    points   <- st_cast(lines,"POINT")
    points   <- cbind(points, line = rep(a, each = 2), type = c("origin","dest") )




    # Create temporary files to store maps
	gpkgfile <- tempfile(fileext=".gpkg")
    filedest <- tempfile(pattern = paste0("dest",a), fileext = ".gpkg")
    filecost <- tempfile(pattern = paste0("cost",a), fileext = ".tif")
    filedir  <- tempfile(pattern = paste0("dir",a),  fileext = ".tif")
    filelcpt <- tempfile(pattern = paste0("lcpt",a), fileext = ".shp")
    filelcli <- tempfile(pattern = paste0("lcli",a), fileext = ".shp")
   
    # Separates origin and destination and write destination in a file for
    # SAGA use.
    or <- points[points$line ==a & points$type=="origin",]
    dest <- points[points$line ==a & points$type=="dest",]
    cat(st_coordinates(or),st_coordinates(dest),filecost,"\n")
    # Uses the minimum bounding box between points to avoid extensive
    # calculation. Add a buffer of 30m to avoid having destination
    # points outside this extent.
    extent <- st_bbox(rbind(or,dest))[c("xmin","xmax","ymin","ymax")]
    extent <- extent + c(-120,120,-120,120)
    extent <- paste(extent, collapse=",")

    # Calculate accumulated cost surface. Might take a while.
    # it assumes a starting point in the origin
	bat <- shQuote("C:/Program Files/QGIS 3.4/bin/python-qgis.bat")
	script <- shQuote(normalizePath("./code/exploratory code/r.cost wrapper.py"))
    x <- shQuote(paste(st_coordinates(or),collapse=","))
    y <- shQuote(paste(st_coordinates(dest),collapse=","))
    map <- shQuote(normalizePath(cost))
    fld <- shQuote(filedir)
    flc <- shQuote(filecost)
    ext <- shQuote(extent)

    system(paste(bat,script,x,y,map,fld,flc,ext))
    if(!file.exists(filedir)) {stop(paste("file", x, y,"was not created"))}
    


    pathpoints <- pather(raster(filedir),st_coordinates(dest))
    if(nrow(pathpoints)==1) {"only one point was found"}
    lcline   <- st_linestring(pathpoints)
    linessfc <- st_sfc(lcline,crs=st_crs(areas_sf))
    st_write(linessfc,dsn = gpkgfile)
    files[[a]] <- gpkgfile
    costsucess[[a]] <- TRUE

}


# Combine each list path in a single object, and relates it to the original reserves
noterror <- !sapply(files,is.na)
leastpaths   <- lapply(files[noterror], st_read)
leastpathssf <- do.call(rbind,leastpaths)
leastpathssf <- cbind(leastpathssf,origin = combs[noterror,1],target=combs[noterror,2])

# Associate a cost to each path as the sum of costs along each least cost path
valuepaths <- raster::extract(pred,as(leastpathssf,"Spatial"),fun=sum)
leastpathssf <- cbind(leastpathssf, cost = valuepaths)

# Turn that in a graph with edge weight being the cost
g <- graph_from_data_frame(st_drop_geometry(leastpathssf[,c("origin","target","cost")]),
    directed=FALSE)
E(g)$weight <- E(g)$cost

# Running minimum spanning tree algorithm to select a network that ensure  connectivity
# among all reserves while keeping the lowest cost possible
selected_corridors <- as_long_data_frame( mst(g) )[,5:6]

# Link that information back the original paths
bestpaths <- numeric()
for(a in 1:nrow(selected_corridors)) {
    currentbp <- unlist(sort(selected_corridors[a,]))
    paths <- t(apply(st_drop_geometry(lines),1,sort))
    isequal <- apply(paths,1,function(x) all(currentbp==x))
    bestpaths[a] <- which(isequal)
}
write_sf(leastpathssf[bestpaths,], outfile)

}