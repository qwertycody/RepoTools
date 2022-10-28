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

   # Check all the variables to see if they are 
   # properly set before proceeding with execution
   testVariables

   # Convert the REPOSITORY_CHECKOUT_URL variable to an array and split 
   # on the | character if the user wants to checkout more than 
   # one directory 
   IFS='|' read -ra CHECKOUT_URL_ARRAYLIST <<< "$REPOSITORY_CHECKOUT_URL"
   unset IFS

   # If there is only one CHECKOUT_URL in the list don't bother
   # numbering the folders with a prefix

   NUMBER_OF_CHECKOUTS=$(echo "${#CHECKOUT_URL_ARRAYLIST[@]}")

   # Loop through the CHECKOUT_URL_ARRAYLIST and process
   # each entry into it's respective sub folder with the 
   # appended checkout number on the end of the folder

   CHECKOUT_NUMBER=1

   for CHECKOUT_URL in "${CHECKOUT_URL_ARRAYLIST[@]}"; do
      CHECKOUT_SUBDIRECTORY="$REPOSITORY_CHECKOUT_DIRECTORY"

      processCheckoutEntry "$CHECKOUT_SUBDIRECTORY" "$CHECKOUT_URL"    
      ((CHECKOUT_NUMBER++))
   done
}

function processCheckoutEntry()
{
   local REPOSITORY_CHECKOUT_DIRECTORY="$1"
   local CHECKOUT_URL="$2"

   echo "Cloning Repository to $REPOSITORY_CHECKOUT_DIRECTORY Located at $CHECKOUT_URL"

   #Create the directory and cd to it
   mkdir -p "$REPOSITORY_CHECKOUT_DIRECTORY"
   cd "$REPOSITORY_CHECKOUT_DIRECTORY"

   processGitEntry "$REPOSITORY_CHECKOUT_DIRECTORY" "$CHECKOUT_URL"
}

function processSvnEntry()
{
   local REPOSITORY_CHECKOUT_DIRECTORY="$1"
   local CHECKOUT_URL="$2"

   svn checkout --non-interactive --username "$REPOSITORY_USERNAME" \
                                  --password "$REPOSITORY_PASSWORD" \
                                  "$CHECKOUT_URL"

   EXIT_CODE=$?    

   #Check to see if the svn operation failed or not

   if [ "$EXIT_CODE" != "0" ]; then
      echo "[ERROR] Subversion Operation Failed!"
      exit 1
   fi
}

function processGitEntry()
{
   local REPOSITORY_CHECKOUT_DIRECTORY="$1"
   local CHECKOUT_URL="$2"

   CHECKOUT_URL_WITH_CREDENTIAL=$(getRepoUrlWithUsernamePassword "$CHECKOUT_URL")

   # Uncomment if you want it to delete the directories each time before attempting to clone
   GIT_REPO_NAME=$(misc_findReplace_standardInput ".git" "" "$CHECKOUT_URL")
   GIT_REPO_NAME=$(getSourceDirectoryName_withoutFullPath "$GIT_REPO_NAME") 
   rm -Rf "$REPOSITORY_CHECKOUT_DIRECTORY/$GIT_REPO_NAME"

   # Change to repo directory and clone
   cd "$REPOSITORY_CHECKOUT_DIRECTORY"
   git clone --branch "$REPOSITORY_BRANCH_CHOICE" "$CHECKOUT_URL_WITH_CREDENTIAL"

   EXIT_CODE=$?

   #Check to see if the git operation failed or not
   if [ "$EXIT_CODE" != "0" ]; then
      echo "[WARNING] GIT Operation Failed - Attempting to Clone $REPOSITORY_BRANCH_DEFAULT_1 instead"

      git clone --branch "$REPOSITORY_BRANCH_DEFAULT_1" "$CHECKOUT_URL_WITH_CREDENTIAL"

      EXIT_CODE=$?

      if [ "$EXIT_CODE" != "0" ]; then
         echo "[WARNING] GIT Operation Failed - Attempting to Clone $REPOSITORY_BRANCH_DEFAULT_2 instead"

         git clone --branch "$REPOSITORY_BRANCH_DEFAULT_2" "$CHECKOUT_URL_WITH_CREDENTIAL"
         
         EXIT_CODE=$?

         if [ "$EXIT_CODE" != "0" ]; then
            echo "[WARNING] GIT Operation Failed - Attempting to Clone $REPOSITORY_BRANCH_DEFAULT_3 instead"

            git clone --branch "$REPOSITORY_BRANCH_DEFAULT_3" "$CHECKOUT_URL_WITH_CREDENTIAL"
            
            EXIT_CODE=$?

            if [ "$EXIT_CODE" != "0" ]; then
               echo "[WARNING] GIT Operation Failed!"
               exit 1
            fi
         fi
      fi
   fi
}

