#!/bin/bash

# ****************************************
# see this beautiful tutorial on getopt: http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt
# and for long options see here http://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash-script
# ****************************************

display_usage() { 
	echo -e "\nUsage:\n\n$0 --host [rsync destination] [--fast/-f] [--quiet/-q] \n\nExample: $0 --host user@server:/foo/bar\n\n" 
	} 

# if less than one argument supplied, display usage and exit 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 

# default values for input arguments
fast=false
hostname=""
flags="-avz"

# now read and parse the input arguments, some have options, others don't
for arg in "$@"; do

  case "$1" in

    "-f"|"--fast")  
    
      echo "FITS files will not be copied"
      fast=true
      shift
      ;;

    "-h"|"--host")  

      shift
      hostname=$1
      echo "Hostname: " ${hostname}
      shift
      ;;

    "-q"|"--quiet")  
    
      echo "Suppress all non-error messages"
      flags="-aqz"
      shift
      ;;

  esac

done


# Check for presence of mandatory arguments
if [ -z "$hostname" ]; then
  echo "Mandatory argument --host [hostname] not present!"
  exit 1
fi

# This temporary file contains the list of file to be rsynced and it will be
# removed at the end of the script
tempFile="temp.dat"

# If this temporary file already exists, delete it
if [ -f "$tempFile" ] ; then
  rm $tempFile
fi

# File to remember what was there during the last sync
previousFile="previously_synced.dat"

# Create the file, it will not be removed
touch $previousFile

while true ; do

  # Print to the temporary file the parameter file(s) contained in the directory
  list="$(find . -name '*param')"

  for file in $list; do
    echo ${file} >> ${tempFile}
  done

  suffix="_BANGS"

  # Print the files containing BANSG results
  list="$(find . -name '*fits.gz' ! -size 0)"

  for file in $list; do

    i=$(awk -v a="$file" -v b="$suffix" 'BEGIN{print index(a,b)}')

    file=${file:0:$i-1}

    if [ "$fast" = false ] ; then
      echo ${file}${suffix}.fits.gz >> ${tempFile}
    fi

    echo ${file}${suffix}_MNstats.dat >> ${tempFile}
    echo ${file}${suffix}_MNpost_separate.dat >> ${tempFile}

  done  

  # Check if we have a file from the previous sync
  if [ -f $previousFile ] ; then
    # Check that rsync is not still running
    if [ ! pgrep rsync > /dev/null ] ; then
      # Transfer the files to the new location with rsync if anything has changed
      cmp --silent $previousFile $tempFile || rsync ${flags} --files-from=${tempFile} ./ ${hostname}
      # Move temporary file to something more permantent
      mv ${tempFile} ${previousFile}
    fi
  fi

  # Remove the temporary file
  if [ -f "$tempFile" ] ; then
    rm $tempFile
  fi

  sleep 15m || exit 2

done
