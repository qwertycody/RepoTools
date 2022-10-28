#!/bin/bash

######################################################
### Begin - Variable Inheritance from Args Section ###
######################################################

#Ensure nothing happens outside the directory this script is ran from
cd "$(dirname "$0")"
export SCRIPT_DIRECTORY=$(pwd)

ARGS_FILE="$SCRIPT_DIRECTORY/../args.sh"
ARGS_PRIVATE_FILE="$SCRIPT_DIRECTORY/../args_private.sh"

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

CONTAINER_NAME="redis-gui"
IMAGE_NAME="rediscommander/redis-commander:latest"

docker pull $IMAGE_NAME
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
docker run -d --name $CONTAINER_NAME -p 8081:8081 \
                                     -e REDIS_HOSTS=host.docker.internal \
                                     -e HTTP_USER=root \
                                     -e HTTP_PASSWORD=password \
                                     $IMAGE_NAME