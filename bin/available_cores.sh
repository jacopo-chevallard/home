#!/bin/bash

if hash lscpu 2>/dev/null; then
  # For Unix systems use lscpu
  lscpu | grep -E '^Thread|^Core|^Socket|^CPU\('
else
  # For Mac OS X use sysctl
  sysctl hw | grep -E 'physicalcpu|logicalcpu'
fi

