#!/bin/bash

CONTAINER_NAME="redis"
IMAGE_NAME="redis:latest"

docker pull $IMAGE_NAME
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
docker run -d --name $CONTAINER_NAME -p 6379:6379 \
                                     $IMAGE_NAME