# Description: Invoked by LFS_Git_Integration.yaml action when a file has been edited.
#
# This results in the update of the existing .lfs file with the appending of the issue body.

echo UPDATE Git LFS file: $FILE_PATH

MAX_RETRIES=5
RETRY_COUNT=0

#read the issue body from disk
ISSUE_BODY=$(< "$BODY_FILE")
FILE_NAME="$FILE_PATH.lfs"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do

    echo "$ISSUE_BODY" >> $FILE_NAME
    echo "" >> $FILE_NAME

    # Add, commit, and push the file to the repository
    git add $FILE_NAME 
    git commit -m "Updating LFS file - fixes #$ISSUE_NUMBER"
    git push origin HEAD

    if [ $? -ne 0 ]; then
       RETRY_DELAY=$((RANDOM % 16 + 10))  # Random delay between 10 and 25 seconds
        echo "ERROR: MOVE Failed to push changes. Retrying in $RETRY_DELAY seconds..."
        ((RETRY_COUNT++))
        sleep $RETRY_DELAY
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then 
            echo "ERROR: MOVE Unable to push changes after $MAX_RETRIES "
            exit 1
        fi
        
        #undo the changes and pull 
        git reset HEAD~1
        git reset $FILE_PATH
        git pull 

    else
        echo "UPDATE Successfully committed and pushed lfs file"
        exit 0
    fi
end