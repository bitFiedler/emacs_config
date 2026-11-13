# Next and previous buffer navigation

`~/.emacs` loads `~/emacstools/my-buffer-navigation.el`. The built-in `next-buffer` and `previous-buffer` commands keep their normal key bindings and ordering, but skip buffer names hidden by Helm Mini's default buffer filter.

The helper uses the live values of `helm-boring-buffer-regexp-list` and `helm-white-buffer-regexp-list` when Helm is loaded. Before that it uses Helm's standard exclusions: names starting with a space, `*helm`, `*Echo Area` or `*Minibuf`. Minibuffers and dead buffers are always excluded. Whitelisted ordinary buffers can override matching name exclusions. Normal named buffers, including `*scratch*`, `*Messages*`, shells and Help buffers, remain reachable just as they can be in Helm Mini; this is not restricted to file buffers or editing modes.

The setting is `switch-to-prev-buffer-skip`, using `my/buffer-navigation-skip-p`. The same built-in option also influences window buffer replacement after burying, quitting or killing a buffer. If there is no eligible alternative, normal navigation does not deliberately fall back to a hidden buffer. Helm's own list ordering, source configuration and display are unchanged.

Helm deliberately sets its candidate display buffer writable while initializing it, so it can rebuild the candidate list. The fix filters navigation rather than forcing Helm buffers read-only, which could interfere with Helm updates. Explicitly choosing an internal buffer by name remains possible; this policy applies to next/previous buffer navigation and related window replacement.

Apply without restarting using `M-:`:

```elisp
(load-file "~/emacstools/my-buffer-navigation.el")
```

To customize which buffer names are hidden, adjust Helm's boring-buffer patterns or whitelist. `~/.emacs` was backed up under `~/emacstools/backup/` before editing. Verification covers matching and whitelists, ordinary non-file buffers, actual previous/next-buffer navigation, and retaining the current buffer when all alternatives are hidden.
