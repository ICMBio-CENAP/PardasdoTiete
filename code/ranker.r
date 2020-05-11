#' ---
#' title: 'Ranker '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 
# This code takes a maxent projection (from maxenter() ) and blurs the image using
# a gaussian filter. (similar to zoner) This blurring is used to generate a map of reserve design that
# values aggregation. This aggregation is based on a gaussian radius. 
# This radius, on the other hand, is estimated from the puma's home range in the 
# dataset.
# Once blurred, we discard areas outside AES control and inside AES areas. Thus this map
# deals exclusively with areas for exapnsion
# Input:  

# The maxent quality map (as a path to the  raster file), 
# and a numeric value representing the radius, and two shapes one restricing
# the optimal distribution and another represent the current choice.
# qgis folder must also be set so we can run algoritms using SAGA.
# Finally a folder for storing byproducts and the shapes

# Output:
# A vector map containing the rank of each remaining cell


ranker <- function( quality.map, sigma, reserves, constrain, out.folder) {

# Producing blurred image
run_qgis(alg   = "saga:gaussianfilter", 
         INPUT = normalizePath(quality.map), 
         SIGMA = sigma, 
         MODE  = 1,
         RESULT= paste0(out.folder,"/qualityblurred2.sdat")
         )

quality <- raster(paste0(out.folder,"/qualityblurred2.sdat"))

spreserves  <- readOGR(reserves) 

if(!is.null(constrain)) {
spconstrain <- readOGR(constrain)

qualityconst <- quality %>% 
                crop(spconstrain) %>%
                mask(spconstrain) %>%
                mask(spreserves, inverse=T)
} else {
    qualityconst <- quality %>% 
                mask(spreserves, inverse=T)
}


opt <- qualityconst
opt[] <- rank(values(qualityconst), na.last="keep")
writeRaster(opt, filename =  paste0(out.folder,"/optimalrankadd.tif"), overwrite=T)

cat("rank on",quality.map,"complete")

}

# FOR DEBUG AND EXPLORATION:
#quality <- crop(quality,extent(450000, 470000, -1070000,-1050000))
#testm <- mask(qualityt, spreserves)

