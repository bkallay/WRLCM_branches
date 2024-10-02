#!/bin/bash
echo "CUSTOM MERGE DRIVER RUNNING..."
# Parameters provided by Git
BASE="$1"   # The common ancestor (base file), if available
LOCAL="$2"   # The local file
REMOTE="$3" # The remote file 
MERGED="$4" # The output file where the merged result should be saved

# Get the last line of the local file 
LAST_LINE=$(tail -n 1 "$REMOTE")
echo "$LAST_LINE"

# Use the remote file as the base
cp "$LOCAL" "$MERGED"

# Append the last line of the local file to the merged file
echo "$LAST_LINE" >> "$MERGED"

# Exit successfully
exit 0
