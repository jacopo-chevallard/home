#!/bin/bash

display_usage() { 
  echo -e "\nUsage:\n\n$0 [archive name] \n\nExample: $0 my_new_archive\n\n" 
	} 

# if less than one argument supplied, display usage 
if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then 
	display_usage
	exit 1
fi 

# if less than two arguments supplied, use default name 
if [  $# -eq 1 ]; then 
	archive=$1
else
  archive="aaa"
fi 


# This temporary file contains the list of file to be rsynced and it will be
# removed at the end of the script
tempFile="temp.dat"

# If this temporary file already exists, delete it
if [ -f "$tempFile" ] ; then
  rm $tempFile
fi

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

  #echo ${file}${suffix}.fits.gz >> ${tempFile}
  echo ${file}${suffix}_MNstats.dat >> ${tempFile}
  echo ${file}${suffix}_MNpost_separate.dat >> ${tempFile}

done  

# Create tar.gz archive
tar -czvf ${archive}.tar.gz --files-from=${tempFile}

# Remove the temporary file
rm ${tempFile}

