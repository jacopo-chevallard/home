#!/bin/bash

# ****************************************
# see this beautiful tutorial on getopt: http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt
# and for long options see here http://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash-script
# ****************************************

display_usage() { 
	echo -e "\nUsage:\n\n$0 --host [rsync destination] [--quiet/-q] \n\nExample: $0 --host user@server:/foo/bar\n\n" 
	} 

# if less than one argument supplied, display usage and exit 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 

# default values for input arguments
fast=false
hostname=""
flags="-avz -r --min-size=1"
suffix="_BEAGLE"
inputDir="BEAGLE-input-files"

# now read and parse the input arguments, some have options, others don't
for arg in "$@"; do

  case "$1" in

    "--host")  

      shift
      hostname=$1
      echo "Hostname: " ${hostname}
      shift
      ;;

    "-q"|"--quiet")  
    
      echo "Suppress all non-error messages"
      flags="-aqz -r"
      shift
      ;;

  esac

done


# Check for presence of mandatory arguments
if [ -z "$hostname" ]; then
  echo "Mandatory argument --host [hostname] not present!"
  exit 1
fi

# Print to the temporary file the folder containing the BEAGLE input files (if the folder exists)
if [ -d "$inputDir" ]; then
  echo ${inputDir} >> ${tempFile}
fi

# Transfer the files to the new location with rsync
rsync ${flags} "${hostname}/${inputDir}" .
rsync ${flags} "${hostname}/*${suffix}.fits.gz" .

