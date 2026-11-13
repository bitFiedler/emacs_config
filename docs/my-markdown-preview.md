# Emacs Markdown Preview and HTML Export

Documentation checked against the local implementation on 2026-11-11.

## What the feature does

`markdown-preview` uses Livedown for a live browser preview. It prefers embedded xwidget WebKit when available in the current graphical Emacs frame and otherwise opens an external browser. Edits update automatically after a short idle delay; saving refreshes immediately.

HTML exports use the same Markdown parser and plugins as Livedown. Preview and export include tables, embedded Nerd Font symbols, dark/light styling and a theme chooser. Dark is the initial default; a previously saved browser choice can override it.

This is local configuration layered onto `markdown-mode`, not a separate Markdown major mode. It does not require Eglot or Tree-sitter. It does not enable or replace `markdown-live-preview-mode`.

## Files and initialization

| File | Purpose |
|---|---|
| `~/emacstools/my-markdown-preview.el` | Emacs commands, browser selection, live updates, export integration |
| `~/emacstools/my-markdown-render.cjs` | Node renderer using Livedown's Markdown dependencies |
| `~/emacstools/my-markdown-preview-tests.el` | ERT regression checks |
| `~/emacstools/assets/nerd-symbols.woff2` | Compressed Symbols Nerd Font embedded in HTML |
| `~/emacstools/assets/markdown-theme.css` | Dark/light colors, typography, tables and chooser layout |
| `~/emacstools/assets/markdown-theme.js` | Theme persistence, reload handling and scroll visibility |
| `~/emacstools/assets/markdown-theme-controls.html` | Native Dark/Light radio controls |
| `~/.emacs` | Loads the integration |
| `~/Documents/codex/emacs/my-markdown-preview.md` | This documentation |

The initialization entry is:

```elisp
(load-file "~/emacstools/my-markdown-preview.el")
```

The older `~/emacstools/livedown.el` is not required by this integration. The new code calls the Livedown executable directly, without constructing a shell command.

## Requirements and installed tools

Required: `markdown-mode`, Node.js, Livedown and the bundled font/theme assets. Embedded browsing additionally requires an Emacs build with xwidget WebKit and a graphical frame.

At setup time the installed Livedown was version 2.1.1, located at:

```text
~/.nvm/versions/node/v24.21.0/bin/livedown
```

The executable is discovered through Emacs' executable path, then an NVM installation path if necessary. Node is located beside the Livedown executable when possible, falling back to `executable-find`. If Node is only available through a shell's NVM setup, the sibling lookup avoids relying on interactive shell startup.

For export, the renderer resolves the real Livedown executable path and loads `markdown-it` and its task-checkbox, emoji and GitHub-heading plugins from that installation. It supports GitHub-style tables and preserves raw HTML. Livedown is a preview server, so it is not used directly as a stdin-to-HTML converter. The old `/usr/bin/markdown` converter is no longer used by this configuration.

## Start, stop and reload

Open a Markdown buffer and run:

```text
M-x markdown-preview
```

`M-x my/markdown-livedown-preview` starts the same preview directly. The normal `markdown-preview` function is overridden by this integration; its usual keybindings continue to invoke that command.

By default the preview URL is:

```text
http://localhost:1337
```

Stop it with:

```text
M-x my/markdown-preview-stop
```

There is one active preview process and source buffer per Emacs instance. Starting another preview stops the previous one. Killing the source buffer or exiting Emacs also stops the owned process and removes its temporary Markdown copy. Stopping does not force-close browser or xwidget buffers; their displayed page may remain until you close or reuse them.

Reload implementation changes with `M-:`:

```elisp
(load-file "~/emacstools/my-markdown-preview.el")
```

Then run `markdown-preview` again from the source Markdown buffer to restart the server and attach the current hooks/settings. Refresh an already-open external browser if it retains an old page. Existing exported HTML must be exported again to receive updated fonts, styles, controls or scripts.

## Browser selection

The default `my/markdown-preview-browser` value is `auto`.

Embedded browsing is selected only when all of these are true:

- The originating frame is graphical.
- Emacs provides the compiled `xwidget-internal` feature.
- The `xwidget` library loads successfully.
- `xwidget-webkit-browse-url` is available.

An autoload or function name alone is not proof of compiled WebKit support. In terminal Emacs, preview uses the external browser.

For embedded browsing, Livedown starts without `--open`. The process filter waits for its verbose “markdowning started on” readiness message and schedules `xwidget-webkit-browse-url` with a new session in the originating frame. Opening is deferred outside the process filter, and callbacks from a stopped/replaced preview are ignored. This avoids navigating before the server is listening or changing the source buffer during startup hook installation.

If opening WebKit raises an error, the code reports it and falls back to `browse-url-default-browser`. When internal browsing is unavailable or explicitly disabled, Livedown starts with `--open` and uses its external browser launcher.

Force external browsing:

```elisp
(setq my/markdown-preview-browser 'external)
```

Restore automatic preference for xwidget:

```elisp
(setq my/markdown-preview-browser 'auto)
```

