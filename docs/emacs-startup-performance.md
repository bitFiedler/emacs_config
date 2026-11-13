# Emacs startup performance

The shared config loads optional tools on demand, reduces garbage collection during startup, and bounds synchronous terminal capability-query waits. These changes are separate from the existing weekly Quelpa update policy.

## What changed

- `~/.emacs.d/early-init.el` requires `~/emacstools/my-startup-performance.el`. Before initialization finishes, it raises the GC threshold to at least 64 MiB and the allocation percentage to at least 0.6. A late `emacs-startup-hook` restores the original early-init values. It does not leave the startup threshold enabled during normal editing or force an extra collection at startup completion.
- Vundo loads through `C-c u`. Its undo memory limits still apply immediately; its glyph and face setup runs when Vundo loads.
- Multiple Cursors loads through its existing shortcuts, including `C->`, `C-<` and `C-c C-s`.
- Deadgrep loads through `M-s`, then loads the local recursion, hiding and error-summary extension.
- Magit loads through its commands, including `magit-status` and `magit-dispatch`. Its existing configuration and Gitflow integration run after Magit loads.
- Helm Gtags loads when one of its existing Dired, Eshell, C/C++, Tree-sitter C/C++ or assembly hooks runs. Its navigation shortcuts are installed then.
- Helm RG, Git file selection, Company, Flycheck, Fuzzy, LSP, Ispell and BM integrations load through their commands. In particular, the Helm LSP integration no longer pulls `lsp-mode` into startup solely because Helm is active. Eglot remains your configured language client.
- Elpy and Pyvenv load through their commands. Python shell settings remain available immediately. This does not enable Elpy automatically.
- The Org configuration no longer explicitly requires the whole Org library during startup. Its mode, link, agenda and indentation commands autoload their libraries. Existing settings, keybindings, Superstar and Org Tempo configuration remain in place.

Helm itself, the theme, your editing modules and the existing global modes retain their configured startup behavior. File visits can still load the relevant packages during startup if command-line files or restored sessions need them. Deferred loading shifts a library's cost to its first use; it does not remove the feature.

## Measuring startup

After a normal restart, run:

```text
M-x my/startup-report
```

This reports Emacs's initialization time, elapsed time through the late startup hook (`ready`), the most recent XTerm initialization duration, the number of collections since the early performance module loaded, and the current restored GC threshold. `M-: (emacs-init-time)` reports only initialization time: Emacs initializes its terminal library afterward, so this value alone can miss terminal-query delays. These timings exclude total desktop launch/rendering overhead and completion of asynchronous language-server work. Requiring the performance module late in an already running session cannot reconstruct startup GC counts.

On `mp-linux`, an isolated evaluation of the changed package declarations (with package installation disabled) measured:

| Check | Before | After |
| --- | --- | --- |
| Median of three fresh batch processes | 0.508 s | 0.152 s |
| Individual runs | 0.514, 0.507, 0.508 s | 0.153, 0.152, 0.152 s |

This is approximately 0.36 seconds less work for that selected subset, about 70%. It is **not** a measurement of the entire graphical startup. Filesystem caches, device performance and opened files affect the result. No full init was executed for testing because that would run package updates, session hooks and other configured integrations.

## Terminal startup delays

On the installed Emacs 31 build, XTerm-compatible initialization normally sends secondary and primary device-attribute queries. The default query timeout is two seconds. A terminal or multiplexer that does not answer those queries can therefore add roughly four seconds after the main init has finished. An additional terminal-name query has its own shorter timeout.

An isolated PTY test, with no real user init or package activation, measured **4.278 seconds** with the original waits and **0.570 seconds** with the shorter waits. A separate `emacs -nw -Q` check took 4.249 seconds. This demonstrates a terminal-negotiation delay in the test PTY; timing in the actual terminal emulator, WSL host or multiplexer can differ.

`my/startup-terminal-query-timeout` defaults to **0.2 seconds**. An advice around `terminal-init-xterm` temporarily caps synchronous query waits and caps the initial redisplay wait at 0.05 seconds. Emacs's asynchronous fallback remains installed for unanswered initialization queries. This does not disable terminal feature detection, bracketed paste or focus tracking. Dynamic binding restores the normal query settings after initialization, so clipboard requests during editing retain their original timeout. The setting also applies when initializing later XTerm-compatible terminal frames; graphical initialization does not call this terminal function.

To restore Emacs's original waits, put this **before** the performance-module require in `early-init.el`:

```elisp
(setq my/startup-terminal-query-timeout nil)
```

If features require more time on a slow remote terminal, a larger value such as 0.5 can be used instead. Restart the terminal Emacs to compare; loading the module after terminal initialization cannot speed up the initialization that has already occurred. The timing report still records terminal duration when the cap is disabled.

## Profiling slow initialization on another device

The reported WSL2 terminal launch took 3.635 seconds for initialization, 3.928 seconds through the startup checkpoint, and only 0.111 seconds for terminal initialization. The graphical WSL2 launch took 4.184 seconds for initialization and 4.643 seconds through the startup checkpoint, with no terminal initialization recorded. Both interfaces therefore spend most of their startup time inside initialization; these single-run differences do not establish an interface-specific bottleneck. This indicates that the remaining delay is primarily inside initialization, rather than the terminal capability waits. The exact slow operation needs measurements from that device; a slow executable path, package load, filesystem lookup or helper process must not be assumed without a profile.

Copy the updated `~/emacstools/my-startup-performance.el` to the WSL2 installation, then launch from its shell:

```sh
EMACS_STARTUP_PROFILE=1 emacs -nw
```

For a graphical comparison, launch `EMACS_STARTUP_PROFILE=1 emacs` instead. After startup, run:

