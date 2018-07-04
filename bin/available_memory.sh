#!/bin/bash

if hash free 2>/dev/null; then
  # For Unix systems use lscpu
  free -h
else
  # For Mac OS X use vm_stat
  vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-20s % 16.2f GB\n", "Memory $1:", $2 * $size / 1000000000);' | head -n 7
fi

