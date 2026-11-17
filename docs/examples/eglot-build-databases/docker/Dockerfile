FROM debian:trixie-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bear build-essential clangd cmake ninja-build ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /work/project
CMD ["bash"]
