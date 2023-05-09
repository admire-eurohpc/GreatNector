library(cowplot)
library(ggplot2)
library(ggthemes)
library(dplyr)

tracefile = "queueHPCmodel_analysis/queueHPCmodel-analysis-1.trace"

ModelAnalysisPlot <-function(tracefile,referencefile = NULL,Namefile = ""){
  # PlaceNotToPlot = c()
  PlaceNotToPlot = c( )
  
  trace=read.csv(tracefile, sep = "")
  n_sim_tot<-table(trace$Time)
  time_delete<-as.numeric(names(n_sim_tot[n_sim_tot!=n_sim_tot[1]]))
  if(length(time_delete)!=0) trace = trace[which(trace$Time!=time_delete),]
  
  trace$ID <- rep(1:n_sim_tot[[1]], each = length(unique(trace$Time)) )
  
  # Reference!!!!
  if(!is.null(referencefile)){
    library(readr)
    
    reference <- as.data.frame(t(read.csv(referencefile, header = FALSE, sep = "")))
    colnames(reference) = c("Time", "Cluster", "io_p","iops","mpi_hit","mpi_p","InterTims")
    
    reference = reference %>% tidyr::gather(key = "Jobs", value = "Value")
  }
  # 
  ###
  ### Let's calculate the mean and median time the token stays in the place
  
  #unit.time =  unique(diff(trace[trace$ID == 1, "Time"]))
  #interval.time = unit.time * 5
  
  output.final.all <-  trace %>% 
    tidyr::gather(-Time,-ID,key = "Jobs", value = "Value")
  
  output.final.notio <-  output.final.all  %>%
    filter(!grepl(x = Jobs,"P1|Queue"))%>%
    group_by(Time,ID,Jobs)%>%
    summarise(SumValue = sum(Value))%>%
    ungroup()
  
  unique(output.final.notio$Jobs)
  
  output.final.io = output.final.all %>%
    filter(grepl(x = Jobs,"P1|(IOQueue)")) %>%
    mutate(Jobs = gsub(replacement = "", x = Jobs,pattern = "_q[0-9]+")) %>%
    group_by(Time,ID,Jobs)%>%
    summarise(SumValue = sum(Value))%>%
    ungroup()
  
  unique(output.final.io$Jobs)

  output.final.all = rbind(output.final.notio,output.final.io)
  
  
  pl = ggplot(output.final.all) +
    geom_line(aes(x = Time,y = SumValue, group = ID,col = ID),alpha = 0.4)+
    #geom_bar(data = reference, aes(x = "Reference", y = Value,fill = Jobs),col = "red",stat = "identity")+
    theme(axis.text=element_text(size=10),
          axis.title=element_text(size=14,face="bold"),
          legend.text=element_text(size=10),
          legend.title=element_text(size=14,face="bold"),
          legend.position="none",
          legend.key.size = unit(1.3, "cm"),
          legend.key.width = unit(1.3,"cm") )+
    labs(x="Time", y="Total number of tokenks")+
    geom_line(data = output.final.all %>% group_by(Time,Jobs) %>%
                summarise(MeanV = mean(SumValue)),
              aes(x = Time,y = MeanV))+
    facet_wrap(~Jobs)
  
  return(pl)
  
  # output.final.all <-  trace %>% 
  #   tidyr::gather(-Time,-ID,key = "Jobs", value = "Value") %>%
  #   group_by(ID, Jobs) %>%
  #   #dplyr::mutate(TimeInterval = Time %/% interval.time) %>%
  #   ungroup() %>%
  #   #filter(TimeInterval != max(TimeInterval) ) %>%
  #   group_by(ID, Jobs, TimeInterval) %>%
  #   dplyr::summarise(IoRunningTime = sum(Value)/interval.time) %>%
  #   ungroup()
# 
#   output.final.all %>% 
#     group_by(ID,TimeInterval) %>%
#     dplyr::summarise(sum = sum(MeanUsageTime)) %>%
#     ungroup() %>%
#     select(sum) %>%
#     distinct()
#   
#   output.final = output.final.all %>%
#     group_by(Jobs, TimeInterval) %>%
#     dplyr::summarise(MeanTime = mean(MeanUsageTime)) %>%
#     ungroup()
#   
#   output.final %>% 
#     group_by(TimeInterval) %>%
#     dplyr::summarise(sum = sum(MeanTime)) %>%
#     ungroup() %>%
#     select(sum) %>%
#     distinct()
#   
#   pl = ggplot(output.final) +
#     geom_bar(aes(x = TimeInterval,y = MeanTime,fill = Jobs),stat = "identity")+
#     #geom_bar(data = reference, aes(x = "Reference", y = Value,fill = Jobs),col = "red",stat = "identity")+
#     theme(axis.text=element_text(size=10),
#           axis.title=element_text(size=14,face="bold"),
#           legend.text=element_text(size=10),
#           legend.title=element_text(size=14,face="bold"),
#           legend.position="right",
#           legend.key.size = unit(1.3, "cm"),
#           legend.key.width = unit(1.3,"cm") )+
#     labs(x="", y="")
#   
#   ggsave(pl,filename = paste0(Namefile,"_BarTraceSimulated.png"),
#          device = "png",path = "Plots",width = 10,height = 6)
#   
#   pl = ggplot(output.final.all) + 
#     geom_boxplot(aes(x =TimeInterval, group = TimeInterval,y = MeanUsageTime),col = "grey", alpha = .3) +
#     geom_line(data = output.final, 
#               aes(x = TimeInterval,y = MeanTime, col = Jobs,linetype = "Mean"), alpha = .9) +
#     geom_hline(data = reference, aes(yintercept = Value,col = Jobs,linetype = "Reference"),size = 1)+
#     facet_wrap(~Jobs) +
#     theme_bw()
#   
#   pl
#   
#   ggsave(pl,filename = paste0(Namefile,"_LinesTraceSimulated.png"),device = "png",path = "Plots",width = 10,height = 6)
#   
#   
#   return(pl)
}
