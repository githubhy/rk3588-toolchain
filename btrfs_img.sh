#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <image_folder> <total_size>"
    echo "Example: $0 /path/to/images 100G"
    exit 1
fi

IMAGE_FOLDER="$1"
TOTAL_SIZE="$2"

MOUNT_FOLDER=/mnt/merged

# Ensure the image folder exists
mkdir -p "$IMAGE_FOLDER"

mkdir -p "$MOUNT_FOLDER"

# Function to convert human-readable size to bytes
convert_to_bytes() {
    local size=$1
    local unit=${size: -1} # Get the last character (unit)
    local num=${size%$unit} # Get the numeric part
    case $unit in
        "G" | "g")
            echo $(($num * 1024 * 1024 * 1024)) ;;
        "M" | "m")
            echo $(($num * 1024 * 1024)) ;;
        "K" | "k")
            echo $(($num * 1024)) ;;
        *)
            echo $size ;;
    esac
}

# Convert TOTAL_SIZE to bytes
TOTAL_BYTES=$(convert_to_bytes "$TOTAL_SIZE")

# Calculate size of each new disk image (adjust as needed)
IMAGE_SIZE=$((5*1024*1024*1024)) # 5G

# Array to store existing image filenames
existing_images=("$IMAGE_FOLDER"/*.img)

# Calculate the number of images needed to reach or exceed the total size
total_images=$(( (TOTAL_BYTES + IMAGE_SIZE - 1) / IMAGE_SIZE )) # Round up division

# Variable to track if an available image index is found
available_index_found=false

# Loop through and create the required number of new disk images
for (( i=1; i<=$total_images; i++ )); do
    NEW_DISK="$IMAGE_FOLDER/new_disk_$i.img"

    # Check if the filename already exists
    if [[ -e "$NEW_DISK" ]]; then
        echo "File $NEW_DISK already exists. Skipping."
        continue
    fi
    
    # Create a new disk image using truncate
    truncate -s "$IMAGE_SIZE" "$NEW_DISK"
    
    # Find the next available loop device
    LOOP_DEVICE=$(losetup -f)
    
    # Create a loopback device for the new disk image
    losetup "$LOOP_DEVICE" "$NEW_DISK"
    
    # Add the new loopback device to the existing btrfs filesystem
    btrfs device add "$LOOP_DEVICE" "$MOUNT_FOLDER"
    
    echo "Added $NEW_DISK to the btrfs filesystem."

    # Set flag to true indicating an available index was found
    available_index_found=true
done

# Check if no available index was found
if [ "$available_index_found" = false ]; then
    echo "No available image index found. Exiting."
    exit 1
fi

# Balance the btrfs filesystem to distribute data across the new devices
btrfs balance start /mnt/merged
