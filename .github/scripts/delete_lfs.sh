# Description: Invoked by LFS_Git_Integration.yaml action when a file has been deleted. 
#
# This results in the deletion of the .lfs file. The file name is also removed from .gitignore.

echo DELETE Git LFS file: $FILE_PATH

MAX_RETRIES=5
RETRY_COUNT=0

DIR_PATH=$(dirname "$FILE_PATH")
IGNORE_NAME=$(echo "$ISSUE_TITLE" | grep -oP '(?<=:)[^\s]+') 
IGNORE_PATH="$DIR_PATH/.gitignore"




FILE_NAME="$FILE_PATH.lfs"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    
    # delete the counterpart .lfs file
    git rm $FILE_NAME 

    # remove the file name from .gitignore
    grep -v -w "$IGNORE_NAME" "$IGNORE_PATH" > temp.txt
    mv temp.txt "$IGNORE_PATH"
    
    git add $IGNORE_PATH
    git commit -m "Deleted LFS file & removed file from .gitignore - fixes #$ISSUE_NUMBER"
    git push origin HEAD

    # Check if push was successful
    if [ $? -ne 0 ]; then
        RETRY_DELAY=$((RANDOM % 16 + 10))  # Random delay between 10 and 25 seconds
        echo "ERROR: DELETE Failed to push changes. Retrying in $RETRY_DELAY seconds..."
        ((RETRY_COUNT++))
        sleep $RETRY_DELAY
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then 
            echo "ERROR: DELETE Unable to push changes after $MAX_RETRIES "
            exit 1
        fi

        # unstage the commit and checkout the .gitignore - necessary because an automerge
        # is not possible. 
        git reset HEAD~1
        git reset $IGNORE_PATH
        git checkout $IGNORE_PATH
        git pull 

    else
        echo "DELETE Successfully committed and pushed lfs file"
        exit 0
    fi
done

