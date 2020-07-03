
#setwd("D:/Trabalho/pardasdotiete/PardasdoTiete/code/presentation code/shinyapp")
#setwd("D:/Trabalho/pardasdotiete/PardasdoTiete")
#library(rsconnect)
# rsconnect::setAccountInfo(name='jfsmenezes',
#			  token='715B40D3A39A9B5086CD21C5A330AD8E',
#			  secret='')
#rsconnect::deployApp("./code/presentation code/shinyapp")
# https://bit.ly/2VzZuwe
# https://jfsmenezes.shinyapps.io/shinyapp/


library(rgdal)
library(shiny)
library(leaflet)
library(raster)
library(leafpop)	


# the scan part is completely unecessary. It is just there to ensure no one reading
# the github page has acess to the link to the GIS files
ui <- fillPage(
    leafletOutput("map",height ="100%"),
    a(href=scan("linkgdrive.txt",what = "character"),
    "Link to GIS files",
    style="position:absolute;bottom:1%;left:1%;font-size:large")
)

server<- function(input,output) {
    library(shiny)
    library(leaflet)
    library(sf)
    library(leafpop)
    
    # Read data, project and round for interactive table
    studyarea    <- st_read("study_area_prep.gpkg")
    polys        <- st_read("optimalpricednow_prep.gpkg",layer="reserves") 
    corridors    <- st_read("optimalpricednow_prep.gpkg",layer="corridors")
    polysfut     <- st_read("optimalpricedfuture_prep.gpkg",layer="reserves")
    corridorsfut <- st_read("optimalpricedfuture_prep.gpkg",layer="corridors")


    # set colo palletes
    colorpoly <- colorFactor(rainbow(length(unique(polys$cluster_id))), polys$cluster_id)
    colorcor <- colorNumeric(palette = "Greens", domain = corridors$corridorvalue)
    colorpolyfut <- colorFactor(rainbow(length(unique(polysfut$cluster_id))), polysfut$cluster_id)


    m <- leaflet() %>% 
        setView(lng = -48.8317, lat = -21.7548, zoom = 8) %>%
        addProviderTiles(providers$CartoDB.Positron,group="Mapa Base") %>%
        addProviderTiles(providers$Esri.WorldImagery,group="Satélite") %>%
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
            overlayGroups = c("Reservas atual","Corredor atual","Reservas futuro","Corredor futuro"),
            options = layersControlOptions(collapsed = FALSE)
            )
    
    
    
    #addRasterImage(op, colors = colorNumeric(palette = "#90ee90", na.color="#00000000", domain=1),project=FALSE)
    output$map <- renderLeaflet(m)
}
shinyApp(ui, server)