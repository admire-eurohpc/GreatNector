#devtools::install_github('qBioTurin/epimod', ref='master',dependencies=TRUE)
library(dplyr)
library(epimod)
#downloadContainers()

setwd("Modeling/")
### source all the functions ##
source("RFunction/PlotGeneration.R")
source("./RFunction/names.R")
source("./RFunction/csvGeneration.R")
source("./RFunction/ReferenceGeneration.R")

###############################
model.generation(net_fname = "Net/queueHPCmodel.PNPRO",
                 transitions_fname = "Net/NewGenTransitions.cpp")

system("mv ./queueHPCmodel.* ./Net")

### Files preparation ####

# 1. Let cluster the trace in order to identify similar windows in the trace
# such that we can associate with the same parameter

files = list.files(path = "./Data/QuantumEspresso/",pattern = "*.csv")
for(f in files)
  reference.generation(x = f,
                       path = "./Data/QuantumEspresso/")

# 2. Let save places and transitions name.
name.generation(path = "Net/queueHPCmodel.PlaceTransition",out = "Input/")

# 3. Let save the csv file that associates the rate parameter with the right transition 
# and saves the names of the unknown parameters
paramenterCSV.generation(csvname = "parametersList.csv",
                         pathReference = "Input/Reference/QE_8Deltas.RDs",
                         transitions = "Input/transitionsNAMES.RDS")

#########################

### Uknown parameter definition ###
ref <- read.csv("../Clustering/Data/QE_8Deltas.csv") %>% 
  na.omit()
maxTime = max(ref[,"ts"])

paramsName = readRDS("Input/paramsNAMES.RDs")
params = rep(0.0,length(paramsName) )
names(params) = paramsName

params["IO_queue_app1_n1_c1"] = 144655.3
params["IO_end_app1_n1_c1"] = 301498.5
params["IO_start_app1_n1_c1"] = 311443507
params["State_start_app1_n1_mpi2_c1"] = 214851.3
params["State_start_app1_n1_other3_c1"] = 185378.2
params["State_end_app1_n1_mpi2_c1"] = 80027.6
params["State_end_app1_n1_other3_c1"] = 4382.651
params["IO_queue_app1_n1_c2"] = 132718.9*0.05
params["IO_end_app1_n1_c2"] = 312562.1*0.045
params["IO_start_app1_n1_c2"] = 91597669
params["State_start_app1_n1_mpi2_c2"] = 144763.7
params["State_start_app1_n1_other3_c2"] = 235967.7
params["State_end_app1_n1_mpi2_c2"] = 152130
params["State_end_app1_n1_other3_c2"] = 1276.057
params["IO_queue_app1_n1_c3"] = 142632.5*0.004
params["IO_end_app1_n1_c3"] = 2308668*0.003
params["IO_start_app1_n1_c3"] = 292692459
params["State_start_app1_n1_mpi2_c3"] = 28390.93
params["State_start_app1_n1_other3_c3"] = 284585.3
params["State_end_app1_n1_mpi2_c3"] = 195884.5
params["State_end_app1_n1_other3_c3"] = 4998.286


###################################

model.analysis(solver_fname = "./Net/queueHPCmodel4analysis.solver",
               parameters_fname = "Input/parametersList.csv",
               functions_fname = "./RFunction/QueueFunctions.R",
               f_time = (maxTime),
               s_time = 1,
               i_time = 0,
               n_run = 100,
               solver_type = "SSA",
               parallel_processors = 2,
               ini_v = params)

pl = ModelAnalysisPlot(tracefile = "queueHPCmodel4analysis_analysis/queueHPCmodel4analysis-analysis-1.trace",
                       timestrace = "queueHPCmodel4analysis_analysis/timedPlace.trace",
                       referencefile = "Input/Reference/CompleteTraceQE_8Deltas.RDs")
pl

