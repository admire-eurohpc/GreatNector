library(readr)
name.generation = function(path,out)
{
  Names <- read_table2(path)
  transStart<- which(Names[,1] == "#TRANSITION")
  # places name
  NAMES = unlist(Names[1:(transStart-1),1])
  NAMES = unname(NAMES)
  # transitions name
  trNAMES = Names[(which(Names$`#PLACE` == "#TRANSITION")+1):length(Names$`#PLACE`),1]
  trNAMES = unlist(trNAMES)
  trNAMES = unname(trNAMES)
  # save names
  saveRDS(NAMES,file=paste0(out,"placeNAMES.RDS"))
  saveRDS(trNAMES,file=paste0(out,"transitionsNAMES.RDS"))
  
  ##################################################
  # 
  # library(readxl)
  # Data <- read_excel("input/Data.xlsx", na = "NA")
  # saveRDS(Data,file="./input/Data.RDS")
  # ############################
  # 
  # reference <- Data[,c("Place name","final perc")]
  # NA.pos <- which(is.na(reference[,2]))
  # reference<-as.data.frame(reference[-NA.pos,])
  # 
  # reference$`Place name`<- which(NAMES%in%reference$`Place name` )
  # write.table(t(reference),"./input/reference.csv",row.names = F, col.names= F, sep =" ")
  
}

# name.generation(path = "Net/queueHPCmodel.PlaceTransition",out = "Input/")
