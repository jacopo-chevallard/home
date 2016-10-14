#!/bin/bash

# We firstly list all files which have not been modified int he last 30 min,
# indicating that the procees is hanged...
list="$(find . -name 'BANGS.o*' -mmin +30)"

# We then loop over this files and delete them from the SunGrid engine
for file in $list;
do
  # For the use of "IFS" to split a string see
  # http://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
  IFS='.o' read -ra array <<< "$file"
  echo "Deleting the job with ID ${array[3]}"
  qdel ${array[3]}
done  
