#!/bin/bash

display_usage() { 
	echo -e "\nDescription:\nIt removes files created by BEAGLE when they correspond to objects for which the fitting was not completed.\n"
	echo -e "\nUsage:\n$0 --silent/-s --results/-r [directory containing BEAGLE results]"
	echo -e "\nExample:\n$0 --results /Users/John/BEAGLE \n" 
	} 

# if less than one argument supplied, display usage and exit 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 


# default values for input arguments
projectName=""
libraryName=""
archiveName=""
gitUrl=""
gitTag=""
urlName=""
otherUrlsName=""
cmakeArgs="-DCMAKE_Fortran_COMPILER=\${CMAKE_Fortran_COMPILER} -DCMAKE_Fortran_FLAGS=\${CMAKE_Fortran_FLAGS} -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DCMAKE_NO_DEFAULT_PATH=\${CMAKE_NO_DEFAULT_PATH} -DCMAKE_PARENT_SOURCE_DIR=\${CMAKE_CURRENT_SOURCE_DIR} -DCMAKE_LIBRARY_TYPE=\${CMAKE_LIBRARY_TYPE}"
defaultPatch=false

# array containing mandatory arguments
declare -a mandatoryArgs=(projectName libraryName)

# now read and parse the input arguments, some have options, others don't
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{ st = index($0,"=");print $1}'`
    VALUE=`echo $1 | awk -F= '{ st = index($0,"=");print substr($0,st+1)}'`
  case $PARAM in

    "-h"|"--help")  

      display_usage
      exit 1
      ;;

    "--external-project-name")  

      projectName=$VALUE
      echo "Setting external project name ----> " ${projectName}
      ;;

    "--library-name")  

      libraryName=$VALUE
      echo "Setting library name ----> " ${libraryName}
      ;;

    "--archive-name")  

      archiveName=$VALUE
      echo "Setting archive name ----> " ${archiveName}
      ;;

    "--default-patch")  

      defaultPatch=true
      echo "Using default patch command"
      ;;

    "--git-url")  

      gitUrl=$VALUE
      echo "Setting GIT repository url ----> " ${gitUrl}
      ;;

    "--git-tag")  

      gitTag=$VALUE
      echo "Setting GIT repository tag ----> " ${gitTag}
      ;;

    "--cmake-args-add")  

      tmp=${VALUE//,/ }
      cmakeArgs=${cmakeArgs} $tmp
      echo "Setting CMake arguments ----> " ${cmakeArgs}
      ;;

    "--cmake-args-set")  

      cmakeArgs=${VALUE//,/ }
      echo "Setting CMake arguments ----> " ${cmakeArgs}
      ;;

    "--url")  

      urlName=$VALUE
      echo "Setting URL ----> " ${urlName}
      ;;

    "--see-also")  

      otherUrlsName=${VALUE//,/ }
      echo "Setting see also URL ----> " ${otherUrlsName}
      ;;

    *) 

      echo "Option $PARAM not recognized!"
      echo "Type '${0} --help' for information on how to use the script"
      exit 1
      ;;

  esac
  shift
done

fileName="External_${projectName}.cmake"
# First, check if the external project CMake file already exists
if [ -f ${fileName} ] ; then
  echo -e "The file ${fileName} already exists in the present directory!"
  exit 1
fi

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


###########################################
# Start writing the CMakeLists.txt
###########################################

printf '%s\n' "# An external project for ${projectName}" >> ${fileName}
if [ ! -z ${urlName} ] ; then
  printf '%s\n' "# URL ${urlName}" >> ${fileName}
fi
if [ ! -z ${otherUrlsName} ] ; then
  printf '%s\n' "# see also ${otherUrlsName}" >> ${fileName}
fi
printf '%s\n\n' "set ( ${projectName}_PREFIX \${CMAKE_BINARY_DIR}/dependencies )" >> ${fileName}

printf '%s\n' "set (${projectName}_SOURCE  \${${projectName}_PREFIX}/${libraryName}-src)" >> ${fileName}
printf '%s\n' "set (${projectName}_BINARY  \${${projectName}_PREFIX}/${libraryName})" >> ${fileName}
printf '%s\n\n' "set (${projectName}_INSTALL \${CMAKE_INSTALL_PREFIX})" >> ${fileName}

printf '%s\n' "set (${projectName}_LIBRARY_NAME ${libraryName})" >> ${fileName}
printf '%s\n' "set (${projectName}_CMAKE_LIBDIR "\${CMAKE_INSTALL_PREFIX}/lib")" >> ${fileName}
printf '%s\n\n' "set (${projectName}_CMAKE_INCLUDEDIR \${CMAKE_INSTALL_PREFIX}/include/\${${projectName}_LIBRARY_NAME})" >> ${fileName}

printf '%s\n' "ExternalProject_Add(" >> ${fileName}
printf '%s\n' "  EXT_${projectName}" >> ${fileName}
printf '%s\n' "  DOWNLOAD_DIR \${${projectName}_PREFIX}" >> ${fileName}
printf '%s\n' "  SOURCE_DIR \${${projectName}_SOURCE}" >> ${fileName}
printf '%s\n' "  BINARY_DIR \${${projectName}_BINARY}" >> ${fileName}
printf '%s\n' "  INSTALL_DIR \${${projectName}_INSTALL}" >> ${fileName}

if [ ! -z "${archiveName}" ] ; then
  printf '%s\n' "  URL \${CMAKE_CURRENT_SOURCE_DIR}/dependencies/archives/${archiveName}" >> ${fileName}
elif [ ! -z "${gitUrl}" ] ; then
  printf '%s\n' "  GIT_REPOSITORY ${gitUrl}" >> ${fileName}
  if [ ! -z "${gitTag}" ] ; then
    printf '%s\n' "  GIT_TAG ${gitTag}" >> ${fileName}
  fi
fi

if [ "${defaultPatch}" = true ] ; then
  printf '%s\n' "  PATCH_COMMAND cp \${CMAKE_CURRENT_SOURCE_DIR}/cmake/${libraryName}/CMakeLists.txt <SOURCE_DIR>" >> ${fileName}
fi
printf '%s\n' "  CMAKE_ARGS ${cmakeArgs}" >> ${fileName}
printf '%s\n\n' "  )" >> ${fileName}

printf '%s\n' "set ( ${projectName}_INCLUDE_DIR \${${projectName}_CMAKE_INCLUDEDIR} CACHE INTERNAL \"${projectName} include directory\" )" >> ${fileName}
printf '%s\n' "set ( ${projectName}_LIBRARIES \"\${${projectName}_CMAKE_LIBDIR}/\${CMAKE_LIBRARY_PREFIX}\${${projectName}_LIBRARY_NAME}\${CMAKE_LIBRARY_SUFFIX}\" CACHE INTERNAL \"${projectName} library\" )" >> ${fileName}

