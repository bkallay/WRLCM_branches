# Description: Invoked by LFS_Git_Integration.yaml action when a file has been created. 
#
# This results in the creation of a counterpart .lfs file with the contents of the issue body,
# which contains file metadata. The file name is also added to .gitignore.

echo CREATE Git LFS file: $FILE_PATH

MAX_RETRIES=5
RETRY_COUNT=0

#read the issue body from disk
ISSUE_BODY=$(< "$BODY_FILE")
DIR_PATH=$(dirname "$FILE_PATH")
IGNORE_NAME=$(echo "$ISSUE_TITLE" | grep -oP '(?<=:)[^\s]+') 
IGNORE_PATH="$DIR_PATH/.gitignore"

if [ ! -f "$IGNORE_PATH" ]; then
touch "$IGNORE_PATH"
fi

# Check if the file is already in .gitignore
if ! grep -qx "$IGNORE_NAME" "$IGNORE_PATH"; then
echo "$IGNORE_NAME" >> "$IGNORE_PATH"
fi

FILE_NAME="$FILE_PATH.lfs"
echo "$ISSUE_BODY" >> $FILE_NAME
echo "" >> $FILE_NAME

# this enables the custom merge driver that adds the last line of the local
# .gitignore file and adds it to the remote file
git config --global merge.custom-merge-driver.name "Custom Merge Driver"
git config --global merge.custom-merge-driver.driver ".github/scripts/merge_create_driver.sh %O %A %B %A"

git add $FILE_NAME $IGNORE_PATH
git commit -m "Add LFS file - fixes #$ISSUE_NUMBER"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Add, commit, and push the file to the repository
    git pull --rebase --no-edit
    git push origin HEAD

    # Check if push was successful
    if [ $? -ne 0 ]; then
        RETRY_DELAY=$((RANDOM % 16 + 10))  # Random delay between 10 and 25 seconds
        echo "ERROR: CREATE Failed to push changes. Retrying in $RETRY_DELAY seconds..."
        ((RETRY_COUNT++))
        sleep $RETRY_DELAY
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then 
            echo "ERROR: CREATE Unable to push changes after $MAX_RETRIES "
            exit 1
        fi
    else
        echo "CREATE Successfully committed and pushed lfs file"
        exit 0
    fi
done
