# Project build tasks (proof of concept)

`my-project-build.el` adds a Helm chooser on top of Emacs compilation mode. It supports native commands and commands in a matching Docker build container, without adding a new package dependency. Helm loads only when the chooser is opened; without Helm it uses ordinary completion. Eglot continues to provide language services independently.

## Commands and keys

| Key / command | Action |
| --- | --- |
| `C-c B b` / `M-x my/helm-project-build` | Choose and run a task |
| `C-c B p` / `C-u M-x my/helm-project-build` | Choose a task and preview its command without running it |
| `C-c B r` / `M-x my/project-build-repeat` | Repeat this project's most recent task |
| `g` in a build buffer | Repeat that buffer's task |
| `M-g n` / `M-g p` | Next / previous compiler diagnostic |
| `RET` on a diagnostic | Visit its source location |

Helm's action menu (`TAB`) also offers **Preview command**. Previews do not contact Docker. Before starting, Emacs offers to save modified files from that project. Builds use distinct buffers named with project, a short root hash and task name; different projects cannot accidentally reuse one another's output. Starting the same active task twice is refused. Repeat operates on the most recent build buffer in the current Emacs session; it is not persisted across restarts.

## Repeat the last selected build

Use `C-c B b` to select a task, then `C-c B r` from a source buffer in the same project to repeat that exact command, flags and working directory. Selecting another task changes the last choice. Make decides what needs rebuilding. `g` instead repeats the task belonging to the displayed build buffer. A running task cannot be started a second time through repeat.

The current session stores the last build buffer for each project. Closing that buffer removes the available repeat target; choose the task again to recreate it. The chooser-to-repeat path is covered by an isolated test that selects an action through the chooser callbacks and invokes the actual `b`/`r` keymap commands from an editing buffer.

## Live output scrolling

Build windows follow new output by default, including output after compiler errors. Scrolling up into older output pauses following in that window; scrolling back until the live end is visible resumes it. `M->` jumps directly to the end and resumes following. Each window follows independently, so one split can show older output while another follows the same build.

The previous `first-error` setting stopped following at the first compiler error. Project build mode now uses live-end following with no automatic jump to the first error. Error navigation remains available through `RET` and `M-g n` / `M-g p`.

Reloading only the module upgrades already open/running build buffers without restarting their modes or processes:

```elisp
(load-file "~/emacstools/my-project-build.el")
```

The scrolling regression runs in a real isolated terminal Emacs after its first redisplay, because batch Emacs has no reliable rendered window geometry. It verifies independent windows, pause/resume, repeated pause, and rapid output bursts arriving before redisplay. Eight non-rendering ERT checks now run in batch; the scrolling check runs separately in a terminal. These include parent-root override, auto-start flag selection and the chooser-to-repeat regression.

## Per-project configuration

Merge a `nil` section into the project's existing `.dir-locals.el` (keep existing Eglot settings):

```elisp
((nil
  . ((my/project-build-tasks
      . (("Make: incremental" :command "make -j2")
         ("Make: capture compiler database"
          :command "CCACHE_DISABLE=1 bear --output compile_commands.json -- make -B -j2")
         ("CMake: configure"
          :command "cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
         ("CMake: build" :command "cmake --build build -j2")
         ("CMake: test" :command "ctest --test-dir build --output-on-failure"))))))
```

Choose tasks appropriate to the project; this example shows alternatives. Each task is `(NAME :command SHELL-COMMAND ...)`, with an optional `:directory` relative to the project root. That directory must already exist. The project is located using built-in `project.el`; a Git checkout needs no additional project package. Task settings contain executable commands and are deliberately treated as risky local variables: review and accept Emacs's local-variable prompt. They are not globally marked safe.

For sources inside a Git submodule whose build scripts/Docker mount belong to a parent checkout, set `my/project-build-root` in the same `nil` directory-local section:

```elisp
(my/project-build-root . "/absolute/path/to/parent-checkout")
```

This optional existing absolute directory overrides only the build task root. It leaves Eglot and other `project.el` commands unchanged. The parent `.dir-locals.el` can then supply tasks inherited by source files inside the submodule. Review local-variable settings and adjust the path on another device. With nil, normal project-root discovery remains the default.

With no configured task list, a root `CMakeCache.txt` offers `cmake --build .`; otherwise a root `Makefile` offers `make -j2`. The proof of concept does not infer CMake build directories, cross-compilers, U-Boot board configurations or packaging scripts. Configure those explicitly.

Bear records compiler calls that actually occur; incremental cache hits or an up-to-date tree can produce incomplete/empty captures. The force-rebuild example avoids a no-op and disables ccache for that invocation. For an established script that captures internally, run the script directly, without nesting Bear. Keep build commands and compiler-database generation in the project; this chooser does not silently wrap all builds in Bear or reconnect Eglot.

## Docker tasks

Add both `:docker-image` and `:container-root`:

