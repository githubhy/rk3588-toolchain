#!/bin/bash

set -e

IMAGE_DIR=${IMAGE_DIR:-.btrfs_imgs}  # Directory containing disk images

# Mount points
TEMP_MP=${TEMP_MP:-/mnt/btrfs_temp}
IMAGES_MOUNT_POINT=${IMAGES_MOUNT_POINT:-/mnt/merged}
SNAPS_MOUNT_POINT=$IMAGES_MOUNT_POINT/.snapshots

umount_if_exists() {
    local device="$1"
    while mount | grep -E "$device" # There might be multiple mount point on a single device
    do
        umount -v "$device"
    done
}

clean_loopdevs() {
    local arg="$1"
    if [ -z "$arg" ]; then
        devices="$(blkid -t TYPE=btrfs -o device | grep "^/dev/loop" | cat)" # seems the output of `grep` will make the assignment fail
    else
        devices="$arg"
    fi
    for device in $devices; do
        umount_if_exists $device
        echo "Detaching $device"
        losetup -d $device
        rm -f $device # the btrfs seems create a loop device to file system mapping. So the loop devices used in creation should be keep the same
    done
}

# Clean the loop devices for btrfs
clean_loopdevs

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
    #btrfs device add $loopdev $TEMP_MP
    loopdevs="$loopdevs $loopdev"
done

confirm_btrfs_creation() {
    read -p "Are you sure you want to create a btrfs filesystem? This will erase all data on the device. (yes/no): " response
    case $response in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            echo "Operation cancelled."
            clean_loopdevs "$loopdevs"
            return 1
            ;;
    esac
}

# Create a btrfs filesystem spanning the loopback devices if it doesn't already exist
if ! blkid | grep -q btrfs; then
    echo "Seems no btrfs filesystem on $loopdevs"
    if confirm_btrfs_creation; then
        BTRFS_CREATION_LOG=$IMAGE_DIR/btrfs_creation.log
        mkfs.btrfs -d single $loopdevs > $BTRFS_CREATION_LOG
        if [ $? -eq 0 ]; then
            echo "btrfs filesystem created successfully on $loopdevs. Logs are in $BTRFS_CREATION_LOG"
        else
            echo "Failed to create btrfs filesystem on $loopdevs. Logs are in $BTRFS_CREATION_LOG"
            exit 1
        fi
    else
        exit 1
    fi
fi


# Option1: before mounting, let's do some workaround in case the loop devices are considered missing
# https://www.reddit.com/r/btrfs/comments/ja5nqz/btrfs_thinks_devices_are_missing_at_boot_but_they/
#for dev in $loopdevs;
#do
#    btrfs device scan $dev
#done
# Option 2: use the better advice here: https://unix.stackexchange.com/a/755866
# mount UUID=${FS_UUID} $TEMP_MP
# Option 3: use the fstab like method in: https://www.reddit.com/r/btrfs/comments/ja5nqz/btrfs_thinks_devices_are_missing_at_boot_but_they/
FS_UUID=$(btrfs filesystem show | grep -oP 'uuid: \K[0-9a-fA-F-]+')
BTRFS_DEVS=$(blkid | grep -Eo '^/dev/loop[0-9]+.*UUID="[0-9a-fA-F-]+.*btrfs.*$')
# We need to preserve newlines. https://stackoverflow.com/a/5386562
FSTAB_DEVS=$(echo "$BTRFS_DEVS" | awk -F: '{ print "device="$1 }' | paste -sd ',' -)

echo "UUID=$FS_UUID    $TEMP_MP    btrfs    defaults,$FSTAB_DEVS 0 0" > /etc/fstab
echo "UUID=$FS_UUID    $IMAGES_MOUNT_POINT    btrfs    subvol=@,defaults,$FSTAB_DEVS 0 0" >> /etc/fstab
echo "UUID=$FS_UUID    $SNAPS_MOUNT_POINT    btrfs    subvol=@snapshots,defaults,$FSTAB_DEVS 0 0" >> /etc/fstab

# Create snapshorts
echo "Mounting $loopdev to $TEMP_MP"
mkdir -p $TEMP_MP
umount_if_exists $TEMP_MP
mount $TEMP_MP
BTRFS_PATH=${TEMP_MP} create_snapshot.sh
umount $TEMP_MP
rmdir $TEMP_MP

# Mount the root subvolume
#mount -o subvol=@ UUID=${FS_UUID} ${IMAGES_MOUNT_POINT}

# Mount the snapshots subvolume
# mkdir -p $SNAPS_MOUNT_POINT
#mount -o subvol=@snapshots UUID=${FS_UUID} ${SNAPS_MOUNT_POINT}

# change to fstab for all subvolumes
echo "Mounting filesystem root to $IMAGES_MOUNT_POINT"
mkdir -p $IMAGES_MOUNT_POINT
umount_if_exists $IMAGES_MOUNT_POINT
mount $IMAGES_MOUNT_POINT
echo "Mounting snapshots to $SNAPS_MOUNT_POINT"
umount_if_exists $SNAPS_MOUNT_POINT
mkdir -p $SNAPS_MOUNT_POINT
mount $SNAPS_MOUNT_POINT

echo "Done."
