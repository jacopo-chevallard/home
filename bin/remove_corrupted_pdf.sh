#!/bin/bash

find . -iname '*.pdf' | while read -r f
do
  if pdftotext "$f" &> /dev/null; then 
    :
  else
    #mv "$f" "$f.broken";
    echo "$f" is broken and will be removed
    rm "${f}"    
  fi; 
done