```elisp
((nil
  . ((my/project-build-tasks
      . (("Container: check tools"
          :command "command -v make && command -v bear && command -v clangd"
          :docker-image "my-build-image:latest"
          :container-root "/workspace")
         ("Container: incremental build"
          :command "make -j2"
          :docker-image "my-build-image:latest"
          :container-root "/workspace")
         ("Container: build subdirectory"
          :command "make -j2"
          :directory "tools"
          :docker-image "my-build-image:latest"
          :container-root "/workspace"))))))
```

The Python runner reuses `my-docker-clangd.py` discovery: match the exact configured image and an exact bind mount of the current project root to the configured container root. A matching running container is reused, including one started with the project's normal script. If none is running, the chooser now starts a background build container automatically. Multiple matches, Docker permission errors and daemon failures remain errors; they never trigger an additional container.

Automatic startup is enabled by `my/project-build-auto-start-docker` (default `t`). Set it to nil globally or use `:docker-auto-start nil` on a particular task when its environment must be started manually. `:docker-auto-start t` explicitly enables startup for a task. Command previews never start/restart containers; the runner's `--print-command` also refuses to start one, even with `--auto-start`.

The background container has a deterministic `emacs-build-...` name based on image, canonical host checkout, container mount and host UID. Repeated builds reuse it; a stopped container with that name is restarted only after validating its image and checkout mount. Docker's unique name prevents concurrent requests from creating duplicates. Unrelated stopped containers are left alone. Manual startup remains available for special environments.

Managed startup uses the existing local image (`--pull=never`), the checkout bind mount and work directory, host UID/GID, read-only `/etc/passwd`, and writable `HOME=/tmp`. A small `/bin/sh` wait loop keeps it alive without an interactive terminal. It does not run the interactive project startup script, copy SSH keys, mount the Docker socket, enable privileged mode, inject host proxy settings or add pretty-shell/history customization. Use a manually started matching container when those project-specific extras are needed. The local image must already contain the toolchain; missing images are reported rather than downloaded. Automatic mount creation currently rejects commas in mount paths.

These containers remain running after a build finishes or its buffer is killed, allowing subsequent builds and Eglot to reuse them. Stop a managed container explicitly with `docker stop NAME` when it is no longer needed; Eglot in that container will disconnect. Eglot itself still does not auto-start containers—run a build/tool-check task first or start one manually.

The command runs with `docker exec --workdir ... CONTAINER sh -c COMMAND`, with no TTY or interactive input. Shell commands are intentional, reviewed project configuration; the outer invocation quotes each argument. Docker's exit status appears in the compilation buffer. Paths under the configured container mount translate to the host checkout for error navigation, including relative diagnostics following Make's entering-directory messages. Output text itself stays unchanged. Translation is local to these build buffers and survives `g`/repeat. Headers outside the mount need additional mappings and are outside this proof of concept.

Requires Python 3, the Docker CLI, access to Docker, and a locally installed image containing `/bin/sh`, `sleep` and the build tools. `my/project-build-python` selects the Python executable. Install both Python helpers together; the repository installer includes them automatically. Native tasks do not need Python or Docker.

## Limits and validation

This is a chooser for existing commands, not a new build system. No automatic cleaning, signing, flashing or building on save occurs. A task that invokes a packaging script still performs every action that script contains. Interactive password prompts are not supported. Interrupting/killing a Docker client is not guaranteed to stop its container-side build; check the container before rerunning a canceled task.

Tests cover native/Docker shell quoting, directory validation, nonexecuting previews, duplicate-build rejection, compiler failure status, actual navigation to both relative and absolute simulated Docker diagnostics, and repeat/path-map persistence. Python tests cover shared container discovery handoff and non-TTY execution. A real Docker tool check can verify connectivity without compiling firmware. Full firmware builds, image builds and GUI layout are separate manual checks.

Validation on 17 November 2026: 24 Python tests and five isolated ERT tests passed. The actual Helm picker was exercised in an isolated terminal Emacs with the preview action; no build was started. A live tool-check command selected the intended running container and found Make, Bear, clangd and the compiler. The current Emacs server socket was unavailable, so activation in an existing session uses the targeted load below rather than a full configuration reload.

```elisp
;; M-: in a project file buffer; then review any directory-variable prompt.
(progn (load-file "~/emacstools/my-project-build.el")
       (hack-local-variables))
```

Automatic startup validation: 32 Python tests passed, including reuse, missing-container creation, matching stopped-container restart, conflict recovery, startup-error preservation and no startup on ambiguity/permission/daemon failures or previews. Seven non-rendering ERT tests passed; the existing rendering test is run separately in a terminal. A live isolated Docker test verified creation, repeat reuse, host UID, tool availability and restart of the same stopped container. Its temporary container was removed; user project containers were not stopped or altered. No firmware build was run. Reload the module and select a task afresh after upgrading; an old build buffer's `g` repeats its original saved command.
