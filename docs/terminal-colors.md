# Matching graphical and terminal Emacs colors

## Configuration

The Alect theme defaults to `alect-display-class` of `((type graphic))`, so `alect-black` was not styling terminal Emacs. `~/.emacs` now sets the class to `((class color) (min-colors 256))` before loading the theme. Alect builds theme face specifications in a macro, so its compiled theme file already freezes the graphical-only class. The load is therefore wrapped in `(let ((load-suffixes '(".el"))) ...)` to expand the installed theme source using the current display class; package files are not edited. It also removes the old terminal-only colors for the default face, current-line highlight, region, Man and Company. The same theme palette and shared customizations now apply in graphical and sufficiently capable terminal frames. Very limited terminals remain unthemed by this setting.

The old `(setq xterm-tmux-extra-capabilities '(RGB))` was removed: that option controls terminal interaction/keyboard features and does not enable truecolor. No shell environment or terminal application settings have been changed.

## Exact RGB colors

Start a fresh terminal Emacs, then inspect `M-: (display-color-cells)`. `16777216` means 24-bit truecolor; `256` means theme RGB values are approximated by a smaller palette. The terminal and any SSH/multiplexer layer must actually support the selected capability.

For a terminal and multiplexer known to support 24-bit color, this launch command advertises it before Emacs initializes its terminal:

```sh
COLORTERM=truecolor emacs -nw
```

This Emacs build's terminal initialization explicitly recognizes `COLORTERM=truecolor`. Setting it inside `.emacs` is too late for initial terminal setup. `TERM=xterm-direct` is another terminfo-based approach, but only use it when it accurately describes the terminal and its supported escape sequences; it is not set globally here.

A plain 256-color terminal cannot reproduce every GUI RGB value exactly. Fonts, Nerd Font glyphs and italics also depend on the terminal's configured fonts and rendering. Terminal background opacity is controlled by the terminal application; Emacs's graphical `alpha-background` setting does not control it. Matching RGB settings does not imply identical perceived appearance when GUI and terminal transparency differ.

## Apply and verify

Restart terminal Emacs to remove previously loaded terminal-only face overrides cleanly. The theme class must be configured before the theme is created/loaded. Manual updates to an already-loaded theme can leave old face specifications, so restarting is preferred for this change.

The original init was backed up under `~/emacstools/backup/`. Verification loads the installed Alect theme in isolated terminal Emacs processes without running the full init or updating packages, and compares applied default, keyword, string, region and hl-line colors with the theme's RGB specifications. Full init source readability is checked separately.

## Neutral main text color

The main `default` face foreground is now neutral light gray `#B8B8B8`, replacing Alect Black's yellow-beige `#b2af95`. It is set through the high-priority `user` theme after loading `custom.el`, so it applies to graphical and terminal frames and persists across color-theme changes. Only the foreground is specified; font, background, opacity and explicitly colored syntax faces are preserved. Faces that inherit the default foreground naturally become gray too. Truecolor is needed to reproduce this RGB value exactly in a terminal.

Apply immediately with `M-:`:

```elisp
(custom-theme-set-faces 'user '(default ((t (:foreground "#B8B8B8")))))
```
