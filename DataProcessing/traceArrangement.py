#!/usr/bin/env python3
import argparse
import json
import sys
import matplotlib.pyplot as plt
import pandas as pd 
import seaborn as sb
import numpy


parser = argparse.ArgumentParser(description='memapper plot program')

# Profile Support
parser.add_argument('-i', '--input', required=True, type=str, help="Input JSON file to plot")
parser.add_argument('-p', '--proccount', required=True, type=int, help="Number of MPI processes in measurement")
parser.add_argument('-o', '--out', type=str, help="Output file for graph")

args = parser.parse_args(sys.argv[1:])

with open(args.input, 'r') as f:
    data = json.load(f)
    dataframe = pd.concat([ pd.DataFrame( x ) for x in data ])

def filter_events(data, to_keep):
    return data[ data.name.isin( to_keep )]


def _get_point(data, offset):
   if offset == 0:
      return 0
   #print(data.iloc[69])
   for x in range(len(data) - 1, 0, -1):
      cur = data.iloc[x]
      x1 = cur["ts"]
      if x1 < offset:
         #print("{} - {}", x1, offset)
         nxt = data.iloc[x + 1]
         x2 = nxt["ts"]
         y1 = cur["value"]
         y2 = nxt["value"]
         slp = (y2-y1)/(x2-x1)
         yint = y1 + (offset-x1)*slp
         #print("({}, {}) ({}, {}) target ({}, {})".format(x1,y1,x2,y2, offset, yint))
         return yint
   return 0.0

def resample_array(data, x):
   ret = []
   for xx in x:
      p = _get_point(data, xx)
      ret.append(p)
   return ret



tau_str = "tau_mpi_total{metric=\"time\"}"
strace_str = "strace_total{desc=\"time\"}"
hit_read_strace = "strace_hits_total{scall=\"read\"}"
hit_write_strace = "strace_hits_total{scall=\"write\"}"
hit_total_strace = "strace_total{desc=\"hits\"}"
hit_mpi_strace = "tau_mpi_total{metric=\"hits\"}"

vectordat = filter_events(dataframe, [ tau_str, strace_str,hit_read_strace, hit_write_strace, hit_total_strace, hit_mpi_strace])
    
mi, ma = vectordat.ts.min(), vectordat.ts.max()
max_ts = ma - mi
    #print(vectordat)
vectordat.ts = vectordat.ts.apply( lambda v: v - mi )
    # print(vectordat)
    #print(mi, ma, max_ts)

io = vectordat[ vectordat.name == strace_str ].copy()
io["Color"] = "IO"
mpi = vectordat[ vectordat.name == tau_str ].copy()
mpi["Color"] = "mpi"

# quantum is the time dimension of intervals that we want to consider in order to have one observation every quantum sec
quantum = 10

x = numpy.arange(0,max_ts, quantum)

ympi = resample_array(mpi, x)
yio = resample_array(io, x) 

####### Reading the HITS
read_io = vectordat[ vectordat.name == hit_read_strace ].copy()
write_io = vectordat[ vectordat.name == hit_write_strace ].copy()
total_hit = vectordat[ vectordat.name == hit_total_strace ].copy()
mpi_hit = vectordat[ vectordat.name == hit_mpi_strace ].copy()

# We devide w.r.t. args.proccount in order to have an average number of hits per process
y_hit_w = resample_array(write_io, x)
y_hit_r = resample_array(read_io, x)
y_hit_mpi = resample_array(mpi_hit, x)
y_hit_tot = resample_array(total_hit, x)

y_hit_io = numpy.add(y_hit_r,y_hit_w)
y_hit_other = numpy.subtract(y_hit_tot, y_hit_io ) 

d = {"ts": x, "io": yio, "mpi": ympi, "iops":y_hit_io, "mpi_hit":y_hit_mpi,"other_hit":y_hit_other} 
    
newdata = pd.DataFrame(data=d)
newdata["other_hit"] =  newdata["other_hit"] / args.proccount
newdata["iops"] =  newdata["iops"] / args.proccount
newdata["mpi_hit"] =  newdata["mpi_hit"] / args.proccount

deltas = newdata.diff(axis=0)
deltas["ts"] = newdata["ts"]
deltas["io_p"] = deltas["io"]/(quantum * args.proccount)*100
deltas["mpi_p"] = deltas["mpi"]/(quantum * args.proccount)*100
deltas["other_p"] = 100 - ( deltas["io_p"] + deltas["mpi_p"])
    
deltas.to_csv(f"./Clustering/Data/{args.out}Deltas.csv")
