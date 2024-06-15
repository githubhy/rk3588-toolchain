To expand an existing ext4 image, you will need to follow these steps:

1. Increase the size of the sparse image file.
2. Use `resize2fs` to resize the filesystem within the expanded image.

### Step 1: Update the Script

Here is an updated `entrypoint.sh` script that includes expanding the image file:

```bash
#!/bin/bash

# Get mount point and image name from environment variables
MOUNT_POINT=${MOUNT_POINT:-/proj/rk3588}
IMAGE_NAME=${IMAGE_NAME:-.rk3588_ext4.img}
NEW_SIZE=${NEW_SIZE:-2G}  # Default new size is 2G

# Create the mount point directory
mkdir -p $MOUNT_POINT

# Check if the image file exists in the current directory
if [ -f "$IMAGE_NAME" ]; then
    echo "Image file $IMAGE_NAME found."

    # Expand the sparse image file
    echo "Expanding $IMAGE_NAME to $NEW_SIZE..."
    truncate -s $NEW_SIZE $IMAGE_NAME

    # Check and repair the filesystem (optional but recommended)
    e2fsck -f $IMAGE_NAME

    # Resize the filesystem to use the new size
    resize2fs $IMAGE_NAME

    # Mount the image
    echo "Mounting $IMAGE_NAME to $MOUNT_POINT..."
    mount -o loop $IMAGE_NAME $MOUNT_POINT
    echo "Image mounted successfully."
    echo "Contents of $MOUNT_POINT:"
    ls -l $MOUNT_POINT
else
    echo "Image file $IMAGE_NAME not found in the current directory."
fi

# Keep the container running to allow inspection or further operations
exec /bin/bash
```

### Step 2: Update the Dockerfile

Ensure your Dockerfile copies the updated script and sets it as the entry point:

```Dockerfile
# Use an official Debian or Ubuntu base image
FROM ubuntu:latest

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    e2fsprogs \
    mount \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables with default values
ENV MOUNT_POINT /proj/rk3588
ENV IMAGE_NAME .rk3588_ext4.img
ENV NEW_SIZE 2G

# Set the working directory
WORKDIR /workspace

# Copy the entrypoint script into the container
COPY entrypoint.sh .

# Make the script executable
RUN chmod +x entrypoint.sh

# Set the entrypoint to the script
ENTRYPOINT ["./entrypoint.sh"]
```

### Step 3: Build the Docker Image

Build the Docker image as usual:

```bash
docker build -t rk3588-mounter .
```

### Step 4: Run the Docker Container with Volume Mapping and Custom Size

Run the Docker container, specifying the new size for the image, and mapping the container's `/proj/rk3588` directory to a directory on the host:

```bash
docker run --rm --privileged -v $(pwd):/workspace -v /host/directory:/proj/rk3588 -e NEW_SIZE=2G -it rk3588-mounter
```

Replace `/host/directory` with the actual path on your host where you want to expose the contents of `/proj/rk3588` from the container. Adjust `NEW_SIZE` as needed.

### Full Directory Structure

Ensure your directory structure looks like this:

```
.
├── Dockerfile
└── entrypoint.sh
```

### Example Outputs

1. **Build the Docker image:**

   ```bash
   docker build -t rk3588-mounter .
   ```

2. **Run the container with volume mapping, custom size, and interactive shell:**

   ```bash
   docker run --rm --privileged -v $(pwd):/workspace -v /host/directory:/proj/rk3588 -e NEW_SIZE=2G -it rk3588-mounter
   ```

   - If the image file `.rk3588_ext4.img` is found, you will see:

     ```
     Image file .rk3588_ext4.img found.
     Expanding .rk3588_ext4.img to 2G...
     Image expanded successfully.
     Checking the filesystem...
     e2fsck 1.45.5 (07-Jan-2020)
     Pass 1: Checking inodes, blocks, and sizes
     ...
     Resize the filesystem...
     resize2fs 1.45.5 (07-Jan-2020)
     Resizing the filesystem on .rk3588_ext4.img to 524288 (4k) blocks.
     The filesystem on .rk3588_ext4.img is now 524288 (4k) blocks long.

     Mounting .rk3588_ext4.img to /proj/rk3588...
     Image mounted successfully.
     Contents of /proj/rk3588:
     total 16
     drwx------ 2 root root 16384 Jan  1  1970 lost+found
     ```

   - If the image file is not found, you will see:

     ```
     Image file .rk3588_ext4.img not found in the current directory.
     ```

After the script finishes, you will be dropped into an interactive Bash shell within the container.

By following these steps, you can expand the ext4 image, mount it, expose the directory to the host, and have an interactive shell ready for further operations.