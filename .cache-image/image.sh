#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <action>"
    echo "Actions: save, load"
    exit 1
fi

if [ "$1" != "save" ] && [ "$1" != "load" ]; then
    echo "Invalid action: $1"
    echo "Actions: save, load"
    exit 1
fi

if [ "$1" == "load" ]; then
    echo "Loading MinIO image..."
    docker load -i minio.minio.RELEASE.2025-04-22T22-12-26Z.tar
    if [ $? -eq 0 ]; then
        echo "MinIO image loaded successfully."
    else
        echo "Failed to load MinIO image."
        exit 1
    fi
  exit 0
fi

if [ "$1" == "save" ]; then
    echo "Saving MinIO image..."
    docker save -o minio.minio.RELEASE.2025-04-22T22-12-26Z.tar minio/minio:RELEASE.2025-04-22T22-12-26Z
    if [ $? -eq 0 ]; then
        echo "MinIO image saved successfully."
    else
        echo "Failed to save MinIO image."
        exit 1
    fi
    exit 0
fi