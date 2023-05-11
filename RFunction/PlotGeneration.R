library(cowplot)
library(ggplot2)
library(ggthemes)
library(dplyr)

#tracefile = "queueHPCmodel_analysis/queueHPCmodel-analysis-1.trace"
#referencefile = "Input/Reference/CompleteTraceplot8Deltas.RDs"

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
    # referencefile = "~/Model_ADMIREproj/Input/Reference/CompleteTraceplot36Deltas.RDs"
    reference <- readRDS(referencefile)
  }
  
  ### Let's calculate the mean and median time the token stays in the place
  unit.time =  unique(diff(trace[trace$ID == 1, "Time"]))
  interval.time = 100 * unit.time 
  trace$IntervalTime = trace$Time %/% interval.time
  
  # tolgo intervalli di tempi non multipli di quello definito
  n_int_tot<-table(trace$IntervalTime)
  time_delete<-as.numeric(names(n_int_tot[n_int_tot!=n_int_tot[1]]))
  if(length(time_delete)!=0) trace = trace[which(trace$IntervalTime!=time_delete),]
  
  processes = trace[1,"SystemProcesses_n1_app1"]
  
  IORunning = grep("IORunning",colnames(trace),value = T)
  trace$IORunning = rowSums(trace[,IORunning])
  trace=trace[,c("ID","Time","IntervalTime",
                 "StateRunning_n1_app1_mpi2","StateRunning_n1_app1_other3",
                 "IOps_n1_app1","Call_Counts_n1_app1_mpi2",
                 "IORunning")]
  
  traceRef = do.call(rbind,
                     lapply(unique(trace$IntervalTime),function(i){
                       
                       trace.tmp = trace[trace$IntervalTime == i,-which(colnames(trace) %in% c("Time","IntervalTime","IOps_n1_app1","Call_Counts_n1_app1_mpi2"))]
                       
                       trace.tmp = do.call("rbind",
                                           lapply(unique(trace.tmp$ID),function(ii){
                                             trace.tmp2 = trace.tmp[trace.tmp$ID == ii,-which(colnames(trace.tmp) == "ID") ]
                                             trace.tmp2[trace.tmp2 != 0] = 1
                                             trace.tmp2 = data.frame( t(apply(trace.tmp2,2,sum)/length(trace.tmp2[,1])*100) )
                                             trace.tmp2$ID = ii
                                             trace.tmp2
                                           })
                       )
                       
                       trace.mean = data.frame(t(apply(trace.tmp[,-which(colnames(trace.tmp) == "ID")],2,mean)))
                       trace.mean$ID = 0
                       trace.tmp$Type = "Trace"
                       trace.mean$Type = "Mean"
                       trace.tmp = rbind(trace.tmp,trace.mean[,colnames(trace.tmp)])
                       
                       trace.tmp[,"Time"] = i
                       return(trace.tmp)
                     })
  )
  
  traceCall = do.call( "rbind", 
                       lapply(unique(trace$IntervalTime),function(i){
                         trace.tmp = trace[trace$IntervalTime == i,which(colnames(trace) %in% c("ID","Call_Counts_n1_app1_mpi2","IOps_n1_app1"))]
                         
                         trace.tmp = do.call("rbind",
                                             lapply(unique(trace.tmp$ID),function(ii){
                                               trace.tmp2 = trace.tmp[trace.tmp$ID == ii, ]
                                               trace.tmp2[length(trace.tmp2[,1]),]
                                             })
                         )
                         trace.mean = data.frame(t(apply(trace.tmp[,-which(colnames(trace.tmp) == "ID")],2,mean)))
                         trace.mean$ID = 0
                         trace.tmp$Type = "Trace"
                         trace.mean$Type = "Mean"
                         trace.tmp = rbind(trace.tmp,trace.mean[,colnames(trace.tmp)])
                         trace.tmp[,"Time"] = i
                         return(trace.tmp)
                       })
  )
  
  traceCall =  traceCall %>% 
    group_by(ID) %>% 
    mutate(IOps = IOps_n1_app1 - lag(IOps_n1_app1,default = 0),
           CallMPI = Call_Counts_n1_app1_mpi2 -lag(Call_Counts_n1_app1_mpi2,default = 0) )
  
  traceRef2 = merge(traceRef,traceCall)
  
  traceRef2 = traceRef2 %>%
    rename(io_p = IORunning, mpi_p = StateRunning_n1_app1_mpi2, iops = IOps, mpi_hit = CallMPI,
           other_p = StateRunning_n1_app1_other3  ) %>%
    dplyr::select(Time, Type, ID, io_p, mpi_p, iops, mpi_hit,other_p) %>%
    tidyr::gather(-Time, -Type, -ID, value = "Measure", key =  "Jobs")
  
  reference = reference %>% dplyr::select(-Diff) %>% rename(RefValue = Value)
  
  pl = ggplot()+
    geom_line(data = traceRef2 %>% filter(Type == "Mean"),aes(x = Time, y = Measure, col = Jobs))+
    geom_line(data = traceRef2 %>% filter(Type != "Mean"),aes(x = Time, y = Measure),col = "grey",alpha = .3)+
    geom_line(data = reference,aes(x = Time, y = RefValue), col = "black")+
    facet_wrap(~Jobs,scales = "free",ncol = 2)+
    theme_bw()
  
  if(Namefile != "")
    ggsave(plot = pl,filename = Namefile,
           path = "./Plots/",
           device = "pdf",width = 10,height = 15)
  
  return(pl)
}
