# Shell indentation

`my-shell-indentation.el` keeps shell indentation predictable in `sh-mode` and `bash-ts-mode`. The default step is four display columns (`my/shell-indent-offset`). `my/shell-indent-tabs` defaults to `detect`: use tabs or spaces according to the majority of indented code lines in the existing file. Leading whitespace containing a tab votes for tabs; spaces-only indentation votes for spaces. Blank lines, comments and multiline string content do not vote. Ties and files without indented code default to spaces. This is a whitespace-style heuristic, not a guess of contextual block indentation.

Set `my/shell-indent-tabs` to `t` to force tabs or nil to force spaces. Explicit file/directory-local `indent-tabs-mode`, `sh-basic-offset` and `tab-width` settings take precedence, including when reloading the module. Interactive `shell-mode` (a comint terminal buffer) is unchanged; classic shell-script editing uses `sh-mode`.

## Why an if body could stay at column zero

In the installed Emacs 31.1.50, `bash-ts-mode` uses tree-sitter for parsing/fontification but still uses `smie-indent-line` for indentation. `dtrt-indent-global-mode` enables indentation detection in programming buffers. For SMIE modes, dtrt-indent delegates to `smie-config-guess`, which learns contextual rules from the file's current layout.

An inconsistently indented shell file can therefore teach SMIE that an if body belongs at column zero. `sh-basic-offset` can still show 4 while the learned rules override it. Changing only tab-width or the basic offset does not remove those rules.

The personal module prevents dtrt-indent from enabling in shell buffers, clears previously learned buffer-local SMIE rules and restores normal shell indentation. It detects tab/space style independently without learning the erroneous zero-column block rules. Other modes keep dtrt-indent behavior. Explicit mode-level SMIE customizations are retained. The module loads before the global dtrt-indent mode is enabled, and a targeted reload also repairs existing shell buffers without changing their text, restarting their mode or restarting Eglot.

## Apply to an existing buffer

Use `M-:`:

```elisp
(load-file "~/emacstools/my-shell-indentation.el")
```

Then indent with `TAB` on a line, or `C-x h` followed by `C-M-\` for the whole buffer. Save after reviewing the indentation changes. The load itself does not reindent or save files. Change `my/shell-indent-offset` through Customize or Lisp and reload/apply `my/shell-indent-apply` to update an existing shell buffer.

These commands use Emacs indentation. `eglot-format` is a separate language-server formatting operation and may depend on an external formatter and its settings; this change does not claim to configure that operation.

## Validation

Seven isolated ERT tests cover tab/space detection and emitted indentation in classic and tree-sitter Bash modes, ignored string/comment content, ties and explicit settings, unchanged interactive shell buffers, nested blocks, recovery after the real dtrt/SMIE guess, preservation of text/modified state during repair, and delegation for other modes. The reported file was also indented in memory with global dtrt-indent enabled: both affected lines received four spaces. No script was executed and the source file on disk was left untouched.
