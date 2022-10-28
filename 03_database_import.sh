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

function main()
{
    # Test if the script works fine
    if [ "$TEST_MODE" == "TRUE" ]; then
        testScript
    fi

    PATTERN_TO_SEARCH_FOR=".git"


    # Only attempt to start mariadb if not test mode
    # if [ "$TEST_MODE" == "FALSE" ]; then
        # Start Maria DB Server
        # bash -c "sudo mysqld &" || exit 1
        # sleep 5
    # fi

    echo "[INFO] Parsing the DATABASE_DUMP_DIRECTORY located at $DATABASE_DUMP_DIRECTORY ..."
    DATABASE_DUMP_LIST=$(find "$DATABASE_DUMP_DIRECTORY" -maxdepth 1 -type f -iname "*.sql") 

    EXIT_CODE=$?

    if [ "$EXIT_CODE" == "0" ]; then
        echo "Found the Following Database Dumps:"
        echo $DATABASE_DUMP_LIST
    else
        echo "[ERROR] There was a problem locating the DATABASE_DUMP_DIRECTORY Dumps!"
    fi

    DIRECTORIES_TO_APPLY_MISC_COMMANDS_ON_LIST=$(find "$REPOSITORY_CHECKOUT_DIRECTORY" -maxdepth 2 -type d -iname "$PATTERN_TO_SEARCH_FOR") 

    EXIT_CODE=$?

    if [ "$EXIT_CODE" == "0" ]; then
        echo "Found the Following $PATTERN_TO_SEARCH_FOR Directories:"
        echo $DIRECTORIES_TO_APPLY_MISC_COMMANDS_ON_LIST

        #Spaces in a String will mess up a for loop - https://askubuntu.com/questions/344407/how-to-read-complete-line-in-for-loop-with-spaces
        IFS=$'\n'

        for DIRECTORY_TO_MATCH_TO_DATABASE_DUMP in $DIRECTORIES_TO_APPLY_MISC_COMMANDS_ON_LIST
        do
            DIRECTORY_TO_MATCH_TO_DATABASE_DUMP=$(misc_findReplace_standardInput "/$PATTERN_TO_SEARCH_FOR" "" "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP")
            DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY=$(getSourceDirectoryName_withoutFullPath "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP")
            DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY_UPPER=${DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY^^}

            ##########################################################
            ### BEGIN - RepoTools - Skip If Detected as This Entry ###
            ##########################################################

            VARIABLE_REPOTOOLS="RepoTools"
            VARIABLE_REPOTOOLS_UPPER=${VARIABLE_REPOTOOLS^^}

            if [[ "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY_UPPER" == "$VARIABLE_REPOTOOLS_UPPER" ]]; then
                continue
            fi

            ########################################################
            ### END - RepoTools - Skip If Detected as This Entry ###
            ########################################################

            # Attempt to find a matching dump file by this repo name and import it
            attemptToFindMatchingDumpAndImport "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP" "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY"
        done

        #Turn it off after - https://askubuntu.com/questions/344407/how-to-read-complete-line-in-for-loop-with-spaces
        unset IFS
    else
        echo "[ERROR] There was a problem locating the $PATTERN_TO_SEARCH_FOR Build Projects!"
    fi
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

function testScript()
{
    REPOSITORY_CHECKOUT_DIRECTORY="/c/Users/Cody/Repository/"
    DATABASE_DUMP_DIRECTORY="/c/Users/Cody/Repository//IDETool/Assets/database"
}

function attemptToFindMatchingDumpAndImport()
{
    DIRECTORY_TO_MATCH_TO_DATABASE_DUMP="$1" 
    DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY="$2"

    #Spaces in a String will mess up a for loop - https://askubuntu.com/questions/344407/how-to-read-complete-line-in-for-loop-with-spaces
    IFS=$'\n'

    for DATABASE_DUMP in $DATABASE_DUMP_LIST
    do
        DATABASE_DUMP_FILENAME_ONLY=$(misc_findReplace_standardInput ".sql" "" "$DATABASE_DUMP")
        DATABASE_DUMP_FILENAME_ONLY=$(getSourceDirectoryName_withoutFullPath "$DATABASE_DUMP_FILENAME_ONLY")
        DATABASE_DUMP_FILENAME_ONLY_UPPER=${DATABASE_DUMP_FILENAME_ONLY^^}

        # echo "[INFO] Comparing Database Dump $DATABASE_DUMP to Repository $DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY"

        DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY_UPPER=${DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY^^}

        if [[ "$DATABASE_DUMP_FILENAME_ONLY_UPPER" == *"$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY_UPPER"* ]]; then
            echo "[INFO] Match Found!"
            echo "[INFO] $DATABASE_DUMP_FILENAME_ONLY is equivalent to $DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY"

            # Only attempt to import dump if not test mode
            if [ "$TEST_MODE" == "FALSE" ]; then
                
                if [ "$DROP_DATABASE" == "TRUE" ]; then
                    # Drop the Database Schema - If it doesn't exist
                    echo "DROP DATABASE IF EXISTS \`$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY\`" | sudo mysql -u root
                fi

                if [ "$CREATE_DATABASE" == "TRUE" ]; then
                    # Create the Database Schema - If it doesn't exist
                    echo "CREATE DATABASE IF NOT EXISTS \`$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY\` \
                          CHARACTER SET utf8mb4 \
                          COLLATE utf8mb4_unicode_ci" | sudo mysql -u root || exit 1
                fi

                if [ "$TRUNCATE_DATABASE" == "TRUE" ]; then
                    # Truncate All the Tables
                    echo "[INFO] Truncating all the tables located under $DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY ..."
                    sudo mysql -u root -Nse 'show tables' "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY" | while read table; do mysql -e "SET FOREIGN_KEY_CHECKS = 0; truncate table $table; SET FOREIGN_KEY_CHECKS = 1;" "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY"; done
                fi                

                # Import the Database Dump on the Empty Schema to avoid constraint issues
                echo "[INFO] Importing the dump for $DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY located at $DATABASE_DUMP ..."
                sudo mysql -u root -f "$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY" < "$DATABASE_DUMP" || exit 1

            else
                echo "[DEBUG] Test Mode Detected - This is the command that would have been executed:"
                echo "sudo mysql -u root \"$DIRECTORY_TO_MATCH_TO_DATABASE_DUMP_FOLDER_ONLY\" < \"$DATABASE_DUMP\" || exit 1"
            fi

            break
        fi
    done
		
    #Turn it off after - https://askubuntu.com/questions/344407/how-to-read-complete-line-in-for-loop-with-spaces
    unset IFS
}

function misc_findReplace_inFile()
{
    VARIABLE_FIND="$1"
    VARIABLE_REPLACE="$2"
    VARIABLE_FILE="$3"

    echo "Finding: $VARIABLE_FIND" &&\
    echo "Replacing With: $VARIABLE_REPLACE" &&\
    echo "File to Operate On: $VARIABLE_FILE" &&\
    
    sed -e "s/${VARIABLE_FIND}/${VARIABLE_REPLACE}/g" "$VARIABLE_FILE" > "$VARIABLE_FILE-changed" && mv "$VARIABLE_FILE-changed" "$VARIABLE_FILE"
}

main