# Line numbers in editing buffers

`~/.emacs` loads `~/emacstools/my-editing-line-numbers.el` and enables `my/editing-line-numbers-mode` globally. This replaces separate programming/text/config/YAML/syslog hooks with one policy.

Text file buffers receive line numbers even when their extension is unrecognized and they use `fundamental-mode`, such as `~/.bash_history_backup`. Read-only text files also receive numbers. Editable non-file programming, text, configuration and fundamental buffers are included, including `*scratch*`.

Helm, minibuffers, internal buffers (including breadcrumb footers), and utility modes are excluded. The default excluded mode list includes `special-mode` and its descendants (Help, compilation output and many other interfaces), Dired, Comint/shell, terminal, Vterm, Eshell, image, Doc View and PDF View modes. Helm modes and buffers named `*helm…` are excluded as well. New buffers and major-mode changes are handled by the globalized minor mode. This is a buffer policy: two windows showing the same buffer share its line-number setting.

Customize exclusions with `M-x customize-group RET my-editing-line-numbers RET`, then run `M-x my/editing-line-numbers-refresh`. Toggle the policy with `M-x my/editing-line-numbers-mode`. The normal `display-line-numbers-mode` command can still toggle the current buffer; the policy is reapplied on mode changes or explicit refresh. Existing line-number type, colors and background settings are preserved.

Apply the new configuration to an existing session with `M-:`:

```elisp
(load-file "~/emacstools/my-editing-line-numbers.el")
```

The initial fix backs up `~/.emacs` under `~/emacstools/backup/`. No contents of the history file are read or modified. Eligibility is checked with file/fundamental, programming, scratch, read-only text, Helm, Help, Dired, shell, internal, minibuffer and mode-transition cases.
