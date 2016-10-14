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

j=1
for i in `seq 1 $nproc`; do

  file="BEAGLE_king.o${j}"

  while [ -f $file ] ; do
    j=$[$j +1]
    file="BEAGLE_king.o${j}"
  done

  echo -e "\nSubmitting job: ${i} (stdout and stderr redirected to $file)" 

  ./BEAGLE 1 $paramfile >& ${file} &

  sleep 5

done

