InitGeneration <- function(n_file,optim_v=NULL, applications)
{
  yini.names <- readRDS(n_file)
  
  y_ini <- rep(0,length(yini.names))
  names(y_ini) <- yini.names
  
  index = sample(1:length(y_ini),size = 1)
  
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
  # pathReference = "Input/Reference/dfProva.RDs"
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
  
  n_sim_tot<-table(output$Time)
  n_sim <- n_sim_tot[1]
  time_delete<-as.numeric(names(n_sim_tot[n_sim_tot!=n_sim_tot[1]]))
  
  if(length(time_delete)!=0) output = output[which(output$Time!=time_delete),]
  
  output$ID <- rep(1:n_sim[1],each = length(unique(output$Time)) )
  
  ### Let's calculate the mean and median time the token stays in the place
  unit.time =  unique(diff(output[output$ID == 1, "Time"]))
  interval.time = 100 * unit.time 
  output$IntervalTime = output$Time %/% interval.time
  
  # tolgo intervalli di tempi non multipli di quello definito
  n_int_tot<-table(output$IntervalTime)
  time_delete<-as.numeric(names(n_int_tot[n_int_tot!=n_int_tot[1]]))
  if(length(time_delete)!=0) output = output[which(output$IntervalTime!=time_delete),]
  
  processes = output[1,"SystemProcesses_n1_app1"]
  
  IORunning = grep("IORunning",colnames(output),value = T)
  output$IORunning = rowSums(output[,IORunning])
  trace=output[,c("ID","Time","IntervalTime",
                  "StateRunning_n1_app1_mpi2","StateRunning_n1_app1_other3",
                  "IOps_n1_app1","Call_Counts_n1_app1_mpi2",
                  "IORunning")]
  
  traceRef = data.frame(
    t(
      sapply(unique(trace$IntervalTime),function(i){
        
        trace.tmp = trace[trace$IntervalTime == i,-which(colnames(trace) %in% c("Time","IntervalTime","IOps_n1_app1","Call_Counts_n1_app1_mpi2"))]
        
        trace.tmp = do.call("rbind",
                            lapply(unique(trace.tmp$ID),function(ii){
                              trace.tmp2 = trace.tmp[trace.tmp$ID == ii, -which(colnames(trace.tmp) == "ID")]
                              trace.tmp2[trace.tmp2 != 0] = 1
                              apply(trace.tmp2,2,sum)/length(trace.tmp2[,1])*100
                            })
        )
        
        trace.tmp = apply(trace.tmp,2,mean)
        trace.tmp["Time"] = i
        return(trace.tmp)
      })
    )
  )
  
  traceCall = do.call( "rbind", 
                       lapply(unique(trace$IntervalTime),function(i){
                         trace.tmp = trace[trace$IntervalTime == i,which(colnames(trace) %in% c("ID","Call_Counts_n1_app1_mpi2","IOps_n1_app1"))]
                         
                         trace.tmp = do.call("rbind",
                                             lapply(unique(trace.tmp$ID),function(ii){
                                               trace.tmp2 = trace.tmp[trace.tmp$ID == ii, -which(colnames(trace.tmp) == "ID")]
                                               trace.tmp2[length(trace.tmp2[,1]),]
                                             })
                         )
                         
                         trace.tmp = apply(trace.tmp,2,mean)
                         return(trace.tmp)
                       })
  )
  
  traceRef$IOps =  c( traceCall[1,"IOps_n1_app1"] , diff(unlist(traceCall[,"IOps_n1_app1"]) ))
  traceRef$CallMPI =  c( traceCall[1,"Call_Counts_n1_app1_mpi2"] , diff(unlist(traceCall[,"Call_Counts_n1_app1_mpi2"]) ))
  
  err = sapply(1:length(reference$Time), function(t){
    if(t == 1){
      subTrace = traceRef[traceRef$Time <= reference$Time[t], ]
    }else{
      subTrace = traceRef[traceRef$Time > reference$Time[t-1] & traceRef$Time <= reference$Time[t] ,]
    }
    
    mean(
      (subTrace$IOps - reference$iops[t])^2 +
        (subTrace$CallMPI - reference$mpi_hit[t])^2 +
        (subTrace$StateRunning_n1_app1_mpi2 - reference$mpi_p[t])^2 + 
        (subTrace$IORunning - reference$io_p[t])^2
    )
    
  })
  
  err = mean(err,na.rm = T)
  
  return(err)
}
# output <- read.csv("queueHPCmodel_calibration/queueHPCmodel-calibration-100.trace",sep = "")
# reference <- as.data.frame(t(read.csv("Input/Reference/plot8Deltas.csv", header = FALSE, sep = "")))





