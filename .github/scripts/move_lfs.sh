# Description: Invoked by LFS_Git_Integration.yaml action when a file has been moved (or renamed). 
#
# This results in the creation of a .lfs file with the new name/path as well as the contents of 
# the old .lfs file. The old .lfs file is deleted. The .gitignore file is also updated by removing 
# the old file name and adding the new one.

echo MOVE Git LFS file: $FILE_PATH  from $PREVIOUS_PATH

MAX_RETRIES=5
RETRY_COUNT=0

DIR_PATH=$(dirname "$FILE_PATH")
IGNORE_NAME=$(echo "$ISSUE_TITLE" | grep -oP '(?<=:)[^\s]+') 
IGNORE_PATH="$DIR_PATH/.gitignore"

ORIGINAL_PATH="$PREVIOUS_PATH.lfs" #full path to lfs file to be removed
PREVIOUS_NAME=$(basename "$PREVIOUS_PATH") #file name that should be removed from .gitignore
PREVIOUS_DIR=$(dirname "$ORIGINAL_PATH")
PREVIOUS_IGNORE_PATH="$PREVIOUS_DIR/.gitignore" #.gitignore file to remove PREVIOUS_NAME from

ISSUE_BODY=$(< "$BODY_FILE")

# create the new counterpart .lfs file with the contents of the previous
# lfs file (preserving the file history)
FILE_NAME="$FILE_PATH.lfs"
echo "$FILE_NAME"
cp $ORIGINAL_PATH $FILE_NAME 
echo "$ISSUE_BODY" >> "$FILE_NAME"
echo "" >> "$FILE_NAME"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do

    # create temp.txt with the contents of the current .gitignore
    # minus the previous file name
    grep -v -w "$PREVIOUS_NAME" "$PREVIOUS_IGNORE_PATH" > temp.txt
    #then replace the current .gitignore with the temp file
    mv temp.txt "$PREVIOUS_IGNORE_PATH"

    # add the new file name to .gitignore (if not there already)
    if ! grep -qx "$IGNORE_NAME" "$IGNORE_PATH"; then
    echo "$IGNORE_NAME" >> "$IGNORE_PATH"
    fi

    #add, commit, and push the files to the repository
    git rm $ORIGINAL_PATH
    git add $IGNORE_PATH $FILE_NAME
    # .gitignore and previous could be the same so check before adding
    if [ $PREVIOUS_IGNORE_PATH != $IGNORE_PATH ]; then
        echo "FULL MOVE"
        git add $PREVIOUS_IGNORE_PATH
    fi
    git commit -m "Deleted LFS file & removed file from .gitignore - fixes #$ISSUE_NUMBER"
    git push origin HEAD

    # Check if push was successful
    if [ $? -ne 0 ]; then
        RETRY_DELAY=$((RANDOM % 16 + 10))  # Random delay between 10 and 25 seconds
        echo "ERROR: MOVE Failed to push changes. Retrying in $RETRY_DELAY seconds..."
        ((RETRY_COUNT++))
        sleep $RETRY_DELAY
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then 
            echo "ERROR: MOVE Unable to push changes after $MAX_RETRIES "
            exit 1
        fi
        
        #undo the .gitignore changes and pull any changes
        git reset HEAD~1
        git reset $IGNORE_PATH
        git reset $PREVIOUS_IGNORE_PATH
        git checkout $IGNORE_PATH
        git checkout $PREVIOUS_IGNORE_PATH
        git pull 

    else
        echo "MOVE Successfully committed and pushed lfs file"
        exit 0
    fi
done