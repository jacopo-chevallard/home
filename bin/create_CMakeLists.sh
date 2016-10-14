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

fileName="CMakeLists.txt"
# First, check if a CMakeLists.txt is already present in the current directory 
if [ -f ${fileName} ] ; then
  echo -e "The file ${fileName} already exists in the present directory!"
  exit 1
fi

# default values for input arguments
cmakeVersion="2.6"
projectName=""
projectVersion=""
libraryName=""
languages="Fortran"
GNUfortranFlags=""
srcPath=""
testPath=""
srcFiles=""

dependencies=""

fyppPreprocess=false

# array containing mandatory arguments
declare -a mandatoryArgs=(projectName)

# now read and parse the input arguments, some have options, others don't
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
  case $PARAM in

    "-h"|"--help")  

      display_usage
      exit 1
      ;;

    "--project-name")  

      projectName=$VALUE
      echo "Setting project name ----> " ${projectName}
      ;;

    "--project-version")  

      projectVersion=$VALUE
      echo "Setting project version ----> " ${projectVersion}
      ;;

    "--library-name")  

      libraryName=$VALUE
      echo "Setting library name ----> " ${libraryName}
      ;;

    "--languages")  

      # Replace commmas with spaces
      languages=${VALUE//,/ }
      echo "Setting project languages----> " ${languages}
      ;;

    "--GNU-fortran-flags")  

      # Replace commmas with spaces
      GNUfortranFlags=${VALUE//,/ }
      echo "Setting Fortran flags----> " ${GNUfortranFlags}
      ;;

    "--add-dependencies")  

      # Replace commmas with spaces
      dependencies=${VALUE//,/ }
      echo "Setting dependencies----> " ${dependencies}
      ;;

    "--cmake-version")  

      cmakeVersion=$VALUE
      echo "Setting minimum cmake version ----> " ${cmakeVersion}
      ;;

    "--src-path")  

      srcPath=$VALUE
      echo "Setting path for source files ----> " ${srcPath}
      ;;

    "--src-files")  

      # Replace commmas with spaces
      srcFiles=${VALUE//,/ }
      echo "Setting source files ----> " ${srcFiles}
      ;;

    "--test-path")  

      testPath=$VALUE
      echo "Setting path for test files ----> " ${testPath}
      ;;

    "--preprocess-fypp")  

      fyppPreprocess=true
      echo "Using FYPP pro-processing"
      ;;

    *) 

      echo "Option $PARAM not recognized!"
      echo "Type '${0} --help' for information on how to use the script"
      exit 1
      ;;

  esac
  shift
done

# If no name has been provided for the library, then use the project name
if [ -z "${libraryName}" ] ; then
  libraryName=${projectName}
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

printf '%s\n' "# CMake project file for ${projectName}" >> ${fileName} 
printf '%s\n\n' "cmake_minimum_required (VERSION ${cmakeVersion})" >> ${fileName}

if [ ! -z ${projectVersion} ] ; then
  printf '%s\n' "# Allows to set project version" >> ${fileName} 
  printf '%s\n' "cmake_policy(SET CMP0048 NEW)" >> ${fileName} 
  printf '%s\n\n' "project (${projectName} VERSION ${projectVersion})" >> ${fileName} 
else
  printf '%s\n\n' "project (${projectName})" >> ${fileName} 
fi

printf '%s\n' "# Which languages do we use" >> ${fileName} 
printf '%s\n\n' "enable_language (${languages})" >> ${fileName} 

printf '%s\n' "# Set the CMAKE_MODULE_PATH" >> ${fileName} 
printf '%s\n\n' "LIST (APPEND CMAKE_MODULE_PATH \$ENV{CMAKE_MACROS})" >> ${fileName} 

printf '%s\n' "# Set library name" >> ${fileName}
printf '%s\n\n' "set(LIBRARY_NAME ${libraryName})" >> ${fileName}

printf '%s\n' "# Include default flags for Fortran and C compiler" >> ${fileName}
printf '%s\n' "if ( NOT Fortran_FLAGS_ARE_SET )" >> ${fileName}
printf '%s\n' "  if ( CMAKE_Fortran_COMPILER_ID STREQUAL GNU )" >> ${fileName}
printf '%s\n' "    include( GNU_Fortran_Flags )" >> ${fileName}
printf '%s\n' "  elseif ( CMAKE_Fortran_COMPILER_ID STREQUAL Intel )" >> ${fileName}
printf '%s\n' "    include( Intel_Fortran_Flags )" >> ${fileName}
printf '%s\n' "  endif ( CMAKE_Fortran_COMPILER_ID STREQUAL GNU )" >> ${fileName}
printf '%s\n\n' "endif ( NOT Fortran_FLAGS_ARE_SET )" >> ${fileName}

