### Script for importing data into a single dataset
## There are three main types of data:
## The animals from phase 1 passed to me by Bernardo in the form of a single .xlsx
## (Aracatuba, Pora, Sucuri, Nick)
## The data for  some animals from phase 2 (kurupi,Mineiro,Piloto,Zeus).
## The data for another group from phase 2 (Marco,Pepira,Rafiki,Tupa,Zorro).
## These two groups have different formatting.

library(lubridate)
library(openxlsx)


## Processing first format
tables <- read.xlsx("./raw/data 29.06.20/Processed/jaguars phase1.xlsx")
tables$timestamp <- as.POSIXct(tables$timestamp, tz="GMT", format = "%Y/%m/%d %H:%M:%S")
tables <- tables[,c("X", "Y", "hDOP", "name", "timestamp")]


## Processing second format
files2f <- c("Kurupi.csv","Mineiro.csv","Piloto.csv","Zeus.csv")
files2f <- paste0("./raw/data 29.06.20/Processed/",files2f)

tables2 <- vector("list", length(files2f))
for(a in 1:length(files2f)) {
    file <- read.csv(files2f[a])
    file$timestamp <- paste(file$UTC_Date, file$UTC_Time)
    file$timestamp <- as.POSIXct(file$timestamp, tz="GMT", format = "%Y-%m-%d %H:%M:%S")
    tables2[[a]] <- file
}
tables2 <- lapply(tables2,"[",c("Latitude","Longitude","HDOP","timestamp"))
names  <- sub("\\.csv","", basename(files2f))
tables2 <- mapply(cbind,tables2,name=names,SIMPLIFY=F)
tables2 <- do.call(rbind,tables2)
colnames(tables2) <- c("Y","X","hDOP","timestamp","name")
tables2 <- tables2[,c("X","Y","hDOP","name","timestamp")]

## Processing third format
files3f <- c("Marco.csv","Pepira.csv","Rafiki.csv","Tupa.csv","Zorro.csv")
files3f <- paste0("./raw/data 29.06.20/Processed/",files3f)

tables3 <- vector("list", length(files3f))
for(a in 1:length(files3f)) {
    file <- read.csv(files3f[a])
    file$timestamp <- convertToDateTime(file$Date...Time..GMT., tz="GMT")+hours(4)
    tz(file$timestamp) <- "GMT"
    tables3[[a]] <- file
}   
tables3 <- do.call(rbind,tables3)
tables3 <- tables3[,c("Longitude", "Latitude", "DOP", "Device.Name", "timestamp")]
colnames(tables3) <- c("X", "Y", "hDOP", "name", "timestamp")


## Combining all three formats in a single file.
combined.tables <- rbind(tables, tables2, tables3)
write.csv(combined.tables,file="./experiment007/dataderived/Pardas_do_Tiete_todos_individuos.csv")

