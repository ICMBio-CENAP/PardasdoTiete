### app preparer:
library(sf)

    st_read("./code/presentation code/shinyapp/study_area.gpkg")  %>%
    st_zm %>% st_write(dsn="./code/presentation code/shinyapp/study_area_prep.gpkg")

    polys<-st_read("./code/presentation code/shinyapp/optimalpricednow.gpkg",layer="reserves") %>% 
    st_transform(crs=4326)
    polys$price <-round(polys$price,2)
    st_write(polys,dsn="./code/presentation code/shinyapp/optimalpricednow_prep.gpkg",layer="reserves")

    corridors<-st_read("./code/presentation code/shinyapp/optimalpricednow.gpkg",layer="corridors") %>%
    st_transform(crs=4326) 
    corridors$corridorvalue <- round(corridors$corridorvalue)
    corridors$price <- round(corridors$price)
    st_write(corridors,dsn="./code/presentation code/shinyapp/optimalpricednow_prep.gpkg",layer="corridors")


    polysfut <- st_read("./code/presentation code/shinyapp/optimalpricedfuture.gpkg",layer="reserves") %>% 
    st_transform(crs=4326)
    polysfut$price <-round(polysfut$price,2)
    st_write(polysfut,dsn="./code/presentation code/shinyapp/optimalpricedfuture_prep.gpkg",layer="reserves")


    corridorsfut<-st_read("./code/presentation code/shinyapp/optimalpricedfuture.gpkg",layer="corridors") %>%
    st_transform(crs=4326) 
    corridorsfut$corridorvalue <- round(corridorsfut$corridorvalue)
    corridorsfut$price <- round(corridorsfut$price)
    st_write(corridorsfut,dsn="./code/presentation code/shinyapp/optimalpricedfuture_prep.gpkg",layer="corridors")
