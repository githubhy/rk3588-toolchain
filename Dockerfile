FROM amd64/ubuntu:18.04

ARG REPO_SRC_LIST=sources.list

COPY ${REPO_SRC_LIST} /etc/apt/
COPY format_usb_to_ext4.sh /usr/local/bin/

# Pakage `tzdata` should be installed to make the enviroment vairable `TZ` work
# Setting the DEBIAN_FRONTEND environment variable suppresses the prompt that lets you select the correct timezone from a menu.
ENV TZ Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive

# Install the tool chain, following the instruction here:
# https://wiki.t-firefly.com/zh_CN/Core-3588SJD4/linux_compile.html
# [Note 1] Before that, a little bit cleanup for working around some dpkg issue.
# Refer to: https://stackoverflow.com/a/72449247
# [Note 2] `ca-certificates` package is for SSL CA error after executing the `repo` command
# [Note 3] Stopping the repo init colorization prompt: https://groups.google.com/g/repo-discuss/c/T_JouBm-vBU
# [Note 4] `gpgv2` package is for solving the "repo not signed" issue: https://blog.csdn.net/Rank_d/article/details/116697985
RUN rm -rf /var/lib/dpkg/info/* \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
                repo git ssh make gcc libssl-dev liblz4-tool \
                expect g++ patchelf chrpath gawk texinfo chrpath diffstat binfmt-support \
                qemu-user-static live-build bison flex fakeroot cmake gcc-multilib g++-multilib \
                unzip \
                device-tree-compiler ncurses-dev \
                gpgv2 \
                bc \
                git-lfs \
                python3
RUN apt-get install -y --no-install-recommends \
        ca-certificates openssl
RUN apt-get autoremove -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*rm /var/log/alternatives.log /var/log/apt/* \
        && rm /var/log/* -r \
        && git config --global user.email "user@firefly.com" \
        && git config --global user.name "Firefly User" \
        && git config --global color.ui false \
        chmod +x /usr/local/bin/format_usb_to_ext4.sh

