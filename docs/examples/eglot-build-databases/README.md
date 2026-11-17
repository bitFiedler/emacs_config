# Eglot examples: native and Docker builds

These original, small C projects show Make/Bear and CMake export in four configurations. They are teaching examples, not copied upstream code. Internal project deployment examples are maintained separately from this repository. In every demo, `main()` calls `answer()` from another source file through a header declaration. The executable returns zero when the answer is 42.

| Build environment | Build system | Source example | Database |
| --- | --- | --- | --- |
| Native host | Make + Bear | [make-demo](make-demo/Makefile) | Checkout root |
| Native host | CMake export | [cmake-demo](cmake-demo/CMakeLists.txt) | `build/` |
| Docker | Make + Bear | [docker/make-demo](docker/make-demo/Makefile) | `/work/project/` inside Docker |
| Docker | CMake export | [docker/cmake-demo](docker/cmake-demo/CMakeLists.txt) | `/work/project/build/` inside Docker |

Each contains `.dir-locals.el` for both tree-sitter C/C++ modes. Native templates use portable relative database discovery/configuration. Docker templates contain `/ABSOLUTE/PATH/TO/...` placeholders: replace the launcher and host-checkout paths with their real absolute paths before using Eglot. Use the original source directories as templates; do not mix a native database/build cache with a Docker database/build cache. Classic C/C++ modes need equivalent mode-specific settings if used instead of TS modes.

## Without Docker: native Make and Bear

The copy commands assume this repository is at `~/sourcen/emacs_config`; adjust that prefix if your checkout is elsewhere. Install host C compiler/build tools, Bear, clangd and Git. On Debian/Ubuntu an example is `sudo apt install build-essential bear clangd git`; do not run it inside Docker for this native setup.

Copy the example to a new scratch checkout:

```sh
mkdir -p ~/sourcen/eglot-examples
cp -a ~/sourcen/emacs_config/docs/examples/eglot-build-databases/make-demo \
  ~/sourcen/eglot-examples/native-make
cd ~/sourcen/eglot-examples/native-make
git init
bear -- make
./build/demo
```

Use a destination that does not already exist; rerunning `cp -a` into an existing checkout can nest directories. `git init` makes the demo root unambiguous to Eglot; no commit is required. Bear captures actual compiler calls and writes `compile_commands.json` here. The native `.dir-locals.el` starts host clangd, which discovers the database in the ancestor checkout directory. No Docker launcher or path mapping is used.

## Without Docker: native CMake

Install host CMake in addition to the native tools. Copy the CMake template to a separate new checkout:

```sh
cp -a ~/sourcen/emacs_config/docs/examples/eglot-build-databases/cmake-demo \
  ~/sourcen/eglot-examples/native-cmake
cd ~/sourcen/eglot-examples/native-cmake
git init
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
./build/demo
```

Create `~/sourcen/eglot-examples` first if not already created. The native CMake `.clangd` file points host clangd to `build/`, relative to that configuration file. CMake native export replaces Bear for this workflow. Use Makefile or Ninja generators for this option. If your host executable is versioned, adjust `clangd` in the settings to the installed name.

## With Docker: create the example build image

Docker and the generic Python launcher must be available on the **host**. Host compiler, Bear and clangd installations are unnecessary for these Docker demos. Build the example image on the host:

```sh
docker build -t emacs-eglot-demo:local \
  ~/sourcen/emacs_config/docs/examples/eglot-build-databases/docker
```

The [Dockerfile](docker/Dockerfile) installs the required tools from Debian's packages. This is an illustrative development image; it downloads packages and has not been pinned for reproducibility. Docker image builds are separate from source builds.

### Docker Make/Bear

On the host, copy to a new checkout and start the build shell:

```sh
mkdir -p ~/sourcen/eglot-examples
cp -a ~/sourcen/emacs_config/docs/examples/eglot-build-databases/docker/make-demo \
  ~/sourcen/eglot-examples/docker-make
cd ~/sourcen/eglot-examples/docker-make
git init
docker run --rm -it \
  --mount "type=bind,src=$(pwd),dst=/work/project" \
  --workdir /work/project --user "$(id -u):$(id -g)" \
  -e HOME=/tmp emacs-eglot-demo:local
```

Now **inside that container shell**, run:

```sh
bear -- make
./build/demo
```

The database is `/work/project/compile_commands.json`. Keep the container shell open while host Emacs connects. The directory settings select `emacs-eglot-demo:local`, the host `docker-make` checkout and the mount `/work/project`, with that database directory.

### Docker CMake

On the host, use a separate new checkout:

```sh
cp -a ~/sourcen/emacs_config/docs/examples/eglot-build-databases/docker/cmake-demo \
  ~/sourcen/eglot-examples/docker-cmake
cd ~/sourcen/eglot-examples/docker-cmake
git init
docker run --rm -it \
  --mount "type=bind,src=$(pwd),dst=/work/project" \
  --workdir /work/project --user "$(id -u):$(id -g)" \
  -e HOME=/tmp emacs-eglot-demo:local
```

Create the scratch parent first if necessary. **Inside the container**:

```sh
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
./build/demo
```

The database is `/work/project/build/compile_commands.json`; the Docker CMake settings use `--database /work/project/build`. Both Docker demos use the same image, but the launcher distinguishes them by their host checkout mounts. Multiple containers mounting the same demo with that image remain ambiguous and must be resolved.

The container is created with your host UID/GID and a writable `HOME=/tmp`; both the build shell and subsequent launcher commands use that container user configuration. See Docker's [container run reference](https://docs.docker.com/engine/containers/run/) and [exec reference](https://docs.docker.com/reference/cli/docker/container/exec/) for the command options. No root user or ownership change is needed in the host checkout.

## Connect Eglot and test navigation

Open the chosen checkout's `src/main.c` in host Emacs. Accept the reviewed directory settings, run `M-x normal-mode` for an already open buffer, then `M-x eglot` if needed. Stop an old connection first and reset the personal retry budget if exhausted. Put point on `answer`: `M-.` should jump to its definition in `src/answer.c`; `M-x eglot-find-declaration` should go to `include/answer.h`; `M-,` returns.

For native examples all paths are host paths. For Docker examples clangd uses container paths and the helper maps results back to the host. Exiting the `--rm` build shell stops/removes that container; Eglot must be reconnected after a replacement starts. Database and source outputs survive in the host bind mount.

See [the general setup guide](../../eglot-c-cpp-build-setup.md) for upstream sources and troubleshooting. Native Make and CMake builds, executable exit status, two-source databases and clangd database discovery/parsing were verified in temporary directories. The Docker templates and commands are provided for running the same workflows inside the demo image; no image build or Docker navigation test is implied unless separately recorded.

For a real upstream project, see [Linux kernel with and without Docker](../linux-kernel/README.md), including its separate kernel-development Dockerfile.
