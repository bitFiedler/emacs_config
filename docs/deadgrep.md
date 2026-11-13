# Deadgrep search controls

`~/.emacs` loads `~/emacstools/my-deadgrep-recursion.el` from the Deadgrep package configuration. The installed package files are unchanged.

## Controls

The results header now contains **Recursive: on off**, using the same clickable-button style as Deadgrep's other settings. The active choice is plain text; click the other choice to switch. The choices are ordinary Emacs text buttons; they can also be activated at point. Press uppercase **R** in a Deadgrep results buffer to toggle and rerun the search.

- **on**: include subdirectories; this is the default for new results buffers.
- **off**: search only direct child files of the displayed search directory, using ripgrep `--max-depth=1`.

The directory is Deadgrep's displayed search root, which may be the project root rather than the current source file's directory. Use **D** or the Directory button to change it. Existing file-type, glob, case, context, hidden-file and ignore settings still apply. Toggling changes only the recursion state in that results buffer; other search buffers keep their own state. Reusing the same results buffer preserves its state, consistent with Deadgrep's other per-buffer search settings. **g** reruns the current settings.

## Hiding results while reviewing a search

Deadgrep's built-in folding keeps filenames visible: on a **file heading**, **Tab** hides or shows that file's result lines; **Shift-Tab** toggles all file groups.

Use the local extension's `z` command to dismiss items completely:

| Key / cursor location | Effect |
| --- | --- |
| `z` on a result line | Hide that displayed result line. |
| `z` on a filename | Hide the filename and all its currently displayed results, including context/separators and trailing blank lines. |
| `z` on an `rg:` error | Hide that diagnostic and its following blank lines, including permission-denied errors. |
| `z` on a `WARNING:` or the final error summary | Hide that diagnostic line and following blank lines. |
| `u` | Restore the most recently hidden item and move point to its start. Repeat to restore earlier items. |
| `U` | Restore all items hidden with `z` in this results buffer. |

The commands are `my/deadgrep-hide-result`, `my/deadgrep-unhide-result` and `my/deadgrep-unhide-all-results`. They are local to Deadgrep results buffers. Header controls and arbitrary blank lines cannot be dismissed accidentally.

Use `z` for irrelevant results or after returning from a result you have already inspected. Visiting a result does not automatically hide it. Individual-line hiding affects all matches on that displayed line. Source files, result text, search settings, the search's total match count and ripgrep's exit status remain unchanged. Each results buffer has its own stack of hidden items. Hiding an error affects its display only; the search can still be incomplete.

`n`/`p` skip invisible matches and `M-n`/`M-p` skip invisible filename headings. Overlays use a separate invisibility category, so Tab's file-folding code does not delete manually hidden items. `U` restores items hidden with `z` while preserving Tab's file-folding state. Restoring a filename that was already folded brings back its heading; use Tab to unfold its results. Restoring a result inside a separately hidden file does not reveal the enclosing file group until that group is restored too.

Rerunning the search (`g`), changing search settings that restart it, or changing major mode clears the manual hiding state. When a search is still producing output, hiding a file group covers the lines already present; later appended results are not automatically dismissed. The shortcuts are stored outside the installed package and survive package replacement.

## Implementation and compatibility

`my/deadgrep-recursive-p` is a buffer-local boolean, initially t. `my/deadgrep-toggle-recursive` is the interactive command; `my/deadgrep-set-recursive` is the common button/command helper. A heading advice adds the row, an argument advice applies the depth policy, and a scoped process-launch safeguard enforces the same policy on the actual ripgrep invocation. Reloading the extension does not stack duplicate advice.

The UI owns depth limits. A `:filter-return` argument advice processes the final argument list produced by Deadgrep, rather than temporarily rebinding `deadgrep-extra-arguments`. It removes manually supplied `--max-depth`, `--maxdepth` and `-d` forms from the options before `--`, preserves unrelated options such as `--no-config`, and adds `--max-depth=1` only when recursion is off. Search text and paths after `--` are preserved verbatim. Neither the input argument list nor the extra-arguments variable is destructively modified. Other custom finite depths are not represented by this on/off control. Reloading explicitly removes the earlier `:around` advice before installing the new filter.

