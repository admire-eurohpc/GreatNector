InitGeneration <- function(n_file,optim_v=NULL, applications)
{
  yini.names <- readRDS(n_file)
  
  y_ini <- rep(0,length(yini.names))
  names(y_ini) <- yini.names
  
  index = sample(1:length(y_ini),size = 1)
  
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
  colnames(reference) = c("GPU" ,"MPI", "OTHER", "IO")
  
  n_sim_tot<-table(output$Time)
  n_sim <- n_sim_tot[1]
  time_delete<-as.numeric(names(n_sim_tot[n_sim_tot!=n_sim_tot[1]]))
  
  if(length(time_delete)!=0) output = output[which(output$Time!=time_delete),]
  
  output$ID <- rep(1:n_sim[1],each = length(unique(output$Time)) )
  
  ### Let's calculate the mean and median time the token stays in the place
  unit.time =  unique(diff(output[output$ID == 1, "Time"]))
  interval.time = 60 * unit.time 
  output$IntervalTime = output$Time %/% interval.time
  # tolgo intervlli di tempi non multipli di quello definito
  n_int_tot<-table(output$IntervalTime)
  time_delete<-as.numeric(names(n_int_tot[n_int_tot!=n_int_tot[1]]))
  if(length(time_delete)!=0) output = output[which(output$IntervalTime!=time_delete),]
  
  output.final <-  sapply(unique(output$ID),function(i){
    out.tmp = output[output$ID == i, ]
    
    SpendingTime = sapply(colnames(out.tmp)[-which( colnames(out.tmp)%in% c("ID","Time","IntervalTime"))],function(c)
    {
      
      MeanUsageTime = sapply(unique(out.tmp$IntervalTime), function(it) 
        sum(out.tmp[out.tmp$IntervalTime == it,c])/interval.time
      )
      
      mean(MeanUsageTime)
      #r = rle(out.tmp[,c])
      #index0 = which(r[[2]] == 1)
      #time = r[[1]][index1]/sum(r[[1]][index1])
      #mean(time)
    })
    
    return(SpendingTime)
  })
  
  MeanTime = apply(output.final,1,mean)
  
  err = sum(abs(MeanTime[names(MeanTime)] - reference[,names(MeanTime)])*10)
  
  return(err)
}

# output <- read.csv("HPCmodel_calibration/HPCmodel-calibration-7206.trace",sep = "")
# reference <- as.data.frame(t(read.csv("Input/ReferenceCl1.csv", header = FALSE, sep = "")))





