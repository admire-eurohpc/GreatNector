
library(dplyr)
library("factoextra")
library(ggplot2)

# files = list.files(path = "./Data/QuantumEspresso/",pattern = "*.csv")
# x = files[5]
# path = "./Data/QuantumEspresso/"

reference.generation = function(x,path){
  traceMatrix <- read.csv(paste0(path,x)) %>% na.omit()
  ProcessingTimes = traceMatrix[, c("io_p","mpi_p","iops","mpi_hit")]
  set.seed(31)
  plotSilh = fviz_nbclust(ProcessingTimes, kmeans, method = "silhouette", k.max = 10) +
    theme_minimal() +
    labs(title = "The Silhouette Plot",subtitle = "QuantumExpresso 8 processes",
         x = "Number of clusters")
  
  #print(plotSilh)
  
  NumCenters = plotSilh$data$clusters[which.max(plotSilh$data$y)]
  ProcessingTimesClustered= kmeans( ProcessingTimes,
                                    centers = NumCenters )
  traceMatrix$Cluster = ProcessingTimes$Cluster = ProcessingTimesClustered$cluster
  
  df = as.data.frame(traceMatrix) %>%
    dplyr::select(X, io_p,mpi_p,iops,mpi_hit,Cluster) %>%
    tidyr::gather(io_p, mpi_p, iops, mpi_hit ,key = "Jobs",value = "Value") %>%
    rename(Time = X) %>%
    group_by(Jobs) %>%
    mutate(Diff = Cluster - lag(Cluster, default = 0))
  
  dfsimple = df %>%
    filter(Diff != 0) %>%
    dplyr::select(-Diff) %>%
    tidyr::spread(key = Jobs, value = Value) %>%
    mutate(InterTims = Time - lag(Time, default = 0), Time = Time -1)
    
  clusters = as.data.frame(ProcessingTimesClustered$centers)
  clusters$Time = 0
  clusters$Cluster = unique(ProcessingTimesClustered$cluster)
  
 # xtable::xtable((clusters %>% dplyr::select(-Time)))
  
  for(cl in dfsimple$Cluster)
    write.table(t(clusters[,colnames(dfsimple[,-7])] %>% filter(Cluster==cl) ),file = paste0("Input/Reference/c",cl,"_",x) ,
                sep = " ",row.names = F,col.names = F) 
  
  
  saveRDS(df,file = paste0("Input/Reference/CompleteTrace",gsub(x,pattern=".csv",replace=""),".RDs"))
  write.table(t(dfsimple),file = paste0("Input/Reference/",x) ,sep = " ",row.names = F,col.names = F) 
  saveRDS(dfsimple,file = paste0("Input/Reference/",gsub(x,pattern=".csv",replace=""),".RDs"))
}


