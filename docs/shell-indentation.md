# Shell indentation

`my-shell-indentation.el` keeps shell indentation predictable in `sh-mode` and `bash-ts-mode`. The default step is four spaces (`my/shell-indent-offset`), with `indent-tabs-mode` nil. Directory/file-local indentation variables can override these mode-hook defaults.

## Why an if body could stay at column zero

In the installed Emacs 31.1.50, `bash-ts-mode` uses tree-sitter for parsing/fontification but still uses `smie-indent-line` for indentation. `dtrt-indent-global-mode` enables indentation detection in programming buffers. For SMIE modes, dtrt-indent delegates to `smie-config-guess`, which learns contextual rules from the file's current layout.

An inconsistently indented shell file can therefore teach SMIE that an if body belongs at column zero. `sh-basic-offset` can still show 4 while the learned rules override it. Changing only tab-width or the basic offset does not remove those rules.

The personal module prevents dtrt-indent from enabling in shell buffers, clears previously learned buffer-local SMIE rules and restores normal shell indentation. Other modes keep dtrt-indent behavior. Explicit mode-level SMIE customizations are retained. The module loads before the global dtrt-indent mode is enabled, and a targeted reload also repairs existing shell buffers without changing their text, restarting their mode or restarting Eglot.

## Apply to an existing buffer

Use `M-:`:

```elisp
(load-file "~/emacstools/my-shell-indentation.el")
```

Then indent with `TAB` on a line, or `C-x h` followed by `C-M-\` for the whole buffer. Save after reviewing the indentation changes. The load itself does not reindent or save files. Change `my/shell-indent-offset` through Customize or Lisp and reload/apply `my/shell-indent-apply` to update an existing shell buffer.

These commands use Emacs indentation. `eglot-format` is a separate language-server formatting operation and may depend on an external formatter and its settings; this change does not claim to configure that operation.

## Validation

Three isolated ERT tests cover nested shell blocks in classic and tree-sitter Bash modes, recovery after the real dtrt/SMIE guess, preservation of text/modified state during repair, and delegation for other modes. The reported file was also indented in memory with global dtrt-indent enabled: both affected lines received four spaces. No script was executed and the source file on disk was left untouched.
