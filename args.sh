#!/bin/bash

REPOSITORY_CHECKOUT_DIRECTORY="$SCRIPT_DIRECTORY/../"
DATABASE_DUMP_DIRECTORY="$SCRIPT_DIRECTORY/Database_Files"
TARGET_SYM_LINK_DIRECTORY="/var/www/html"
DIRECTORY_WWW="/var/www/html"

NODE_LOG_DIRECTORY="/var/log/apache2"

COMPOSER_INSTALL="TRUE"
PHINX_MIGRATE="TRUE"
CREATE_DATABASE="FALSE"
DROP_DATABASE="FALSE"
TRUNCATE_DATABASE="FALSE"

NODE_MODULES_CLEAN="FALSE"
NODE_MODULES_INSTALL="TRUE"

VARIABLE_PM2_BLACKLIST=()
VARIABLE_PM2_BLACKLIST+=( "RepositoryToIgnore" )

# Confirm the outputs first before executing - Use TEST_MODE Variable below!
TEST_MODE="FALSE"

REPOSITORY_BRANCH_CHOICE="development"

REPOSITORY_BRANCH_DEFAULT_1="development"
REPOSITORY_BRANCH_DEFAULT_2="master"
REPOSITORY_BRANCH_DEFAULT_3="main"

REPOSITORY_CHECKOUT_URL="https://github.com/organization/Repo1.git"
REPOSITORY_CHECKOUT_URL+="|https://github.com/organization/Repo2.git"

# This token will have been deleted/expired by the time you read this - it's not a security risk
REPOSITORY_USERNAME="my_git_username"
REPOSITORY_PASSWORD=""