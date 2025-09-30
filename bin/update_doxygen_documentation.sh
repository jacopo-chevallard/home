#!/bin/bash

suffix=".fpp"
new_suffix=".f90"

folder="fypp-doxygen"

# Create folder for pre-processed *fpp files
cd ./src
mkdir -p ${folder}

# Clean folder from existing files
\rm ./${folder}/*.f90

# Pre-process *fpp files
for file in *${suffix} ; do
  base=`basename ${file} ${suffix}`
  fypp -l 100 -f smart ${file} ./${folder}/${base}${new_suffix}
done

# Run Doxygen
cd ..
doxygen Doxyfile

