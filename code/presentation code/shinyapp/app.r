
# FOR DEBUG:
#setwd("D:/Trabalho/pardasdotiete/PardasdoTiete/code/presentation code/shinyapp")
#setwd("D:/Trabalho/pardasdotiete/PardasdoTiete")

# Settings to deploy app in shinyapps.io.
# You need to fill secret with a passcode to acess the account
# However, for obvious reasons, I'm removing that from public code.

# Remember, shinyapps are freemium. If you use to much, they will block it and
# require payment for extra bandwidth.
# The same goes for the CartoDB.Positron map. If you expect a lot of traffic, 
# buy their services beforehand.

#library(rsconnect)
#rsconnect::setAccountInfo(name='jfsmenezes', token='715B40D3A39A9B5086CD21C5A330AD8E', secret='')
#rsconnect::deployApp("./code/presentation code/shinyapp")


#Link to app deployed. Both links work.
# https://bit.ly/2VzZuwe
# https://jfsmenezes.shinyapps.io/shinyapp/


library(rgdal)
library(shiny)
library(leaflet)
library(raster)
library(leafpop)	


# The the webpage interface, as one map covering the entire screen 
# with a link to my Google drive with the GIS files.
# the scan part is completely unecessary. It is just there to ensure no one reading
# the github page has access to the link to the GIS files.
ui <- fillPage(
    leafletOutput("map",height ="100%"),
    a(href=scan("linkgdrive.txt",what = "character"),
    "Link to GIS files",
    style="position:absolute;bottom:1%;left:1%;font-size:large")
)

# Serverside calculations.
server<- function(input,output) {

    # Read packages
    library(shiny)
    library(leaflet)
    library(sf)
    library(leafpop)
    
    
    # Read pre-prepared data (check app preparer.r for details)
    studyarea    <- st_read( "appfiles.gpkg", layer = studyarea     )
    polys        <- st_read( "appfiles.gpkg", layer = reservesnow   )
    corridors    <- st_read( "appfiles.gpkg", layer = corridorsnow  )
    polysfut     <- st_read( "appfiles.gpkg", layer = reservesfut   )
    corridorsfut <- st_read( "appfiles.gpkg", layer = corridorsfut  )
    polysaes     <- st_read( "appfiles.gpkg", layer = apps          )

    # set color palletes for future reserves and current reserves.
    colorpoly    <- colorFactor(rainbow(length(unique(polys$cluster_id))), polys$cluster_id)
    colorpolyfut <- colorFactor(rainbow(length(unique(polysfut$cluster_id))), polysfut$cluster_id)

    # add the actual map object, consisting of two basemaps (the Carto and ESRI), 2 reserve layers,
    # 2 line layers, and a layer control (to turn layers on and off).
    m <- leaflet() %>% 
        setView(lng = -48.8317, lat = -21.7548, zoom = 8) %>%
        addProviderTiles(providers$CartoDB.Positron,group="Mapa Base") %>%
        addProviderTiles(providers$Esri.WorldImagery,group="Satélite") %>%
        addPolygons(
            data=polysaes,
            color = "#92F492",
            fill = FALSE,
            group = "Reservas AES"
            ) %>%
        addPolygons(data=studyarea, 
            color = "#000000",
            weight = 2,
            fill=FALSE,
            opacity=0.5
            ) %>%
        addPolygons(data=polys, 
            color = ~colorpoly(cluster_id),
            weight = 2,
            popup= popupTable(polys,zcol=c("cluster_id","price"),row.numbers=F,feature.id=F),
            fillColor = ~colorpoly(cluster_id),
            group = "Reservas atual",
            ) %>%
        addPolylines(
            data=corridors,
            color = "red",
            weight = 2,
            popup= popupTable(corridors,zcol=c("corridorvalue","price"),row.numbers=F,feature.id=F),
            group = "Corredor atual"
            ) %>%
        addPolygons(data=polysfut, 
            color = ~colorpoly(cluster_id),
            weight = 2,
            popup= popupTable(polysfut,zcol=c("cluster_id","price"),row.numbers=F,feature.id=F),
            fillColor = ~colorpolyfut(cluster_id),
            group = "Reservas futuro"
            ) %>%
        addPolylines(
            data=corridorsfut,
            color = "red",
            weight = 2,
            popup= popupTable(corridorsfut,zcol=c("corridorvalue","price"),row.numbers=F,feature.id=F),
            group = "Corredor futuro"
            ) %>%
        addLayersControl(
            baseGroups =c("Mapa Base","Satélite"),
            overlayGroups = c("Reservas atual","Corredor atual","Reservas futuro","Corredor futuro","Reservas AES"),
            options = layersControlOptions(collapsed = FALSE)
            )
    
    
    # Actually render the map object create before
    output$map <- renderLeaflet(m)
}

# Run the functions above in the form of an app.
shinyApp(ui, server)