InitGeneration <- function(n_file,optim_v=NULL, applications)
{
  yini.names <- readRDS(n_file)
  
  y_ini <- rep(0,length(yini.names))
  names(y_ini) <- yini.names
  
  y_ini["QueueRemove_q01"] = 1
  y_ini["QueueAdd_q01"] = 1
  y_ini["Servers"] = 30
  
  if( length(applications) <= length(grep(pattern = "SystemProcesses",x = yini.names)) ){
    for(i in 1:length(applications))
      y_ini[paste0("SystemProcesses_n1_app",i)] = applications[[i]]
      
  }else{
    stop("The number of applications passed for the marking are greater than the number of colors in the App color class.")
  }
  
  
  
  return( y_ini )
}

TimeTable_generation = function(optim_v=NULL, pathReference, indexes ){
  # pathReference = "Input/Reference/plot8Deltas.RDs"
  # indexes = list(State_start_mpi = c(1,2), State_start_other = c(3,4))
  # the first transition must be related to mpi!!!
  
  df = readRDS(pathReference)
  M = data.frame(Time = df[,"Time"])
  # indexes is a list that associates the transitions with a set of indexes for the parameters.
  for(i in names(indexes)){
    M[,paste(i)] = optim_v[ indexes[[i]] ]
  }
  return(M)
}

error<-function(reference, output)
{
  
  colnames(reference) = c("Time", "Cluster", "io_p","iops","mpi_hit","mpi_p","InterTims")
  timedTrace = read.csv("timedPlace.trace",
                        header = FALSE, sep = "\t")
  colnames(timedTrace) = c("Time", "IOQueue_n1_app1_q01", "IOQueue_n1_app1_q11",
                           "IOQueue_n1_app1_q21",
                           "IOQueue_n1_app1_q31",
                           "IOQueue_n1_app1_q41",
                           "SystemProcesses_n1_app1", "StateRunning_n1_app1_mpi2",
                           "StateRunning_n1_app1_other3","IORunning_n1_app1_q01",
                           "IORunning_n1_app1_q11","IORunning_n1_app1_q21",
                           "IORunning_n1_app1_q31", "IORunning_n1_app1_q41" )

  
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
      system_p = SystemProcesses_n1_app1) %>%
    ungroup() %>%
    dplyr::select(Time,io_p,system_p,mpi_p)
  
  
  traceRef = output %>%
    dplyr::select(Time,IOps_n1_app1,Call_Counts_n1_app1_mpi2) %>%
    group_by(Time) %>%
    group_by(Time) %>%
    summarise(IOps = mean(IOps_n1_app1),
              CallMPI = mean(Call_Counts_n1_app1_mpi2)) %>%
    mutate(IOps = IOps-lag(IOps) ,
           CallMPI = CallMPI-lag(CallMPI) )  %>%
    na.omit()
  
  traceRef = merge(traceRef,MeantimedTrace) %>%
    mutate(mpi_p = mpi_p*100,
           io_p = io_p*100,
           system_p = system_p*100 )
  
  err = sapply(1:length(reference$Time), function(t){
    if(t == 1){
      subTrace = traceRef[traceRef$Time <= reference$Time[t], ]
    }else{
      subTrace = traceRef[traceRef$Time > reference$Time[t-1] & traceRef$Time <= reference$Time[t] ,]
    }
    
    mean(
      (subTrace$IOps - reference$iops[t])^2 +
        (subTrace$CallMPI - reference$mpi_hit[t])^2 +
        (subTrace$CallMPI - reference$mpi_hit[t])^2 +
        (subTrace$io_p - reference$io_p[t])^2 +
        (subTrace$mpi_p - reference$mpi_p[t])^2 +
        (subTrace$system_p - 0)^2
    )
    
  })
  
  err = mean(err,na.rm = T)
  
  return(err)
}

# output <- read.csv("queueHPCmodel_calibration/queueHPCmodel-calibration-100.trace",sep = "")
# reference <- as.data.frame(t(read.csv("Input/Reference/plot8Deltas.csv", header = FALSE, sep = "")))

