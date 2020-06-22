#' ---
#' title: 'Corridor designer '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This function takes a map of all selected corridors and calculate minimum subset that
# will connect all reserve clusters.


# Input:  

# corridors: a map with corridors among all reserve clusters
# cents : path to GIS file with points used as centroids in the cluster calculation
# destfile: the path to store the output file.

# Output:
# A geopackage with the best corridors selects, as represented by lines.



 
corridor.designer <-  function(corridors, cents, destfile) {


corridors <- st_read(corridors)
cents     <- st_read(cents)
cents     <- st_transform(cents,st_crs(corridors))

# Find cluster of origin and arrival of the corridor.
corridors <- endfinder(corridors, cents)

# split by clusters of origin and destination
bysec <- split(corridors, list(corridors$cluster1, corridors$cluster2 ) )
selectedcorrs <- lapply(bysec, function(x) x[which.min(x$corridorvalue),])
selectedcorrs <- do.call(rbind,selectedcorrs)

# Make df to import as igraph (the graph is symetric so from and to is arbitrary)
selectedcorrs.df <-  st_drop_geometry(selectedcorrs)[,c("cluster1","cluster2")]
g <- graph_from_data_frame(selectedcorrs.df, directed=F)


# Apply minimum spanning tree to find out necessary edges.
gopt <-  mst(g,weights = selectedcorrs$corridorvalue )

# Convert it back to data.frame
selected <- igraph::as_data_frame(gopt, what="edges")

# Select lines in corridors that have the origin and destination in selected
mstcorridors <- list()
for(a in 1:nrow(selected)) {
    mstcorridors[[a]] <- selectedcorrs[
    (selectedcorrs$cluster1==selected[a,1] & selectedcorrs$cluster2==selected[a,2]),]
}
mstcorridors <- do.call(rbind, mstcorridors)

# Write selected corridors in a file
mstcorridors <- mstcorridors[,c("cluster1","cluster2","corridorvalue")]
st_write(mstcorridors, dsn=destfile)

}

#  Finding start and endpoint of lines
endfinder <-  function(lines, points) {
    # add an id field unique for each line
    lines <- cbind(lines,id=1:nrow(lines))

    # cast vertices to point, and take first and last points
    # st_cast could work for the entire dataset, but it is greatly increase memory 
    # consumption.
    endpoints <- st_line_sample(lines,sample=c(0,1))
    endpoints <- st_cast(endpoints,"POINT")
    # get the nearest point from the point feature and take its cluster info
    nearpoints <- st_nearest_feature(endpoints,points)
    clusterid  <- points$cluster_id[nearpoints]
    clustermat <- matrix(clusterid,,2,byrow=T)
    clusterdf <- as.data.frame(clustermat)
    colnames(clusterdf) <- c("cluster1","cluster2")
    
    # get information back on the lines
    linesf<- cbind(lines,cluster1=clusterdf$cluster1,cluster2=clusterdf$cluster2)
    return(linesf)

}