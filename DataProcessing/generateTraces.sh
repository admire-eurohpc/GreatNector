#!/bin/bash

path="./Data/QE-single-node/"

for filename in $path*.json; do
    echo ${filename} starts 
    base_name=$(basename ${filename})
     ./DataProcessing/traceArrangement.py -i $filename -p ${base_name%%.*} -o QE_${base_name%%.*}
     echo ${filename} done
done