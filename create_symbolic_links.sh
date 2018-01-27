#!/bin/bash


confirm () {
  # call with a prompt string or use a default
  read -r -p "$1 " response
  case $response in
      [yY]) 
          true
          ;;
      *)
          false
          ;;
  esac
}

display_usage() { 
	echo "\nDescription:\n\n"
	echo "\nUsage:\n$0 "
	echo "\nExample:\n$0 \n" 
	} 

# default values for input arguments
ignore=false

# array containing mandatory arguments
#declare -a mandatoryArgs=(repoDir installDir)

# now read and parse the input arguments, some have options, others don't
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{ st = index($0,"=");print substr($0,st+1)}'`
  case $PARAM in

    "-h"|"--help")  

      display_usage
      exit 1
      ;;

    "-i"|"--ignore")  

      ignore=true
      echo "Existing files will be ignored, i.e. they will *not* be symlinked again *nor* removed"
      ;;

    *) 

      echo "Option $PARAM not recognized!"
      echo "Type '${0} --help' for information on how to use the script"
      exit 1
      ;;

  esac
  shift
done


dir=$(pwd)

# Check if $HOME/bin directory exists
if [ ! -d "~/bin" ] ; then
  mkdir ~/bin
fi

for file in bin/*; do 
  file_name=$(basename "$file")
  new_file=$dir/bin/$file_name
  local_file=$HOME/bin/$file_name
  if [ -f $local_file ] ; then
    if [ "$ignore" = false ] ; then
      echo ''
      echo WARNING: The $local_file file already exists.
      confirm 'Are you sure you want to replace it? (y/n)' && rm $local_file
    fi
  fi
  if [ ! -f $local_file ] ; then
    echo Creating symbolic link of $new_file
    ln -sf $new_file $local_file
  fi
done

# Check if directories exist
files=( .vim .zprezto .tmux )
for file in "${files[@]}"; do 
  local_file=~/$file
  new_file=$dir/$file
  if [ -d $local_file ] ; then
    if [ "$ignore" = false ] ; then
      echo ''
      echo WARNING: The $local_file directory already exists.
      confirm 'Are you sure you want to replace it? (y/n)' && rm -rf $local_file
    fi
  fi
  if [ ! -d $local_file ] ; then
    ln -s $new_file $local_file
  fi
done

# Check if files exist
files=( .vimrc .zshrc.local .matplotlib/matplotlibrc .tmux.conf .git-flow-completion.zsh )
for file in "${files[@]}"; do 
  local_file=~/$file
  new_file=$dir/$file
  if [ -f $local_file ] ; then
    if [ "$ignore" = false ] ; then
      echo ''
      echo WARNING: The $local_file file already exists.
      confirm 'Are you sure you want to replace it? (y/n)' && rm $local_file
    fi
  fi
  if [ ! -f $local_file ] ; then
    ln -s $new_file $local_file
  fi
done
