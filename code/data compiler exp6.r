### Script for importing data into a single dataset

library(sf)
library(lubridate)
library(openxlsx)


getdatafromdesc <- function(kml,col) {
    kml %>% .$Description %>% as.character %>% strsplit("<br>") %>% sapply("[[",col)

}

kmlfolder <- "./experiment006/dataderived/kml"
kmls <- lapply(list.files(kmlfolder,full.names=T),st_read)
kmls <- do.call(rbind,kmls)

date <- getdatafromdesc(kmls,4) %>% sub(".*: ","",.) %>% mdy_hms
Name <- getdatafromdesc(kmls,1) %>% sub(".*: ","",.)

newdata <-data.frame(Name,date,st_coordinates(kmls)[,2:1])
colnames(newdata) <- c("Name","timestamp","Latitude","Longitude")


oldata <- read.xlsx("./experiment006/dataderived/Pardas_do_Tiete_old.xlsx")
oldata$timestamp <- dmy_hms(oldata$timestamp)

alldata<-rbind(oldata,newdata)
alldata<-alldata[!duplicated(alldata),]
write.xlsx(alldata,file="./experiment006/dataderived/Pardas_do_Tiete_todos_individuos.xlsx")
