args <- commandArgs(TRUE)
cat(args)
interval <- args[1]

library(dplyr)
library(epimod)

intervalDir = paste0("Calibration/Interval_",interval,"/")
if(!dir.exists(intervalDir)){
  system(paste0("mkdir ", intervalDir) )
}


system(paste0("cp Input ",intervalDir,"/ -r"))
#system(paste0("cp RFunction Calibration/Interval_",interval,"/ -r"))

setwd(intervalDir)

### Uknown parameter definition ###
ref <- read.csv("~/Model_ADMIREproj/Data/QuantumEspresso/plot8Deltas.csv") %>% 
  na.omit()
maxTime = max(ref[,"X"])

paramsName = readRDS("~/Model_ADMIREproj/Input/paramsNAMES.RDs")
params = rep(0.0,length(paramsName) )
names(params) = paramsName

params["IO_queue_app1_n1_c1"] = 15658.29         
params["IO_end_app1_n1_c1"] = 15133856           
params["IO_start_app1_n1_c1"] = 33408435          
params["State_start_app1_n1_mpi2_c1"] = 24023.35  
params["State_start_app1_n1_other3_c1"] = 32419.64
params["State_end_app1_n1_mpi2_c1"] = 69772.35    
params["State_end_app1_n1_other3_c1"] = 9123.807

params["IO_queue_app1_n1_c2"] = 15658.29         
params["IO_end_app1_n1_c2"] = 15133856           
params["IO_start_app1_n1_c2"] = 33408435          
params["State_start_app1_n1_mpi2_c2"] = 24023.35  
params["State_start_app1_n1_other3_c2"] = 32419.64
params["State_end_app1_n1_mpi2_c2"] = 69772.35    
params["State_end_app1_n1_other3_c2"] = 9123.807

params["IO_queue_app1_n1_c3"] = 15658.29         
params["IO_end_app1_n1_c3"] = 15133856           
params["IO_start_app1_n1_c3"] = 33408435          
params["State_start_app1_n1_mpi2_c3"] = 24023.35  
params["State_start_app1_n1_other3_c3"] = 32419.64
params["State_end_app1_n1_mpi2_c3"] = 69772.35    
params["State_end_app1_n1_other3_c3"] = 9123.807


grep(x=paramsName,pattern = paste0("_",interval)) -> indexesInterval


model.calibration(solver_fname = "~/Model_ADMIREproj/Net/queueHPCmodel.solver",
                  parameters_fname = paste0("~/Model_ADMIREproj/Input/parametersList_SingInterval.csv"),
                  functions_fname = "~/Model_ADMIREproj/RFunction/QueueFunctions.R",
                  reference_data = paste0("~/Model_ADMIREproj/Input/Reference/",interval,"_plot8Deltas.csv"),
                  distance_measure = "error_singleC",
                  parallel_processors = 3,
                  f_time = 1,
                  s_time = 1,
                  i_time = 0,
                  n_run = 300,
                  lb_v = params[indexesInterval]*0.001,
                  ub_v = params[indexesInterval]*10,
                  ini_v = params[indexesInterval],
                  solver_type = "SSA"
)
