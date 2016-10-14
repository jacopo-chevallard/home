#!/bin/bash

# ****************************************
# see this beautiful tutorial on getopt: http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt
# and for long options see here http://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash-script
# ****************************************

plots_dir="pyp-beagle"
suffix="_BEAGLE"

display_usage() { 
	echo -e "\nDescription:\nIt searches for *${suffix}.fits.gz files in the current directory," \
    "and sync the \ncorresponding *pdf files into the ${plots_dir}/plot directory."
	echo -e "\nUsage:\n$0 --host [rsync destination]"
	echo -e "\nExample:\n$0 --host user@server:/foo/bar\n" 
	} 

# if less than one argument supplied, display usage and exit 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 

# default values for input arguments
hostname=""

# now read and parse the input arguments, some have options, others don't
for arg in "$@"; do

  case "$1" in

    "-h"|"--host")  

      shift
      hostname=$1
      echo "Hostname: " ${hostname}
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

plots="${plots_dir}/plot/"

# Include all subdirs
#echo "+ */" >> ${tempFile}
echo "list ${list}"

# List all files *fits.gz
list="$(find . -name '*fits.gz' ! -size 0)"

for file in $list ; do

  i=$(awk -v a="$file" -v b="$suffix" 'BEGIN{print index(a,b)}')

  file=${file:0:$i-1}

  # Plots
  echo "+ ${file:2}${suffix}*.pdf" >> ${tempFile}

done  

echo "- *" >> ${tempFile}

# Transfer the files to the new location with rsync
rsync -avz --include-from=${tempFile} ${hostname} ./

# Remove the temporary file
rm ${tempFile}

