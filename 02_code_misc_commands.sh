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

function main()
{
    # Test if the script works fine
    if [ "$TEST_MODE" == "TRUE" ]; then
        testScript
    fi

    processPhpProjects
}

function processPhpProjects()
{
    PATTERN_TO_SEARCH_FOR="composer.json"
        
    DIRECTORIES_TO_APPLY_MISC_COMMANDS_ON_LIST=$(find "$REPOSITORY_CHECKOUT_DIRECTORY" -maxdepth 2 -type f -iname "$PATTERN_TO_SEARCH_FOR") 

    EXIT_CODE=$?

    if [ "$EXIT_CODE" == "0" ]; then
        echo "Found the Following $PATTERN_TO_SEARCH_FOR Directories:"
        echo $DIRECTORIES_TO_APPLY_MISC_COMMANDS_ON_LIST

        #Spaces in a String will mess up a for loop - https://askubuntu.com/questions/344407/how-to-read-complete-line-in-for-loop-with-spaces
        IFS=$'\n'

        for DIRECTORY_TO_APPLY_MISC_COMMANDS_ON in $DIRECTORIES_TO_APPLY_MISC_COMMANDS_ON_LIST
        do
            DIRECTORY_TO_APPLY_MISC_COMMANDS_ON=$(misc_findReplace_standardInput "/$PATTERN_TO_SEARCH_FOR" "" "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON")
            DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY=$(getSourceDirectoryName_withoutFullPath "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON")
            DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY_UPPER=${DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY^^}

            cd "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON"

            ##########################################################
            ### BEGIN - RepoTools - Skip If Detected as This Entry ###
            ##########################################################

            VARIABLE_REPOTOOLS="RepoTools"
            VARIABLE_REPOTOOLS_UPPER=${VARIABLE_REPOTOOLS^^}

            if [[ "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY_UPPER" == "$VARIABLE_REPOTOOLS_UPPER" ]]; then
                continue
            fi

            ########################################################
            ### END - RepoTools - Skip If Detected as This Entry ###
            ########################################################

            mkdir "logs"
            chmod 777 -R logs
            touch logs/app.log
            chmod 777 logs/app.log

            if [ "$COMPOSER_INSTALL" == "TRUE" ]; then
                

                #################################################################################
                ### BEGIN - PHPRepositoryName1 - Install Cake Forcefully since not in JSON ###
                #################################################################################

                VARIABLE_PHPREPOSITORY1="PHPRepositoryName1"
                VARIABLE_PHPREPOSITORY1_UPPER=${VARIABLE_PHPREPOSITORY1^^}

                if [[ "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY_UPPER" == "$VARIABLE_PHPREPOSITORY1_UPPER" ]]; then

                    # Install all Composer Dependencies
                    composer install -n || composer update -n || composer install -n

                    # Install Phinx Dependency to Git Project
                    composer require robmorgan/phinx --ignore-platform-reqs -n

                    composer require cakephp/i18n --ignore-platform-reqs -n
                    composer require cakephp/orm --ignore-platform-reqs -n
                    composer require cakephp/utility --ignore-platform-reqs -n

                    # Copy Env File
                    DOT_ENV_FILE_PATH="$SCRIPT_DIRECTORY/Misc_Files/Env_Files/php_projects.env"
                    cp "$DOT_ENV_FILE_PATH" "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON/.env"

                    # Configure .env file for Each Repo
                    configureDotEnvFile "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON" "$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY"

                    if [ "$CREATE_DATABASE" == "TRUE" ]; then
                        # Create the Database Schema - If it doesn't exist
                        echo "CREATE DATABASE IF NOT EXISTS \`$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY\` \
                            CHARACTER SET utf8mb4 \
                            COLLATE utf8mb4_unicode_ci" | sudo mysql -u root || exit 1
                        fi

                        if [ "$PHINX_MIGRATE" == "TRUE" ]; then
                        # Apply Phinx Migration
                        ./vendor/bin/phinx migrate
                    fi
                fi

                #########################################################################
                ### END - PHPRepositoryName1 - Install Cake Forcefully since not in JSON ###
                #########################################################################
            fi
            
            
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
}

function configureDotEnvFile()
{
    DIRECTORY_TO_APPLY_MISC_COMMANDS_ON="$1" 
    DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY="$2"
    
    DOT_ENV_FILE_PATH="$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON/.env"

    echo "[INFO] Adding .env args to $DIRECTORY_TO_APPLY_MISC_COMMANDS_ON ..."

    # Not needed in this script
    # echo "$DOT_ENV_FILE" > "$DOT_ENV_FILE_PATH"

    echo "[INFO] Adding DB_DATABASE='$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY' to $DIRECTORY_TO_APPLY_MISC_COMMANDS_ON ..."
    echo "" >> "$DOT_ENV_FILE_PATH"
    echo "DB_DATABASE='$DIRECTORY_TO_APPLY_MISC_COMMANDS_ON_FOLDER_ONLY'" >> "$DOT_ENV_FILE_PATH"

    # Replace Single Quotes with Double Quotes
    misc_findReplace_inFile "'" '\"' "$DOT_ENV_FILE_PATH"
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