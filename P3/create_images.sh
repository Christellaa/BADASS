#!/bin/bash

HOST=host
ROUTER=router
IMAGE1=host-1
IMAGE2=router-1

if ! docker image inspect "$IMAGE1" > /dev/null 2>&1; then
    if docker build -t "$IMAGE1" -f "$HOST" .; then
        echo "Image $IMAGE1 built successfully."
    else
        echo "Image $IMAGE1 failed to build."
    fi
fi
if ! docker image inspect "$IMAGE2" > /dev/null 2>&1; then
    if docker build -t "$IMAGE2" -f "$ROUTER" .; then
        echo "Image $IMAGE2 built successfully."
    else
        echo "Image $IMAGE2 failed to build."
    fi
fi
