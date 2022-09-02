library(cowplot)
library(ggplot2)
library(ggthemes)
library(dplyr)

ModelAnalysisPlot <-function(tracefile){
  # PlaceNotToPlot = c()
  PlaceNotToPlot = c( )
  
  trace=read.csv(tracefile, sep = "")
  n_sim_tot<-table(trace$Time)
  time_delete<-as.numeric(names(n_sim_tot[n_sim_tot!=n_sim_tot[1]]))
  if(length(time_delete)!=0) trace = trace[which(trace$Time!=time_delete),]
  
  trace$ID <- rep(1:n_sim_tot[[1]], each = length(unique(trace$Time)) )
  
  # Reference!!!!
  library(readr)
  
  reference <- as.data.frame(t(read.csv("Input/reference.csv", header = FALSE, sep = "")))
  colnames(reference) = c("GPU" ,"MPI", "OTHER", "IO")
  
  reference = reference %>% tidyr::gather(key = "Jobs", value = "Value")
  
  ###
  ### Let's calculate the mean and median time the token stays in the place
  
  unit.time =  unique(diff(trace[trace$ID == 1, "Time"]))
  interval.time = unit.time * 60
  
  output.final.all <-  trace %>% 
    tidyr::gather(-Time,-ID,key = "Jobs", value = "Value") %>%
    group_by(ID, Jobs) %>%
    dplyr::mutate(TimeInterval = Time %/% interval.time) %>%
    ungroup() %>%
    filter(TimeInterval != max(TimeInterval) ) %>%
    group_by(ID, Jobs, TimeInterval) %>%
    dplyr::summarise(MeanUsageTime = sum(Value)/interval.time) %>%
    ungroup()

  output.final.all %>% 
    group_by(ID,TimeInterval) %>%
    dplyr::summarise(sum = sum(MeanUsageTime)) %>%
    ungroup() %>%
    select(sum) %>%
    distinct()
  
  output.final = output.final.all %>%
    group_by(Jobs, TimeInterval) %>%
    dplyr::summarise(MeanTime = mean(MeanUsageTime)) %>%
    ungroup()
  
  output.final %>% 
    group_by(TimeInterval) %>%
    dplyr::summarise(sum = sum(MeanTime)) %>%
    ungroup() %>%
    select(sum) %>%
    distinct()
  
  pl = ggplot(output.final) +
    geom_bar(aes(x = factor(TimeInterval),y = MeanTime,fill = Jobs),stat = "identity")+
    geom_bar(data = reference, aes(x = "Reference", y = Value,fill = Jobs),col = "red",stat = "identity")+
    theme(axis.text=element_text(size=10),
          axis.title=element_text(size=14,face="bold"),
          legend.text=element_text(size=10),
          legend.title=element_text(size=14,face="bold"),
          legend.position="right",
          legend.key.size = unit(1.3, "cm"),
          legend.key.width = unit(1.3,"cm") )+
    labs(x="", y="")
  
  ggsave(pl,filename = "BarTraceSimulated.pdf",device = "pdf",path = "Plots",width = 10,height = 6)
  
  pl = ggplot(output.final.all) + 
    geom_line(aes(x = TimeInterval,y = MeanUsageTime,group = ID),col = "grey", alpha = .3) +
    geom_line(data = output.final, 
              aes(x = TimeInterval,y = MeanTime, col = Jobs,linetype = "Mean"), alpha = .9) +
    geom_hline(data = reference, aes(yintercept = Value,col = Jobs,linetype = "Reference"),size = 1)+
    facet_wrap(~Jobs) +
    theme_bw()
  
  pl
  
  ggsave(pl,filename = "LinesTraceSimulated.pdf",device = "pdf",path = "Plots",width = 10,height = 6)
  
  
  return(pl)
}
