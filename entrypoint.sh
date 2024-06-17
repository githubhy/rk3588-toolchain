#!/bin/bash

# Get mount point and image name from environment variables
MOUNT_POINT=${MOUNT_POINT:-/proj/rk3588}
IMAGE_NAME=${IMAGE_NAME:-.rk3588_ext4.img}

# Create the mount point directory
mkdir -p $MOUNT_POINT

# Check if the image file exists in the current directory
if [ -f "$IMAGE_NAME" ]; then
    echo "Image file $IMAGE_NAME found. Mounting to $MOUNT_POINT..."
    # Mount the image
    mount -o loop $IMAGE_NAME $MOUNT_POINT
    echo "Image mounted successfully."
    echo "Contents of $MOUNT_POINT:"
    ls -l $MOUNT_POINT
else
    echo "Image file $IMAGE_NAME not found in the current directory."
fi

IMAGE_DIR=${IMAGE_DIR} IMAGES_MOUNT_POINT=${IMAGES_MOUNT_POINT} btrfs_mount.sh

# Keep the container running to allow inspection or further operations
exec /bin/bash
