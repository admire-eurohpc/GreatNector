paramenterCSV.generation = function(csvname, transitions,pathReference){
  
  #### definition of the initial marking:
  file = "i; ini; InitGeneration; n_file=\"/home/docker/data/Input/placeNAMES.RDS\""
  file = paste0( file, "; applications = list(app1 = 3)" )
  
  #### Transitions definition:
  out_pathReference = paste0("pathReference = \"/home/docker/data/",pathReference,"\"")
  
  Ref = readRDS(pathReference)
  numParams = length(Ref$Time)
  
  transitionsNames = readRDS(transitions)
  index_param <<- 1
  x_names <<- ""
  # TRANSITION: IO 
  SubTrans = c("IO_queue","IO_end","IO_start")
  rows = sapply(SubTrans,function(t){
    str = paste0(t, " = c(", paste0((index_param):(index_param+numParams-1), collapse = "," ), ")" ) 
    
    tr = transitionsNames[grep(x = transitionsNames, pattern = paste0(t,"_") )]
    tt = unique(gsub(pattern = "(_q_q[0-9]+)",
                     replacement = "",
                     x = gsub(replacement = "_",
                              tr,
                              pattern = "(_a_)|(_x_)|(_n_)")
                     )
                )
    
    x_names[(index_param):(index_param+numParams-1)] <<- paste0(tt,"_interval",1:numParams)
    index_param <<- index_param + numParams
    
    str = paste0(str, collapse = ", " )
    return(
      paste0("g; ",t,
             "; TimeTable_generation;  indexes = list( ", str, " ); ", out_pathReference)
      #"; ",t,"_TimeTable;  indexes = list( ", str, " ); ", out_pathReference)
    )
  })
  
  # TRANSITION: State
  SubTrans = c("State_start","State_end")
  rows2 = sapply(SubTrans,function(t){
    tr = transitionsNames[grep(x = transitionsNames, pattern = paste0(t,"_") )]
    str = ""
    for( i in 1:length(tr) ){
      str[i] = paste0(tr[i], " = c(", paste0((index_param):(index_param+numParams-1), collapse = "," ), ")" ) 
      tt = gsub(replacement = "_",tr[i],pattern = "(_a_)|(_x_)|(_n_)")
      x_names[(index_param):(index_param+numParams-1)] <<- paste0(tt,"_interval",1:numParams)
      index_param <<- index_param + numParams
    }
    
    str = paste0(str, collapse = ", " )
    
    return(
      paste0("g; ",t,
             "; TimeTable_generation;  indexes = list( ", str, " ); ", out_pathReference)
      #"; ",t,"_TimeTable;  indexes = list( ", str, " ); ", out_pathReference)
    )
    
  })
  
  final = c(file,rows,rows2)
  
  saveRDS(x_names,file = "Input/paramsNAMES.RDs")
  
  write.table(final,file = paste0("Input/",csvname),
              quote = F,row.names = F,col.names = F)
  
}

# 
# paramenterCSV.generation(csvname = "parametersList.csv",
#                          pathReference = "Input/Reference/dfProva.RDs",
#                          transitions = "Input/transitionsNAMES.RDS")
