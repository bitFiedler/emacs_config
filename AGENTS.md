# Agent instructions and personal Emacs preferences

These instructions apply to this repository. They record the owner's preferences from the configuration work through 14 November 2026. Follow newer explicit requests when they change a preference. Check the actual configuration before treating a recorded setting as current.

## Working together

- Complete authorized work and routine verification without repeatedly asking for confirmation. Ask when a required choice is missing or an overwrite decision is needed.
- Give concise progress updates and a practical final result. Explain relevant limitations honestly, especially GUI versus terminal behavior.
- When a configuration change needs reloading, provide the smallest working command for the active Emacs session, usually an expression entered with `M-:`. Avoid requiring a restart when a targeted reload works.
- Preserve unrelated settings and the user's own changes. Keep commits focused and report what was committed. Push only when explicitly requested; report authentication failures clearly.

## Git and backups — latest preference

- Git history is the recovery copy for **tracked files whose current contents match HEAD**. Do not make an extra backup before routine edits to those files.
- Before replacing an existing file with **uncommitted changes**, make a separate backup. This includes staged changes as well as unstaged edits: compare against HEAD, not just the index.
- Before replacing an existing **untracked file or a file outside Git**, make a backup. Newly created files do not need a pre-creation backup.
- Resolve a live configuration symlink to its real target when checking Git state. Edit the repository target once and preserve the live symlink.
- Configuration/code backups belong in `~/emacstools/backup/`. Documentation backups belong in `~/Documents/codex/emacs/backups/`. Keep backups out of Git. Remove existing backups only when requested.
- The installer is a separate deployment workflow: conflicting older local files need its backup/skip/cancel decision and recoverable journal. Keep that protection, including preservation of newer edits during recovery.

## Repository and installation

- `~/sourcen/emacs_config` is the authoritative configuration checkout. Live `~/.emacs`, `~/.emacs.d/early-init.el`, personal modules and assets are linked to it by `install.py`.
- Keep `~/emacstools` and `~/.emacs.d` as real directories; link individual personal files. They also contain local packages, upstream checkouts and runtime data.
- Keep an existing `~/.emacs.d/custom.el` local. Seed it as a regular copy only when missing. Promote intentionally shared Customize preferences into tracked configuration rather than replacing device-local settings automatically.
- Use Python for installation/recovery tools. Support dry runs, missing directory creation, repeatable installation, explicit overwrite decisions and rollback to original destinations.
- Never deploy automatically as part of merely editing or testing the installer. Test installation and recovery using temporary home directories.
- Track personal settings, integrations, extensions, tests and documentation. Obtain third-party Emacs libraries from package archives or upstream Git repositories; do not vendor their implementations unnecessarily.
- The owner requested `emacstools/emacs-libvterm` and `emacstools/emacs-lsp-booster` as pinned Git submodules. Keep upstream sources in those submodules, build artifacts ignored, and Linux/macOS build/install instructions current. `build-native.py` deploys only these dependencies through the existing recoverable installer.
- The legacy `emacstools/ascii-table.el` is also explicitly bundled at the owner's request. Preserve its upstream attribution, GPL-2.0-or-later notice and accompanying license; the personal wrapper keeps the 0–255/read-only/`q` behavior.
- Fonts are an explicit exception: keep the fonts used by this config, preview WOFF2, original licenses, attribution and checksums in the repository for easy setup on new devices.
- Keep package trees, compiled Lisp/native artifacts, caches, histories, sessions, credentials, autosaves and backups out of Git. Preserve existing upstream source checkouts.
- `legacy/` is historical personal material, not part of automatic startup or installation.

## Documentation and validation

- Update `readme.md` when changing behavior, shortcuts, options, dependencies or installation. It is the consolidated customization/module reference, based on `emacs-customizations-and-modules.md`.
- Maintain focused guides under `docs/` when their feature changes. The user's documentation folder is `~/Documents/codex/emacs`, not `~/.codex`; follow the backup rule for files outside Git.
- Keep this preferences file aligned with explicit preference changes; detailed implementation and command inventories belong in the README/guides.
- Test the behavior affected by a change. For installer/recovery changes, use `python3 -m unittest discover -s tests -v`. Emacs modules have their own ERT suites, normally run separately because some exit Emacs themselves.
- Do not load the full live init for automated checks: it can install packages, start services or reconnect language servers. Use isolated `emacs -Q --batch` checks and selected module loads.
- Verify terminal-specific changes in a real isolated `emacs -nw` session where practical. Distinguish configuration tests from actually observing GUI glyph rendering.
- Update affected `export-manifest.json` entries when their exported source changes. The installer selects personal files directly; the export manifest is a provenance record, not a package lockfile.

## Devices, fonts and appearance

- The recorded build is GNU Emacs 31.1.50, revision `bcfc4e7e1973`, with PGTK, HarfBuzz, tree-sitter, native compilation and Xwidgets support. Verify capabilities rather than assuming them on another build.
- The config is shared between `mp-linux` (Pop!_OS) and `N900D9658` (Debian/WSL2). Device differences should be configurable and detected rather than maintained as divergent copies.
- Current GUI font sizes in `my-device-font.el` are JetBrains Mono **11 pt on mp-linux**, **9 pt on N900D9658**, and 11 pt fallback. Preserve the current source values; older discussion mentioned a different WSL size.
- Keep GUI and terminal colors as similar as the display supports. Use capability checks for truecolor/256-color/limited-color behavior. Terminal font choice and transparency belong to the terminal application.
- Main text should be neutral gray, not yellowish (`#B8B8B8` in the config). The configured graphical background opacity is **87**.
- Match line-number, minibuffer and breadcrumb backgrounds to the editor. Avoid bright boxes or mismatched background slabs. Do not describe a face color blend as independent transparency.
- Show line numbers in editing buffers, including plain-text/dotfiles; exclude Helm and other utility interfaces. Ordinary buffer cycling should focus on editing buffers rather than transient Helm buffers.

