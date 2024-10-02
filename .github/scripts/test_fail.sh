#!/bin/bash

touch testtouch

# Check the exit status of the last command (mkdir)
if [ $? -ne 0 ]; then
    echo "touch failed!"
    # Optionally, exit the script with a non-zero status
    exit 1
else
    echo "file touched successfully!"
fi

# Continue with other tasks
echo "Script is continuing..."
