#!/bin/bash

FILE1=_cde-sous-1_host
IMAGE1=cde-sous-1_host
FILE2=_cde-sous-2
IMAGE2=cde-sous-2

if ! docker image inspect "$IMAGE1" > /dev/null 2>&1; then
    if docker build -t "$IMAGE1" -f "$FILE1" .; then
        echo "Image $IMAGE1 built successfully."
    else
        echo "Image $IMAGE1 failed to build."
    fi
fi
if ! docker image inspect "$IMAGE2" > /dev/null 2>&1; then
    if docker build -t "$IMAGE2" -f "$FILE2" .; then
        echo "Image $IMAGE2 built successfully."
    else
        echo "Image $IMAGE2 failed to build."
    fi
fi
