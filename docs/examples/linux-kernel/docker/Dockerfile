FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bear clangd build-essential git ca-certificates python3 \
      bc bison flex gawk perl pkg-config libssl-dev libelf-dev libncurses-dev \
      dwarves cpio rsync kmod xz-utils zstd \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work/linux
CMD ["bash"]
