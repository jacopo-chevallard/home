#!/usr/bin/env bash

if hash xdg-open 2>/dev/null; then

  if [ $# -eq 0 ]; then
    xdg-open &> /dev/null
  else
    for file in "$@"; do
      xdg-open "$file" &> /dev/null
    done
  fi

else

  echo xdg-open does not exist on this machine

fi
