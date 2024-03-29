#!/usr/bin/env bash
set -e

use_tag="khulnasoft/uvicorn-gunicorn-readyapi:$NAME"

DOCKERFILE="$NAME"

if [ "$NAME" == "latest" ] ; then
    DOCKERFILE="python3.11"
fi

docker build -t "$use_tag" --file "./docker-images/${DOCKERFILE}.dockerfile" "./docker-images/"
