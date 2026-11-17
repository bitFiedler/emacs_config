# Upstream U-Boot: Eglot with and without Docker

[U-Boot](https://source.denx.de/u-boot/u-boot) uses Make/Kbuild. Use **Bear** to capture its actual compiler calls; CMake export is not the build mechanism here. The public walkthrough uses a fresh `v2025.10` upstream checkout and `sandbox_defconfig`, allowing compilation for the Linux host without a private board setup, firmware signing or flashing. No upstream source is vendored.

| Environment | Settings | Database |
| --- | --- | --- |
| Native Linux | [native directory settings](native/.dir-locals.el), [clangd configuration](native/.clangd) | Checkout root |
| Docker | [Dockerfile](docker/Dockerfile), [directory settings](docker/.dir-locals.el), [clangd configuration](docker/.clangd) | `/work/u-boot` |

## Native Linux

Install GCC/build tools, Bear, clangd and the development dependencies for the selected U-Boot version/target. The [upstream GCC build guide](https://docs.u-boot.org/en/v2025.10/build/gcc.html) is authoritative for prerequisites. The Dockerfile lists a useful Debian package starting point; sandbox requires additional host libraries compared with some embedded-board targets.

Use a fresh source tree:

```sh
mkdir -p ~/sourcen/eglot-examples
cd ~/sourcen/eglot-examples
git clone --depth 1 --branch v2025.10 \
  https://source.denx.de/u-boot/u-boot.git u-boot-native
cd u-boot-native
cp ~/sourcen/emacs_config/docs/examples/u-boot/native/.dir-locals.el .
cp ~/sourcen/emacs_config/docs/examples/u-boot/native/.clangd .
make sandbox_defconfig
bear --output compile_commands.json -- make -j"$(nproc)"
```

These commands assume this Emacs repository is at `~/sourcen/emacs_config`; adjust that prefix as needed. `sandbox_defconfig` sets the configuration, so use it in the new example checkout only. Preserve the actual board `.config`, cross-compiler and `O=` build directory when adapting to an existing project. A full sandbox build is a real build, not just editor setup. Upstream documents sandbox operation in its [sandbox guide](https://docs.u-boot.org/en/latest/arch/sandbox/sandbox.html).

Open a captured source file such as `common/board_f.c` in host Emacs, accept the reviewed settings and run `M-x eglot` if it does not start automatically. Host clangd reads the root database. Native settings contain no Docker paths. If the executable is versioned, adjust its name. Prefer a current clangd for the native example.

## Existing projects with build.sh

If a project's normal script performs the actual build, capture that script rather than replacing its configuration steps with generic Make commands:

```sh
# Run from the actual project root, with its intended script/arguments.
bear --output "$(pwd)/compile_commands.json" -- ./build.sh
```

The absolute output path stays stable if the script changes working directory. If the script already invokes Bear, do not nest another wrapper. Review its cleaning, configuration, signing and packaging actions before running it solely for editor purposes. Build captures only provide commands that actually execute; a no-op/incomplete build is not complete source coverage.

Keep one coherent board/configuration state. A script building several variants in one tree leaves one final set of generated headers. Do not assume one mixed database provides simultaneous analysis of all those variants. `bear --append` is useful for incremental work on the same configuration, not arbitrary mixing of targets/toolchains.

## Docker image and source checkout

Build the [public development Dockerfile](docker/Dockerfile) on the host:

```sh
docker build -t emacs-eglot-u-boot:local \
  ~/sourcen/emacs_config/docs/examples/u-boot/docker
```

This installs Bear, clangd, GCC/build tools and common sandbox prerequisites. The image does not contain a kernel or U-Boot checkout and does not flash hardware. Package requirements can vary with the selected U-Boot release/target; consult upstream if a build requests an additional tool/library. Base/package versions are not pinned for reproducibility.

On the host, create a separate new checkout:

```sh
mkdir -p ~/sourcen/eglot-examples
cd ~/sourcen/eglot-examples
git clone --depth 1 --branch v2025.10 \
  https://source.denx.de/u-boot/u-boot.git u-boot-docker
cd u-boot-docker
cp ~/sourcen/emacs_config/docs/examples/u-boot/docker/.dir-locals.el .
cp ~/sourcen/emacs_config/docs/examples/u-boot/docker/.clangd .
```

Edit `.dir-locals.el` to replace both `/ABSOLUTE/PATH/TO/...` placeholders with the host launcher path and this checkout's real absolute path. Keep the image `emacs-eglot-u-boot:local`, container mount `/work/u-boot` and database `/work/u-boot` in agreement.

Start a container from that checkout:

```sh
docker run --rm -it \
  --mount "type=bind,src=$(pwd),dst=/work/u-boot" \
  --workdir /work/u-boot --user "$(id -u):$(id -g)" \
  -e HOME=/tmp emacs-eglot-u-boot:local
```

Inside the container:

```sh
make sandbox_defconfig
bear --output /work/u-boot/compile_commands.json -- make -j"$(nproc)"
```

Keep the shell/container running while host Emacs connects. The helper selects exactly one container by image and exact host bind mount; it does not rely on generated names. Database/compiler/header paths stay inside the container. The helper maps LSP URIs back to host files. After the `--rm` container exits, start a replacement and reconnect Eglot.

## GCC/clangd compatibility

The templates document two GCC options that older clangd may reject: `-fstack-usage` and `-fno-toplevel-reorder`. `.clangd` removes them for analysis, with `--enable-config` explicitly passed. These settings do not change the real GCC build.

Some older clangd versions can still retain such flags in their initial commands. The Docker example additionally uses the generic helper's repeatable `--remove-compile-flag=-flag` option. It reads the raw database on the host bind mount, writes a content-keyed derived database under `.cache/my-docker-clangd/`, and points container clangd there. Only exact requested flags are removed; compiler, working directory, includes, defines and source paths remain intact. The raw Bear database is not overwritten.

The generated database is selected at launch. After a new Bear capture, reconnect Eglot to regenerate/select the new derived database. `--print-command` inspects the selected command without writing cache files; normal launch creates them. Filtering requires the raw database to be inside the mounted project root. For native older clangd, upgrade the server or create an equivalent separate analysis database rather than changing real build flags. Add other exclusions only for actual diagnostics.

## Eglot use and validation limits

Stop an obsolete connection, run `M-x normal-mode`, accept the reviewed directory settings and run `M-x eglot` if needed. Clear the personal exhausted retry budget with `M-x my/eglot-reset-retries`. Use `M-.` for definitions, `M-x eglot-find-declaration` for declarations, `M-?` for references and `M-,` to return. Coverage depends on the selected config, generated headers, captured sources and index progress; disabled board code may not be represented.

The generic helper's derived-database behavior is unit-tested with argument-array and command-string entries. Its compatibility options were verified in a separate existing U-Boot development environment with Bear 3.0.8 and clangd 11: a captured C source parsed with zero errors, and a real definition request returned a host-path location. This does not claim the public v2025.10 sandbox clone/build or this Dockerfile has been executed. Those are documented workflows checked against upstream instructions. The [general C/C++ guide](../../eglot-c-cpp-build-setup.md) and [small Make/CMake demos](../eglot-build-databases/README.md) explain the broader setup.
