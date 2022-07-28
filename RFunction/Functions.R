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
  reference[1,] -> times_ref
  reference[3,] -> infect_ref
  
  # We will consider the same time points
  Infect <- output[which(output$Time %in% times_ref),"I"]
  infect_ref <- infect_ref[which( times_ref %in% output$Time)]
  
  diff.Infect <- 1/length(times_ref)*sum(( Infect - infect_ref )^2 )
  
  return(diff.Infect)
}