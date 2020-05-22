### path walker

## this function replaces r.path, since it is not available in qgis toolbox
## in version 3.4 (and i need this version due to other conflicts in the code)
## and SAGA gives to many errors and is too poor documented for anything useful.
## existing solutons in R with gdistance are also not memory safe for larger rasters
## because it requires storing a sparse matrix,
# dir <- raster("C:/Users/Jorge/AppData/Local/Temp/RtmpaMt62b/dir23d302c417fe6.tif")
# start <- c(622685.2,-1225375)
# pt <- pather(dir,start)
# li <- st_linestring(pt)
# sfc<-st_sfc(li,li)

# st_write(sfc,layer="lc",dsn="file.gpkg")

pather <- function(dir,start) {
    # get the row and column from start position
    col <- colFromX(dir,start[1])
    row <- rowFromY(dir,start[2])

    # Create holder
    points <- matrix(c(row,col),1,2)
    
    while(!is.na(dir[points[nrow(points),1],points[nrow(points),2]])) {
    # get value in degree change it to radian and them 
    #apply cos and sin to get movement direction
        radv <- dir[points[nrow(points),1],points[nrow(points),2]] * pi/180
        coldelta <- round(cos(radv),0)
        rowdelta <- -round(sin(radv),0)

        points <-rbind(points,c(points[nrow(points),1]+rowdelta,points[nrow(points),2]+coldelta))

    }
     points[,2] <- xFromCol(dir,points[,2])
     points[,1] <- yFromRow(dir,points[,1])
     #this complicated way keeps it as a matrix even when there is only one point
     pointsc <-  matrix(NA,nrow(points),2)
     pointsc[,1] <- points[,2]
     pointsc[,2] <-points[,1]
     colnames(pointsc) <- c("x","y")

    return(pointsc)
}