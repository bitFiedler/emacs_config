# Helm file browsing and protected results

`~/.emacs` loads `~/emacstools/my-helm-files.el` from the Helm configuration. The module keeps retained Helm result buffers read-only and gives the Find Files chooser room in split-window layouts.

## Why a Helm listing was editable

Helm creates its candidate buffer in a mode derived from Fundamental mode and explicitly makes it writable for its rendering engine. The buffer can remain writable after the chooser closes. It is an internal candidate listing, not the selected source file.

The local cleanup hook sets the retained results buffer read-only when each Helm session ends, including cancellation. Loading the module also locks existing inactive Helm result buffers. Helm's real setup function makes the buffer writable again when reusing it for a live session, so updates, marking and selection keep working. The active candidate rendering buffer remains internally writable; input should be edited through the minibuffer. This is protection for inactive listings, not a replacement for Helm's rendering model.

The cleanup applies to Helm results generally, including Find Files and Mini. It does not lock the minibuffer, opened source files, or intentional file-renaming interfaces. Existing next/previous-buffer filtering continues to skip internal Helm buffers.

## Long paths and split windows

For Helm file browsing, the results open in a full-width bottom side window, about 35% of the frame's height. Existing editor windows remain above it. Helm restores their layout on selection or cancellation.

Path input appears in the normal visible minibuffer rather than being echoed into the file-picker header. The minibuffer permits long input to wrap and grow up to 25% of the frame; very long input can still scroll after that limit. Other Helm commands retain the configured header-line input style. File paths and candidates are not rewritten or abbreviated for actions.

Candidate labels show just filenames by default, while the editable prompt contains the current directory. Dotted entries remain compact (`.` and `..`). The built-in `C-]` toggle switches basename/full-path candidate labels when needed.

## Useful keys inside Find Files

| Key | Effect |
| --- | --- |
| `C-x C-f` outside Helm | Open Helm Find Files, as before. |
| `C-c C-b` inside Find Files | Return to the directory of the buffer where the chooser was opened. |
| `C-l` inside Find Files | Go up one directory. A numeric prefix moves up that many levels. |
| `C-a`, `C-e` | Move to the beginning/end of the input line to edit the path. |
| `C-k` | Clear Helm input; this is Helm's binding, not ordinary kill-to-end-of-line. |
| `C-]` | Toggle filename-only/full-path candidate labels. |
| `C-c h` | Browse file/directory history. |
| `Tab` | Persistent action, such as entering a selected directory, with your existing configuration. |
| `Enter` | Enter a directory or open the selected file. |
| `C-g` | Cancel and restore the editor layout. |

Helm normally guesses a filename or path from text under the cursor. If your buffer contains an unrelated filename and Find Files starts there, press **`C-c C-b`**: hold Ctrl, press c, then b while still holding Ctrl. `my/helm-files-origin-directory` replaces the chooser input with the actual directory of the originating buffer's visited file. In a non-file buffer, it uses that buffer's `default-directory`. It stays in the existing chooser; no file is opened by this shortcut.

The guessed-path behavior remains enabled. To always start from the current buffer's default directory instead, the built-in option is:

```elisp
(setq helm-find-files-ignore-thing-at-point t)
```

This option is documented as an alternative and is **not enabled** by the local module. It disables using paths at point as the initial input; `C-c C-b` provides a one-shot return without that global change.

Typing another absolute path or a path beginning with `~/` uses Helm's normal file-navigation behavior. No file is renamed merely by editing the prompt; explicit Helm file actions retain their usual behavior.

## Options

Use `M-x customize-group RET my-helm-files` or set these variables:

| Option | Default | Purpose |
| --- | --- | --- |
| `my/helm-files-wide-window` | `t` | Full-width bottom file picker; nil uses the existing Helm display policy. |
| `my/helm-files-window-height` | `0.35` | Desired frame-height fraction for that picker, subject to window minimum sizes. |
| `my/helm-files-edit-in-minibuffer` | `t` | Visible, wrapping path input for file browsing; nil uses the existing input-display policy. |

These options take effect the next time the chooser opens. The width and input settings are dynamically scoped to `helm-find-files-1` sessions; global layout settings for other Helm commands are unchanged. The module sets `helm-ff-transformer-show-only-basename` to t and `helm-ff-show-dot-file-path` to nil on load. The built-in label toggle remains available during a session.

To apply without restarting, close any active Helm chooser and evaluate with `M-:`:

```elisp
(load-file "~/emacstools/my-helm-files.el")
```

For another device, synchronize the updated `~/.emacs` and the new module. Package installation files are unchanged; local hooks/advice do not stack on reload.

## Validation

```sh
emacs -Q --batch -l ~/emacstools/my-helm-files-tests.el
```

All five tests pass. They exercise real Helm buffer creation/reuse, protection against accidental insertion, active/inactive buffer handling, actual full-width side-window placement with two editor splits, session-local input/layout settings, and returning to the source directory despite unrelated path text, including non-file buffers and missing-origin handling. The module byte-compiles without warnings. A real interactive terminal smoke check also passed cancellation, subsequent chooser reuse, opening a temporary file, editable nontruncating input, retained read-only results and restoration of both editor windows. Graphical font/rendering details were not inspected.

Backups are in `~/emacstools/backup/` and `~/Documents/codex/emacs/backups/`.
