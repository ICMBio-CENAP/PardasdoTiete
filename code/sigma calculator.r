#' ---
#' title: 'Sigma calculator'
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent:
# This function calculates the ideal sigma for a gaussian buffer 
# that is used to generate increase aggregation on the algorithm to
# select reserves.
# Following a discussion with Ronaldo, we opted for using the arbitrary
# value of the average step-length on 1h across individuals.
# We reason that this represent animal decision making in a situation where
# they do not the environment. Under these conditions, animals would only use
# their immediate surroundings for decision making.

# Input:
# The geodatabase with all animal data.

# Output:
# A single number represeting the desired sigma.

sigma.calculator <- function(infile) {
    infile <- "C:\\Users\\jorge\\Documents\\AssociadoCNAP\\Projeto Pardas do Tiete\\experiment004\\dataderived\\pardas_tiete_all_individuals.gpkg"
    
    # Load data and convert it to amt format
    data <- st_read(infile) 
    crs  <- st_crs(data)[[2]]
    data <- mk_track(data, .x = "Longitude", .y = "Latitude", .t = timestamp, 
                      crs = CRS(crs), ID, Name)
    
    # Reorder values based on name and then timestamp
    data <- data[order(data$Name,data$t_),]
    
    # Resample every hour.
    rsp <- list()
    for( a in 1:length(unique(data$Name))) {
        tmp <- subset(data, data$Name == unique(data$Name)[a] )
        rsp[[a]] <- track_resample(tmp,rate = hours(1), tolerance = minutes(10))
    }

    # take average step lenght per burst and individual
    data<- do.call(rbind,rsp)
    data.split <- split(data, list(data$Name,data$burst_))
    data.split <- data.split[sapply(data.split,nrow)>3]
    sls <- lapply( data.split, function(x) step_lengths(x))
    average_step <- mean( do.call(c, sls), na.rm=T)
    return(average_step)
}