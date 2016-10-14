#!/bin/bash


git_success() {

  if [[ ! $1 -eq 0 ]] ; then
    echo ""
    echo "Problem with git commands... aborting the automatic build"
    echo ""
    exit 1
  fi

}

# Function to build Beagle from its repository
build_beagle() {

  # Clean the installation folders from Beagle, astrofortran, and mcfor libraries
  rm $1/lib/*astrofortran* $1/lib/*mcfor*
  rm -rf $1/include/astrofortran $1/include/mcfor $1/include/BEAGLE

  # Start by updating the mcfor and astrofortran repos
  repos=( astrofortran mcfor BEAGLE )
  for repo in "${repos[@]}" ; do
    if [ -d "${repoDir}/${repo}" ] ; then
      cd ${repoDir}/${repo}
      git fetch --tags
      git_success $?

      git pull origin master
      git_success $?
    else
      # Clone the Beagle GitHub repo
      GIT_SSH_COMMAND=${GIT_SSH_COMMAND} git clone git@${gitHub}:jacopo-chevallard/BEAGLE.git "${repoDir}/${repo}"
      git_success $?
      cd ${repoDir}/${repo}
    fi

    # At this point we are inside the repo, and the repo is updated wrt remote
    if [ -d "build" ]; then
      rm -rf build
    fi
    mkdir build ; cd build 
    cmake -DCMAKE_INSTALL_PREFIX=$1 $2 ..
    make ; make install
  done

}


####################################################################
####################################################################
####################################################################

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

#
gitHub="github"
BEAGLE_exec="BEAGLE"
#gitHub="github.com"

# Firstly, check if Beagle is running on any of the cluster machines, in which
# case **do not** run the script

if qhost -j | grep -w -q $BEAGLE_exec ; then
  echo "$BEAGLE_exec is running, so the nightly build will be skipped for tonight!"
  exit 0
else
  echo "$BEAGLE_exec is *not* running, continuing with the nightly build!"
fi


GIT_SSH_COMMAND="ssh -i ~/.ssh/id_beagle_machine -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# default values for input arguments
repoDir=""
cmakeFlags=""
installDir=""

# array containing mandatory arguments
declare -a mandatoryArgs=(repoDir installDir)

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

# Clone/update the public repositories
repos=( cmake-macros cmake-dependencies )
for repo in "${repos[@]}" ; do
  # If the needed repositories don't exist, clone them!
  if [ ! -d "${repoDir}/${repo}" ]; then
    GIT_SSH_COMMAND=${GIT_SSH_COMMAND} git clone git@${gitHub}:jacopo-chevallard/${repo}.git "${repoDir}/${repo}"
    git_success $?
  else
    cd "${repoDir}/${repo}"
    git pull origin master
    git_success $?
  fi
done
export CMAKE_MACROS="${repoDir}/cmake-macros"
export CMAKE_DEPENDENCIES="${repoDir}/cmake-dependencies"

# Check if the folder containing the Beagle repository exists, in which case move to it and pull the latest master
if [ -d "${repoDir}/BEAGLE" ] ; then
  cd ${repoDir}/BEAGLE
  git fetch --tags
  git_success $?
  git pull origin master
  git_success $?
else
  # Check if the SSH key allowing the access to the beagle-machine profile exists
  if [ ! -f "~/.ssh/id_beagle_machine" ]; then
    echo "SSH key for the beagle-machine GitHub account not found!"
    exit 1
  fi
  # Clone the Beagle GitHub repo
  GIT_SSH_COMMAND=${GIT_SSH_COMMAND} git clone git@${gitHub}:jacopo-chevallard/BEAGLE.git "${repoDir}/BEAGLE"
  git_success $?
  cd ${repoDir}/BEAGLE
fi

# Get latest tag in Beagle repo, checking all branches
TAG=$(git describe --tags `git rev-list --tags --max-count=1`)

# Get version of currently installed version of Beagle
if hash ${installDir}/bin/${BEAGLE_exec} 2>/dev/null; then
  INSTALL_TAG=$(${installDir}/bin/${BEAGLE_exec} --version | head -n 1 | awk '{print $3}')
else
  INSTALL_TAG=0.0.0
fi

# Get latest tag in remote repo
# see https://addhewarman.com/tag/how-to-get-latest-tag-from-github-remote/ and http://stackoverflow.com/a/4495368
#git fetch
#REMOTE_TAG=$(git ls-remote --tags  | awk '{print $2}' | grep -v '{}' | awk -F"/" '{print $3}' | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -n 1)

echo Latest tag: $TAG
echo Installed version: $INSTALL_TAG

#echo Remote tag: $REMOTE_TAG 

# compare the two tags
i=$(version_compare $TAG $INSTALL_TAG)
if [ $i == 0 ] ; then
  echo The local and remote tag coincide. No action will be taken.
elif [ $i == 1 ] ; then
  echo The remote tag appears newer then the local one. 
  echo Updating the local repository and building the package.
  build_beagle ${installDir} ${cmakeFlags}
elif [ $i == -1 ] ; then
  echo The local tag appears newer than the remote one... strange!
fi
