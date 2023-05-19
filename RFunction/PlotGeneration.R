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
  
  reference <- reference <- readRDS(referencefile)
  
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
  
  MeantimedTrace = timedTrace %>%
    group_by(Time) %>%
    summarise(across(colnames(timedTrace[,-1]), mean)) %>%
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
    ungroup() %>%
    dplyr::select(Time,io_p,system_p,mpi_p,other_p)
  
  traceRef = output %>%
    dplyr::select(Time,IOps_n1_app1,Call_Counts_n1_app1_mpi2) %>%
    group_by(Time) %>%
    group_by(Time) %>%
    summarise(IOps = mean(IOps_n1_app1),
              CallMPI = mean(Call_Counts_n1_app1_mpi2)) %>%
    mutate(IOps = IOps-lag(IOps) ,
           CallMPI = CallMPI-lag(CallMPI) ) %>%
    na.omit()
  
  traceRef2 = merge(traceRef,MeantimedTrace)%>%
    rename( iops = IOps, mpi_hit = CallMPI ) %>%
    mutate(mpi_p = mpi_p*100,
           io_p = io_p*100,
           system_p=system_p*100,
           other_p =other_p*100) %>%
    dplyr::select(Time, io_p, mpi_p, iops, mpi_hit,system_p,other_p) %>%
    tidyr::gather(-Time, value = "Measure", key =  "Jobs")
  
  reference = reference %>%
    dplyr::select(-Diff) %>%
    rename(RefValue = Value)
  
  pl = ggplot()+
    geom_line(data = reference,aes(x = Time, y = RefValue), col = "black")+
    geom_line(data = traceRef2,aes(x = Time, y = Measure, col = Jobs))+
    facet_wrap(~Jobs,scales = "free",ncol = 2)+
    theme_bw()

  
  if(Namefile != "")
    ggsave(plot = pl,filename = Namefile,
           path = "./Plots/",
           device = "pdf",width = 10,height = 15)
  
  return(pl)
}
