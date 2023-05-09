
library(dplyr)
library("factoextra")
library(ggplot2)

reference.generation = function(x,path){
  traceMatrix <- read.csv(paste0(path,x)) %>% na.omit()
  ProcessingTimes = traceMatrix[, c("io_p","mpi_p","iops","mpi_hit")]
  set.seed(31)
  plotSilh = fviz_nbclust(ProcessingTimes, kmeans, method = "silhouette", k.max = 10) +
    theme_minimal() +
    ggtitle("The Silhouette Plot")
  
  print(plotSilh)
  
  NumCenters = plotSilh$data$clusters[which.max(plotSilh$data$y)]
  ProcessingTimesClustered= kmeans( ProcessingTimes,
                                    centers = NumCenters )
  traceMatrix$Cluster = ProcessingTimes$Cluster = ProcessingTimesClustered$cluster
  
  print(
    ggplot(
      ProcessingTimes %>%
        tidyr::gather(-Cluster,value = "V",key="Jobs")
    ) +
      geom_boxplot(aes( y = V, fill = as.factor(Cluster) ) ) +
      theme_bw()+
      facet_wrap( ~Jobs, scales = "free" )
  )
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
    mutate(InterTims = Time - lag(Time, default = 0))
  
  write.table(t(dfsimple),file = paste0("Input/Reference/",x) ,sep = " ",row.names = F,col.names = F) 
  saveRDS(dfsimple,file = paste0("Input/Reference/",gsub(x,pattern=".csv",replace=""),".RDs"))
}

#files = list.files(path = "~/Desktop/GIT/Modelli_GreatMod/HPCmodel/SystemPointView/Data/QuantumEspresso/",pattern = "*.csv")
#x = files[1]
