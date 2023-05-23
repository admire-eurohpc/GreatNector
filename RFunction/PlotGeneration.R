library(ggplot2)
library(ggthemes)
library(dplyr)
library(readr)

#tracefile = "queueHPCmodel_calibration/queueHPCmodel-calibration-1.trace"
#timestrace = "queueHPCmodel_calibration/timedPlace-1.trace"
#referencefile = "Input/Reference/CompleteTraceplot8Deltas.RDs"

ModelAnalysisPlot <-function(tracefile,timestrace,referencefile,Namefile = ""){
  output <- read.csv(tracefile, sep = "")
  
  timedTrace = read.csv(timestrace,
                        header = FALSE, sep = "\t")
  
  reference <- readRDS(referencefile)
  #reference$Time = reference$Time+1
  
  colnames(timedTrace) = c("Time",
                           "IOQueue_n1_app1_q01", "IOQueue_n1_app1_q11",
                           "IOQueue_n1_app1_q21", "IOQueue_n1_app1_q31",
                           "IOQueue_n1_app1_q41",
                           "SystemProcesses_n1_app1",
                           "StateRunning_n1_app1_mpi2",
                           "StateRunning_n1_app1_other3",
                           "IORunning_n1_app1_q01",
                           "IORunning_n1_app1_q11","IORunning_n1_app1_q21",
                           "IORunning_n1_app1_q31", "IORunning_n1_app1_q41" )
  
  
  n_sim_tot<-table(output$Time)
  time_delete<-as.numeric(names(n_sim_tot[n_sim_tot!=n_sim_tot[1]]))
  if(length(time_delete)!=0) output = output[which(output$Time!=time_delete),]
  output$ID = rep(1:n_sim_tot[1],each = length(unique(output$Time)) )
  
  timedTraceInfo = timedTrace %>%
    mutate(
      io_p = IOQueue_n1_app1_q11+IOQueue_n1_app1_q21+
        IOQueue_n1_app1_q31+IOQueue_n1_app1_q01+
        IOQueue_n1_app1_q41+
        IORunning_n1_app1_q01+
        IORunning_n1_app1_q11+IORunning_n1_app1_q21+
        IORunning_n1_app1_q31+IORunning_n1_app1_q41,
      mpi_p = StateRunning_n1_app1_mpi2,
      system_p = SystemProcesses_n1_app1,
      other_p = StateRunning_n1_app1_other3) %>%
    dplyr::select(Time,io_p,system_p,mpi_p,other_p) %>%
    dplyr::mutate(mpi_p = mpi_p*100,
                  io_p = io_p*100,
                  system_p=system_p*100,
                  other_p =other_p*100) %>%
    tidyr::gather(-Time, value = "Measure", key =  "Jobs") %>%
    group_by( Time, Jobs ) %>%
    summarise(Mean = mean(Measure),
              q1 = min(Measure),#quantile(Measure,probs = 0.25),
              q3 = max(Measure),#quantile(Measure,probs = 0.75)
    ) %>%
    ungroup() %>%
    tidyr::gather(-Time,-Jobs, value = "Measure", key =  "Statistics")
  
  traceRef = output %>%
    dplyr::select(ID,Time, IOps_n1_app1, Call_Counts_n1_app1_mpi2) %>%
    group_by(ID) %>%
    rename(iops = IOps_n1_app1,
           mpi_hit = Call_Counts_n1_app1_mpi2) %>%
    mutate(iops = iops-lag(iops) ,
           mpi_hit = mpi_hit-lag(mpi_hit) ) %>%
    na.omit() %>%
    tidyr::gather(-Time,-ID, value = "Measure", key =  "Jobs") %>%
    ungroup()%>%
    dplyr::select(-ID) %>%
    group_by( Time, Jobs ) %>%
    summarise(Mean = mean(Measure),
              q1 = min(Measure),#quantile(Measure,probs = 0.25),
              q3 = max(Measure),#quantile(Measure,probs = 0.75)
    ) %>%
    ungroup()%>%
    tidyr::gather(-Time,-Jobs, value = "Measure", key =  "Statistics")
  
  traceRef2 = rbind(traceRef,timedTraceInfo) %>% tidyr::spread(value = "Measure", key =  "Statistics")
  #dplyr::select(Time, io_p, mpi_p, iops, mpi_hit,system_p,other_p) %>%
  #tidyr::gather(-Time,-Statistics, value = "Measure", key =  "Jobs") %>%
  #
  
  reference = reference %>%
    dplyr::select(-Diff) %>%
    rename(RefValue = Value)
  
  pl = ggplot()+
    geom_line(data = reference,aes(x = Time, y = RefValue), col = "black")+
    # geom_point(data = traceRef2,aes(x = Time, y = Measure, col = Jobs))+
    geom_line(data = traceRef2,aes(x = Time, y = Mean, col = Jobs))+
    geom_ribbon(data = traceRef2,aes(x = Time, ymin = q1, ymax = q3, fill = Jobs),alpha = 0.9)+
    facet_wrap(~Jobs,scales = "free",ncol = 2)+
    theme_bw()+
    xlim(c(0,max(traceRef2$Time+1)))
  
  
  if(Namefile != "")
    ggsave(plot = pl,filename = Namefile,
           path = "./Plots/",
           device = "pdf",width = 10,height = 15)
  
  return(pl)
}
