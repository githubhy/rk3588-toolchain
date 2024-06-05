#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# List available block devices
echo "Available block devices:"
lsblk

# Prompt the user to enter the device identifier
read -p "Enter the device identifier (e.g., sdb): " DEVICE_ID
DEVICE="/dev/${DEVICE_ID}"

# Check if the selected device is the primary system drive
PRIMARY_DRIVES=("sda" "nvme0n1")

if [[ " ${PRIMARY_DRIVES[@]} " =~ " ${DEVICE_ID} " ]]; then
    echo "ERROR: Selected device $DEVICE is likely the primary system drive. Aborting."
    exit 1
fi

# Confirm the device to format
echo "WARNING: This will format the device $DEVICE to ext4."
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Operation cancelled."
    exit 1
fi

# Unmount the device if it is mounted
echo "Unmounting ${DEVICE}1..."
sudo umount ${DEVICE}1

# Format the device to ext4
echo "Formatting $DEVICE to ext4..."
sudo mkfs.ext4 $DEVICE

# Optional: Label the filesystem
read -p "Enter a label for the filesystem (leave blank for no label): " LABEL
if [ -n "$LABEL" ]; then
    sudo mkfs.ext4 -L "$LABEL" $DEVICE
else
    sudo mkfs.ext4 $DEVICE
fi

# Create a mount point
MOUNT_POINT="/mnt/usbdrive"
echo "Creating mount point at $MOUNT_POINT..."
sudo mkdir -p $MOUNT_POINT

# Mount the device
echo "Mounting $DEVICE to $MOUNT_POINT..."
sudo mount $DEVICE $MOUNT_POINT

# Verify the mount
echo "Verifying the mount..."
ls $MOUNT_POINT

echo "Done. The device $DEVICE is now formatted to ext4 and mounted at $MOUNT_POINT."