function misc_findReplace()
{
    VARIABLE_FIND="$1"
    VARIABLE_REPLACE="$2"
    VARIABLE_STRING="$3"
 
    echo "$VARIABLE_STRING" | sed --expression "s|${VARIABLE_FIND}|${VARIABLE_REPLACE}|g"
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

function getRepoUrlWithUsernamePassword()
{   
   CHECKOUT_URL="$1"

   REPOSITORY_PASSWORD_ENCODED=$(rawurlencode "$REPOSITORY_PASSWORD")

   VARIABLE_REPO_TO_RETURN=$(misc_findReplace 'https://' "https://$REPOSITORY_USERNAME:$REPOSITORY_PASSWORD_ENCODED@" "$CHECKOUT_URL")
   VARIABLE_REPO_TO_RETURN=$(misc_findReplace 'http://' "http://$REPOSITORY_USERNAME:$REPOSITORY_PASSWORD_ENCODED@" "$VARIABLE_REPO_TO_RETURN")

   echo "$VARIABLE_REPO_TO_RETURN"
}

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o
  
  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
}

#Set Company Credentials for Authentication
function setCredentials() {
   echo "Enter Company Username: "
   read VARIABLE_USERNAME

   REPOSITORY_USERNAME="$VARIABLE_USERNAME"

   #Set Password
   VARIABLE_PASSWORD=""
   VARIABLE_PASSWORD2=""

    while true; do
        read -s -p "Enter Company Password: " VARIABLE_PASSWORD
        echo
        read -s -p "Enter Company Password (again): " VARIABLE_PASSWORD2
        echo

        [ "$VARIABLE_PASSWORD" = "$VARIABLE_PASSWORD2" ] && break
        echo "Passwords do not match. Please try again."
    done

   REPOSITORY_PASSWORD="$VARIABLE_PASSWORD"
   REPOSITORY_PASSWORD_ENCODED=$(rawurlencode $VARIABLE_PASSWORD)
}

function testScript()
{
   # We do this because test mode doesn't have an absolute directory path
   # to anchor on unlike when it's executing in Docker which has an absolute
   # path to the checkout directory - aka /home/oracle/Repository
   #
   # Ensure nothing happens outside the directory this script is ran from
   cd "$(dirname "$0")"
   SCRIPT_DIRECTORY=$(pwd)

   setCredentials

   # Checkout Directory
   REPOSITORY_CHECKOUT_DIRECTORY="$SCRIPT_DIRECTORY/testRepoFolder"

   # Multi URL Scenario
   REPOSITORY_CHECKOUT_URL=https://svn.company.com/svn/repo/branch1|https://svn.company.com/svn/repo/branch2

   # Single URL Scenario
   #REPOSITORY_CHECKOUT_URL=https://svn.company.com/svn/repo/branch1
}

function testVariables()
{
   local ERROR_DETECTED="FALSE"

   declare -A VARIABLE_TESTING_LIST

   VARIABLE_TESTING_LIST+=(["REPOSITORY_CHECKOUT_DIRECTORY"]=$REPOSITORY_CHECKOUT_DIRECTORY)
   VARIABLE_TESTING_LIST+=(["REPOSITORY_USERNAME"]=$REPOSITORY_USERNAME)
   VARIABLE_TESTING_LIST+=(["REPOSITORY_PASSWORD"]=$REPOSITORY_PASSWORD)
   VARIABLE_TESTING_LIST+=(["REPOSITORY_CHECKOUT_URL"]=$REPOSITORY_CHECKOUT_URL)

   for VARIABLE_ENTRY in "${!VARIABLE_TESTING_LIST[@]}"
   do
      #Pull Values from Array
      VARIABLE_VALUE=${VARIABLE_TESTING_LIST[$VARIABLE_ENTRY]}
 
      if [ -z "$VARIABLE_VALUE" ]; then
         echo "[ERROR] $VARIABLE_ENTRY is not set - please check the args file!"
         ERROR_DETECTED="TRUE"
      fi
 
      LENGTH_OF_VARIABLE_ENTRY="${#VARIABLE_ENTRY}"
 
      if [ "${#VARIABLE_VALUE}" == "0" ]; then
         echo "[ERROR] $VARIABLE_ENTRY is empty - please check the args file!"
         ERROR_DETECTED="TRUE"
      fi
   done

   if [ "$ERROR_DETECTED" == "TRUE" ]; then
      exit 1
   fi
}

 

main