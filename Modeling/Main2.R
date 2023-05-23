library(epimod)
library(dplyr)
### Uknown parameter definition ###
ref <- read.csv("Data/QuantumEspresso/plot8Deltas.csv") %>% 
  na.omit()
maxTime = max(ref[,"X"])

paramsName = readRDS("Input/paramsNAMES.RDs")
params = rep(0.0,length(paramsName) )
names(params) = paramsName

params["IO_queue_app1_n1_c1"] = 15658.29
params["IO_end_app1_n1_c1"] = 15133856
params["IO_start_app1_n1_c1"] = 33408435
params["State_start_app1_n1_mpi2_c1"] = 24023.35
params["State_start_app1_n1_other3_c1"] = 32419.64
params["State_end_app1_n1_mpi2_c1"] = 69772.35
params["State_end_app1_n1_other3_c1"] = 9123.807

params["IO_queue_app1_n1_c2"] = 14805.4
params["IO_end_app1_n1_c2"] = 14614880
params["IO_start_app1_n1_c2"] = 33000472
params["State_start_app1_n1_mpi2_c2"] = 22714.82
params["State_start_app1_n1_other3_c2"] = 14851503
params["State_end_app1_n1_mpi2_c2"] = 16886159
params["State_end_app1_n1_other3_c2"] = 270940.3

params["IO_queue_app1_n1_c3"] = 15659.17
params["IO_end_app1_n1_c3"] = 15133855
params["IO_start_app1_n1_c3"] = 33408436
params["State_start_app1_n1_mpi2_c3"] = 1427731
params["State_start_app1_n1_other3_c3"] = 26013954
params["State_end_app1_n1_mpi2_c3"] = 69772.41
params["State_end_app1_n1_other3_c3"] = 9124.306

system("nohup Rscript IntervalCalibration.R c1 > logC1 &")
system("nohup Rscript IntervalCalibration.R c2 > logC2 &")
system("nohup Rscript IntervalCalibration.R c3 > logC3 &")

########################################

model.analysis(solver_fname = "./Net/queueHPCmodel4analysis.solver",
               parameters_fname = "Input/parametersList_c1.csv",
               functions_fname = "./RFunction/QueueFunctions.R",
               f_time = 1,
               s_time = 1,
               i_time = 0,
               n_run = 100,
               solver_type = "SSA",
               parallel_processors = 10,
               ini_v = params)

pl = ModelAnalysisPlot(tracefile = "queueHPCmodel4analysis_analysis/queueHPCmodel4analysis-analysis-1.trace",
                       timestrace = "queueHPCmodel4analysis_analysis/timedPlace.trace",
                       referencefile = "Input/Reference/CompleteTraceplot8Deltas.RDs")

pl
