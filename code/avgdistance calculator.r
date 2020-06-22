### Calculator of average distance travelled per day


avgdistance.calculator <- function(infile) {
    # FOR DEBUG:
    #infile <- ".\\experiment005\\dataderived\\pardas_tiete_all_individuals.gpkg"
    data<- st_read(infile)
    crs  <- st_crs(data)[[2]]
    data <- mk_track(data, .x = Longitude, .y = Latitude, .t = timestamp, 
                      crs = CRS(crs), Name)
    
    # Reorder values based on name and then timestamp
    data <- data[order(data$Name,data$t_),]
    data.split<-split(data,list(date(data$t_),data$Name))
    daydists <- sapply(data.split,tot_dist)
    return(mean(daydists))

}