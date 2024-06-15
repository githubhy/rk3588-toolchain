# rk3588-toolchain
## Build the docker image locally
```
docker build --pull --rm -f "Dockerfile" -t ${LABEL}:latest "."
```
`${LABEL}` could any string.
## How to use this tool chain
### 1. Pull the newest version from the DockerHub.
  ```
  docker pull dockerhy/rk3588-toolchain
  ```
### 2. File system images
Since compiling the linux kernel requires a file system that is compatible, both `ext4` and `btrfs` are considered here.
#### `ext4`
You need to create a `ext4` disk image and name it as `.rk3588_ext4.img` and then format it to `ext4`. The size of the image should be large enough to use.

Disk expansion is also possible.

Put it right in the working directory in the host.
#### `btrfs`
`btrfs` supports mounting multiple disk images as one. And expanding the file systems only needs adding more disk images. So you can have a lot of small sized disk images. `btrfs` will merge them togather.

### 3-a. If an `ext4` drive is to be used
  1. Open `Windows PowerShell` as administrator
  2. In the power shell, run
      ```
      GET-CimInstance -query "SELECT * from Win32_DiskDrive"
      ```
  3. Identify the usb drive ID, which is like `\\.\PHYSICALDRIVE${n}`, where `${n}` is a number
  4. In the same power shell, [mount the drive](https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk)
      ```
      wsl --mount \\.\PHYSICALDRIVE${n} --name usbdrive
      ```
  5. Open `WSL`:
      ```
      docker run -it --rm -v /mnt/wsl/usbdrive:/proj/rk3588 -w /proj/rk3588 dockerhy/rk3588-toolchain
      ```
  6. Remember to umount the usb drive before unplugging it
      ```
      wsl --unmount \\.\PHYSICALDRIVE${n}
      ```
### 3-b. If no `ext4` drive is to be used
  1. Change to a directory, which could also be on a USB drive. Network drive is also supported.

  2. Map the directory into the docker container
      ```
      docker run -it --rm --privileged -e MOUNT_POINT=/proj/rk3588 -e IMAGE_NAME=.rk3588_ext4.img -v ${PWD}:/workspace dockerhy/rk3588-toolchain
      ```
### 4. Things you can do in the container
Now you are in the docker container. You can init the repo and sync the codebase inside the container, following the instructions listed at the [products' site](https://wiki.t-firefly.com/zh_CN/Core-3588SJD4/linux_compile.html?highlight=docker#chu-shi-hua-cang-ku)

  1. repo init:
      ```
      repo init --no-clone-bundle --repo-url https://gitlab.com/firefly-linux/git-repo.git -u https://gitlab.com/firefly-linux/manifests.git -b master -m rk3588_linux_release.xml
      ```
  2. repo sync:

      Repo sync is a little bit tricky. You need to append `-j1 -f --force-sync` to the sync command to make it work, otherwise the sync would be stuck somewhere.

      - First time sync:
      ```
      .repo/repo/repo sync -c --no-tags -j1 -f --force-sync
      ```
      ```
      .repo/repo/repo start firefly --all
      ```

      - After the first time:
      ```
      .repo/repo/repo sync -c --no-tags -j1 -f --force-sync
      ```
## Tips

### Copy between two folders
As suggest in [this thread](https://unix.stackexchange.com/a/203854), we can use `rsync` to do the heavy lifting
```
rsync -avu --delete "/home/user/A/" "/home/user/B"
```
You can also add a `-z` option if the tranmission bandwidth is bottleneck.