Restart the preview after changing browser settings. These settings govern `markdown-preview`; `markdown-export-and-preview` retains markdown-mode's ordinary `browse-url-of-file` behavior.

## Complete customization reference

Use `M-x customize-group RET my-markdown-preview RET`, or evaluate settings in Emacs Lisp. Restart the preview to apply startup settings. To persist changes, place them in `.emacs` after the module load or save through Customize.

| Variable | Default | Meaning |
|---|---|---|
| `my/markdown-livedown-program` | Discovered executable, NVM fallback, or `livedown` | Livedown program; also locates its export dependencies |
| `my/markdown-livedown-port` | `1337` | Preview port |
| `my/markdown-livedown-open-browser` | `t` | Automatically open an embedded/external browser; nil starts only the server |
| `my/markdown-preview-browser` | `auto` | `auto` prefers available graphical xwidget WebKit; `external` always uses the external launcher |
| `my/markdown-nerd-font-file` | `~/emacstools/assets/nerd-symbols.woff2` | WOFF2 file embedded in generated content |

Example:

```elisp
(setq my/markdown-preview-browser 'auto
      my/markdown-livedown-open-browser t
      my/markdown-livedown-port 1337)
```

Setting automatic opening to nil allows manual navigation to the URL. There is no separate “force internal even when unsupported” option.

## Automatic update behavior

Preview uses a hidden temporary sibling file named `.emacs-livedown-*.md` in the source buffer's `default-directory`. Keeping it beside the source allows Livedown's relative image/resource paths to resolve from that directory. The directory must be local and writable; remote/TRAMP directories are rejected. Unsaved buffers work if their default directory meets those requirements.

The preview copy includes the complete widened source buffer, theme controls, embedded font CSS, styling and scripts. It does not save or modify the original Markdown buffer. The file need not be saved before previewing edits.

- `after-change-functions` schedules an update after 0.4 seconds of Emacs idle time. Further edits reset that timer.
- `after-save-hook` performs an immediate update and cancels a pending timer.
- Content is written completely to a staging file in the same directory, then renamed over the watched preview copy.
- Staging files are removed after success or failure. A failure before replacement leaves the last complete preview file intact.

Atomic replacement prevents the browser from receiving an empty/truncated copy during a large rewrite, especially because the embedded font makes the preview copy relatively large.

Livedown's older native watcher could stop detecting changes after an inode replacement. Its process therefore receives these environment settings:

```text
CHOKIDAR_USEPOLLING=1
CHOKIDAR_INTERVAL=100
```

These settings apply to the child process, not Emacs' global environment. Polling the single preview path detects repeated atomic replacements. Watcher polling is separate from the 0.4-second source edit delay.

The original Markdown file is never overwritten by these preview updates. If you stop the preview, its source hooks and timer are removed. Browser disconnection does not itself stop the server; reopening the URL reconnects it.

## Dark/light theme chooser

The chooser is pinned to the top-left corner, with extra space above document content. It is visible at the top of the page, hides as soon as you scroll below the top, and reappears when you return to the very top.

The controls are native Dark/Light radio buttons. Dark is the default when there is no saved choice. JavaScript stores your selection under the browser local-storage key `emacs-markdown-theme`, retains it across live updates and removes duplicate controls. It moves the active chooser outside Livedown's replaced article so the toolbar survives content refreshes.

The scroll listener uses the window's vertical scroll offset and the control's `hidden` attribute. CSS explicitly honors that attribute even though the chooser normally uses flex layout.

Theme colors cover page backgrounds, body text, links, code, syntax highlighting, tables, borders and blockquotes. The chooser is hidden when printing.

CSS `:has()` selectors allow theme switching through the native controls even without the theme script in browsers supporting that selector. JavaScript supplies persistence and automatic scroll hiding; those extras are unavailable when scripts are blocked. Browsers without `:has()` require the JavaScript path to switch colors.

Both JavaScript-enabled and CSS-only Dark → Light → Dark switching were checked in headless Firefox. This does not guarantee identical behavior on every embedded WebKit version. If a page has old controls after an update, restart the preview and refresh it.

## Nerd Font icons and portable export

Private-use characters such as ``, `` and `` require a font containing those glyphs. Installing the font only in Emacs or WSL does not make it available to a separate Windows browser.

The integration embeds the WOFF2 font as a base64 `data:font/woff2` URL in `@font-face`. The CSS font family is `Emacs Nerd Symbols`, restricted to private-use Unicode ranges. Regular prose and code use system/monospace fallback fonts; the Nerd Font supplies the icons. Code elements also include the icon font in their stack.

The local WOFF2 asset was generated from `~/.local/share/fonts/NFM.ttf` (Symbols Nerd Font Mono). Its glyph map was checked for every breadcrumb icon. Font CSS is cached by path and modification time; changing the font file invalidates that cache.

Exported HTML contains the font, CSS, controls and scripts, so no Nerd Font installation or font CDN is needed by the recipient's browser. Images and linked documents are not embedded automatically and still need their normal paths/resources. The embedded font also increases output size.

## Export commands

