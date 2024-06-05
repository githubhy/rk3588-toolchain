# rk3588-toolchain
## Build the docker image locally
```
docker build --pull --rm -f "Dockerfile" -t ${LABEL}:latest "."
```
`${LABEL}` could any string.
## How to use this tool chain
1. Pull the newest version from the DockerHub. If it is already there, go to step 2.
  ```
  docker pull dockerhy/rk3588-toolchain
  ```
2. Create you project folder and change to the folder.
3. (Only for Windows WSL) If the ext4 usb drive is to be used, run the following commands
  - run `Windows PowerShell as Administrator`
  - In the power shell, run `GET-CimInstance -query "SELECT * from Win32_DiskDrive"`
  - Identify the usb drive ID, which is like `\\.\PHYSICALDRIVE${n}`, where `${n}` is a number
  - In the same power shell, run `wsl --mount \\.\PHYSICALDRIVE${n}`
4. Run the following command to start using this toolchain.
  - Windows(WSL):
    ```
    docker cp dockerhy/rk3588-toolchain:/usr/local/bin/mount_ext4_in_wsl2.sh .
    ```
    ```
    . ./mount_ext4_in_wsl2.sh
    ```
    Follow the instructions in the script.
    ```
    docker run -it --rm -v "$PWD":/proj/rk3588 -w /proj/rk3588 dockerhy/rk3588-toolchain
    ```
4. Now you are in the docker container. You can init the repo and sync the codebase inside the container, as the instructions listed at the [products' site](https://wiki.t-firefly.com/zh_CN/Core-3588SJD4/linux_compile.html?highlight=docker#chu-shi-hua-cang-ku)
   - repo init:
    ```
    ## 完整 SDK
    repo init --no-clone-bundle --repo-url https://gitlab.com/firefly-linux/git-repo.git -u https://gitlab.com/firefly-linux/manifests.git -b master -m rk3588_linux_release.xml
    ```
    ```
    ## BSP （ 只包含基础仓库和编译工具 ）
    ## BSP 包括 device/rockchip 、docs 、 kernel 、 u-boot 、 rkbin 、 tools 和交叉编译链
    repo init --no-clone-bundle --repo-url https://gitlab.com/firefly-linux/git-repo.git -u https://gitlab.com/firefly-linux/manifests.git -b master -m rk3588_linux_bsp_release.xml
    ```
   - repo sync:
   
     Repo sync is a little bit tricky. You need to append `-j1 -f --force-sync` to the sync command to make it work, otherwise the sync would be stuck somewhere.
    ```
    # 第一次同步
    .repo/repo/repo sync -c --no-tags -j1 -f --force-sync
    .repo/repo/repo start firefly --all
    ```
    ```
    # 后续同步
    .repo/repo/repo sync -c --no-tags -j1 -f --force-sync
    ```
