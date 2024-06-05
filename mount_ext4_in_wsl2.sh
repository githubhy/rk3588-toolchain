#!/bin/bash

# Check if the script is run as root
# if [ "$(id -u)" -ne 0 ]; then
#     echo "Please run this script as root or using sudo."
#     return 1
# #    exit 1
# fi

# List available block devices
echo "Available block devices:"
lsblk

# Prompt the user to enter the device identifier
read -p "Enter the device identifier (e.g., sdb1 for /dev/sdb1): " DEVICE_ID
DEVICE="/dev/${DEVICE_ID}"

# Confirm the device to mount
echo "You have selected $DEVICE."
read -p "Are you sure you want to mount this device? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Operation cancelled."
    return 1
#    exit 1
fi

# Check if the device exists
if [ ! -b "$DEVICE" ]; then
    echo "ERROR: Device $DEVICE does not exist. Aborting."
    return 1
#    exit 1
fi

# Unmount the device if it is mounted
echo "Unmounting $DEVICE (if it is mounted)..."
sudo umount $DEVICE

# Create a mount point
MOUNT_POINT="/mnt/usbdrive"
echo "Creating mount point at $MOUNT_POINT..."
sudo mkdir -p $MOUNT_POINT

# Mount the device
echo "Mounting $DEVICE to $MOUNT_POINT..."
sudo mount -t ext4 $DEVICE $MOUNT_POINT

# Verify the mount
if mountpoint -q $MOUNT_POINT; then
    echo "The device $DEVICE has been successfully mounted to $MOUNT_POINT."
else
    echo "ERROR: Failed to mount $DEVICE."
    return 1
#    exit 1
fi

# List the contents of the mount point to verify
echo "Listing the contents of $MOUNT_POINT:"
ls $MOUNT_POINT

echo "Done."

cd $MOUNT_POINT