| Command | Result |
|---|---|
| `M-x markdown-export` | Export HTML, normally beside the source with `.html` extension |
| `M-x markdown-export-and-preview` | Export, then open the HTML through markdown-mode's browser handling |
| `M-x markdown-standalone` | Generate standalone HTML in an output buffer |
| `M-x markdown-preview` | Start the Livedown live preview instead of static export |

`markdown-command` is set to `my/markdown-render`; `markdown-command-needs-filename` is nil. Rendering accepts a buffer region on stdin and writes HTML into markdown-mode's output buffer.

An around-advice on `markdown-standalone` adds the embedded font/theme to `markdown-xhtml-header-content` and the controls to `markdown-xhtml-body-preamble`, preserving existing configured content. Export continues to use markdown-mode's normal file handling. The live-preview promise not to save the source applies to the Livedown preview; export uses markdown-mode's own save/restore behavior.

## Xwidget WebKit navigation

Select the xwidget window before using its keys. The integration adds direct bindings for page movement, avoiding dependence on global scrolling remaps. Both shifted-space event forms are covered.

| Action | Keys |
|---|---|
| Page down | `SPC`, `C-v`, `PageDown` |
| Page up | `Backspace`, `M-v`, `Shift-SPC`, `PageUp` |
| Top of page | `M-<` |
| Bottom of page | `M->` |
| Previous webpage | `b` |
| Next webpage | `f` |
| Reload | `r` |
| Open a URL | `g` |
| Search within the page | `C-s` / `C-r` |
| Zoom in / out | `+` / `-` |

Page-up bindings explicitly call `xwidget-webkit-scroll-down`; page-down bindings call `xwidget-webkit-scroll-up`. These names follow Emacs scrolling terminology: moving the content down reveals an earlier part of the page.

The direct bindings are installed after `xwidget` loads and also apply to existing xwidget buffers after reloading this module. Browser edit/input modes or desktop key interception can affect delivery of a shortcut; Backspace and PageUp are useful alternatives. Use `C-h k` in the xwidget buffer to inspect a delivered key's binding.

## Logs and troubleshooting

The Emacs process buffer is `*Markdown Livedown*`. It receives Livedown's verbose output and startup/runtime errors. The minibuffer reports the URL, stopped processes and embedded-browser fallback errors. The owned process is named `markdown-livedown` and does not ask for confirmation when Emacs exits.

| Symptom | Check / action |
|---|---|
| Preview still invokes `markdown` | Reload this module, then invoke `markdown-preview` again |
| Missing Livedown or Node | Check `my/markdown-livedown-program`, its sibling Node executable, and Emacs' executable path |
| Preview does not open in Emacs | Confirm a graphical frame, compiled `xwidget-internal` support and browser setting `auto`; inspect the process log for startup errors |
| Want an external browser | Set browser to `external`, then restart the preview |
| Browser opens too early | Current internal path waits for Livedown's readiness message; reload and restart |
| Preview goes blank or stops updating | Reload and restart so atomic writes, save hooks and polling are active; inspect the log |
| Only one of several browser tabs updates | The installed older Livedown server targets its latest connected client for changes; use one active preview tab or reconnect the desired tab |
| Preview stops when switching to another file's preview | Only one source is previewed at a time by design |
| Saving does not update | Check `after-save-hook` in the source buffer and restart the preview to reinstall current hooks |
| Temporary file cannot be created | The source buffer's local default directory must be writable |
| Port already occupied | Choose another port and restart; Livedown's own launcher may stop an existing Livedown server on its selected port |
| Icons appear as boxes | Re-export/restart using this module and confirm the WOFF2 asset exists; inspect browser font loading if necessary |
| Old theme chooser remains | Restart the preview and refresh the page; regenerate existing exports |
| Chooser disappears while reading | Expected: scroll all the way to the top to show it |
| Page-up shortcut fails | Reload the module for direct bindings, select the xwidget window, or use Backspace/PageUp |

## Validation and maintenance

Run the regression suite:

```sh
emacs -Q --batch -l /home/mp/emacstools/my-markdown-preview-tests.el
```

The test file runs ERT and exits Emacs. The latest run passed seven tests covering table/icon/font HTML, unsaved preview content and save hooks, font caching, atomic publication, keeping the previous preview after a failed update, automatic browser selection, readiness detection and fallback after a WebKit opening error. Browser dispatch tests use mocked opening functions; they do not establish actual embedded WebKit rendering quality.

Additional checks performed during implementation:

- Five consecutive live updates over Livedown's HTTP/socket connection after atomic replacements, with polling enabled and no empty frames.
- Headless Firefox Dark → Light → Dark switching, both with and without the theme script.
- Presence of all breadcrumb icon code points in the embedded WOFF2 font.
- Explicit xwidget keymap bindings for Meta-v, both Shift-Space forms and PageUp.

Before modifying an existing implementation, test or asset file, save a timestamped backup in `~/emacstools/backup/` and verify matching bytes. `.emacs` backups go there too. Back up this document in `~/Documents/codex/emacs/backups/`. Avoid leaving stale `.elc` files beside edited source; use temporary copies for compilation checks.
