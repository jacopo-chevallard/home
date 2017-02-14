#!/bin/bash

display_usage() { 
	printf "Description:\nAllows to launch a Beagle run from a GAZPAR package.\n"
  printf "By default, it assumes that the script is launched from withih the GAZPAR package folder.\n"
	printf "\nUsage:\n$0 [--package-dir=<GAZPAR package folder>] [--beagle-exec=<path to Beagle executable>]\n"
	printf "\nExample:\n$0 --package-dir=request1_Name_Surname --beagle-exec=/foo/bar/BEAGLE\n" 
	} 


# array containing mandatory arguments
declare -a mandatoryArgs=()
beagleExec="BEAGLE"
packageDir=""

# now read and parse the input arguments, some have options, others don't
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{ st = index($0,"=");print substr($0,st+1)}'`
  case $PARAM in

    "-h"|"--help")  

      display_usage
      exit 1
      ;;

    "--package-dir")  

      packageDir=$VALUE
      echo "Setting package directory to ----> " ${packageDir}
      ;;

    "--beagle-exec")  

      beagleExec=$VALUE
      echo "Setting Beagle executable ----> " ${beagleExec}
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

# If a package directory has been specified through the command line argument,
# then move into the package directory
if [ ! -z $packageDir ] ; then
  cd ${packageDir}
fi

# Get number of filters in the system-wide filters file
n_filt=`tail -n 1 ${BEAGLE_FILTERS}/filters.log | awk '{print $1}'`

echo "Number of filter transmission curves in the original FILTERBIN.RES: ${n_filt}"

# Concatenate the system-wide filters file and the one provided by GAZPAR
# (to avoid getting same problems as in https://github.com/jacopo-chevallard/BEAGLE-general/issues/34)
#mv filterfrm.res filterfrm_GAZPAR.res
if [ ! -s "filterfrm_GAZPAR.res" ]; then
  cp filterfrm.res filterfrm_GAZPAR.res
fi
rm filterfrm.res
cat ${BEAGLE_FILTERS}/filterfrm.res filterfrm_GAZPAR.res > filterfrm.res

# Create the filter binary file
${BEAGLE_FILTERS}/build_filterbin

filters=`pwd`
filters=${filters}/FILTERBIN.RES

# Check if you're on a GNU or BSD (e..g Mac OS) system, since you need to use a different flag for sed
if echo "1234" | sed -r "s/[0-9]+/0/g" > /dev/null 2>&1 ; then
    # Flag for GNU
    my_sed="sed -r"
else
    # Flag for BSD
    my_sed="sed -E"
fi

# Change the filters_GAZPAR.dat file to reflect the changed filter indices
if [ ! -s "filters_GAZPAR.dat" ]; then
  cp filters.dat filters_GAZPAR.dat
fi
rm filters.dat

while read -r line
do
    if [[ $line == index* ]]; then
      echo "Name read from file - $line"
      var=$(echo $line |  awk -F'[:]' '{print $2}' | awk '{print $1}')
      var=$(($var + $n_filt + 1))
      echo "var: $var"
      new_line=$(echo $line | $my_sed "s/index:[0-9]+/index:$var/g")
      echo $new_line >> filters.dat
    else
      echo $line >> filters.dat
    fi
done < "filters_GAZPAR.dat"

# Convert the ASCII catalogue to FITS
#sed '1s/^/#/' $1 > $1.header
name=`find . -iname 'catalog*.in'`
if [ -z $name ] ; then
  ./prepare_header.sh
  name=`find . -iname 'catalog*.in'`
fi

if [ -f "./ASCII_To_FITS.py" ] ; then
  ./ASCII_To_FITS.py -i ${name} -o ${name}.fits
else
  ASCII_To_FITS.py -i ${name} -o ${name}.fits
fi

# Finally, launch Beagle!
FILTERS=${filters} ${beagleExec} --fit -p beagle.param