The launch safeguard captures the results buffer and its recursion setting around `deadgrep--start`. It filters `start-file-process` arguments only during that call and only for that target buffer. It therefore also works when the argument-builder advice is bypassed; unrelated process launches are unchanged. The actual executable and arguments are stored buffer-locally in `my/deadgrep--last-command`, and `deadgrep--debug-command` is refreshed from that captured invocation. `M-x my/deadgrep-diagnose` reports the search directory, recursion state and captured command.

The extension integrates with the installed Deadgrep private heading/argument/start/sentinel/reset/navigation functions. If a future package upgrade changes those interfaces, this local extension may need adjustment. A postponed search remains postponed according to Deadgrep's normal behavior; use **g** to start it.

## Reload without restarting Emacs

Evaluate with `M-:`:

```elisp
(load-file "~/emacstools/my-deadgrep-recursion.el")
```

In an already-open Deadgrep results buffer, press **g** to rebuild the header and rerun the search with the visible recursion state. New searches receive the control automatically. No new global shortcut is added: `M-s` continues to open Deadgrep and **R** is local to Deadgrep buffers.

## Validation

Checks cover reversible result/file/error hiding, boundaries between file groups and diagnostics, buffer isolation, cleanup on rerun/mode changes, navigation over hidden matches, interaction with file folding, the default recursive state, clickable header actions, keyboard binding, independent buffers, reinitialization, idempotent reload, removal of old depth arguments and preservation of unrelated arguments. A temporary ripgrep fixture verifies that a matching file in a subdirectory is included with recursion on and excluded with recursion off. Configuration/documentation backups are kept in the established backup folders.

The regression suite is `~/emacstools/my-deadgrep-recursion-tests.el`. The current run passes all sixteen tests, including real asynchronous searches and clicking the header control. Recheck after an upgrade with:

```sh
emacs -Q --batch -l ~/emacstools/my-deadgrep-recursion-tests.el
```

Package updates do not overwrite this extension, its tests, your init load statement or these guides: they are stored outside the package installation directory. Compatibility still depends on the heading/argument/start/sentinel/reset/navigation interfaces described above.

## Search root, permission errors and verifying the actual command

The search directory is the **Directory** shown in the results header. Ripgrep's final `.` is relative to that directory: for `Directory: /home/mp/`, it searches `/home/mp/`. Use **D** to change this root. A recursive search can encounter unreadable files or subdirectories anywhere in that tree; ripgrep returns exit code 2 for errors. The file-type filter selects matching files; it does not grant access to directories. Nonrecursive mode avoids descending into subdirectories, but an unreadable file directly in the root can still cause an error.

Earlier versions could show recursion off while the reported command contained no depth limit. The process-launch safeguard now enforces the limit even if the argument-builder advice is bypassed. After loading the updated extension and pressing **g**, run `M-x my/deadgrep-diagnose`: with recursion off, the captured command must include `--max-depth=1`. `M-: deadgrep--debug-command` also reports that invocation. The regression suite checks the actual `process-command`, including a word/log search with an unreadable subdirectory and the argument-builder advice deliberately disabled. Permission messages are not suppressed or permissions changed by the extension.

If exit code 2 persists with `--max-depth=1` present, inspect the accompanying `rg:` error lines to identify the remaining error; exit code alone does not identify its cause. A no-match search normally returns exit code 1.

## Continuing past unreadable paths

Ripgrep already skips permission-denied paths and continues searching accessible files and subdirectories. Exit code 2 is its final error report; it does not mean it stopped at the first unreadable directory or discarded matches. Repeating the same search cannot make protected paths readable.

By default, `my/deadgrep-friendly-error-summary` replaces Deadgrep's final “exited abnormally with code 2” line with:

```text
Search finished with errors (ripgrep exit 2). Results may be incomplete; see errors above.
```

All matches and diagnostic lines remain visible. The actual process exit status stays 2, including for errors other than permissions. Successful searches, no-match searches and interrupted searches retain their normal handling. Set the option to nil to restore the original wording:

```elisp
(setq my/deadgrep-friendly-error-summary nil)
```

A real recursive-search regression test creates an unreadable directory alongside readable top-level and nested matching files. It verifies both readable matches remain available, the permission error is retained, and the final summary explains incomplete results. No permissions on existing files are modified.
