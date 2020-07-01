#' ---
#' title: 'Price calculator '
#' author: Jorge Menezes    - CENAP/ICMBio
#' ---

# Intent: 

# This functions takes a system of reserves (a reserve map and a corridor map)
# and a map of costs, and associates a price for each piece in this system of reserves.


# Input:  

# corridors: path a map with corridors among all reserve clusters
# polys : path with selected reserve system
# prices: path to a map with the price value per hectare (in the large polygons)
# output: path to outputfiles

# Output:
# A geopackage with corridors and polygons each with value of price


# TODO: fix behavior where it works as a script but not as a function

price.calculator <- function( corridors, polys, prices, output) {

polys     <- st_read("./experiment006/mapsderived/currentqualitytotal/corridors/reservesvect.gpkg")
prices    <- st_read("./raw/price data/SPGADM_priced.gpkg")
corridors <- st_read("./experiment006/mapsderived/currentqualitytotal/corridors/corridorssel.gpkg")
outfile   <- "./experiment006/mapsderived/currentqualitytotal/optimalpriced.gpkg"


    corridors <-  st_read(corridors)
    polys     <-  st_read(polys)
    prices    <-  st_read(prices)
    colnames(prices)[1:2] <- c("regiao","Preco.medio") # Fix problwm with UTF-8
    prices    <-  st_transform(prices,st_crs(polys))

 ## calculating prices for reserve polygons

 # get average price for each reserve. If a reserve is in the edge of two administrative
 # regions, get the value of the area with most overlap,
polys <- cbind(polys,id=1:nrow(polys))
ints <- st_intersection(polys,prices)

ints$price <- drop_units(ints$"Preco.medio" * st_area(ints)/10000)

polys <- ints %>% 
        group_by(id) %>% 
        summarize(price = sum(price)) %>% 
        select(price)%>%
        st_drop_geometry() %>%
        c() %>%
        cbind(polys,price=.)

## get average price for each corridor
corridors <- cbind(corridors,id=1:nrow(corridors))
ints <- st_intersection(corridors,prices)

# FOR DEBUG:
# mapview(ints,zcol="Preço.médio")

ints$price <- drop_units(ints$"Preco.medio" * st_length(ints)*30/10000)
corridors <- ints %>% 
        group_by(id) %>% 
        summarize(price = sum(price)) %>% 
        select(price)%>%
        st_drop_geometry() %>%
        c() %>%
        cbind(corridors,price=.)

st_write(polys,dsn = outfile,layer="reserves")
st_write(corridors,dsn = outfile,layer="corridors")


}