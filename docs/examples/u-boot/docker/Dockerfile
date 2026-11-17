FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bear clangd build-essential git ca-certificates bc bison flex \
      python3 python3-dev python3-setuptools python3-pyelftools \
      python3-pycryptodome python3-venv swig device-tree-compiler \
      libssl-dev libgnutls28-dev libsdl2-dev libncurses-dev \
      uuid-dev pkg-config openssl xz-utils lz4 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work/u-boot
CMD ["bash"]
