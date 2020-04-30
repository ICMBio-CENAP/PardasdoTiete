
library(openxlsx)
datanew <- read.csv("C:/Users/Jorge/Desktop/Pardas_do_Tiete_todos_individuos.csv",stringsAsFactors=F)
dataold <- read.csv("C:/Users/Jorge/Desktop/movement_data_Pardas_Tiete_all_individuals_2019_06_30.csv")



dataold.rename <- dataold[,c("name","timestamp","Y","X")]
colnames(dataold.rename) <- c("Name","timestamp","Latitude","Longitude")
colnames(datanew) <- c("Name","timestamp","Latitude","Longitude")

#convert data format in old file
timestampform <- strptime(dataold.rename$timestamp, format = "%Y/%m/%d %H:%M:%S",tz="GMT")
dataold.rename$timestamp <- format(timestampform,"%d/%m/%Y %H:%M:%S")

#convert in new file
timestampformnew <- strptime(datanew$timestamp, format = "%m/%d/%Y %H:%M:%S",tz="GMT")
datanew$timestamp <- head(format(timestampformnew,"%d/%m/%Y %H:%M:%S"))

final <- rbind(datanew,dataold.rename)
write.xlsx(final, file="./experiment005/dataderived/Pardas_do_Tiete_todos_individuos.xlsx")
