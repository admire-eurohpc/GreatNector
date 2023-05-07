#devtools::install_github('qBioTurin/epimod', ref='master',dependencies=TRUE)
library(dplyr)
library(epimod)
#downloadContainers()

### source all the functions ##
source("RFunction/PlotGeneration.R")
source("./RFunction/names.R")
source("./RFunction/csvGeneration.R")
source("./RFunction/ReferenceGeneration.R")

###############################
model.generation(net_fname = "Net/queueHPCmodel.PNPRO",
                 transitions_fname = "Net/GenTransitions.cpp")
system("mv ./queueHPCmodel.* ./Net")

### Files preparation ####

# 1. Let cluster the trace in order to identify similar windows in the trace
# such that we can associate with the same parameter

files = list.files(path = "~/Desktop/GIT/Modelli_GreatMod/HPCmodel/SystemPointView/Data/QuantumEspresso/",pattern = "*.csv")
for(f in files)
  reference.generation(f,"~/Desktop/GIT/Modelli_GreatMod/HPCmodel/SystemPointView/Data/QuantumEspresso/")

# 2. Let save places and transitions name.
name.generation(path = "Net/queueHPCmodel.PlaceTransition",out = "Input/")

# 3. Let save the csv file that associates the rate parameter with the right transition 
# and saves the names of the unknown parameters
paramenterCSV.generation(csvname = "parametersList.csv",
                         pathReference = "Input/Reference/dfProva.RDs",
                         transitions = "Input/transitionsNAMES.RDS")

#########################

### Uknown parameter definition ###

paramsName = readRDS("Input/paramsNAMES.RDs")
params = rep(0,length(paramsName) )
names(params) = paramsName

params[c("IO_queue_app1_n1_interval1","IO_queue_app1_n1_interval2")] = c(0,0) 
params[c("IO_end_app1_n1_interval1","IO_end_app1_n1_interval2")] = c(0,0)
params[c("IO_start_app1_n1_interval1","IO_start_app1_n1_interval2")] = c(0,0)

params[c("State_start_app1_n1_other3_interval1","State_start_app1_n1_other3_interval2")] = c(.6,0)
params[c("State_start_app1_n1_mpi2_interval1","State_start_app1_n1_mpi2_interval2")] = c(0,0.6)
params[c("State_end_app1_n1_other3_interval1","State_end_app1_n1_other3_interval2")] = c(0.5,0)
params[c("State_end_app1_n1_mpi2_interval1","State_end_app1_n1_mpi2_interval2")] = c(0,0.5)

###################################

model.analysis(solver_fname = "./Net/queueHPCmodel.solver",
               parameters_fname = "Input/parametersList.csv",
               functions_fname = "./RFunction/QueueFunctions.R",
               f_time = 50,
               s_time = 1,
               i_time = 0,
               n_run = 1,
               solver_type = "LSODA",
               parallel_processors = 1,
               ini_v = params,
               debug = T )


ModelAnalysisPlot("queueHPCmodel_analysis/queueHPCmodel-analysis-1.trace")

### Calibration 

model.calibration(solver_fname = "./Net/HPCmodel.solver",
                  parameters_fname = "Input/parametersList.csv",
                  functions_fname = "./RFunction/Functions.R",
                  reference_data = "./Input/ReferenceCl2.csv",
                  distance_measure = "error",
                  parallel_processors = 10,
                  f_time = 5*60, # simulo 5 minuti
                  s_time = 1,
                  i_time = 0,
                  n_run = 500,
                  lb_v = rep(0,length(paramsName)),
                  ub_v = rep(1,length(paramsName)),
                  ini_v = rep(0.5,length(paramsName)),
                  solver_type = "SSA"
) #debug = T )

