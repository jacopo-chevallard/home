#!/bin/bash

set -euo pipefail

FILE_ELF="$1"
DIR_CONTAINER="$2"

# Create the container directory if it does not exist
mkdir -p "$DIR_CONTAINER"

# Collect libraries
mapfile -t libs < <(ldd "$FILE_ELF" | grep '=>' | awk '{print $3}' | xargs realpath || true)
libs+=($(readelf -l "$FILE_ELF" 2>/dev/null | grep -Po "(?<=preter:\\s).+(?=\\])" || true))

# Filter out invalid or non-existent paths
valid_libs=()
for l in "${libs[@]}"; do
    if [[ -n "$l" && -e "$l" ]]; then
        valid_libs+=("$l")
    fi
done

# Copy libraries to the container directory
for l in "${valid_libs[@]}"; do
    mkdir -p "${DIR_CONTAINER}/$(dirname ${l})"
    cp -L "$l" "${DIR_CONTAINER}/${l}"
done
