#!/bin/bash

######################################################
### Begin - Variable Inheritance from Args Section ###
######################################################

#Ensure nothing happens outside the directory this script is ran from
cd "$(dirname "$0")"
export SCRIPT_DIRECTORY=$(pwd)

ARGS_FILE="$SCRIPT_DIRECTORY/args.sh"
ARGS_PRIVATE_FILE="$SCRIPT_DIRECTORY/args_private.sh"

function pathExists()
{
    PATH_TO_CHECK="$1"

    ls -alh "$PATH_TO_CHECK" > /dev/null 2>&1

    EXIT_CODE=$?

    if [ "$EXIT_CODE" == "0" ]; then
        echo "TRUE"
    else
        echo "FALSE"
    fi
}

ARGS_FILE_EXISTS=$(pathExists "$ARGS_FILE")

if [ "$ARGS_FILE_EXISTS" == "TRUE" ]; then
    echo "[INFO] ARGS_FILE - Overriding Default Variables from $ARGS_FILE ... "
    chmod 700 "$ARGS_FILE"
    source "$ARGS_FILE"
else
    echo "[ERROR] ARGS_FILE - Args File not detected - Exitting ..."
    echo "[ERROR] Read the README.md!"
    exit 1
fi

ARGS_PRIVATE_FILE_EXISTS=$(pathExists "$ARGS_PRIVATE_FILE")

if [ "$ARGS_PRIVATE_FILE_EXISTS" == "TRUE" ]; then
    echo "[INFO] ARGS_PRIVATE_FILE - Overriding Default Variables from $ARGS_PRIVATE_FILE ... "
    chmod 700 "$ARGS_PRIVATE_FILE"
    source "$ARGS_PRIVATE_FILE"
else
    echo "[ERROR] ARGS_PRIVATE_FILE - Args File not detected - Exitting ..."
    echo "[ERROR] Read the README.md!"
    exit 1
fi

####################################################
### End - Variable Inheritance from Args Section ###
####################################################

# Variable inherited from args.sh or args_private.sh
# REPOSITORY_CHECKOUT_DIRECTORY="$SCRIPT_DIRECTORY/../"
# DATABASE_DUMP_DIRECTORY="$SCRIPT_DIRECTORY/Database_Files"
# TARGET_SYM_LINK_DIRECTORY="/var/www/html"
# DIRECTORY_WWW="/var/www/html"

function main()
{
    # sudo npm install pm2 -g
    pm2 delete all
    find "/home/$USER/.pm2/logs" -name "*.log" | xargs truncate -s 0
    
    # If you use directories like Staging or Production works - use this one
    # DIRECTORIES_TO_PM2_SETUP=$(find "$DIRECTORY_WWW" -maxdepth 1 -type f) 
    
    # If you use symbolic links instead of hosting the files at the directory - use this one
    DIRECTORIES_TO_PM2_SETUP=$(find "$DIRECTORY_WWW" -maxdepth 1 -type l) 

    EXIT_CODE=$?

    if [ "$EXIT_CODE" == "0" ]; then
        echo "Found the Following $PATTERN_TO_SEARCH_FOR Directories:"
        echo $DIRECTORIES_TO_PM2_SETUP

        #Spaces in a String will mess up a for loop - https://askubuntu.com/questions/344407/how-to-read-complete-line-in-for-loop-with-spaces
        IFS=$'\n'

        for DIRECTORY_TO_PM2 in $DIRECTORIES_TO_PM2_SETUP
        do
            DIRECTORY_TO_PM2_FOLDER_ONLY=$(getSourceDirectoryName_withoutFullPath "$DIRECTORY_TO_PM2")
            DIRECTORY_TO_PM2_FOLDER_ONLY_UPPER=${DIRECTORY_TO_PM2_FOLDER_ONLY^^}

            BOOLEAN_IS_BLACKLISTED=$(checkIfInBlackList "$DIRECTORY_TO_PM2_FOLDER_ONLY_UPPER")

            if [ "$BOOLEAN_IS_BLACKLISTED" == "FALSE" ]; then
                setupPM2 "$DIRECTORY_TO_PM2"
            fi
        done

        #Turn it off after - https://askubuntu.com/questions/344407/how-to-read-complete-line-in-for-loop-with-spaces
        unset IFS
    else
        echo "[ERROR] There was a problem locating the $PATTERN_TO_SEARCH_FOR Build Projects!"
    fi

    pm2 save
    pm2 status
    # echo "[INFO] Sleeping for 5 seconds before beginning to tail the logs..."
    # sleep 5
    # find "/home/$USER/.pm2/logs" -name "*.log" | xargs tail -f -n+1
}

function debugString() { echo "$@" 1>&2; }

function checkIfInBlackList()
{
    ENTRY_TO_CHECK="$1"
    BOOLEAN_IS_BLACKLISTED="FALSE"

    debugString "[INFO] [BLACKLIST] Checking if $ENTRY_TO_CHECK is blacklisted..."

    for BLACKLISTED_STRING in "${VARIABLE_PM2_BLACKLIST[@]}"
    do
        ENTRY_TO_CHECK_UPPER=${ENTRY_TO_CHECK^^}
        BLACKLISTED_STRING_UPPER=${BLACKLISTED_STRING^^}

        # debugString "[INFO] [BLACKLIST] Comparing $ENTRY_TO_CHECK_UPPER to $BLACKLISTED_STRING_UPPER"

        if [[ "$ENTRY_TO_CHECK_UPPER" == *"$BLACKLISTED_STRING_UPPER"* ]]; then
            debugString "[INFO] [BLACKLIST] Match found! $ENTRY_TO_CHECK_UPPER has $BLACKLISTED_STRING_UPPER in it."
            BOOLEAN_IS_BLACKLISTED="TRUE"
            break;
        fi
    done 

    debugString "[INFO] [BLACKLIST] BOOLEAN_IS_BLACKLISTED is $BOOLEAN_IS_BLACKLISTED"

    echo "$BOOLEAN_IS_BLACKLISTED"
}

function misc_findReplace_standardInput()
{
    VARIABLE_FIND="$1"
    VARIABLE_REPLACE="$2"
    VARIABLE_STRING="$3"
    echo "$VARIABLE_STRING" | sed --expression "s|${VARIABLE_FIND}|${VARIABLE_REPLACE}|g"
}

function getSourceDirectoryName_withoutFullPath()
{
    DIRECTORY_TO_SYM_LINK="$1"
    DIRECTORY_TO_SYM_LINK_WITHOUT_FULL_PATH=$(basename -- "$DIRECTORY_TO_SYM_LINK")
    echo "$DIRECTORY_TO_SYM_LINK_WITHOUT_FULL_PATH"
}

function setupPM2()
{
    DIRECTORY_TO_PM2="$1"
    DIRECTORY_TO_PM2_WITHOUT_FULL_PATH=$(getSourceDirectoryName_withoutFullPath "$DIRECTORY_TO_PM2")

    cd "$DIRECTORY_TO_PM2"

    PM2_Name="$DIRECTORY_TO_PM2_WITHOUT_FULL_PATH-SpecialCommand"
    pm2 start "app.php" --name "$PM2_Name" -- "app:special-command" > /dev/null 2>&1

    if [ "$DIRECTORY_TO_PM2_WITHOUT_FULL_PATH" == "SpecialProject" ]
    then
        PM2_Name="$DIRECTORY_TO_PM2_WITHOUT_FULL_PATH-SpecialProgram"
        pm2 start "app.php" --max-memory-restart 512M --name "$PM2_Name" -- "app:special-command-2"
    fi

    # pm2 describe "$PM2_Name"
}

main