```text
M-x my/startup-profile-report
```

The read-only `*Emacs Startup Profile*` buffer lists measured operations, sorted by **Self ms**, with **Incl. ms**, call count, operation kind and name. Self time excludes nested measured calls; inclusive time includes them. Do not add inclusive times across rows, because parent and child calls overlap. Share the first 20–30 rows to identify the dominant remaining costs. File/library/program names are recorded; file contents, process arguments and clipboard text are not.

The optional profiler measures `load`, `require`, `executable-find`, `call-process` and `process-file` until the late startup hook. It uses wall time so filesystem waits and synchronous helper waits are represented. Operations outside these functions are only represented indirectly when enclosed by a measured load. Some earliest work before the performance module loads, asynchronous process completion and desktop rendering are outside this profile. Instrumentation adds overhead, so compare normal launches for final speed measurements.

Profiling is off by default. The shell assignment applies only to this launch, and profiling advice is removed at the startup checkpoint even for the profiling launch. No report file is written automatically; the collected timings stay available in that Emacs session. Loading the module after startup cannot reconstruct a profile. `M-x my/startup-report` remains the quick overall timing command.

## WSL: slow executable searches

The N900D9658 profile identified executable searches as the dominant measured startup cost: seven probes for `gm` took 734 ms, with missing browser candidates and image/network utilities generally taking around 100 ms each. Installed tools such as `git` and `rg` were found quickly. These are optional-tool availability checks, not a request to install every missing utility. Repeated scans through a slow directory late in the search path explain this pattern; WSL's inherited Windows-drive directories are a likely source, but the actual directory list was not included in the submitted profile.

With `my/startup-wsl-native-executable-lookups` enabled (the default), the performance module detects WSL through its environment or kernel release. During startup only, it filters Windows-drive entries out of `exec-path` **inside `executable-find` calls for bare native tool names**. By default, those entries match `/mnt/<drive-letter>/...`. It keeps the order and contents of the remaining Linux search directories.

- This applies to graphical and terminal WSL Emacs. Ordinary Linux/Pop!_OS is unaffected.
- Explicit paths, bare names ending in `.exe` (case-insensitive), and remote-aware requests retain the full original lookup policy.
- Neither the global `exec-path` nor the `PATH` environment variable is modified. Process-launch and shell-command search paths remain intact.
- The temporary advice is removed at the late startup checkpoint. Subsequent `executable-find` calls use the complete original search path.
- Linux scripts stored only on an excluded Windows drive can be missed by startup availability checks; packages may retain the resulting choice. Add such native-tool directories to the keep list, or disable the optimization. Explicit paths still work during startup.

Options, set before the performance-module require in `early-init.el`:

```elisp
;; Optional: restore full-path probing throughout startup.
(setq my/startup-wsl-native-executable-lookups nil)

;; Or retain an exact exec-path entry containing native Linux tools.
(setq my/startup-wsl-keep-exec-directories '("/mnt/c/my-linux-tools/bin"))
```

`my/startup-wsl-windows-directory-regexp` configures the skipped directory pattern; its default matches a single-letter drive beneath `/mnt/`. The optional startup profile reports how many Windows-drive directories were skipped. A count of zero means no matching entries were filtered; if lookups remain slow, inspect the actual executable search path instead of assuming the source is a standard Windows mount.

The subsequent WSL2 measurements reported from N900D9658 were:

| Interface | Initialization before → after | Ready before → after | Terminal init after |
| --- | --- | --- | --- |
| Graphical | 4.184 → 0.837 s | 4.643 → 1.261 s | Not applicable |
| Terminal | 3.635 → 0.780 s | 3.928 → 1.472 s | 0.124 s |

These individual launches show roughly 80% less initialization time and strongly support the executable-search diagnosis. They are user-reported measurements from the WSL device, not repeated controlled benchmarks on this machine. Both launches restored the GC threshold to 800000 bytes and recorded two startup collections.

Synchronize the updated `my-startup-performance.el` to WSL2 and restart to apply it. Loading the module into an already started session does not apply the startup-only filter retroactively.

## Applying on both devices

Restart Emacs to measure the effect: reloading the init does not unload packages already in memory. Synchronize these changed files to the other device along with the shared config:

- `~/.emacs`
- `~/.emacs.d/early-init.el`
- `~/emacstools/my-startup-performance.el`
- `~/emacstools/python_config.el`
- `~/emacstools/org_config.el`

The performance changes have no hostname condition. The separate `my-device-font.el` module continues selecting 9 pt on N900D9658 and 11 pt on mp-linux.

## Validation and maintenance

The isolated regression suite is:

```sh
emacs -Q --batch -l ~/emacstools/my-startup-performance-tests.el
```

All nine tests pass. They verify GC restoration, safe manual reload, on-demand loading, preserved shortcuts and settings, first-use Deadgrep/Vundo/Magit/Gtags configuration, and Org mode's indentation, Superstar and Tempo setup. Terminal checks also verify scoped timeouts, opt-out behavior, preserved asynchronous handlers and restoration of the editing-time query defaults. Profiling checks cover real load/executable lookups, nested self/inclusive accounting, original return/error behavior, advice cleanup and omission of process arguments from the report. WSL checks cover native executable selection, mounted-directory exclusions and exceptions, explicit paths and .exe commands, remote bypass, unchanged global PATH/exec-path, detection, opt-out and cleanup at the startup checkpoint. The module compiles without warnings, and edited Lisp files pass balanced-parenthesis checks. The tests do not execute the full init, package installers, external language servers or preview processes.

Backups of changed configuration/modules are in `~/emacstools/backup/`; documentation backups are in `~/Documents/codex/emacs/backups/`. Installed package files are unchanged.
