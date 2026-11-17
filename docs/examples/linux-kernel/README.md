# Upstream Linux kernel: Eglot with and without Docker

These examples use a fresh checkout of the public [upstream Linux kernel](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git), tag `v6.12`, for a concrete x86-64 teaching example. No kernel source is vendored in this repository. They use **Bear for Make/Kbuild**, preserving GCC as the actual compiler. They do not use or document internal projects/registries.

| Environment | Configuration examples | Compiler database |
| --- | --- | --- |
| Native Linux x86-64 | [native settings](native/.dir-locals.el), [clangd flags](native/.clangd) | `linux-native/compile_commands.json` |
| Docker Linux amd64 | [Dockerfile](docker/Dockerfile), [Docker settings](docker/.dir-locals.el), [clangd flags](docker/.clangd) | `/work/linux/compile_commands.json` |

Use separate new checkouts for native and Docker builds so their absolute paths and generated files do not mix. The commands assume `emacs_config` is at `~/sourcen/emacs_config`; adjust that prefix if needed. This is editor/build tooling: none of these commands installs or boots a kernel.

## Native: prepare a fresh checkout

Use a Linux x86-64 host. The package example below targets Debian/Ubuntu; use equivalent packages on other distributions. Kernel requirements depend on the source version/configuration; see [upstream requirements](https://docs.kernel.org/6.12/process/changes.html).

```sh
sudo apt install bear clangd build-essential git ca-certificates python3 \
  bc bison flex gawk perl pkg-config libssl-dev libelf-dev libncurses-dev \
  dwarves cpio rsync kmod xz-utils zstd
mkdir -p ~/sourcen/eglot-examples
cd ~/sourcen/eglot-examples
git clone --depth 1 --branch v6.12 \
  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux-native
cd linux-native
cp ~/sourcen/emacs_config/docs/examples/linux-kernel/native/.dir-locals.el .
cp ~/sourcen/emacs_config/docs/examples/linux-kernel/native/.clangd .
make ARCH=x86_64 defconfig
```

Run `defconfig` only in this fresh example tree: it sets the configuration. Keep the existing intended `.config` when adapting these commands to a real project. `ARCH=x86_64` selects the example architecture; a non-x86 host requires the corresponding cross toolchain or the amd64 Docker workflow below.

## Native: smaller first capture

Build one kernel source object and its required preparation steps:

```sh
bear --output compile_commands.json -- \
  make ARCH=x86_64 -j"$(nproc)" init/main.o
```

This is a real compilation, including generated headers and build tools needed for the object; it is substantially narrower than compiling the whole kernel. It captures the selected object and prerequisite compiler invocations, not every driver/subsystem. An up-to-date object may not trigger another compiler call. Reuse an existing database or capture a later real compilation rather than assuming every invocation repopulates it.

Open `init/main.c` in host Emacs, accept the reviewed directory settings, and run `M-x eglot` if needed. The native settings start host clangd, which finds the root database without Docker/path mapping. Confirm that its executable is named `clangd`, or edit the settings to the installed versioned name.

## Native: broader indexing through a normal build

When a full build is desired, capture it with the same configuration:

```sh
bear --append --output compile_commands.json -- \
  make ARCH=x86_64 -j"$(nproc)"
```

This can take substantial time/resources. Append is suitable for the same configuration; regenerate coherently when switching architecture/configuration/toolchain. Capture only actual compiler invocations; a no-op build adds no source coverage. Files disabled in `.config` are not guaranteed indexed. Preserve your actual `O=`, `CROSS_COMPILE=` and target options if adapting this workflow; out-of-tree build directories require database/generated-header paths to match that layout.

## Docker: build the development image

The [Dockerfile](docker/Dockerfile) installs Bear, clangd, GCC/Kbuild tools and common Linux build dependencies. On the host:

```sh
docker build --platform linux/amd64 -t emacs-eglot-linux:local \
  ~/sourcen/emacs_config/docs/examples/linux-kernel/docker
```

The example targets amd64 even on a host of another architecture. A non-amd64 Docker host requires amd64 emulation support; performance depends on that environment. The source tag is fixed for the walkthrough, while the Debian base/package versions are not pinned by digest/version. This image is a development example, not a reproducible kernel distribution.

## Docker: checkout and start the container

On the host, use a separate fresh source tree:

```sh
mkdir -p ~/sourcen/eglot-examples
cd ~/sourcen/eglot-examples
git clone --depth 1 --branch v6.12 \
  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux-docker
cd linux-docker
cp ~/sourcen/emacs_config/docs/examples/linux-kernel/docker/.dir-locals.el .
cp ~/sourcen/emacs_config/docs/examples/linux-kernel/docker/.clangd .
```

Edit the copied `.dir-locals.el`: replace `/ABSOLUTE/PATH/TO/my-docker-clangd.py` with the host helper path (normally `~/emacstools/my-docker-clangd.py`, expanded to an absolute path), and `/ABSOLUTE/PATH/TO/linux-docker` with this checkout's actual absolute path. Keep the demo image, container root and database settings as provided.

Then start the container from that checkout:

```sh
docker run --rm -it --platform linux/amd64 \
  --mount "type=bind,src=$(pwd),dst=/work/linux" \
  --workdir /work/linux --user "$(id -u):$(id -g)" \
  -e HOME=/tmp emacs-eglot-linux:local
```

The container remains running while its shell is open. The generic launcher selects it by image `emacs-eglot-linux:local` and exact checkout mount at `/work/linux`; generated container names do not matter. Stop duplicate matching containers if selection is ambiguous.

## Docker: build/capture inside the container

Run these commands **inside the container shell**, not on the host:

```sh
make ARCH=x86_64 defconfig
bear --output /work/linux/compile_commands.json -- \
  make ARCH=x86_64 -j"$(nproc)" init/main.o
```

For an intentionally broader build of the same configuration:

```sh
bear --append --output /work/linux/compile_commands.json -- \
  make ARCH=x86_64 -j"$(nproc)"
```

Database paths and generated headers remain container paths. Host Emacs edits the bind-mounted sources; the launcher runs clangd in that container and maps `/work/linux/...` navigation results back to the host checkout. Using host clangd with this container database would require accessible dependencies and compatible paths, so do not mix the workflows.

The container is created with your host UID/GID; source/build outputs are owned accordingly. The helper and host Docker access are required, but host Bear/clangd/GCC installations are not needed for this Docker workflow. Exiting the `--rm` shell removes the container, while bind-mounted outputs persist. Start a replacement and reconnect Eglot after that.

## clangd compatibility and navigation

Both examples supply `.clangd` exclusions for common GCC-only x86 kernel flags. They affect analysis only; the GCC build flags remain intact. Treat the list as a starting point for the documented version/architecture. Other kernel/compiler configurations may need different adjustments based on actual diagnostics.

Keep `.config`, generated includes, architecture headers, source and database consistent. clangd's index follows the built configuration. Source files outside captured commands may receive inferred flags or incomplete results; broader indexing takes time.

In host Emacs, stop any old connection, run `M-x normal-mode` to reload directory settings and then `M-x eglot`. If the personal retry budget was exhausted, run `M-x my/eglot-reset-retries` first. In `init/main.c`, choose a function name and use `M-.` for its definition, `M-x eglot-find-declaration` for its declaration, `M-?` for references and `M-,` to return. Completion, rename and code actions depend on server support and valid parsing; not every kernel macro/configuration combination guarantees complete results.

Inspect a representative file in the chosen build environment with `clangd --check=init/main.c --compile-commands-dir=.`. Read the diagnostics: standalone checking can also test refactorings and does not replace a real Eglot connection test.

## Optional: use saved Kbuild records

Bear is the preferred Make workflow. If an already built kernel has useful `.cmd` files and you do not want another compilation, the upstream [Kbuild database generator](https://github.com/torvalds/linux/blob/v6.12/scripts/clang-tools/gen_compile_commands.py) is an optional alternative. Run it in the same environment/layout as the build. Eglot analysis does not require switching the real build to Clang; [upstream LLVM build instructions](https://docs.kernel.org/kbuild/llvm.html) cover that separate choice.

## Sources and validation

The examples were checked against the [Linux v6.12 Makefile](https://github.com/torvalds/linux/blob/v6.12/Makefile), [Kbuild documentation](https://docs.kernel.org/6.12/kbuild/makefiles.html) and [software requirements](https://docs.kernel.org/6.12/process/changes.html). See also the [general Eglot setup](../../eglot-c-cpp-build-setup.md) and [small native/Docker demos](../eglot-build-databases/README.md).

The configuration syntax and links are checked locally. clangd 20 also accepted the exclusion list when parsing a tiny synthetic C file with those GCC flags; this checks flag filtering, not kernel compilation or navigation. No upstream kernel clone, fresh native kernel build, demo image build or live kernel-Docker navigation test was performed for this documentation. These examples provide the workflow and configuration, with testing limits stated separately from the previously verified small C demos.
