#! /bin/bash

temp_file="autocompletion.txt"
execut="genzshcomp"
folder="zsh_autocompletion"

if ! hash ${execut} 2>/dev/null; then
  echo "The command '${execut}' is not available on this machine!"
  exit 1
fi

mkdir -p ${folder}
path=`pwd`

for f in *.py; do 
  if [ -f ${temp_file} ]; then
    \rm ${temp_file}
  fi
  ./$f --help > ${temp_file}
  ret=$?
  if [ $ret -eq 0 ]; then
    ${execut} ${temp_file} > ${folder}/_${f}
    ln -s -f ${path}/${folder}/_${f} ~/.zprezto/modules/completion/external/src/_${f}
  fi
done

\rm -f ~/.zcompdump
compinit
