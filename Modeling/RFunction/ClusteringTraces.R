library(readr)
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)

Trace <- read_csv("Data/Trace", col_names = FALSE)

traceMatrix = as.data.frame(do.call("rbind",lapply(2:(dim(Trace)[1]-1), function(i){
  a = gsub(Trace[i,],pattern = "(\")|(\\{)|(\\})",replacement = "")
  a = gsub(a,pattern = " v:",replacement = "")
  a = gsub(a,pattern = ",$",replacement = "")
  a =str_split(str_split(a,pattern = ", ",simplify = T),pattern = ": ")
  Values = matrix(as.numeric(sapply(a,"[[",2)),nrow = 1)
  colnames(Values) = sapply(a,"[[",1)
  return(Values)
})))

#####

traceMatrix = traceMatrix  %>%
  dplyr::mutate(
    InterTempi = c(traceMatrix$ti[1],diff(ti)),
    io = io + io_read + io_write 
    ) %>%
  select(-io_read,-io_write)


hist(traceMatrix$InterTempi)
summary(traceMatrix$InterTempi)

# Potrebbe essere necessario riscalare nel tempo per avere gli stessi intervalli temporali? In quanto 
# il campionamento viene fatto non regolarmanente, quindi le percentuali dei processi 
# dovrebbero essere ripesate? Forse no in quanto a noi interessa la media 
# ( quindi e' come se avessi 10 barre simili)

ProcessingTimes = traceMatrix[ , c("io","gpu","other","mpi")]

library("factoextra")
library(ggplot2)
set.seed(31)
# function to compute total within-cluster sum of squares
fviz_nbclust(ProcessingTimes, kmeans, method = "wss", k.max = 8) + 
  theme_minimal() + 
  ggtitle("the Elbow Method")

fviz_nbclust(ProcessingTimes, kmeans, method = "silhouette", k.max = 8) +
  theme_minimal() + 
  ggtitle("The Silhouette Plot")

ProcessingTimesClustered = kmeans(ProcessingTimes,centers = 2)
                    
ProcessingTimes$Cluster = traceMatrix$Cluster = ProcessingTimesClustered$cluster


ggplot(ProcessingTimes %>% tidyr::gather(-Cluster,value = "V",key="Jobs")) +
  geom_boxplot(aes(y = V,fill = as.factor(Cluster)) ) +
  theme_bw()+
  facet_wrap(~Jobs)


df = as.data.frame(traceMatrix) %>%
  select(-InterTempi) %>%
  gather(-ti,-Cluster,key = "Jobs",value = "Value") %>%
  rename(Time = ti)

ggplot(df) +
  geom_bar(aes(x = Time,y = Value,fill = Jobs),stat = "identity") +
  theme_bw() +
  facet_wrap(~Cluster)

ggplot(df %>% filter(Cluster == 1)) +
  geom_bar(aes(x = Time,y = Value,fill = Jobs),stat = "identity") +
  theme_bw() +
  facet_wrap(~Cluster)

ggplot(df%>% filter(Cluster == 2)) +
  geom_bar(aes(x = Time,y = Value,fill = Jobs),stat = "identity") +
  theme_bw() +
  facet_wrap(~Cluster)

ClProcTime = ProcessingTimes %>%
  tidyr::gather(-Cluster,value = "V",key="Jobs") %>%
  group_by(Cluster,Jobs) %>%
  dplyr::summarize(Mean = mean(V)) %>% 
  tidyr::spread(key = Jobs, value = Mean) %>% 
  ungroup()

for( cl in unique(ClProcTime$Cluster)){
  c = ClProcTime %>% 
    filter(Cluster == cl) %>%
    select(gpu,mpi,other,io) 
  write.table(t(c),
            file = paste0("Input/ReferenceCl",cl,".csv"),
            quote = F, row.names = F, col.names = F)
}

                                                                                                    