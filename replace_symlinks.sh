#!/bin/bash

# Function to print usage
print_usage() {
    echo "Usage: $0 [-n] directory"
    echo "Options:"
    echo "  -n    Dry run (don't make any changes)"
    exit 1
}

# Function to replace symbolic links with hard links
replace_symlinks() {
    local directory="$1"
    local dry_run="$2"

    find "$directory" -type l | while read -r symlink; do
        # Get the target of the symbolic link (resolved path)
        target=$(readlink -f "$symlink")
        
        # Check if target exists
        if [ -e "$target" ]; then
            if [ "$dry_run" = true ]; then
                echo "Would replace symlink: $symlink -> $target"
            else
                # Remove the symbolic link
                rm "$symlink"
                
                # Create a hard link
                ln "$target" "$symlink"
                
                echo "Replaced symlink: $symlink -> $target"
            fi
        else
            echo "Warning: Target does not exist for $symlink -> $target"
        fi
    done
}

# Parse command line options
dry_run=false
while getopts "n" opt; do
    case $opt in
        n)
            dry_run=true
            ;;
        \?)
            print_usage
            ;;
    esac
done

# Shift the options out of the argument list
shift $((OPTIND-1))

# Check if directory argument is provided
if [ "$#" -ne 1 ]; then
    print_usage
fi

# Check if directory exists
if [ ! -d "$1" ]; then
    echo "Error: Directory '$1' does not exist"
    exit 1
fi

# Run the replacement function
if [ "$dry_run" = true ]; then
    echo "Performing dry run (no changes will be made)..."
fi

replace_symlinks "$1" "$dry_run"