printf '%s\n' "if ( NOT RPATH_CONFIG )" >> ${fileName}
printf '%s\n' "  include ( General_rpath_config ) " >> ${fileName}
printf '%s\n\n' "endif ( NOT RPATH_CONFIG )" >> ${fileName}

printf '%s\n' "# Whether you build a static or shared library" >> ${fileName}
printf '%s\n' "set(LIBRARY_TYPE SHARED)" >> ${fileName}
printf '%s\n' "if (CMAKE_LIBRARY_TYPE)" >> ${fileName}
printf '%s\n' "  set(LIBRARY_TYPE \${CMAKE_LIBRARY_TYPE})" >> ${fileName}
printf '%s\n\n' "endif (CMAKE_LIBRARY_TYPE)" >> ${fileName}

printf '%s\n' "if (\${LIBRARY_TYPE} STREQUAL \"STATIC\")" >> ${fileName}
printf '%s\n' "  set (CMAKE_LIBRARY_PREFIX \${CMAKE_STATIC_LIBRARY_PREFIX} CACHE INTERNAL \"Prefix for CMake libraries\")" >> ${fileName}
printf '%s\n' "  set (CMAKE_LIBRARY_SUFFIX \${CMAKE_STATIC_LIBRARY_SUFFIX} CACHE INTERNAL \"Suffix for CMake libraries\")" >> ${fileName}
printf '%s\n' "elseif (\${LIBRARY_TYPE} STREQUAL \"SHARED\")" >> ${fileName}
printf '%s\n' "  set (CMAKE_LIBRARY_PREFIX \${CMAKE_SHARED_LIBRARY_PREFIX} CACHE INTERNAL \"Prefix for CMake libraries\")" >> ${fileName}
printf '%s\n' "  set (CMAKE_LIBRARY_SUFFIX \${CMAKE_SHARED_LIBRARY_SUFFIX} CACHE INTERNAL \"Suffix for CMake libraries\")" >> ${fileName}
printf '%s\n\n' "endif (\${LIBRARY_TYPE} STREQUAL \"STATIC\")" >> ${fileName}

printf '%s\n' "# Library installation directory" >> ${fileName}
printf '%s\n\n' "set (CMAKE_LIBDIR \${CMAKE_INSTALL_PREFIX}/lib)" >> ${fileName}

printf '%s\n' "# Header files installation directory" >> ${fileName}
printf '%s\n\n' "set (CMAKE_INCLUDEDIR \${CMAKE_INSTALL_PREFIX}/include/${libraryName})" >> ${fileName}

printf '%s\n' "# Binary files installation directory" >> ${fileName}
printf '%s\n\n' "set (CMAKE_BINDIR \${CMAKE_INSTALL_PREFIX}/bin)" >> ${fileName}

printf '%s\n' "# Set installation directory for *mod files" >> ${fileName}
printf '%s\n\n' "set(CMAKE_Fortran_MODULE_DIRECTORY \${CMAKE_BINARY_DIR}/mod_files)" >> ${fileName}

printf '%s\n' "# Pre-processing of source files (e.g. with fypp or C preprocessor)" >> ${fileName}

if [ "${fyppPreprocess}" = true ] ; then

  printf '%s\n' "# Find all *fpp files " >> ${fileName}
  printf '%s\n%s\n' "FILE(GLOB fppFiles RELATIVE \${CMAKE_CURRENT_SOURCE_DIR}" "\"${CMAKE_CURRENT_SOURCE_DIR}/src/*.fpp\")" >> ${fileName}

  printf '%s\n\n' "# Pre-process files" >> ${fileName}
  printf '%s\n\n' "FOREACH(infileName \${fppFiles}) " >> ${fileName}

  printf '%s\n' "    # Generate output file name " >> ${fileName}
  printf '%s\n\n' "    STRING(REGEX REPLACE \".fpp\\\$\" \".f90\" outfileName \"${infileName}\") " >> ${fileName}

  printf '%s\n\n' "    SET(outfile \${CMAKE_CURRENT_BINARY_DIR}/\${outfileName}) " >> ${fileName}

  printf '%s\n' "    # Generate input file name " >> ${fileName}
  printf '%s\n\n' "    SET(infile \${CMAKE_CURRENT_SOURCE_DIR}/${infileName}) " >> ${fileName}

  printf '%s\n' "    # Custom command to do the processing " >> ${fileName}
  printf '%s\n' "    ADD_CUSTOM_COMMAND( " >> ${fileName}
  printf '%s\n' "        OUTPUT \${outfile} " >> ${fileName}
  printf '%s\n' "        COMMAND fypp \${infile} \${outfile} -l 100 -f smart " >> ${fileName}
  printf '%s\n' "        MAIN_DEPENDENCY \${infile} " >> ${fileName}
  printf '%s\n' "        VERBATIM " >> ${fileName}
  printf '%s\n\n' "        ) " >> ${fileName}

  printf '%s\n' "    # Finally remember the output file for dependencies " >> ${fileName}
  printf '%s\n\n' "    SET(outFiles \${outFiles} \${outfile}) " >> ${fileName}

  printf '%s\n' "ENDFOREACH(infileName) " >> ${fileName}
      
