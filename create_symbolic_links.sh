#!/bin/bash

dir=$(pwd)

for file in bin/*; do 
  full_path=$dir/$file 
  file_name=$(basename "$file")
  echo Creating symbolic link of $full_path
  ln -s -f $full_path ~/bin/$file_name
done
