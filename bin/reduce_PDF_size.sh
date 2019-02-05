#!/bin/bash

display_usage() { 
  echo -e 'Help not implemented'
	} 

# if less than one argument supplied, display usage and exit 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 

# Check if ImageMagick command "convert" is available on the machine
if ! command -v convert >/dev/null 2>&1 ; then
  echo "Error: 'convert' command not available. Perhaps ImageMagick is not installed?"
  exit 1
fi

# default values for input arguments
input=""
output=""
density=300
delay=100
loop=0

# array containing mandatory arguments
declare -a mandatoryArgs=(input output)

# now read and parse the input arguments, some have options, others don't
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{ st = index($0,"=");print $1}'`
    VALUE=`echo $1 | awk -F= '{ st = index($0,"=");print substr($0,st+1)}'`
  case $PARAM in

    "-h"|"--help")  

      display_usage
      exit 1
      ;;

    "-i"|"--input")  

      input=$VALUE
      echo "Input files ----> " ${input}
      ;;

    "-o"|"--output")  

      output=$VALUE
      echo "Output file name ----> " ${output}
      ;;

    "--density")  

      density=$VALUE
      echo "Density (DPI)----> " ${density}
      ;;

    *) 

      echo "Option $PARAM not recognized!"
      echo "Type '${0} --help' for information on how to use the script"
      exit 1
      ;;

  esac
  shift
done

# Check for presence of mandatory arguments
for arg in "${mandatoryArgs[@]}" ; do
  # Double substituion (see http://unix.stackexchange.com/a/68272)
  eval "value=\${$arg}"
  if [ -z "$value" ]; then
    echo "Mandatory argument '$arg' not set!"
    echo "Type '${0} --help' for information on how to use the script"
    exit 1
  fi
done

convert -compress Zip -density ${density} ${input} ${output}
