InitGeneration <- function(n_file,optim_v=NULL, ini = NULL)
{
  yini.names <- readRDS(n_file)

  y_ini <- rep(0,length(yini.names))
  names(y_ini) <- yini.names
  
  index = sample(1:length(y_ini),size = 1)
  y_ini[index] = 1
  
  return( y_ini )
}

parameterAssegniment = function(optim_v=NULL,index){
  return(optim_v[index+1])
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

# output <- read.csv("HPCmodel_calibration/HPCmodel-calibration-1.trace",sep = "")
# reference <- as.data.frame(t(read.csv("Input/reference.csv", header = FALSE, sep = "")))





