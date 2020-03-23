#' ---
#' title: 'Poor man's Zonator '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 
# This code takes a maxent projection (from maxenter() ) and blurs the image using
# a gaussian filter. This blurring is used to generate a map of reserve design that
# values aggregation. This aggregation is based on a gaussian radius. 
# This radius, on the other hand, is estimated from the puma's home range in the 
# dataset.
# Once blurred, we take a map of existing reserves and calculate their overall quality
# by summing the cells. This value is them compared with the optimal reserve design,
# restricing choice to a second shape.
# This code simulates the zonation software with less options, but with the additional
# benefit of not requiring human input and being easily integrate in this workflow.

# Input:  
# The maxent quality map (as a path to the  raster file), 
# and a numeric value representing the radius, and two shapes one restricing
# the optimal distribution and another represent the current choice.
# qgis folder must also be set so we can run algoritms using SAGA.
# Finally a folder for storing byproducts and the shapes

# Output:
# A vector map containing the optimal set of reserves and another containing the actual
# An rds file contaning the comparison the qualities of current and optimal set of reserves
# along with their ratio.
# A blurred quality map is generated as byproduct


zoner <- function( quality.map, sigma, reserves, constrain, out.folder) {

# Producing blurred image
run_qgis(alg   = "saga:gaussianfilter", 
         INPUT = normalizePath(quality.map), 
         SIGMA = sigma, 
         MODE  = 1,
         RESULT= paste0(out.folder,"/qualityblurred.tif")
         )

# Constrain it to AES tiete regions
run_qgis(alg = "gdal:cliprasterbymasklayer",
         INPUT = normalizePath(paste0(out.folder,"/qualityblurred.sdat")),
         MASK = constrain,
         CROP_TO_CUTLINE = TRUE,
         OUTPUT = paste0(out.folder,"/qualityinAES.tif")
)


# Get quality inside existing reserves
AESareas  <- raster( paste0(out.folder,"/qualityinAES.tif")) 
reserves <-  readOGR(reserves)

res.values <- raster::extract(AESareas, reserves)
res.quality <- sum(unlist(res.values),na.rm=T)
print(res.quality)

# Turn in number of cells in reserves in a quantile estimation
ncells  <- cellStats(AESareas, stat = function(x,na.rm) sum(!is.na(x))  )
res.quantile <- 1 - length(unlist(res.values))/ncells

# find which cell values are above this quantile and calculate
# their value 
target <- quantile(AESareas, res.quantile)
optimal <- calc(AESareas, function(x) x>target, filename = paste0(out.folder,"/optimalplaces.tif") )
optimal.quality <- cellStats(optimal*AESareas, "sum")

# output the Quality ratios:
ratio.vector <- c(reserve = res.quality, optimal = optimal.quality, ratio = res.quality/optimal.quality)
saveRDS(ratio.vector,file = paste0(out.folder,"/qualities.rds") )
cat("estimation on",quality.map,"complete")

}
#test<- readRDS("./experiment004/mapsderived/currentquality/qualities.rds")
