#!/bin/bash

# Define the base paths
BTRFS_PATH=${BTRFS_PATH:-/mnt/merged}
SUBVOL_PATH="${BTRFS_PATH}/@"
SNAPSHOT_PATH="${BTRFS_PATH}/@snapshots"

# Check if the subvolumes exist, create them if they don't
if ! btrfs subvolume list $BTRFS_PATH | grep -q "@"; then
    btrfs subvolume create "$SUBVOL_PATH"
    echo "Subvolume @ created"
else
    echo "Subvolume @ already exists"
fi

if ! btrfs subvolume list $BTRFS_PATH | grep -q "@snapshots"; then
    btrfs subvolume create "$SNAPSHOT_PATH"
    echo "Subvolume @snapshots created"
else
    echo "Subvolume @snapshots already exists"
fi

# Ensure the snapshot directory exists
mkdir -p "$SNAPSHOT_PATH"

# Get the current date and time for the snapshot name
DATE=$(date +%Y-%m-%d_%H-%M-%S)
SNAPSHOT_NAME="@_${DATE}"

# Create the snapshot
btrfs subvolume snapshot "$SUBVOL_PATH" "$SNAPSHOT_PATH/$SNAPSHOT_NAME"

echo "Snapshot created: $SNAPSHOT_NAME"