## Ligatures

- Org ligatures must preserve surrounding line colors/weight. Never shape leading heading stars or override hidden-marker/bullet styling, including Org Superstar composition.
- In every mode, ligatures inside comments and strings must keep their normal syntax color/weight, never the special light-gray/bold operator face. Recognize comment/string syntax and comment/documentation/string faces, including inherited faces.
- C/C++ comments, including `/* ... */` and repeated-star banners, should have no ligatures, ligature styling or arrow gaps by default. Preserve their normal syntax colors and ligatures in code.
- Keep the **full** configured JetBrains Mono ligature set. The temporary arrows-only experiment was reverted.
- Style configured ligature sequences **bold, light gray `#D0D0D0`**. Pure white was tried and softened. Keep the color/weight customizable.
- Preserve this appearance after Eglot semantic fontification; do not disable semantic highlighting or code actions to achieve it.
- Keep the configurable display-only arrow gap, currently **0.2 character widths**, for expressions such as `->r`. Preserve the actual source characters, copying, searching and saved file contents.
- Use the installed `ligature` library or existing `~/emacstools/ligature.el` checkout. The init's explicit Git recipe supports machines without either. Keep upstream code external.

## Bookmarks

- Preserve the existing orange (`DarkOrange1`, standard RGB `#FF7F00`) and subtle hl-line-like tint rather than a large opaque highlight. Resolve RGB colors before terminal palette approximation.
- Use the Nerd Font ribbon **nf-fa-bookmark, U+F02E**. GUI uses its fringe bitmap; terminal windows use the actual glyph on the left.
- Terminal markers should be compact: **normal weight, one character column, no extra padding**. Reuse existing left margins. Keep that column stable in editing windows so bookmark addition/removal does not shift code or line numbers.
- Preserve existing margins when marker support is disabled or a window changes to a utility buffer. Keep GUI/terminal markers window-appropriate, including when both display the same buffer.
- Match GUI orange/tint in capable terminals; use a readable yellow fallback on very limited color terminals. The terminal must have a suitable Nerd Font configured.
- Preserve F2 toggle, C-F2 next, S-F2 previous and C-S-F2 clear-current-buffer bindings.

## Breadcrumbs

- Default to a top breadcrumb; make placement configurable. A bottom breadcrumb must be a separate row **above** the mode line.
- Hide the filename and macro-call leaves by default; keep both configurable. Use file/mode-specific Nerd Font icons, with `nf-cod-file_code` fallback.
- Show the actual enclosing scopes: include loops, avoid unrelated `try` scopes in catches, and flatten an `else if` chain to its selected branch rather than duplicating every preceding branch.
- Namespace representation should use the same icon/format as classes, omit the word “namespace”, and use the namespace syntax color.
- Keep branch detail and else hints always enabled in the user's config. Distinguish hints with `nf-cod-type_hierarchy_sub`; provide always/offscreen/off choices.
- Keep typography independent of Org heading scaling, with configurable face attributes and an editor-matching background. Avoid separate framed boxes.
- Compress intelligently in narrow split windows, keeping the recent/inner context readable. Keep clickable navigation, jump-back support, keyboard shortcuts, Helm navigation and dynamically switchable debug logging.
- Preserve supported code, JSON, YAML, Elisp and Org contexts; keep the supported-mode documentation current.

## Editing, search, preview and integrations

- Keep `C-<f5>` for reloading a buffer while preserving position where possible.
- Pair deletion must work forward and backward, including when point is on the closing delimiter. Preserve C-S-d / M-S-d bindings and ordinary C-d / M-d behavior.
- ASCII reference buffers show values **0–255**, are read-only, refresh normally, and use `q` to quit. Preserve the C/C++ F10 integration.
- Finished Helm result buffers should be read-only without breaking editable active input. Keep the wide Find Files presentation and the shortcut back to the originating file directory.
- Deadgrep defaults to recursive search and exposes a recursive on/off control. Preserve matches when ripgrep reports permission failures, keep errors understandable, and retain result/error hiding with `z`, `u` and `U`.
- Syslog `time=` values use timestamp styling; `msg="..."` values support multiline strings. Every new timestamped record must reset quote state so an unfinished message cannot color following records as one string.
- YAML scalar/script handling should not make most of a CI file appear string-colored. Preserve the existing targeted font-lock integration.
- For container-based LEO clangd, select the running container by configured image and exact host checkout mount, not a generated container name or first image match. Fail clearly on missing/duplicate matches; preserve clean LSP stdin/stdout.
- Limit repeated Eglot startup failures to **10 attempts**. Avoid restart loops across projects/languages and unintended reconnection when navigating to library stubs.
- Clipboard integration should read fresh clipboard contents, normalize CRLF, report timeouts and check tool availability. Enable wl-copy/wl-paste support based on installed tools and display capabilities rather than assuming every device has them.
- Keep terminal/WSL startup fast. Avoid repeated slow executable probes through mounted Windows directories during startup. Package upgrade checks should be weekly rather than noisy on every launch, with the next eligible launch handling elapsed time.
- Markdown preview uses **Livedown**, defaults to dark, updates automatically after edits/saves, and embeds Nerd Font symbols in HTML exports. Prefer Xwidget WebKit when supported, with browser fallback.
- Keep the dark/light chooser at the top left, visible at the document top and hidden after scrolling. Preserve Xwidget page-navigation shortcuts. GitHub README rendering cannot load the custom embedded preview font; keep documentation clear about the separate viewers.