fi

if [ ! -z $srcPath ] ; then
  srcPath=\${CMAKE_CURRENT_SOURCE_DIR}/$srcPath
else
  srcPath=\${CMAKE_CURRENT_SOURCE_DIR}
fi

printf '%s\n' "# Source files used to build the library" >> ${fileName}
printf '%s\n' "FILE(GLOB SRC_FILES RELATIVE \${CMAKE_CURRENT_SOURCE_DIR}" >> ${fileName}

if [ ! -z "$srcFiles" ] ; then
  printf '%s' "  $srcFiles" >> ${fileName}
else
  declare -a tmp=($languages)
  for lang in "${tmp[@]}" ; do
    if [ "$lang" = "Fortran" ] ; then
      printf '%s' "  $srcPath/*.f90 $srcPath/*.F90" >> ${fileName}
    fi
    if [ "$lang" = "C" ] ; then
      printf '%s' "  $srcPath/*.c" >> ${fileName}
    fi
    if [ "$lang" = "C++" ] ; then
      printf '%s' "  $srcPath/*.c $srcPath/*.cpp" >> ${fileName}
    fi
  done
fi
printf '%s\n\n' ")" >> ${fileName}

if [ "${fyppPreprocess}" = true ] ; then
  printf '%s\n' "set (SRC_FILES \${SRC_FILES} \${outFiles})" >> ${fileName}
fi

printf '%s\n' "# Command to build the library" >> ${fileName}
printf '%s\n' "add_library(" >> ${fileName}
printf '%s\n' "  \${LIBRARY_NAME}" >> ${fileName}
printf '%s\n' "  \${LIBRARY_TYPE} " >> ${fileName}
printf '%s\n' "  \${SRC_FILES}" >> ${fileName}
printf '%s\n\n' ")" >> ${fileName}

# Dependencies

if [ ! -z "${dependencies}" ] ; then

  printf '%s\n' '# Write name of the dependencies, library name, and name of one of the header ' >> ${fileName}
  printf '%s\n' '# files that you should find, using as a separator the "%" sign ' >> ${fileName}
  printf '%s\n\n' "set (depend_names ${dependencies})" >> ${fileName}

  printf '%s\n\n' 'foreach (tmp ${depend_names}) ' >> ${fileName}

  printf '%s\n' '  # Parse element from above "depend_names" list, converting each element into ' >> ${fileName}
  printf '%s\n' '  # a string, i.e. replacing all instances of "%" with ";" (which, in cmake, ' >> ${fileName}
  printf '%s\n' '  # separate the list elements) ' >> ${fileName}
  printf '%s\n\n' '  string(REPLACE "%" ";" tmp_list ${tmp}) ' >> ${fileName}

  printf '%s\n' '  # Get each element from the list into different variables ' >> ${fileName}
  printf '%s\n' '  list(GET tmp_list 0 tmp_name) ' >> ${fileName}
  printf '%s\n' '  list(GET tmp_list 1 tmp_lib) ' >> ${fileName}
  printf '%s\n\n' '  list(GET tmp_list 2 tmp_head) ' >> ${fileName}

  printf '%s\n' '  # Try to find the above libraries ' >> ${fileName}
  printf '%s\n' '  libfind_detect (${tmp_name}  ' >> ${fileName}
  printf '%s\n' '    FIND_PATH ${tmp_head} INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/include/${tmp_lib}  ' >> ${fileName}
  printf '%s\n' '    FIND_LIBRARY ${tmp_lib} LIBRARY_DIRS ${CMAKE_INSTALL_PREFIX}/lib  ' >> ${fileName}
  printf '%s\n\n' '    NO_DEFAULT_PATH ${CMAKE_NO_DEFAULT_PATH}) ' >> ${fileName}

  printf '%s\n' '  # If the library cannot be found, add the compilation instructions ' >> ${fileName}
  printf '%s\n' '  if (NOT ${tmp_name}_FOUND) ' >> ${fileName}
  printf '%s\n' '    include(External_${tmp_name}) ' >> ${fileName}
  printf '%s\n' '    add_dependencies (${LIBRARY_NAME} EXT_${tmp_name}) ' >> ${fileName}
  printf '%s\n\n' '  endif (NOT ${tmp_name}_FOUND) ' >> ${fileName}

  printf '%s\n' '  # Finally, add the current library to the list containinig the include ' >> ${fileName}
  printf '%s\n' '  # folder, libraries folder, and libraries name ' >> ${fileName}
  printf '%s\n' '  set(include_directories_list ${include_directories_list} "${${tmp_name}_INCLUDE_DIR}") ' >> ${fileName}
  printf '%s\n' '  set(link_directories_list ${link_directories_list} "${${tmp_name}_LIBRARIES_DIR}") ' >> ${fileName}
  printf '%s\n\n' '  set(target_link_libraries_list ${target_link_libraries_list} "${${tmp_name}_LIBRARIES}") ' >> ${fileName}

  printf '%s\n\n' 'endforeach(tmp) ' >> ${fileName}

  printf '%s\n' '# Location of include directories, i.e. of the directories containing the *.h ' >> ${fileName}
  printf '%s\n' '# and *.mod files  ' >> ${fileName}
  printf '%s\n\n' 'include_directories(${include_directories_list}) ' >> ${fileName}

  printf '%s\n' '# Location of the libraries ' >> ${fileName}
  printf '%s\n\n' 'link_directories(${link_directories_list}) ' >> ${fileName}

  printf '%s\n' '# Link the library ' >> ${fileName}
  printf '%s\n\n' 'target_link_libraries (${LIBRARY_NAME} ${target_link_libraries_list}) ' >> ${fileName}

