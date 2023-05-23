library(ggplot2)
library(ggthemes)
library(dplyr)
library(readr)

tracefile = "queueHPCmodel4analysis_analysis/queueHPCmodel4analysis-analysis-1.trace"
timestrace = "queueHPCmodel4analysis_analysis/timedPlace.trace"
referencefile = "Input/Reference/CompleteTraceplot8Deltas.RDs"

output <- read.csv(tracefile, sep = "")

timedTrace = read.csv(timestrace,
                      header = FALSE, sep = "\t")

reference <- readRDS(referencefile)
#reference$Time = reference$Time+1

colnames(timedTrace) = c("Time",
                         "IOQueue_n1_app1_q01", "IOQueue_n1_app1_q11",
                         "IOQueue_n1_app1_q21", "IOQueue_n1_app1_q31",
                         "IOQueue_n1_app1_q41",
                         "SystemProcesses_n1_app1",
                         "StateRunning_n1_app1_mpi2",
                         "StateRunning_n1_app1_other3",
                         "IORunning_n1_app1_q01",
                         "IORunning_n1_app1_q11","IORunning_n1_app1_q21",
                         "IORunning_n1_app1_q31", "IORunning_n1_app1_q41" )


n_sim_tot<-table(output$Time)
time_delete<-as.numeric(names(n_sim_tot[n_sim_tot!=n_sim_tot[1]]))
if(length(time_delete)!=0) output = output[which(output$Time!=time_delete),]
output$ID = rep(1:n_sim_tot[1],each = length(unique(output$Time)) )

timedTraceInfo = timedTrace %>%
  mutate(
    io_p = IOQueue_n1_app1_q11+IOQueue_n1_app1_q21+
      IOQueue_n1_app1_q31+IOQueue_n1_app1_q01+
      IOQueue_n1_app1_q41+
      IORunning_n1_app1_q01+
      IORunning_n1_app1_q11+IORunning_n1_app1_q21+
      IORunning_n1_app1_q31+IORunning_n1_app1_q41,
    mpi_p = StateRunning_n1_app1_mpi2,
    system_p = SystemProcesses_n1_app1,
    other_p = StateRunning_n1_app1_other3) %>%
  dplyr::select(Time,io_p,mpi_p) %>%#,system_p,other_p) %>%
  dplyr::mutate(mpi_p = mpi_p*100,
                io_p = io_p*100#,
                #system_p=system_p*100,
                #other_p =other_p*100
                ) %>%
  tidyr::gather(-Time, value = "Measure", key =  "Jobs") %>%
  group_by( Time, Jobs ) %>%
  summarise(Mean = mean(Measure),
            q1 = min(Measure),#quantile(Measure,probs = 0.25),
            q3 = max(Measure),#quantile(Measure,probs = 0.75)
  ) %>%
  ungroup() %>%
  tidyr::gather(-Time,-Jobs, value = "Measure", key =  "Statistics")

traceRef = output %>%
  dplyr::select(ID,Time, IOps_n1_app1, Call_Counts_n1_app1_mpi2) %>%
  group_by(ID) %>%
  rename(iops = IOps_n1_app1,
         mpi_hit = Call_Counts_n1_app1_mpi2) %>%
  mutate(iops = iops-lag(iops) ,
         mpi_hit = mpi_hit-lag(mpi_hit) ) %>%
  na.omit() %>%
  tidyr::gather(-Time,-ID, value = "Measure", key =  "Jobs") %>%
  ungroup()%>%
  dplyr::select(-ID) %>%
  group_by( Time, Jobs ) %>%
  summarise(Mean = mean(Measure),
            q1 = min(Measure),#quantile(Measure,probs = 0.25),
            q3 = max(Measure),#quantile(Measure,probs = 0.75)
  ) %>%
  ungroup()%>%
  tidyr::gather(-Time,-Jobs, value = "Measure", key =  "Statistics")

traceRef2 = rbind(traceRef,timedTraceInfo) %>% tidyr::spread(value = "Measure", key =  "Statistics")
#dplyr::select(Time, io_p, mpi_p, iops, mpi_hit,system_p,other_p) %>%
#tidyr::gather(-Time,-Statistics, value = "Measure", key =  "Jobs") %>%
#

reference = reference %>%
  dplyr::select(-Diff) %>%
  rename(RefValue = Value)

Jobs.labs <- c("IO %","IO calls","MPI calls", "MPI %"  )
names(Jobs.labs) <- c("io_p","iops","mpi_hit", "mpi_p"  )

pl = ggplot()+
  # geom_point(data = traceRef2,aes(x = Time, y = Measure, col = Jobs))+
  geom_line(data = reference,aes(x = Time, y = RefValue, col = "Reference"))+
  geom_ribbon(data = traceRef2,aes(x = Time, ymin = q1, ymax = q3),fill="grey",alpha = 0.7)+
  facet_wrap(~Jobs,scales = "free",
             ncol = 2,
             labeller = labeller(Jobs = Jobs.labs))+
  geom_line(data = traceRef2,aes(x = Time, y = Mean,col ="Mean"),linetype = "dashed")+
  theme_bw()+
  xlim(c(0,max(traceRef2$Time+1)))+
  scale_color_manual(values = c("Mean" = "black", "Reference" ="red"))+
  labs(x="Time (sec.)",y = "",col = "")

pl

ggsave(plot = pl,filename = "QE8procCalibrated.pdf",
         path = "./Plots/",
         device = "pdf",width = 10,height = 8)

### parameters table

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

df = data.frame(Params = gsub(pattern = "_c[1-9]",x = names(params),replacement = ""),
                value = format(unname(params), scientific=FALSE),
                cluster =  stringr::str_sub(names(params), -1,-1) )

df$cluster = paste0("Rate cluster ", df$cluster)

xtable::xtable(df %>% tidyr::spread(value = "value",key = "cluster"))



