library(readr)
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)

#function(TracePath){
  
Trace <- read_csv("Data/Trace", col_names = FALSE)
  
traceMatrix = do.call("rbind",lapply(2:(dim(Trace)[1]-1), function(i){
  a = gsub(Trace[i,],pattern = "(\")|(\\{)|(\\})",replacement = "")
  a = gsub(a,pattern = " v:",replacement = "")
  a = gsub(a,pattern = ",$",replacement = "")
  a =str_split(str_split(a,pattern = ",",simplify = T),pattern = ": ")
  Values = matrix(as.numeric(sapply(a,"[[",2)),nrow = 1)
  colnames(Values) = sapply(a,"[[",1)
  return(Values)
}))


df = as.data.frame(traceMatrix) %>%
  gather(-ti,key = "Jobs",value = "Value") %>%
  rename(Time = ti)

pl = ggplot(df) + geom_bar(aes(x = Time,y = Value,fill = Jobs),stat = "identity")
pl
ggsave(pl,filename = "BarTrace.pdf",device = "pdf",path = "Plots",width = 10,height = 6)

pl = ggplot(df) + geom_line(aes(x = Time,y = Value,col = Jobs)) + facet_wrap(~Jobs)
ggsave(pl,filename = "LinesTrace.pdf",device = "pdf",path = "Plots",width = 10,height = 6)

traceMatrix = as.data.frame(traceMatrix) 
traceMatrix = traceMatrix %>%
  group_by(ti) %>%
  mutate(io = ` io_read` + ` io_write`) %>% 
  select( -` io_read`, -` io_write`, -` io`)

df = as.data.frame(traceMatrix) %>%
  gather(-ti,key = "Jobs",value = "Value") %>%
  rename(Time = ti)


pl = ggplot(df) + geom_line(aes(x = Time,y = Value,col = Jobs)) + facet_wrap(~Jobs)
pl
#}