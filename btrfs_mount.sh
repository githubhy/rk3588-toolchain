#!/bin/bash

set -e

IMAGE_DIR=${IMAGE_DIR:-.btrfs_imgs}  # Directory containing disk images
MOUNT_POINT_MERGED=${MOUNT_POINT_MERGED:-/mnt/merged}

for device in $(blkid -t TYPE=btrfs -o device | grep "^/dev/loop"); do
    if mount | grep -q "^$device "; then
        umount $device
    fi
    echo "Detaching $device"
    losetup -d $device
    rm -f $device # the btrfs seems create a loop device to file system mapping. So the loop devices used in creation should be keep the same
done

# Create loopback devices for each disk image found in the directory
for img in $IMAGE_DIR/*.img; 
do
    if [ ! -f "$img" ]; then
        echo "No disk images found in $IMAGE_DIR"
        exit 1
    fi

    loopdev=$(losetup -f)
    loopname=$(basename $loopdev)

    # workarond: losetup -f can't create the loop device. Create it here mannually
    # https://serverfault.com/a/991754
    FILTER="^${loopname}[[:blank:]]"
    # echo $FILTER
    lsblk --raw -a --output "NAME,MAJ:MIN" --noheadings | grep -E "$FILTER" | while read LINE; do
        DEV=/dev/$(echo $LINE | cut -d' ' -f1)
        MAJMIN=$(echo $LINE | cut -d' ' -f2)
        MAJ=$(echo $MAJMIN | cut -d: -f1)
        MIN=$(echo $MAJMIN | cut -d: -f2)
        [ -b "$DEV" ] || mknod "$DEV" b $MAJ $MIN
    done

    echo "Attaching $img to $loopdev"
    losetup $loopdev $img
    #btrfs device add $loopdev $MOUNT_POINT_MERGED
    loopdevs="$loopdevs $loopdev"
done

# Create a btrfs filesystem spanning the loopback devices if it doesn't already exist
if ! blkid | grep -q btrfs; then
    echo "btrfs not present. Creating btrfs file system..."
    mkfs.btrfs -d single $loopdevs > $IMAGE_DIR/btrfs_creation.log
fi

# Ensure the mount point directory exists
mkdir -p $MOUNT_POINT_MERGED

# Mount the btrfs filesystem
echo "Mounting $loopdev to $MOUNT_POINT_MERGED"
mount -t btrfs $loopdev $MOUNT_POINT_MERGED
