library(leaflet)
library(raster)
setwd("D:/Trabalho/pardasdotiete/PardasdoTiete")
op <- raster("./experiment004/mapsderived/currentquality/optimalplaces.tif")
op[op==0] <- NA
op <- projectRaster()

m <- leaflet() %>% setView(lng = -48.8317, lat = -21.7548, zoom = 8)
m %>% 
    addProviderTiles(providers$Stamen.Toner) %>%
    addRasterImage(op, colors = colorNumeric(palette = "#013220", na.color="#00000000", domain=1))


