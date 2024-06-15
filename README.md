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
### 2-a. If an `ext4` usb drive is to be used
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
### 2-b. If no external drive is to be used
  1. Change to a local directory
  2. Map the directory into the docker container
      ```
      docker run -it --rm --privileged -e MOUNT_POINT=/proj/rk3588 -e IMAGE_NAME=.rk3588_ext4.img -v "$PWD":/workspace -v "$PWD"/proj/rk3588:/proj/rk3588 dockerhy/rk3588-toolchain
      ```
### 3. Things you can do in the container
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
