#!/bin/bash

display_usage() { 
	echo -e "\nUsage:\n\n$0 --parameter-file/-p [parameter file] [ --number-jobs/-n [number of jobs] ] \n\nExample: $0 -p COSMOS.param -n 10\n\n" 
	} 

# if less than one argument supplied, display usage and exit 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 

# default values for input arguments
nproc=1
paramfile=""

# now read and parse the input arguments, some have options, others don't
for arg in "$@"; do

  case "$1" in

    "-n"|"--number-jobs")  
    
      shift
      nproc=$1
      shift
      ;;

    "-p"|"--parameter-file")  

      shift
      paramfile=$1
      echo "Parameter file: " ${paramfile}
      shift
      ;;

  esac

done

echo "Number of jobs that will be submitted: ${nproc}"

# Check for presence of mandatory arguments
if [ -z "$paramfile" ]; then
  echo "Mandatory argument --parameter-file [filename] not present!"
  exit 1
fi

for i in `seq 1 $nproc`; do

  echo "Submitting job: ${i}"

  qsub -V -cwd -m e -b y BEAGLE --parameter-file ${paramfile} --fit

  n_queue=1
  while [ $n_queue -gt 0 ]; do
    echo "Waiting for previous job to run..."
    sleep 1  
    n_queue="`qstat | grep qw | wc -l`" 
    echo "`qstat | grep qw | wc -l`"
  done

  sleep 1

done
