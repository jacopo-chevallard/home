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
    echo ''
    echo WARNING: The $local_file file already exists.
    confirm 'Are you sure you want to replace it? (y/n)' && rm $local_file
  fi
  if [ ! -f $local_file ] ; then
    echo Creating symbolic link of $new_file
    ln -sf $new_file $local_file
  fi
done

# Check if directories exist
files=( .vim .zprezto )
for file in "${files[@]}"; do 
  local_file=~/$file
  new_file=$dir/$file
  if [ -d $local_file ] ; then
    echo ''
    echo WARNING: The $local_file directory already exists.
    confirm 'Are you sure you want to replace it? (y/n)' && rm -rf $local_file
  fi
  if [ ! -d $local_file ] ; then
    ln -s $new_file $local_file
  fi
done

# Check if files exist
files=( .vimrc .zshrc.local .matplotlib/matplotlibrc .tmux.conf )
for file in "${files[@]}"; do 
  local_file=~/$file
  new_file=$dir/$file
  if [ -f $local_file ] ; then
    echo ''
    echo WARNING: The $local_file file already exists.
    confirm 'Are you sure you want to replace it? (y/n)' && rm $local_file
  fi
  if [ ! -f $local_file ] ; then
    ln -s $new_file $local_file
  fi
done
