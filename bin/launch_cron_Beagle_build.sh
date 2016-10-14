#!/bin/bash

# This cron command will launch every day at 2AM the script to automatically build Beagle

display_usage() { 
	echo "\nDescription:\n\n"
	echo "\nUsage:\n$0 "
	echo "\nExample:\n$0 \n" 
	} 

# if less than one argument supplied, display usage and exit 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 

# default values for input arguments
repoDir=""
cmakeFlags=""
installDir=""
server=""
email=""

# array containing mandatory arguments
declare -a mandatoryArgs=(server email repoDir installDir)

# now read and parse the input arguments, some have options, others don't
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{ st = index($0,"=");print substr($0,st+1)}'`
  case $PARAM in

    "-h"|"--help")  

      display_usage
      exit 1
      ;;

    "--repository-dir")  

      repoDir=$VALUE
      echo "Setting repository directory to ----> " ${repoDir}
      ;;

    "--install-dir")  

      installDir=$VALUE
      echo "Setting installation directory to ----> " ${installDir}
      ;;

    "--cmake-flags")  

      # Replace commmas with spaces
      cmakeFlags=${VALUE//,/ }
      echo "Setting CMake flags ----> " ${cmakeFlags}
      ;;

    "--server")  

      server=$VALUE
      echo "Setting server name to ----> " ${server}
      ;;

    "--mailto")  

      email=$VALUE
      echo "Setting mail address to ----> " ${email}
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

#write out current crontab
crontab -l > beagle_cron

echo "00 02 * * *  bash -lc automatic_Beagle_build.sh  --repository-dir='${repoDir}' --install-dir='${installDir}' --cmake-flags='${cmakeFlags}' > ~/cronlog/\`date +\%Y-\%m-\%d-\%H:\%M:\%S\`-cron.log 2>&1 ; mailx -s \"CronJob-Beagle build run successfully on ${server}\" ${email}" >> beagle_cron

crontab beagle_cron

rm beagle_cron