fi


printf '%s\n' "# install library" >> ${fileName}
printf '%s\n' "install(" >> ${fileName}
printf '%s\n' "  TARGETS \${LIBRARY_NAME} " >> ${fileName}
printf '%s\n' "  ARCHIVE DESTINATION \${CMAKE_LIBDIR}" >> ${fileName}
printf '%s\n' "  LIBRARY DESTINATION \${CMAKE_LIBDIR}" >> ${fileName}
printf '%s\n\n' ")" >> ${fileName}

printf '%s\n' "# install header (*mod) files" >> ${fileName}
printf '%s\n' "install(" >> ${fileName}
printf '%s\n' "  DIRECTORY \${CMAKE_Fortran_MODULE_DIRECTORY}/ " >> ${fileName}
printf '%s\n' "  DESTINATION \${CMAKE_INCLUDEDIR}" >> ${fileName}
printf '%s\n\n' ")" >> ${fileName}


printf '%s\n' "# configure a number version file to pass some of the CMake settings" >> ${fileName}
printf '%s\n' "# to the source code" >> ${fileName}
printf '%s\n' "configure_file(" >> ${fileName}
printf '%s\n' "  \$ENV{CMAKE_MACROS}/pkg-config.pc.cmake" >> ${fileName}
printf '%s\n' "  \${CMAKE_CURRENT_SOURCE_DIR}/\${LIBRARY_NAME}.pc" >> ${fileName}
printf '%s\n' "  @ONLY" >> ${fileName}
printf '%s\n\n' ")" >> ${fileName}

printf '%s\n' "# install configuration file" >> ${fileName}
printf '%s\n' "install(" >> ${fileName}
printf '%s\n' "  FILES \${CMAKE_CURRENT_SOURCE_DIR}/\${LIBRARY_NAME}.pc" >> ${fileName}
printf '%s\n' "  DESTINATION \${CMAKE_LIBDIR}/pkgconfig" >> ${fileName}
printf '%s\n\n' "  )" >> ${fileName}

if [ ! -z "${GNUfortranFlags}" ] ; then
  printf '%s\n' "if ( CMAKE_Fortran_COMPILER_ID STREQUAL GNU ) " >> ${fileName}
  printf '%s\n' "  set (Fortran_FLAGS \"-fno-range-check\")" >> ${fileName}
  printf '%s\n\n' "endif ( CMAKE_Fortran_COMPILER_ID STREQUAL GNU )"  >> ${fileName}
fi

printf '%s\n' "set_target_properties(" >> ${fileName}
printf '%s\n' "  \${LIBRARY_NAME}" >> ${fileName}
printf '%s\n' "  PROPERTIES COMPILE_FLAGS \"\${Fortran_FLAGS} \${CMAKE_Fortran_COMPILER_FLAGS}\"" >> ${fileName}
printf '%s\n\n' "  )" >> ${fileName}

up=$(echo ${libraryName} | awk '{print toupper($0)}')
printf '%s\n' "set ( ${up}_INCLUDE_DIR \"\${CMAKE_INCLUDEDIR}\" CACHE INTERNAL \"${libraryName} include directory\" )" >> ${fileName}
printf '%s\n' "set ( ${up}_LIBRARIES_DIR \"\${CMAKE_LIBDIR}\" CACHE INTERNAL \"${libraryName} library directory\" )" >> ${fileName}
printf '%s\n' "set ( ${up}_LIBRARIES \"\${LIBRARY_NAME}\" CACHE INTERNAL \"${libraryName} library\" )" >> ${fileName}
