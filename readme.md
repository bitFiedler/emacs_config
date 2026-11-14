# Personal Emacs configuration

Exported on **13 November 2026** from Matthias Popp's working configuration. This repository tracks personal settings, extensions, tests and documentation. Installed packages and upstream source trees are dependencies, not vendored code. Fonts and the legacy ASCII table library are bundled as explicit exceptions for installation on new devices. No live configuration is replaced by this export.

## Emacs version and devices

Used with **GNU Emacs 31.1.50**, development revision **bcfc4e7e1973**, branch `emacs-31`, build date **2026-08-24**, `x86_64-pc-linux-gnu`. The build includes PGTK, tree-sitter, native compilation, dynamic modules and GTK3 Xwidgets/WebKit. Older versions have not been validated.

| Device | System | GUI font |
| --- | --- | --- |
| mp-linux | Pop!_OS | JetBrains Mono, 11 pt |
| N900D9658 | Debian under WSL2 | JetBrains Mono, 9 pt |

Terminal Emacs uses the terminal's font. `my-device-font.el` selects graphical sizes by hostname.

## Repository layout and installation

- [AGENTS.md](AGENTS.md): agent workflow rules and personal preferences.
- `.emacs` and `.emacs.d/{early-init,custom}.el`: home-directory configuration.
- `emacstools/`: personal modules, integration settings, tests and Markdown assets.
- `install.py`: backup-aware configuration link installer and recovery tool.
- `tests/test_install.py`: isolated installer/recovery integration checks.
- `fonts/`: bundled TTFs, license notices, checksum manifest and a user-local installer.
- `legacy/`: inactive personal settings and historic Matthias Popp ADSP/template extensions; not loaded automatically.
- `docs/`: focused guides; the consolidated working reference follows below.
- `export-manifest.json`: source and exported hashes for the explicit allowlist.

The configuration expects `~/emacstools` and `~/.emacs.d`. Run `python3 install.py --dry-run` to review the linked setup, then `python3 install.py` to install it with conflict prompts and recoverable backups. See the installation/recovery section below. Review device-specific paths and install the external dependencies before starting Emacs.

## Installing linked configuration and recovering backups

Use the repository as the authoritative copy of your personal configuration. The standard-library-only **Python 3** installer creates missing directories and individual absolute symlinks for `.emacs`, `.emacs.d/early-init.el`, personal top-level `.el`/`.cjs` modules and Markdown assets under `~/emacstools/`. Tests and `legacy/` are not installed. Keep the checkout at its installed location; moving it breaks absolute links until the installer is run again from the new location.

Save your buffers and exit Emacs before installation or recovery. From the repository root:

```sh
python3 install.py --dry-run
python3 install.py
```

The dry run writes nothing and does not prompt. Normal installation lists the changes and, if existing paths conflict, asks whether to **back up and replace all**, **skip existing paths**, or **quit**. There is no overwrite-without-backup option. Skipping installs only missing paths and can leave a mixed configuration. Noninteractive runs with conflicts stop unless explicitly given `--backup`:

```sh
python3 install.py --backup
```

When maintaining this Git checkout, committed files with a clean working copy rely on Git history for recovery. Make a separate backup before replacing uncommitted edits or files outside Git. The installer still backs up conflicting local destinations for its recovery manifest, because those older local files are not necessarily represented by the checkout history.

Correct links are left alone, so rerunning normally makes no changes. An existing `~/.emacs.d/custom.el` is preserved as-is; on a new machine it is seeded as a regular local copy. Emacs can keep saving Customize settings locally. Shared preferences should be promoted into tracked modules deliberately. Package directories, upstream checkouts, sessions, histories, backups and unrelated files stay local. Parent directory symlinks or file/directory conflicts in parent paths are rejected before changes, rather than replacing a whole configuration directory.

Stale `.emacs.elc`, `early-init.elc` and compiled siblings of installed Lisp modules are included in the backup prompt and moved aside, so they cannot mask linked source. Existing destination files, symlinks (including broken links) and directories are moved into a private backup session before replacement; symlinks are preserved as links, not dereferenced. Each session has a journal at:

```text
~/emacstools/backup/install/<ID>/manifest.json
```

List sessions and inspect a recovery before applying it:

```sh
python3 install.py --list-backups
python3 install.py --restore latest --dry-run
python3 install.py --restore latest
# Or choose an exact ID printed by --list-backups:
python3 install.py --restore BACKUP_ID
```

`--recover` is an alias for `--restore`. Recovery restores the original destinations, removes newly installed links/local seed files, and removes only empty directories created for the installation. Backup journals are retained. Undo the newest session first if several installations have been applied. If a destination has changed since installation, recovery asks before proceeding and saves the newer data under that session's `recovery-saved/` directory; `--backup` explicitly approves this preservation without prompting. Backup files are moved back during restoration, so the restored session is recorded as complete and a repeat restore is harmless. Recovery also supports a partially completed installation after an interruption; the error prints its recovery ID. It restores local destinations, not the Git checkout's history or changes to files edited through links.

`--home /path/to/home` selects an existing target home directory for installation, listing and recovery; it is useful for testing or another account. All target parents must be real directories. A manifest for a different home, unsafe relative paths, or a changed/missing original file backup is rejected. The checkout must remain available for the installed links to work. Restart Emacs after installation or recovery.

Install bundled fonts separately when needed:

```sh
python3 fonts/install.py
```

The font installer has its own backups; configuration recovery does not undo that separate font installation. External libraries and language servers still need the setup described in the dependency table; this link installer does not download packages or upstream checkouts.

Validation: `python3 -m unittest discover -s tests -v` exercises fresh/repeated installs, read-only dry runs, backup/skip/cancel decisions, unattended conflicts, preservation of local Custom/packages/upstream sources, original file modes, broken symlinks, directory contents and stale bytecode, rollback with newer edits, interrupted installation, parent-link rejection and invalid/corrupted recovery data, using isolated temporary homes.

## Dependencies kept outside Git

Emacs packages declared with `use-package :ensure` are installed through the configured GNU ELPA/MELPA archives; `:quelpa` declarations retain their upstream Git recipes. The complete package inventory and customizations appear in the reference below. Package versions are not locked by this export; an installed version is not a dependency lockfile.

| Dependency | Source / setup |
| --- | --- |
| bm | MELPA package `bm`, [joodland/bm](https://github.com/joodland/bm); exported bookmark config uses `:ensure t` |
| ws-butler | Clone [lewang/ws-butler](https://github.com/lewang/ws-butler) into `~/emacstools/ws-butler`, matching the existing `:ensure nil` declaration |
| vterm | Clone [akermu/emacs-libvterm](https://github.com/akermu/emacs-libvterm) into `~/emacstools/emacs-libvterm`; build its native module with the upstream instructions |
| ASCII table | Bundled as `emacstools/ascii-table.el`: Alex Schroeder's legacy version 1.0.0, copied unchanged from the working configuration on 14 November 2026. Original attribution and GPL-2.0-or-later notice are retained; see [license text](licenses/ascii-table-GPL-2.0.txt) and [upstream reference](https://www.emacswiki.org/emacs/AsciiTable). `install.py` links it to `~/emacstools/ascii-table.el`. The separate personal wrapper `my-ascii-table.el` supplies the 0–255 default, read-only buffer and `q` to quit. This legacy API differs from the newer MELPA package with the same name. |
| Xah insertion commands | Clone [xahlee/xah-fly-keys](https://github.com/xahlee/xah-fly-keys) into `~/emacstools/xah-fly-keys`. Exported `xah_extension.el` contains only personal bindings and autoloads, including modern Unicode angle-command names. The modal editing mode is not enabled. Older unbound helper snippets listed in the historic reference are not bundled. |
| Livedown | Install npm package `livedown` externally; the custom Markdown renderer uses its dependencies |
| Fonts | Bundled under `fonts/`, with the preview WOFF2 in `emacstools/assets/`; run `python3 fonts/install.py`. See the bundled-font section below. |
| Language servers and tools | Install the configured servers (e.g. clangd/Python server), ripgrep, optional `wl-copy`/`wl-paste`, Git and build tools through the system package manager; see language, clipboard and startup sections below |
| Tree-sitter grammars | Install the grammars referenced by the configuration using Emacs grammar installation facilities; generated parser binaries are excluded |
| Legacy a2ps | Historic F11/F12 printer bindings reference an external a2ps Lisp integration; this inactive upstream library is not bundled |

Excluded: ELPA/Quelpa package directories, upstream Git checkouts, compiled Lisp/native modules, backups, autosaves, sessions, recent files, clipboard/history data and obsolete credential comments. Export adjustments include package-managed bm, the bindings-only Xah adapter, repository-local test loading, and updating stale font documentation/test expectations to the current 9 pt setting on N900D9658. Historic Latin-1 personal sources are converted to UTF-8 without dropping characters. The ASCII read-only improvement was also applied to the live configuration after backing up its C/C++ integration and guide.

## Bundled fonts and installation on a new device

Fonts are an explicit exception to the rule excluding third-party dependencies: the repository now includes the fonts selected by the active configuration so installation does not require downloading or converting them.

| Files | Purpose / version | Attribution |
| --- | --- | --- |
| `fonts/JetBrainsMono/JetBrainsMono-*.ttf` | Complete unpatched JetBrains Mono styles, version 2.304; editing and inherited bold/italic faces | [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono/tree/v2.304), SIL OFL 1.1; bundled `OFL.txt` |
| `fonts/JetBrainsMono/JetBrainsMonoNL-*.ttf` | Complete JetBrains Mono NL styles, version 2.304; includes the NL ExtraBold face referenced by the config | Same JetBrains license |
| `fonts/SymbolsNerdFontMono/NFM.ttf` | Symbols Nerd Font Mono, Nerd Fonts 3.4.0; icon font used by `nerd-icons` | [Nerd Fonts symbols](https://github.com/ryanoasis/nerd-fonts/tree/v3.4.0/patched-fonts/NerdFontsSymbolsOnly); bundled upstream MIT notice and component license audit |
| `emacstools/assets/nerd-symbols.woff2` | Existing converted symbols font used by local preview and standalone HTML export | Symbols font notices above apply; no conversion needed on the new device |

The font files are copied unchanged from the working machine, with SHA-256 hashes and TTF metadata recorded in `fonts/manifest.json`. Installed Nerd Font patched variants of JetBrains Mono are not selected by the active config and are not duplicated here. Preserve the bundled font license notices when redistributing.

From the repository root, install for the current Linux user:

```sh
python3 fonts/install.py
```

This copies TTFs and their notices into `${XDG_DATA_HOME:-~/.local/share}/fonts/emacs-config/`, and the preview WOFF2 into `~/emacstools/assets/`. It skips unchanged files, backs up each changed destination under `~/emacstools/backup/fonts/`, and refreshes the font cache if `fc-cache` is installed. It does not replace your Emacs configuration. Inspect destinations first with `python3 fonts/install.py --dry-run`; use `--help` for custom destinations. Python 3 is the only installer dependency. Validation covered dry-run with no writes, installation into an isolated directory, an unchanged second run, and verified backup/replacement of an existing font. Restart graphical Emacs if it does not detect newly installed fonts.

For Windows-hosted WSL terminals, also install the bundled TTFs **on Windows**, then choose a terminal font with the required symbol coverage/fallback. The Linux installer cannot change Windows Terminal's font settings. A Linux graphical Emacs uses the Linux font installation.

Bundling the fonts makes Emacs and the custom HTML preview easier to set up; GitHub's README viewer still cannot load a custom font from Markdown. Use icon images for guaranteed GitHub display.

## Ligatures in graphical Emacs

The personal `emacstools/my-ligatures.el` module configures the external [ligature package](https://github.com/mickeynp/ligature.el), loaded from an installed library or the existing `~/emacstools/ligature.el` checkout. If neither exists, the init installs it through the explicit Quelpa Git recipe `mickeynp/ligature.el`. The upstream package is not vendored. The personal module automatically adds the existing checkout to `load-path` when no installed library is available.

The Emacs 31.1.50 build includes HarfBuzz, and bundled **JetBrains Mono** supports programming ligatures. The separate **JetBrains Mono NL** family means “no ligatures”; a face explicitly selecting that family, such as the existing Vundo UI face, does not gain programming ligatures. Nerd Font icons are independent of ligatures.

By default ligatures apply to `prog-mode`, `text-mode` and `conf-mode`, including derived modes such as C/C++, Python, Org and Markdown. The full ligature set is enabled, including arrows, comparisons, logical operators and punctuation combinations. Configured sequences use light gray (`#D0D0D0`) and bold through the `my/ligature-symbol` face, overriding syntax foreground/weight while retaining the existing font family and background. A small display-only gap separates arrows from immediately following word characters (`->r`, `=>value`, etc.). Existing whitespace is preserved without adding a second gap. The actual characters, cursor positions, search, copying and file contents remain unchanged. These rules do not replace Emacs/GTK menus, title bars or buttons, and do not promise shaping of mode-line/header-line strings. Terminal rendering depends on the terminal's font and shaping support.

| Setting or command | Purpose |
| --- | --- |
| `M-x ligature-mode` | Toggle ligatures in the current buffer |
| `M-x global-ligature-mode` | Toggle the upstream global mode |
| `my/ligatures-enabled` | Default `t`; set nil and apply to disable globally |
| `my/ligature-modes` | Default `(prog-mode text-mode conf-mode)`; set `t` to include all major modes, including UI buffers |
| `my/ligature-sequences` | Full default set from `my/ligature-default-sequences`; customize the combinations offered to the font |
| `my/ligature-arrow-gap` | Default `0.2` character widths; display-only gap between an arrow and an immediately following word, such as `->r`; `0` disables it |
| `my/ligatures-highlight` | Default `t`; enable light-gray/bold styling of configured sequences |
| `my/ligature-symbol` | Customize this face to change light-gray/bold appearance independently of syntax faces |
| `M-x my/ligatures-use-full-set` | Restore the full set, enable ligatures and their light-gray/bold styling |
| `M-x my/apply-ligatures` | Reapply settings and refresh existing buffers; also used at startup |

Validation: nine ERT checks cover inherited-mode selection, repeat application and selector changes, on/off behavior, unchanged buffer text/modified state, light-gray/bold syntax overrides, removal on disable, fontification after edits, display-only arrow spacing, gap removal after edits/toggles, disabling the gap, precedence over a later Eglot semantic operator face, and preserving expanded fontifier bounds/return values. The checks validate configuration; graphical glyph appearance requires viewing it in a GUI frame.

Eglot in Emacs 31 can prepend `eglot-semantic-operator` after ordinary font-lock keywords; that face inherits `font-lock-function-name-face` and can make an operator blue. The personal module applies its final ligature face and arrow gap through a buffer-local wrapper after the normal fontifier completes. This preserves syntax and semantic faces underneath, leaves semantic highlighting enabled, and restores their precedence when ligatures are disabled. No Eglot internals or global operator faces are changed. The Eglot message “Swap operands to !=” is a code-action/refactoring suggestion, separate from operator coloring. The source expression `rc != 0` is not changed by this display fix.

For the current Emacs session, the existing local checkout needs no package installation. Evaluate:

```elisp
(load-file "~/emacstools/my-ligatures.el")
```

If `package-install` says “package not found”, the current archive metadata may not include the package; `M-x package-refresh-contents` can refresh that list, but the local checkout needs no archive access. On another device without the checkout or installed package, restart with the updated init to use its explicit Quelpa Git recipe (network access required). To disable persistently, set `my/ligatures-enabled` to nil through Customize and run `my/apply-ligatures`.

To restore the full set and apply its light-gray/bold style in an active session, evaluate:

```elisp
(progn
  (load-file "~/emacstools/my-ligatures.el")
  (my/ligatures-use-full-set))
```

Use `M-x customize-group RET my/ligatures RET` to choose combinations, adjust `my/ligature-arrow-gap` or save preferences. Fractional gap widths are intended for graphical Emacs; terminals may round them. `M-x customize-face RET my/ligature-symbol RET` changes the symbol styling. Styling follows configured character sequences, including inside strings/comments, and requires font-lock; it does not detect whether a particular font actually supplies a shaped glyph. Disabling `ligature-mode` removes the additional style. A face choosing JetBrains Mono NL will display the characters separately regardless of this list.

## Nerd Font symbols: installation and rendering problems

Nerd Font icons are characters in Unicode's Private Use Areas. Their appearance depends on a compatible font; a square, empty box or incorrect symbol usually means that the viewer has no matching glyph or uses an incompatible font version. Installing the Emacs `nerd-icons` package supplies icon names and lookup code, and the corresponding font must also be installed. See the [upstream nerd-icons installation instructions](https://github.com/rainstormstudio/nerd-icons.el#installing-fonts).

The repository includes the required TTFs and preview WOFF2. Run `python3 fonts/install.py` after cloning to install them; merely storing fonts in Git does not register them with the operating system. There are separate rendering environments:

| Where the icons are viewed | Required setup |
| --- | --- |
| Graphical Emacs, including breadcrumbs | Run `M-x nerd-icons-install-fonts` to install Symbols Nerd Font Mono, then restart Emacs if the new font is not detected. Check `M-: (find-font (font-spec :family "Symbols Nerd Font Mono"))`; a non-nil result means Emacs can find it. |
| `emacs -nw` | Select a Nerd Font in the terminal application's settings. In WSL, a Windows terminal needs the font installed on Windows; installing a font only inside Debian does not configure the Windows terminal. |
| Custom Livedown preview or exported HTML | Supply the WOFF2 file configured by `my/markdown-nerd-font-file`. The personal preview/export module embeds that file in the generated HTML, so recipients of that HTML do not need to install the font. |
| GitHub's rendered `readme.md` | The page uses GitHub/browser fonts. Markdown cannot force GitHub to load the embedded font used by the local HTML preview. For reliable icons for all readers, use SVG/PNG images with descriptive alt text, or plain-text icon names. |

### Rebuilding the preview/export font (optional)

The bundled WOFF2 needs no conversion. To rebuild it instead, install Symbols Nerd Font Mono from [nerd-icons](https://github.com/rainstormstudio/nerd-icons.el/tree/main/fonts) or [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts). With `woff2_compress` installed through the system package manager, convert the downloaded `NFM.ttf`:

```sh
woff2_compress /path/to/NFM.ttf
mkdir -p ~/emacstools/assets
# Back up an existing destination before replacing it.
cp /path/to/NFM.woff2 ~/emacstools/assets/nerd-symbols.woff2
```

Alternatively, point the preview at an existing WOFF2 file without copying it:

```elisp
(setq my/markdown-nerd-font-file "/absolute/path/to/nerd-symbols.woff2")
```

Keep the font/icon data versions compatible when synchronizing devices. The preview reports `Nerd Font file is missing: ...` if this asset has not been installed; that error concerns the external asset, rather than a missing Markdown renderer. The repository's `*.woff2` ignore rule has a narrow exception for the bundled preview asset.

### Can the font be added directly to the README?

The README can contain icon characters, installation instructions and image references. Embedding a font with a `<style>`/`@font-face` block will **not** make GitHub's README viewer render those characters reliably: [GitHub sanitizes rendered markup and removes custom styles](https://github.com/github/markup#github-markup). Uploading the font beside the README alone does not change the viewer's font. Local standalone HTML exported by the custom Markdown module supports embedded fonts; GitHub README rendering is a separate viewer.

## Validation and scope

The test files are personal ERT suites. They are development checks, not startup dependencies. Test module loading is relative to this repository. Some older tests still require local YAML project fixtures; these require that environment and are not portable fixtures. Syntax checks can run without evaluating the full init. Loading the entire init may install packages or start services, so it is not used as an automated export test.

Export validation on 13 November 2026: all 42 Lisp files passed syntax checks, the Node renderer passed `node --check`, and all 93 ERT tests passed with locally installed dependencies/fixtures. Markdown tests originally used the separately installed Nerd Font; the checkout now includes the WOFF2 at the default module-relative path, so no external font override is needed. ASCII checks additionally verified read-only protection, `q`, repeated regeneration, the default limit 255 and an explicit limit of 127. Values 128–255 display using Emacs character names/glyphs; there is no universal extended-ASCII code page implied. A credential-pattern scan found no matching secrets in the export.

The following reference describes the working source configuration; where upstream layout differs in this export, the dependency and export notes above take precedence.

---

# My Emacs customizations and modules

Configuration reference, reviewed **13 November 2026** against the local source files. This is a snapshot of the configuration on disk, not a claim that every setting has already been reloaded into a running Emacs.

This single document combines the active configuration, personal modules, package integrations, shortcuts, troubleshooting and the existing detailed guides. It documents your customizations to third-party packages; their complete upstream manuals are available through Emacs Help and the installed package sources.

## Contents

- [Configuration files and startup](#configuration-files-and-startup)
- [Startup performance](#startup-performance)
- [Appearance, fonts and terminal colors](#appearance-fonts-and-terminal-colors)
- [Everyday keyboard shortcuts](#everyday-keyboard-shortcuts)
- [Buffers, windows, Helm and file search](#buffers-windows-helm-and-file-search)
- [Editing, completion, undo and saved files](#editing-completion-undo-and-saved-files)
- [Sessions and frame geometry](#sessions-and-frame-geometry)
- [Language modes, indentation and templates](#language-modes-indentation-and-templates)
- [Eglot and language servers](#eglot-and-language-servers)
- [Syslog highlighting](#syslog-highlighting)
- [Clipboard and vterm](#clipboard-and-vterm)
- [Bookmarks](#bookmarks)
- [Breadcrumb and Markdown preview overview](#breadcrumb-and-markdown-preview-overview)
- [Package inventory](#package-inventory)
- [Personal command and option registry](#personal-command-and-option-registry)
- [Configuration declaration reference](#configuration-declaration-reference)
- [Detailed breadcrumb guide](#detailed-breadcrumb-guide)
- [Detailed Markdown preview guide](#detailed-markdown-preview-guide)
- [Detailed package startup guide](#detailed-package-startup-guide)
- [Detailed terminal colors guide](#detailed-terminal-colors-guide)
- [Detailed editing line numbers guide](#detailed-editing-line-numbers-guide)
- [Detailed buffer navigation guide](#detailed-buffer-navigation-guide)
- [Detailed Deadgrep guide](#detailed-deadgrep-guide)
- [Maintenance and reload](#maintenance-and-reload)

## Configuration files and startup

| File or directory | Role |
|---|---|
| `~/.emacs.d/early-init.el` | Startup GC helper, initial frame size/position and geometry helper; optional geometry debug logger |
| `~/.emacs` | Main startup, package declarations, global shortcuts, theme, module loads and inline customizations |
| `~/.emacs.d/custom.el` | Customize-generated package selection list and face settings; loaded by the main init |
| `~/emacstools/` | Local modules, configurations and supporting libraries |
| `~/emacstools/backup/` | Backups made before editing personal Emacs configuration/modules |
| `~/Documents/codex/emacs/` | Emacs documentation, including this reference |
| `~/Documents/codex/emacs/backups/` | Previous versions of documentation |
| `~/.emacs.d/backups/` | Normal Emacs versioned backups of edited files; separate from configuration-edit backups |
| `~/.emacs.d/auto-saves/` | Emacs automatic recovery files |

The main init initializes `package.el` and configures GNU ELPA, MELPA Stable and MELPA. Package archive contents are refreshed if empty. `use-package-always-ensure` is enabled, with explicit exceptions for built-in/local packages. An entry in `package-selected-packages` records package-manager selection; it does not itself prove that a mode is enabled. Commented old setups and unused files are not treated as active configuration.

Installed Quelpa packages are skipped by ordinary `:quelpa` startup declarations. A normal upgrade check is scheduled after 15 idle seconds following startup, when seven days have elapsed since the last completed run. This is elapsed-time scheduling: missing a weekend means the next startup can run the check. A single Emacs session left open indefinitely does not have a repeating weekly timer. Missing packages can still be installed. See the integrated package-startup guide below.

### Active local module map

| File under `~/emacstools/` | How it is used |
|---|---|
| `my-startup-performance.el` | Required by early init; bounded startup GC boost, restoration, terminal-query wait cap, timing report and optional wall-time profiler and WSL native executable lookup optimization |
| `my-device-font.el` | Loaded by main init; hostname-based graphical font sizes and frame hooks |
| `my-emacs-geometry.el` | Required by early init and main init; persists graphical frame dimensions |
| `my-emacs-sessions.el` | Required by main init; saves independent desktop sessions and restores them through Helm |
| `my-editing-line-numbers.el` | Loaded by main init; line numbers for editing/text-file buffers, excluding tools |
| `my-buffer-reload.el` | Loaded by main init; Ctrl+F5 file reload with cursor/scroll restoration |
| `my-deadgrep-recursion.el` | Loaded on first Deadgrep use; recursion controls, launch enforcement, result/file/error hiding, diagnostics and clearer error summaries |
| `my-helm-files.el` | Loaded by Helm config; protected retained listings, full-width file picker, visible path input and C-c C-b return to the source directory |
| `my-buffer-navigation.el` | Loaded by main init; next/previous-buffer skip Helm's hidden buffers |
| `my-context-breadcrumb.el` | Loaded by main init; globally enabled syntax-context bar and navigation |
| `bookmarks_config.el` | Loaded by main init; bookmark keys, ribbon bitmap, orange/tinted highlighting |
| `bm.el` | Loaded by bookmark configuration; local bookmark library |
| `json_config.el` | Loaded by main init; JSON associations, indentation and formatting commands |
| `python_config.el` | Loaded by main init; Python interpreter, Elpy declaration, virtual environments and mode hooks |
| `c_mode_config.el` | Loaded by main init; C/C++ modes, indentation, keys, tags and Tree-sitter remapping |
| `c_cpp_templates.el` | Loaded by C/C++ configuration; Tempo templates and expansion hooks |
| `ascii-table.el` | Loaded by C/C++ configuration; ASCII reference commands |
| `org_config.el` | Loaded by main init; Org appearance, source blocks, agenda, links and bullets |
| `my-pair-editing.el` | Loaded by main init; global forward/backward pair-deletion keys preserving lowercase bindings |
| `xah_extension.el` | Loaded by main init; bracket/quote insertion, deletion and matching helpers |
| `my-markdown-preview.el` | Loaded by main init; Livedown preview, renderer/export, embedded browser and font assets |
| `my-markdown-render.cjs` | Called by Markdown renderer/export; Node helper |
| `assets/markdown-theme.css`, `.js`, `markdown-theme-controls.html` | Markdown preview/export themes and chooser |
| `assets/nerd-symbols.woff2` | Portable Nerd Font symbols embedded in preview and exported HTML |
| `my-yaml-ts-font-lock.el` | Loaded by main init; prevents whole YAML scalar/script blocks turning string-colored |
| `my-wayland-clipboard.el` | Loaded conditionally for graphical Wayland with `wl-paste`; fresh clipboard reads |
| `my-eglot-retry-limit.el` | Loaded when Eglot config runs; bounded server retries and exited-event cleanup |
| `emacs-libvterm/` | Added to `load-path`; local vterm Lisp and native module |
| `ws-butler/` | Local load path for whitespace-on-save handling |

`treesitter_config.el`, `helm_config.el`, `doomModeLine_config.el`, `dictionary_config.el`, `php_sgml_config.el` and `sich/syslog_config.el` exist in the local tree but are not loaded by the reviewed active init chain. The active grammar list, Helm, Doom modeline and Syslog setup are elsewhere, chiefly in `~/.emacs`. The old `treesitter_config.el` grammar list is not the effective list. Files named `*-tests.el` are validation suites, not normal startup modules.

## Startup performance

Integrated from [emacs-startup-performance.md](docs/emacs-startup-performance.md).

The shared config loads optional tools on demand, reduces garbage collection during startup, and bounds synchronous terminal capability-query waits. These changes are separate from the existing weekly Quelpa update policy.

### What changed

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

### Measuring startup

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

### Terminal startup delays

On the installed Emacs 31 build, XTerm-compatible initialization normally sends secondary and primary device-attribute queries. The default query timeout is two seconds. A terminal or multiplexer that does not answer those queries can therefore add roughly four seconds after the main init has finished. An additional terminal-name query has its own shorter timeout.

An isolated PTY test, with no real user init or package activation, measured **4.278 seconds** with the original waits and **0.570 seconds** with the shorter waits. A separate `emacs -nw -Q` check took 4.249 seconds. This demonstrates a terminal-negotiation delay in the test PTY; timing in the actual terminal emulator, WSL host or multiplexer can differ.

`my/startup-terminal-query-timeout` defaults to **0.2 seconds**. An advice around `terminal-init-xterm` temporarily caps synchronous query waits and caps the initial redisplay wait at 0.05 seconds. Emacs's asynchronous fallback remains installed for unanswered initialization queries. This does not disable terminal feature detection, bracketed paste or focus tracking. Dynamic binding restores the normal query settings after initialization, so clipboard requests during editing retain their original timeout. The setting also applies when initializing later XTerm-compatible terminal frames; graphical initialization does not call this terminal function.

To restore Emacs's original waits, put this **before** the performance-module require in `early-init.el`:

```elisp
(setq my/startup-terminal-query-timeout nil)
```

If features require more time on a slow remote terminal, a larger value such as 0.5 can be used instead. Restart the terminal Emacs to compare; loading the module after terminal initialization cannot speed up the initialization that has already occurred. The timing report still records terminal duration when the cap is disabled.

### Profiling slow initialization on another device

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

### WSL: slow executable searches

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

### Applying on both devices

Restart Emacs to measure the effect: reloading the init does not unload packages already in memory. Synchronize these changed files to the other device along with the shared config:

- `~/.emacs`
- `~/.emacs.d/early-init.el`
- `~/emacstools/my-startup-performance.el`
- `~/emacstools/python_config.el`
- `~/emacstools/org_config.el`

The performance changes have no hostname condition. The separate `my-device-font.el` module continues selecting 9 pt on N900D9658 and 11 pt on mp-linux.

### Validation and maintenance

The isolated regression suite is:

```sh
emacs -Q --batch -l ~/emacstools/my-startup-performance-tests.el
```

All nine tests pass. They verify GC restoration, safe manual reload, on-demand loading, preserved shortcuts and settings, first-use Deadgrep/Vundo/Magit/Gtags configuration, and Org mode's indentation, Superstar and Tempo setup. Terminal checks also verify scoped timeouts, opt-out behavior, preserved asynchronous handlers and restoration of the editing-time query defaults. Profiling checks cover real load/executable lookups, nested self/inclusive accounting, original return/error behavior, advice cleanup and omission of process arguments from the report. WSL checks cover native executable selection, mounted-directory exclusions and exceptions, explicit paths and .exe commands, remote bypass, unchanged global PATH/exec-path, detection, opt-out and cleanup at the startup checkpoint. The module compiles without warnings, and edited Lisp files pass balanced-parenthesis checks. The tests do not execute the full init, package installers, external language servers or preview processes.

Backups of changed configuration/modules are in `~/emacstools/backup/`; documentation backups are in `~/Documents/codex/emacs/backups/`. Installed package files are unchanged.

## Appearance, fonts and terminal colors

| Setting | Current configuration |
|---|---|
| Theme | `alect-black` |
| Theme displays | `((class color) (min-colors 256))`: GUI, 256-color and truecolor terminals |
| Main text | Neutral gray `#B8B8B8`, set through the high-priority `user` theme after `custom.el` |
| Strings | `font-lock-string-face` foreground `#FF5252` applied by the configured after-init hook |
| Graphical font | JetBrains Mono: 9 pt on `N900D9658`, 11 pt on `mp-linux` and unlisted devices; applied to existing and new graphical frames |
| Graphical background opacity | `alpha-background` 87: 87% opaque / 13% transparent, initial and new GUI frames |
| Current line | `global-hl-line-mode` enabled; theme background, no separate terminal override |
| Lines | Visual wrapping: `truncate-lines` and `truncate-partial-width-windows` both default nil |
| Modeline | Doom modeline, height 18, bar width 4, size and column information |
| Startup chrome | Menu/tool/scroll bars disabled where applicable; startup messages/screen suppressed; no bell and no blinking cursor |
| Date/time | Day/date and 24-hour format configured; `display-time` activation is commented out |

Alect generates theme specifications through a macro. Its byte-compiled theme freezes the original graphical-only display class, so your theme is loaded with `load-suffixes` temporarily restricted to `.el`. This uses the installed theme source without editing package files.

The main gray foreground preserves explicit syntax colors, font family and background. Faces inheriting the default foreground also become gray. Main text color can be reapplied with:

```elisp
(custom-theme-set-faces 'user '(default ((t (:foreground "#B8B8B8")))))
```

A terminal needs truecolor for exact RGB values. With a terminal/multiplexer that supports it, start `COLORTERM=truecolor emacs -nw`; inspect `M-: (display-color-cells)` afterward. `16777216` means truecolor; `256` means approximation. Terminal fonts and transparency belong to the terminal application, not Emacs's GUI font/alpha settings. The old terminal-only hl-line/region/Man/Company colors and ineffective tmux `RGB` keyboard-capability setting have been removed.

### Device-specific font sizes

`~/.emacs` loads `~/emacstools/my-device-font.el` in the font configuration block. This replaces the old unconditional `JetBrains Mono-11` setting. One shared configuration can therefore select a different font size on each device:

| Short hostname | Environment | GUI font size |
| --- | --- | --- |
| `N900D9658` | Debian under WSL2 | 9 pt |
| `mp-linux` | Pop!_OS | 11 pt |
| Any other hostname | Any | 11 pt fallback |

Selection uses Emacs's `system-name`, ignoring capitalization and the domain suffix. It deliberately matches the device rather than the operating system: another Debian/WSL installation does not automatically receive this machine's font size. Inspect the detected name with `M-: (system-name)`. If the WSL distribution uses a different hostname, add that name to `my/device-font-sizes`.

| Option | Default | Purpose |
| --- | --- | --- |
| `my/device-font-family` | `"JetBrains Mono"` | Graphical editing font family |
| `my/device-font-sizes` | `(("N900D9658" . 9) ("mp-linux" . 11))` | Per-device sizes in points |
| `my/device-font-default-size` | `11` | Size for unmatched devices |

`my/device-font-size` returns the selected size; `my/device-font` returns its font specification. `my/fontify-frame` applies it only to graphical frames. `my/apply-device-font` updates all existing graphical frames, the default font for future frames, and the frame-creation hook. Reloading is idempotent and supports daemon/client frames. Terminal font size remains controlled by the terminal application.

After changing these options, run `M-x my/apply-device-font`. To load this change without restarting Emacs, evaluate:

```elisp
(load-file "~/emacstools/my-device-font.el")
```

Keep the updated `~/.emacs` and `~/emacstools/my-device-font.el` on both devices. Hostname detection only selects settings on the computer running Emacs; it does not synchronize files to the other computer. Both devices must have JetBrains Mono installed for the intended font family.

The breadcrumb's default `my/context-breadcrumb-font-size` is nil, so it follows the selected frame's editing font size automatically. An explicit value such as 110 would override that inheritance.

Validation: `emacs -Q --batch -l ~/emacstools/my-device-font-tests.el` passes two tests covering both hosts, case/domain normalization, unknown-host fallback, custom mappings, existing/new GUI frames, terminal exclusion and duplicate-hook prevention. The module also passes byte compilation with warnings treated as errors. Font rendering on the other device requires loading the synchronized config there.

### Line numbers, minibuffer and breadcrumb backgrounds

Line numbers appear in editable programming/text/configuration/fundamental buffers and text file buffers, including unrecognized names such as `~/.bash_history_backup`. Helm, special/utility modes, Dired, terminals, minibuffers, images/documents and internal footer buffers are excluded. Read-only text files still qualify. The line-number type is left to normal `display-line-numbers` settings.

`my/line-number-match-editor-background` matches the line-number faces to the editor's background. `my/minibuffer-match-editor-background` does the same for input/echo areas through a background-only face and buffer-local remaps. Both have theme/frame hooks; the minibuffer helper also runs on minibuffer setup and after init. Reapply them after manually changing the editor background.

There is no independent face alpha in this setup. Matching background colors follows frame alpha; it does not prove identical perceived transparency across graphical areas. `my/context-breadcrumb-frame-opacity` defaults nil, following the existing frame value; setting a number intentionally affects the whole frame. For persistent visual mismatches use the breadcrumb appearance report; parameter-only checks do not establish graphical rendering quality.

### Modeline contents

The custom main Doom modeline has bar, matches, buffer identity, remote host, position, parrot and selection information on the left. Its right side contains misc/minor-mode/input-method/encoding/major-mode/process/VCS information. Filenames are relative to the project; project detection is set to `ffip`; VCS text is limited to 60 characters. Declaring a segment does not necessarily activate the external feature supplying its data.

## Everyday keyboard shortcuts

`C-` means Ctrl, `M-` usually Alt, `S-` Shift, and `s-` Super/Windows. Key delivery varies between graphical and terminal applications. A major/minor-mode map can override a global binding; use `C-h k` on the actual key sequence to inspect the effective command.

| Key | Command / action |
|---|---|
| `M-x` | Helm command chooser (`helm-M-x`) |
| `C-x b` | Helm Mini: buffers and recent files |
| `C-x C-f` | Helm file finder |
| `C-x r b` | Helm bookmark chooser |
| `C-c h` | Helm command prefix |
| `M-y` | Helm kill-ring chooser |
| `C-c f` | Recursive filename search with ripgrep + Helm |
| `M-s` | Deadgrep project/content search |
| `R` in Deadgrep | Toggle recursive search; also available as header buttons |
| `z` in Deadgrep | Hide a result line, a filename and its results, or an error message at point |
| `u` / `U` in Deadgrep | Restore the last / all manually hidden items |
| `Tab` / `Shift-Tab` in Deadgrep | Fold the current file's results / toggle all file groups; headings stay visible |
| `C-c C-b` in Helm Find Files | Return to the originating buffer's file directory |
| `C-l` in Helm Find Files | Move up one directory; numeric prefixes move up several |
| `C-]` in Helm Find Files | Toggle filename-only / full-path labels |
| `C-k` in Helm | Clear input |
| `C-c h` in Helm Find Files | File/directory history; overrides the global Helm-prefix binding here |
| `M-g` | Personal `goto-line-and-column`: `LINE`, `LINE:COLUMN`, `LINE,COLUMN`, `:COLUMN` |
| `C-q` | Previous window (`my-prev-window`) |
| `C-S-q` | Next window (`other-window`) |
| `C-x k` | Personal current-buffer kill helper |
| `C-z` / `C-S-z` | `undo-only` / `undo-redo` |
| `C-c u` | Vundo visual undo tree |
| `C-*` | Open vterm |
| `F2` / `C-F2` / `S-F2` | Toggle / next / previous bm bookmark |
| `C-S-F2` | Remove bookmarks in current buffer |
| `F5` | `dos2unix`: remove CR at line ends and a trailing DOS EOF marker |
| `C-F5` | Reload the visited file and restore cursor/scroll positions (`my/reload-buffer`) |
| `M-T` | Untabify selection |
| `C-c <left>` / `C-c <right>` | Rigid indentation left/right; Python classic mode substitutes Python indent shifting |
| `C-<backspace>` | C hungry backspace |
| `C-S-d` | Delete the pair following point, preserving its contents (`delete-pair`) |
| `M-D` / `M-S-d` | Delete the pair whose closer is at or just before point, preserving its contents (`my/delete-pair-backward`) |
| `C-c C-s` | Multiple cursors on selected lines |
| `C->` / `C-<` | Mark next / previous matching occurrence |
| `C-M->` / `C-M-<` | Skip to next / previous occurrence |
| `C-c C-<` | Mark all matching occurrences |
| `M-S-<arrow>` | Drag Stuff movement where applicable |
| `C-c b` | Compare buffers with Ediff |
| `C-c p` / `C-c P` | Print buffer / region with faces |
| `F12` / `F11` | a2ps print buffer / region |
| `C-c l` | Org store link |
| `C-c a` | Org agenda |
| `C-h C-h` / `C-h C-e` / `C-h C-i` | Hexl mode / exit / insert hex string |
| `C-c e` | Ellama transient menu |
| `C-c .` | Personal breadcrumb navigation prefix; complete map in integrated guide |

### Bindings whose final assignment matters

- `C-c f` is initially assigned to `ediff-files`, then reassigned at the end of the init to `my/helm-find-files-recursive`. Use `M-x ediff-files` for the earlier command.
- `C-c l` is initially assigned to print landscape switching, then `org_config.el` sets it to `org-store-link`. Use `M-x pr-toggle-landscape` directly.
- In C/C++ mode, `C-f` opens the paired source/header file instead of moving forward one character. `C-i` invokes Imenu; terminals commonly make `TAB` and `C-i` indistinguishable, so inspect their actual mapping in your terminal.
- The Xah `DEL` replacement is commented out; normal Backspace has not been globally replaced by the bracket-text deletion command.
- Session shortcuts `C-c C-s` / `C-c C-r` are commented out; `C-c C-s` is used by multiple cursors globally and JSON's super-pretty command locally.

## Buffers, windows, Helm and file search

`my-buffer-navigation.el` uses the built-in `switch-to-prev-buffer-skip` predicate. Normal next/previous-buffer commands retain their keys and ordering but skip minibuffers, dead buffers and names matched by Helm's boring-buffer patterns, unless a normal buffer is explicitly whitelisted. The fallback patterns skip leading spaces, `*helm`, `*Echo Area` and `*Minibuf`. Helm's live boring/white lists are used when available. Normal named scratch, Help, shell and Messages buffers remain reachable, matching Helm-style name filtering rather than an editing-only policy. This built-in predicate also participates in window replacement after burying, killing or quitting buffers.

Helm intentionally makes its candidate display writable while rebuilding results. Navigation filtering avoids landing in stale internal buffers without changing Helm's own rendering behavior. Manually selecting such a buffer by name is still possible, but `my-helm-files.el` now makes the retained listing read-only after the Helm session ends. The live rendering buffer remains internally writable for Helm updates; the path prompt remains editable.

Helm configuration enables fuzzy matching across command/buffer/file/imenu/tag/history sources, icons in file browsing, cyan file extensions, 40-character buffer labels, 8-line scroll steps, recent-file history, same-window splitting and header-line input for general Helm commands. Find Files overrides that presentation with a full-width bottom window and visible wrapping minibuffer input. A minibuffer overlay hides the redundant input area when header-line input is active. `curl` is used for suggestions when available. In Helm, `TAB` / `C-i` performs the persistent action and `C-z` opens actions.

GNU Global navigation is enabled through `helm-gtags-mode` in Dired, Eshell, C/C++ classic/TS and assembly hooks. Its keys include `C-.` (DWIM), `C-,` (pop stack), `M-.` (xref definition), `s-<backspace>` (mark rings), and `C-t` (transpose characters). The init sets a variable spelled `helmg-gtags-ignore-case`; it is documented as written, not assumed to configure `helm-gtags-ignore-case` successfully. The C/C++ module also enables `ggtags-mode` and unbinds its navigation map's `M-s` so Deadgrep remains available.

Deadgrep now adds a **Recursive: on off** header row. Click a choice or press uppercase **R** to toggle and rerun the current search. New results buffers default to recursive on. Off searches only files directly inside the displayed search directory; **D** changes that directory. Recursion is local to each results buffer and persists when that same buffer is reused. The full integrated guide below covers depth-argument ownership and reloading.

`my/helm-find-files-recursive` starts at `default-directory`, obtains filenames using `rg --files --hidden --glob !.git`, and opens the selected path under that root. It seeds input from the active region or current symbol; `C-u` asks for a pattern. `M-s`/Deadgrep searches content. `helm-rg`, `helm-ls-git`, `helm-xref`, `helm-descbinds`, `helm-company`, `helm-flycheck`, `helm-fuzzy`, `helm-lsp`, `helm-ispell` and `helm-bm` are declared integrations. Their declaration alone does not establish that every related backend/mode is enabled.

`rename-file-and-buffer` moves/renames the visited file, updates the buffer and its default directory, and supports choosing a new directory. `copy-buffer-name` actually copies the visited file's path with `kill-new`, despite its name. `goto-line-and-column` accepts compiler-style one-based column input and converts it to Emacs's zero-based column offset when a delimiter is supplied.

### Reload a file and retain your position

**Ctrl+F5** (`C-<f5>`) runs `my/reload-buffer` from `my-buffer-reload.el`. It reloads the current visited file from disk, then restores the cursor's logical line and column. Each window displaying that buffer also gets its cursor, top-of-window line/column and horizontal/pixel scroll restored where possible. If the file or a line becomes shorter, the corresponding location is clamped to the available text; the command does not insert padding. The line/column describes a position, not a semantic text anchor: inserting or deleting lines above it externally can change the text at that location.

An unmodified buffer reloads without a confirmation question. A modified buffer retains Emacs's discard-edits question, and declining it leaves the buffer unchanged. The command reads the visited disk file rather than an auto-save and preserves current major/minor modes, avoiding an intentional restart of mode hooks or Eglot. Non-file buffers report that no file is being visited. Existing narrowing is temporarily widened for absolute line tracking and restored afterward. Plain F5 remains `dos2unix`.

Apply the binding to an existing session with `M-:`:

```elisp
(load-file "~/emacstools/my-buffer-reload.el")
```

### Detailed Helm file browsing guide

Integrated from [helm-files.md](docs/helm-files.md).

`~/.emacs` loads `~/emacstools/my-helm-files.el` from the Helm configuration. The module keeps retained Helm result buffers read-only and gives the Find Files chooser room in split-window layouts.

#### Why a Helm listing was editable

Helm creates its candidate buffer in a mode derived from Fundamental mode and explicitly makes it writable for its rendering engine. The buffer can remain writable after the chooser closes. It is an internal candidate listing, not the selected source file.

The local cleanup hook sets the retained results buffer read-only when each Helm session ends, including cancellation. Loading the module also locks existing inactive Helm result buffers. Helm's real setup function makes the buffer writable again when reusing it for a live session, so updates, marking and selection keep working. The active candidate rendering buffer remains internally writable; input should be edited through the minibuffer. This is protection for inactive listings, not a replacement for Helm's rendering model.

The cleanup applies to Helm results generally, including Find Files and Mini. It does not lock the minibuffer, opened source files, or intentional file-renaming interfaces. Existing next/previous-buffer filtering continues to skip internal Helm buffers.

#### Long paths and split windows

For Helm file browsing, the results open in a full-width bottom side window, about 35% of the frame's height. Existing editor windows remain above it. Helm restores their layout on selection or cancellation.

Path input appears in the normal visible minibuffer rather than being echoed into the file-picker header. The minibuffer permits long input to wrap and grow up to 25% of the frame; very long input can still scroll after that limit. Other Helm commands retain the configured header-line input style. File paths and candidates are not rewritten or abbreviated for actions.

Candidate labels show just filenames by default, while the editable prompt contains the current directory. Dotted entries remain compact (`.` and `..`). The built-in `C-]` toggle switches basename/full-path candidate labels when needed.

#### Useful keys inside Find Files

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

#### Options

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

#### Validation

```sh
emacs -Q --batch -l ~/emacstools/my-helm-files-tests.el
```

All five tests pass. They exercise real Helm buffer creation/reuse, protection against accidental insertion, active/inactive buffer handling, actual full-width side-window placement with two editor splits, session-local input/layout settings, and returning to the source directory despite unrelated path text, including non-file buffers and missing-origin handling. The module byte-compiles without warnings. A real interactive terminal smoke check also passed cancellation, subsequent chooser reuse, opening a temporary file, editable nontruncating input, retained read-only results and restoration of both editor windows. Graphical font/rendering details were not inspected.

Backups are in `~/emacstools/backup/` and `~/Documents/codex/emacs/backups/`.

## Editing, completion, undo and saved files

Global editing preferences include electric pairing, short yes/no answers, fill column 150 in programming/text/configuration modes, tab width/standard indent 4, a kill ring of 500 entries, highlighted search/query-replace matches, case-sensitive tags and visual wrapping. Automatic fill is not enabled by the personal setup. Lock-file creation is disabled.

CUA rectangle/selection support is enabled through `cua-selection-mode`, while `delete-selection-mode` is explicitly disabled. Both `cua-delete-copy-to-register-0` and `delete-selection-save-to-register` are nil, avoiding the persistent replacement overlay previously seen after replacing a whole buffer. `font-lock-ensure` runs on file visits; C++ TS buffers also flush/ensure font locking in a mode hook. These settings do not mean that every visible highlight is a font-lock face; overlays can have their own appearance.

Company is globally enabled after init with idle delay 0.1 seconds, minimum prefix 1, aligned annotations and an initial `company-capf` backend. The loaded C/C++ module also contains assignments to `company-eglot` inside legacy C/C++ hook code. Runtime backends can therefore depend on mode/hook order; inspect `M-: company-backends` rather than assuming the global initial value is final. Documentation compilation has not changed these existing assignments.

Indent Bars is enabled by configured Python classic and YAML classic hooks. Dtrt-indent global mode detects existing indentation with verbosity 0. Clean-aindent-mode is enabled from programming-mode hooks with the simple-indent option. Local Ws-butler is hooked to classic C/C++ and a hook spelled `pthon-mode`; that misspelling is recorded as written and is not treated as a working Python-mode hook. Its exact declaration is included in the source-level reference.

Vundo uses Unicode symbols and a JetBrains Mono NL font for its display. The final configured undo limits in its block are 80,000,000 soft, 120,000,000 strong and 360,000,000 outer bytes, superseding the earlier outer-limit assignment. Undo-fu-session persists undo history under `~/.emacs.d/undo-fu-session/`, requests zstd compression and excludes Git commit/rebase control files. The older undo-tree setup is commented out, even though undo-tree remains in the Customize package-selection list.

`my-buffer-kill` calls `View-quit` in view mode and otherwise kills the current buffer. Its old undo-tree branch clears the modified flag/removes the undo-tree save hook if that mode is active. The helper does not generally disable every modified-buffer or process query despite the older source comment claiming no prompts.

### Backups and automatic recovery

| Setting | Value / behavior |
|---|---|
| Versioned/VC file backups | `vc-make-backup-files t` |
| Backup directory | `~/.emacs.d/backups/` |
| Versions | `version-control t`; retain 10 new and 2 old versions; delete excess versions |
| Backup method | Copying, preserving the original inode/link behavior |
| Every-save backup helper | Clears `buffer-backed-up` before save for existing files smaller than 20 MiB |
| Automatic recovery files | Rewritten into `~/.emacs.d/auto-saves/` |
| Auto-save input interval | 2000 input events; other timeout behavior remains Emacs-controlled |

These are separate from the backups of configuration files made before requested changes. `dos2unix` edits the current buffer and does not save automatically. Use normal save/revert operations afterward as appropriate.

### Comparison, spelling and printing

Ediff uses plain windows, a side-by-side split (`split-window-horizontally`) and does not highlight every diff at once by default. `flyspell-english` enables Flyspell, selects the American dictionary and checks the current buffer; the larger Hunspell/dictionary setup around it is commented out. Printing shortcuts invoke PostScript/a2ps commands and require the corresponding external printing tools.

## Sessions and frame geometry

`my-emacs-sessions-mode` is enabled globally. Every Emacs instance gets a separate session directory under `~/.emacs.d/sessions/`. Open file sessions are saved automatically on exit, up to 10 recent sessions retained, and `latest` points to the most recently saved session. Sessions without open files are not offered as useful restore candidates. Desktop session restore is explicit, not automatic startup restore.

| Command | Purpose |
|---|---|
| `my/helm-sessions` | Choose a saved session through Helm |
| `my/restore-last-session` | Restore the most recent saved session |
| `my/restore-session` | Choose a session directory directly |
| `my/save-current-session` | Save the current open-file desktop session |
| `my/cleanup-sessions` | Enforce retention policy |

A restore copies the saved desktop to a disposable temporary directory, loads it eagerly, leaves the saved desktop/lock untouched, and cleans up afterward. It reports success only when desktop loading actually succeeds. Desktop frame restoration is disabled so the independent geometry helper keeps control of window dimensions. Saved sessions also have a `files.txt` list.

Shell launch examples already supported by the configuration:

```sh
emacs --eval '(my/helm-sessions)'
emacs-nw --eval '(my/helm-sessions)'
```

The existing shell aliases `emacs-session` and `emacs-nw-session` call those entry points. The local `/usr/local/bin/emacs-nw` wrapper starts Emacs with `-nw`; it does not advertise truecolor itself.

Geometry is loaded early from `~/.emacs.d/frame-geometry.el`. Initial position is left 26/top 23; early init subtracts two columns from the saved width and restores height. Invalid/missing saved data falls back to `my/geometry-default`, currently `(:width 1511 :height 931)` in the source. The source's default docstring calls these pixels, but `my/geometry-save` actually writes `frame-width`/`frame-height` and early init uses columns/rows. This units discrepancy is recorded here without changing its existing behavior. Saving runs only for graphical frames.

`my/geometry-debug-log` can append dimensions, frame edges and initial settings to `~/.emacs.d/frame-geometry-debug.log`. Its automatic startup/exit debug hooks are commented out, so call the Lisp function manually when needed.

## Language modes, indentation and templates

### C and C++

`c_mode_config.el` loads the Tempo templates and ASCII table and configures spaces with width 4, BSD-style TS indentation, folding, tags and personal keys. Later definitions replace earlier copies of `my-c-mode-common-hook` and `insert-current-date-time`; the later source definitions are the applicable ones.

Its final file associations put `.cc`, `.hh`, `.hpp`, `.ipp`, `.tcc`, `.c`, `.C`, `.h` and `.H` into `c++-mode` before remapping, including `.c`/`.h`. The remap list maps classic C/C++/combined modes to `c-ts-mode`, `c++-ts-mode` and `c-or-c++-ts-mode`. The settings therefore do not imply that all `.c` files stay in classic C mode.

Classic CC mode uses user style, auto-newline/hungry behavior, custom case/block/namespace offsets, `//` comments, hs-minor-mode, ggtags and the breadcrumb. TS hooks install a custom C/C++ indentation rule list with 4-space block/control indentation and special namespace/bracket rules. `treesit-simple-indent-debug` is currently t, which can produce indentation diagnostics. The custom rule list is documented as existing configuration, not validated as a new indentation implementation by this documentation task.

| C/C++ key | Action |
|---|---|
| `C-+` | Align region |
| `C-f` | Find paired source/header via `ff-find-other-file` |
| `C-i` | Imenu |
| `RET` | Newline and indent |
| `TAB` | Generic indentation command (subject to terminal C-i equivalence) |
| `F4` | Insert date/time in `%a %b %H:%M:%S %Y` format |
| `F10` | Hexadecimal ASCII reference |
| `M-RET` | Tempo completion in classic and TS C/C++ buffers |

Source/header lookup searches `.`, `../../`, `../`, `../inc`, `./inc`, `../include`, `../src` and `./src`.

Tempo templates prompt for conditions, names and other fields, using file/user/date placeholders. A complete tag list follows later in this document. It includes preprocessors, conditionals, loops, switch/case, class/namespace, vector, exceptions, headers and includes. ASCII commands also support decimal and octal tables.

### Python

`python_config.el` declares Elpy and Pyvenv, uses `python3 -i` for the shell, `python3` for Elpy RPC, requests the current RPC virtual environment and sets `WORKON_HOME` to `~/.pyenv/versions`. The Elpy declaration sets `elpy-enable` as a variable; it does not contain a call to `(elpy-enable)`, so it is not proof that the full Elpy suite is activated. Eglot startup is managed by the shared main-init hooks.

Classic Python hooks use spaces, tab width/indent offset 4, Company and the personal breadcrumb, with `C-c <left/right>` mapped to Python indentation shifting. The module also contains a `python-hook` backend assignment; that hook name is not the standard `python-mode-hook`, so its presence is not treated as a guaranteed active callback. Both classic and TS Python are listed in Eglot configuration and breadcrumb support, but this module's classic-only hooks are not assumed to run for every TS buffer.

### JSON

`json-mode` is associated with `.cfj`, `.jfav`, `.jset`, `.json` and `.jdmxp`. Its hook uses 2-space `js-indent-level`. The native TS mode is supported by the breadcrumb but is not automatically substituted by the JSON module.

| JSON key / command | Action |
|---|---|
| `C-c C-f` / `json-pretty` | Replace buffer with Python `json.tool` formatted output |
| `C-c C-c` / `json-compact` | Replace buffer with compact JSON output |
| `C-c C-s` / `json-super-pretty` | Run the separate `~/sourcen/python-tools/lios/prettyPrintJson.py` helper with `-sp` |

The custom super-pretty helper operates on the visited filename through an external command; it is distinct from the two buffer-replacing Python standard-library commands.

### YAML

Classic `yaml-mode` is obtained from its configured Quelpa recipe, recognizes `.yml` and binds Return to newline-and-indent. Its string rule is limited to quoted YAML scalars. `my-yaml-ts-font-lock.el` replaces the string feature for YAML TS: plain scalars and script block bodies stay neutral while paired quoted fragments receive string color. Quote matching is bounded to each YAML scalar; this is lightweight highlighting, not full embedded shell parsing. Reloading the module updates already-open YAML TS buffers. The global line-number and breadcrumb policies support both classic and TS YAML.

### Org

`.org` files use Org mode with `org-indent-mode`, Org Superstar bullets `◉ ○ ✸ ✿`, hidden emphasis markers, pretty entities and inline images capped through the configured 600 width. The agenda directory is `~/Documents/org`; Return follows links. The final `org-log-done` setting is t, after an earlier assignment of `time` in the same file.

Source blocks use native fontification and indentation, edit in the current window, and use content indentation 2. `org-tempo` is required through the Superstar config (`<s` then completion for source blocks where supported). Global keys are `C-c l` for storing a link and `C-c a` for the agenda. Org breadcrumbs use native headline/source-block context without requiring a Tree-sitter grammar; they have independent fixed typography.

### Other language integrations

Rust mode is declared; Dockerfile and Lua modes are deferred; `.lua` is associated with Lua mode. Built-in `cmake-ts-mode` handles `CMakeLists.txt`. Shell/Bash modes are included in Eglot's hook list, but the main-init sh-to-bash-TS remap is commented out. Grammar sources pinned in the active init are C v0.23.6, C++ v0.23.4, Python v0.23.6, Bash v0.23.3, CMake v0.7.4, JSON v0.24.8 and Rust v0.23.3. The list is not an automatic installer; automatic install code is commented out. Tree-sitter font-lock level is 4 and the maximum configured buffer size is 100 MiB. Already-installed grammars can support additional breadcrumb modes beyond this source list.

### Bracket and quote helpers

`xah_extension.el` supplies commands for ASCII parentheses/braces/brackets, quotes, Markdown quotes/fences and various typographic bracket pairs. Its insertion helper handles selection wrapping or insertion depending on context. The explicitly bound subset is:

| Global key | Insertion |
|---|---|
| `C-x C-(` | Parentheses |
| `C-x C-{` | Braces |
| `C-x C-,` | Single angle quotes |
| `C-x C-<` | Double angle quotes |
| `C-x C-'` | ASCII single quotes |
| `C-x C-"` | ASCII double quotes |

Other commands are available through `M-x`; their names are listed in the command registry. Destructive bracket-text deletion is separate from inserting brackets. `xah-goto-matching-bracket` jumps to the matching bracket or ascends a surrounding expression using the syntax table; it has no explicit global binding in the reviewed file.

### Remove a pair without deleting its contents

`my-pair-editing.el` adds global shifted shortcuts. For forward deletion, place point immediately **before** the opening delimiter and press **Ctrl+Shift+D**. For backward deletion, place point **on the closing delimiter or immediately after it** and press **Alt+Shift+D**. Both preserve the enclosed text. Forward deletion uses the built-in `delete-pair`; the backward wrapper uses direct delimiter scanning so Shell mode does not include the preceding dollar sign in its expression movement.

```text
Before: |(text)     Ctrl+Shift+D → |text
Before: (text)|    Alt+Shift+D  → text|
Before: (text|)    Alt+Shift+D  → text|
Before: "${HW_TYPE|}"  Alt+Shift+D → "$HW_TYPE|"
```

Backward deletion matches pairs from `insert-pair-alist`, handles nesting and escaped delimiters, and validates the match before editing. In `"${HW_TYPE}"`, it removes only `{` and `}` and preserves the dollar sign and double quotes. A non-quote closing bracket under the cursor takes priority over one behind it. If the cursor is just after `}` and on the surrounding closing quote, it prefers the braces behind it. Unmatched delimiters raise an error without editing.

The forward key is explicitly `(kbd "C-S-d")`: `(kbd "C-D")` is equivalent to lowercase Ctrl+D and would overwrite normal deletion. Backward deletion accepts both `M-D` and `M-S-d` event forms. Lowercase `C-d` retains its existing character-deletion binding and lowercase `M-d` retains word killing. Global keys can still be overridden by an active major/minor mode, including terminal modes that deliberately forward keys to their subprocess.

Classic terminal keyboard protocols may send Ctrl+Shift+D as exactly the same byte as Ctrl+D. Emacs cannot distinguish those events in that case; lowercase behavior is retained rather than replaced. Use `C-h k` to inspect the received event, or invoke `M-x delete-pair` / `M-x my/delete-pair-backward`. Terminal support for distinct shifted control keys depends on its keyboard protocol. Alt+Shift+D is normally distinguishable as an uppercase Meta key.

Apply the saved bindings to the current session with `M-:`:

```elisp
(load-file "~/emacstools/my-pair-editing.el")
```

## Eglot and language servers

The Eglot declaration runs `eglot-ensure` from C/C++ classic and TS, Python classic and TS, Sh and Bash TS mode hooks. It connects asynchronously (`eglot-sync-connect nil`), shuts down servers when no managed buffers remain (`eglot-autoshutdown t`), and extends the originating server to xref targets (`eglot-extend-to-xref t`). Opening standard-library stubs should therefore reuse the originating project server rather than requiring a new project session solely because the target is outside the project.

| Modes | Configured server invocation |
|---|---|
| C/C++ classic/TS | `clangd-20 -j=16 --background-index --clang-tidy=false --header-insertion=never` |
| Python classic/TS | `npx pyright-langserver --stdio` |
| Sh/Bash TS | `npx bash-language-server start` |

The external executables/packages must be available in Emacs's environment. These are configured invocations, not evidence that the servers are currently running. `eglot-booster-mode` is enabled through its Quelpa package. Eglot event-buffer configuration requests size 0 and full format. The Python module also sets unnecessary/deprecated diagnostic-tag faces to inherit default.

`my-eglot-retry-limit.el` keys retries by project plus language/mode group, reuses live/initializing connections and limits server starts to 10 per key. A connection must remain running for 60 seconds before its start budget resets. This avoids Python/clangd buffers in one project causing endless replacement sessions. Budgets and timers live in the current Emacs process, not a persistent disk database.

`M-x my/eglot-reset-retries` clears stopped budgets; then `M-x eglot` explicitly reconnects. `M-x my/eglot-close-exited-event-buffers` closes finished Eglot JSONRPC event buffers containing the exit marker, preserving source buffers, stderr and live-server event buffers. Cleanup is also scheduled after process exit. For normal connection control use `eglot`, `eglot-reconnect`, `eglot-shutdown` and Eglot's buffer-local commands as appropriate.

## Syslog highlighting

`syslog-mode` is a Quelpa package with Ov and Hide Lines support. `.log` and `.clog` are mapped to it. The main-init custom setup disables syntax-driven multiline quote parsing, makes quote characters punctuation in a buffer-local syntax table and supplies explicit font-lock rules.

Supported patterns include conventional month/day syslog timestamps, ISO-like dates, compact `YYYYMMDD_HHMMSS` prefixes, host/device names, facility/severity, PIDs, C++ symbol/line blocks, program names, kernel prefixes and IPv4-style addresses.

| Field / severity | Appearance policy |
|---|---|
| Timestamp / structured `time=` value | `font-lock-constant-face`, overriding generic quote/string color |
| `msg="..."` | String face; supports empty and multiline values |
| Missing `msg` closing quote | Stop at the next recognized timestamped record; do not color the following independent record as a string |
| Ordinary paired double quotes | Per-line string highlight with escaped-character handling |
| Single quotes | Restricted per-line matching to avoid ordinary word apostrophes |
| Emerg/FATAL | Red, bold; emerg face has black background |
| Alert/Crit | Red, bold |
| Err/ERROR | Firebrick1, bold |
| Warn/Warning | Orange, bold |
| Notice/VERBOSE | Yellow |
| Info | Spring green |
| Debug | Magenta |
| Program/kernel fields | Light blue |

The multiline matcher consumes escaped characters before treating a quote as closing, and font-lock region extension ensures partial refreshes include the relevant `msg` value. A new timestamp is a hard record boundary even if the writer was interrupted before finishing the previous line/message. Helpers are `syslog-disable-multiline-strings`, `my/syslog-message-end`, `my/syslog-match-message`, `my/syslog-extend-message-region` and `my-syslog-font-lock-setup`.

An octal display such as `\342` describes an underlying byte (0xE2), often part of a multibyte UTF-8 character. Its presence alone is not proof of UART byte loss; encoding/decoding, partial character sequences and actual stream corruption must be distinguished. Inspect buffer coding/character details rather than attributing every escaped byte to the transport.

## Clipboard and vterm

### Clipboard routing

The main init enables the clipboard and disables primary selection and automatic active-region export: `select-enable-clipboard t`, `select-enable-primary nil`, `select-active-regions nil`. Selecting text with the mouse therefore does **not** automatically publish it as the clipboard contents. Use an explicit copy command (`M-w` in ordinary Emacs buffers, or `M-x kill-ring-save` while a region remains active).

Graphical Emacs uses native GUI cutting. Under Wayland with `wl-paste` available, `my-wayland-clipboard.el` reads the current clipboard directly, avoiding the stale PGTK cache. Its timeout is 3 seconds. It preserves Unicode/trailing newlines, normalizes CRLF to LF and preserves standalone CR. Timeouts, unavailable clipboard text and empty text raise an error instead of silently reusing an old item. A timeout is shown in the minibuffer and can be reviewed in `*Messages*`. It compares the new text against the actual current kill-ring yank item.

Terminal Emacs outside Zellij has a separate older Wayland fallback in the init: `wl-copy` runs with `-f -n`, and `wl-paste` is read through a shell command. It uses a live `wl-copy` owner-process check and strips CR in its shell path. That terminal branch is not the same implementation as the strict 3-second graphical helper. The terminal fallback is enabled only when `WAYLAND_DISPLAY` is set, the frame is nongraphical, Zellij is absent, and **both** `wl-copy` and `wl-paste` are found on Emacs's executable path. If either executable is missing, this branch leaves the existing clipboard handlers unchanged. This capability check is shared across devices: mp-linux uses it when available; other devices skip it automatically without requiring hostname-specific rules. The graphical route needs only `wl-paste` for its custom reader because copying uses Emacs's native GUI backend. These checks run at initialization; installing the tools later requires restarting Emacs or reevaluating the relevant clipboard block.

### Vterm shortcuts and mouse-selected text

The local vterm package is loaded from `~/emacstools/emacs-libvterm/`; `C-*` opens it. Its normal mode sends many keys to the shell instead of running the ordinary Emacs command for that key.

| Action | Sequence |
|---|---|
| Paste clipboard / current yank item | `C-y` (`vterm-yank`) |
| Enter or leave copy mode | `C-c C-t` |
| Mark a region in copy mode | `C-SPC`, move point; mouse selection can also be used |
| Copy selected text and exit copy mode | `RET` |
| Copy current line if no region is active | `RET` in copy mode |
| Leave copy mode without copying | `C-c C-t` |
| Browse older output | Shift-PageUp / Shift-PageDown bindings scroll Emacs output |

Copy mode freezes display updates from terminal output and temporarily behaves more like a normal Emacs buffer. The standard reliable workflow is `C-c C-t`, select text, `RET`.

A mouse highlight is not by itself a clipboard copy in your configuration. In normal vterm mode, `M-w` is not among the default key exceptions and is forwarded as terminal input rather than reliably invoking Emacs's copy command. The installed `vterm-mouse-set-point` handler also calls `keyboard-quit`, which can deactivate a region on mouse events. If a region is still active, `M-x kill-ring-save` can copy it without copy mode. If selection is being cleared or output is moving it, use copy mode. No new direct-copy key binding or mouse-selection advice has been installed as part of the documentation task.

`C-c C-y` sends a literal terminal Ctrl+Y through vterm; plain `C-y` pastes via Emacs. Global `M-y` uses your Helm kill-ring chooser and vterm also has yank remapping, so inspect the effective binding with `C-h k` in the actual buffer when choosing older clipboard entries.

## Bookmarks

`bookmarks_config.el` configures the external `bm` package, enables cycling across buffers and uses line-plus-fringe highlighting. Graphical Emacs displays Nerd Font `nf-fa-bookmark` (U+F02E, ) as the existing 8×16 fringe bitmap; a graphical fringe cannot directly display a font glyph. GUI editing margins remain unchanged.

Terminal Emacs has no graphical fringe. It displays the **actual Nerd Font ribbon glyph** at normal weight in a fixed one-cell left column beside the editing area/line numbers. There is no extra blank padding. Terminal glyphs occupy character cells and cannot be shrunk with Emacs pixel-height settings. Each marker overlay belongs to its specific terminal window, so GUI and terminal windows can show the same buffer without changing each other's marker representation. Editing windows keep that column even when they have no bookmarks, so toggling a bookmark does not move text or line numbers. Existing left margins are reused rather than enlarged; a wider existing margin is preserved. The original margin is restored when markers are disabled or the window switches to a non-editing utility buffer. A reload can adjust the old two-cell layout once; subsequent bookmark toggles keep the layout stable. Marker updates follow bookmark addition, removal, redraw and edits without inserting any buffer text.

| Option / behavior | Current value |
|---|---|
| `my/bookmark-orange` | `DarkOrange1`, standard RGB `#FF7F00`, the original GUI orange |
| `my/bookmark-line-tint` | `0.18`: 18% orange blended into the hl-line background |
| Bookmark foreground | Unspecified in GUI/256-color/truecolor frames, preserving syntax foreground colors |
| Fringe/margin marker background | Unspecified; no separate rectangular orange background |
| `my/bookmark-terminal-markers` | `t`: show a left-side ribbon and reserve a stable column in terminal editing windows |
| `my/bookmark-terminal-column-width` | `1` cell minimum; reuse a larger existing margin, and allow enough width for a custom wider symbol |
| `my/bookmark-terminal-symbol` | `` (`nf-fa-bookmark`); change to `B` or another symbol if needed |
| `my/bookmark-terminal-low-color` | `yellow`: fallback for terminals with fewer than 256 colors; marked lines use black foreground on yellow for readability |
| `my/bookmark-terminal-marker` | Face for the terminal ribbon; orange and normal weight by default |
| Persistent bookmarks | Same configured orange/tint styling; persistence itself is not automatically enabled by this file |

The blend now resolves standard color RGB values **before** terminal palette approximation, instead of blending already rounded terminal colors. GUI, truecolor and 256-color frames request the same orange and tint; 256-color terminals approximate those RGB values, while very limited terminals use the explicit yellow fallback rather than a red-looking tint. The subtle tinted line is a **color blend**, not independent opacity. GUI alpha follows the frame background; terminal transparency belongs to the terminal application.

The terminal application's font must contain Nerd Font symbols. For a Windows-hosted WSL terminal this means installing/selecting a suitable font on Windows, as described in the font setup section. The symbol is configurable, so a plain `B` can be used where icon fonts are unavailable.

Apply to an active session using `M-:`:

```elisp
(load-file "~/emacstools/bookmarks_config.el")
```

Run `M-x my/bookmarks-refresh-appearance` after changing colors, marker options or hl-line manually. Theme enable and frame creation also refresh existing bookmark overlays. Window changes maintain the terminal markers automatically. The keys remain `F2` toggle, `C-F2` next, `S-F2` previous, and `C-S-F2` clear the current buffer's bookmarks. Helm BM is declared as a picker integration. Persistent storage and annotation commands are supplied by bm; use `C-h f` / `M-x bm-customize` for its own package options.

Validation: nine ERT checks cover display-independent tint calculation, high/low-color terminal faces, GUI fringe preservation, terminal ribbon/window ownership, unchanged buffer text and modified state, margin restoration, window-buffer switches, marker movement after edits, disabling markers, repeat loading and unchanged window body width/margins when toggling bookmarks. Isolated real `emacs -nw` sessions confirmed U+F02E in the left margin with line numbers in both truecolor and 256-color terminals; the latter emits warm-orange palette index 208 for the ribbon. A real-terminal toggle check also confirmed an unchanged one-column margin and text-area width before adding, while displaying, and after removing a bookmark.

## Breadcrumb and Markdown preview overview

The personal breadcrumb is globally enabled for its supported editing modes. Your settings hide the filename and macro-call leaves, always expand branch detail and else hints, use the editor background and remove the row border. Font family/size default to the frame's editing font independent of Org heading typography; foreground colors come from syntax faces unless explicitly overridden. The innermost section is bold by default. Top and separate bottom placement, smart compression, click navigation, xref return, Helm picking, Nerd Font icons, JSON/YAML/native Elisp/Org support and dynamic debug logging are covered in full below.

The Markdown module replaces `markdown-preview` with Livedown, updates previews after edits/saves, embeds Nerd Font symbols for export, defaults to dark appearance, provides a dark/light chooser and automatically chooses embedded xwidget WebKit in graphical Emacs when available. Otherwise it opens an external browser. It includes browser page navigation fixes and a portable Node-based HTML renderer. Source files, options, commands, ownership/cleanup and troubleshooting are reproduced in the integrated Markdown guide below.

## Package inventory

These are the **52 active `use-package` declarations** read from the main init and loaded personal configuration files. A declaration means configured/available integration, not that every package enables a global mode. Built-in/local exceptions and delayed hooks still apply.

| Package | Configuration purpose | Declaration source |
|---|---|---|
| `quelpa` | Recipe-based package installation and weekly upgrades | `.emacs` |
| `quelpa-use-package` | `:quelpa` integration; skip installed packages at ordinary startup | `.emacs` |
| `alect-themes` | Alect Black GUI/terminal theme | `.emacs` |
| `drag-stuff` | Move lines/regions with Meta+Shift keys | `.emacs` |
| `cua-base` | Built-in rectangle/selection support; register-0 tracking disabled | `.emacs` |
| `doom-modeline` | Customized status/modeline | `.emacs` |
| `recentf` | Recent-file retention settings (500 saved / 60 menu entries) | `.emacs` |
| `vundo` | Visual undo history and configured undo limits | `.emacs` |
| `undo-fu-session` | Persistent compressed undo history | `.emacs` |
| `multiple-cursors` | Multiple-cursor editing commands | `.emacs` |
| `all-the-icons` | Icon support | `.emacs` |
| `nerd-icons` | Nerd Font/Codicon symbols and file icons | `.emacs` |
| `svg-lib` | SVG icon/graphics support | `.emacs` |
| `helm` | Command/file/buffer/kill-ring completion frontend | `.emacs` |
| `helm-gtags` | GNU Global tag navigation with Helm | `.emacs` |
| `helm-xref` | Helm xref chooser | `.emacs` |
| `helm-rg` | Ripgrep interface | `.emacs` |
| `helm-ls-git` | Git-aware file/buffer picker integration | `.emacs` |
| `helm-descbinds` | Helm key-binding descriptions | `.emacs` |
| `helm-company` | Company candidate chooser integration | `.emacs` |
| `helm-flycheck` | Flycheck integration; declaration does not itself enable Flycheck | `.emacs` |
| `helm-fuzzy` | Fuzzy matching support | `.emacs` |
| `helm-lsp` | LSP frontend integration; Eglot is the active configured LSP client | `.emacs` |
| `helm-ispell` | Spelling integration | `.emacs` |
| `helm-bm` | Bookmark picker integration | `.emacs` |
| `deadgrep` | Ripgrep content/project search (`M-s`) | `.emacs` |
| `company` | Global completion after init | `.emacs` |
| `ws-butler` | Local whitespace-on-save package | `.emacs` |
| `dtrt-indent` | Global existing-indentation detection | `.emacs` |
| `clean-aindent-mode` | Programming-mode indentation cleanup | `.emacs` |
| `yaml-mode` | Classic YAML editing via a configured GitHub recipe | `.emacs` |
| `vterm` | Local native terminal emulator | `.emacs` |
| `rust-mode` | Rust editing | `.emacs` |
| `ov` | Overlay utility dependency for log tools | `.emacs` |
| `hide-lines` | Line hiding/filtering dependency for log tools | `.emacs` |
| `syslog-mode` | Customized log highlighting and display | `.emacs` |
| `magit` | Git interface, log formatting and unlimited log color age | `.emacs` |
| `magit-gitflow` | Git-flow integration | `.emacs` |
| `ellama` | Ollama-facing integration, transient menu, auto-scroll and context header | `.emacs` |
| `dockerfile-mode` | Deferred Dockerfile editing | `.emacs` |
| `lua-mode` | Deferred Lua editing and filename associations | `.emacs` |
| `cmake-ts-mode` | Built-in Tree-sitter CMake mode | `.emacs` |
| `eglot-booster` | Accelerated Eglot integration | `.emacs` |
| `eglot` | Built-in asynchronous language-server client | `.emacs` |
| `bm` | Local bookmark overlay library | `emacstools/bookmarks_config.el` |
| `json-mode` | JSON-family file associations and formatter keys | `emacstools/json_config.el` |
| `elpy` | Python development package declaration; no explicit elpy-enable function call | `emacstools/python_config.el` |
| `pyvenv` | Python virtual-environment support | `emacstools/python_config.el` |
| `indent-bars` | Indent guides in configured classic Python/YAML hooks | `emacstools/python_config.el` |
| `ggtags` | GNU Global minor-mode integration | `emacstools/c_mode_config.el` |
| `ascii-table` | Local decimal/octal/hexadecimal ASCII reference | `emacstools/c_mode_config.el` |
| `org-superstar` | Org bullets and Org Tempo loading | `emacstools/org_config.el` |

Magit log configuration requests `--graph --decorate --color` and disables the color-age limit. Ellama is configured with auto-scroll, `C-c e`, an Org Ctrl+C/Ctrl+C hook and a global context header-line mode. The latter shares header-line space with the breadcrumb; the presence of both settings does not imply that their formats can never interact. No API credentials or commented credential examples are reproduced here.

Packages selected in Customize but without an active declaration/call in the reviewed startup chain include historical entries such as `breadcrumb` and `undo-tree`. The personal `my-context-breadcrumb` is a separate implementation; a package selection list is not an activation list.

## Personal command and option registry

This registry comes from reading local Lisp forms without loading the complete init. It lists interactive personal/library commands and modes, including functions without dedicated key bindings. Internal implementation helpers are omitted; complete breadcrumb and Markdown command documentation also appears in their integrated guides. Duplicate definitions are collapsed to the last definition within each source file. Mode hooks and conditional loading can determine availability in a live session.

### Commands and modes by module

#### `.emacs`

| Command or mode | Purpose |
|---|---|
| `my/line-number-match-editor-background` | Match line-number backgrounds to each frame's editing background. |
| `my/minibuffer-match-editor-background` | Match minibuffer and echo-area backgrounds to the editor. |
| `my-prev-window` | Select the previous window. |
| `goto-line-and-column` | Allow a specification of |
| `my-buffer-kill` | Quit view mode or kill the current buffer; includes legacy undo-tree handling. |
| `dos2unix` | Convert this entire buffer from MS-DOS text file format to UNIX. |
| `flyspell-english` | Enable Flyspell, choose the American dictionary and check the buffer. |
| `rename-file-and-buffer` | Renames both current buffer and file it's visiting to NEW-NAME. |
| `copy-buffer-name` | Read buffer file name and copy it to clipboard. |
| `my/helm-find-files-recursive` | Recursively search filenames using ripgrep and Helm. |

#### `emacstools/my-emacs-sessions.el`

| Command or mode | Purpose |
|---|---|
| `my/cleanup-sessions` | Remove old sessions according to `my/session-max-count'. |
| `my/save-current-session` | Save the current session only if files are open. |
| `my/restore-session` | Restore a snapshot of the Emacs desktop stored in DIR. |
| `my/restore-last-session` | Restore the most recently saved Emacs session. |
| `my/helm-sessions` | Select a saved Emacs session using Helm. |
| `my-emacs-sessions-mode` | Global mode for manually restorable Emacs sessions. |

#### `emacstools/my-context-breadcrumb.el`

| Command or mode | Purpose |
|---|---|
| `my/context-breadcrumb-debug-toggle` | Toggle breadcrumb tracing on/off at runtime, without restarting Emacs. |
| `my/context-breadcrumb-debug-show` | Show the syntax-context and formatting decision log. |
| `my/context-breadcrumb-debug-clear` | Clear queued and recorded breadcrumb diagnostics. |
| `my/context-breadcrumb-choose` | Choose any section of the full, unshortened breadcrumb path. |
| `my/context-breadcrumb-helm` | Navigate the full current breadcrumb path using Helm. |
| `my/context-breadcrumb-parent` | Jump to the nearest enclosing section header before point. |
| `my/context-breadcrumb-function` | Jump to the enclosing function or method. |
| `my/context-breadcrumb-class` | Jump to the enclosing class or struct. |
| `my/context-breadcrumb-statement` | Jump to the innermost control-flow or statement header. |
| `my/context-breadcrumb-refresh` | Apply changed breadcrumb preferences in all enabled buffers. |
| `my/context-breadcrumb-diagnose-appearance` | Show the current source window's actual frame and breadcrumb settings. |
| `my/context-breadcrumb-toggle-position` | Switch all breadcrumb bars between the top and bottom. |
| `my/context-breadcrumb-mode` | Enable or disable the breadcrumb in the current supported buffer. |
| `my/context-breadcrumb-global-mode` | Enable the personal breadcrumb automatically in supported modes. |

#### `emacstools/my-markdown-preview.el`

| Command or mode | Purpose |
|---|---|
| `my/markdown-preview-stop` | Stop the owned Livedown process and remove its disposable Markdown copy. |
| `my/markdown-livedown-preview` | Preview the current Markdown buffer using Livedown, with embedded icons. |

#### `emacstools/my-eglot-retry-limit.el`

| Command or mode | Purpose |
|---|---|
| `my/eglot-reset-retries` | Clear stopped Eglot start budgets.  Use M-x eglot to try connecting again. |
| `my/eglot-close-exited-event-buffers` | Close finished Eglot events buffers containing the JSONRPC exit marker. |

#### `emacstools/my-editing-line-numbers.el`

| Command or mode | Purpose |
|---|---|
| `my/editing-line-numbers-mode` | Global editing-buffer line-number policy. |
| `my/editing-line-numbers-refresh` | Reapply the active policy to existing buffers. |

#### `emacstools/bookmarks_config.el`

| Command or mode | Purpose |
|---|---|
| `my/bookmarks-refresh-appearance` | Apply bookmark colors and ribbon markers, including existing bookmarks. |

#### `emacstools/json_config.el`

| Command or mode | Purpose |
|---|---|
| `json-compact` | Compact prettified JSON into a single line. |
| `json-pretty` | Pretty-print JSON using Python. |
| `json-super-pretty` | Format JSON using custom prettyPrintJson.py script. |

#### `emacstools/c_mode_config.el`

| Command or mode | Purpose |
|---|---|
| `insert-current-date-time` | Insert the current date/time at point. |

#### `emacstools/xah_extension.el`

| Command or mode | Purpose |
|---|---|
| `xah-insert-paren` | Insert or wrap with paren. |
| `xah-insert-square-bracket` | Insert or wrap with square bracket. |
| `xah-insert-brace` | Insert or wrap with brace. |
| `xah-insert-markdown-quote` | Insert or wrap with markdown quote. |
| `xah-insert-markdown-triple-quote` | Insert or wrap with markdown triple quote. |
| `xah-insert-double-curly-quote` | Insert or wrap with double curly quote. |
| `xah-insert-curly-single-quote` | Insert or wrap with curly single quote. |
| `xah-insert-single-angle-quote` | Insert or wrap with single angle quote. |
| `xah-insert-double-angle-quote` | Insert or wrap with double angle quote. |
| `xah-insert-ascii-double-quote` | Insert or wrap with ascii double quote. |
| `xah-insert-ascii-single-quote` | Insert or wrap with ascii single quote. |
| `xah-insert-emacs-quote` | Insert or wrap with emacs quote. |
| `xah-insert-corner-bracket` | Insert or wrap with corner bracket. |
| `xah-insert-white-corner-bracket` | Insert or wrap with white corner bracket. |
| `xah-insert-angle-bracket` | Insert or wrap with angle bracket. |
| `xah-insert-double-angle-bracket` | Insert or wrap with double angle bracket. |
| `xah-insert-white-lenticular-bracket` | Insert or wrap with white lenticular bracket. |
| `xah-insert-black-lenticular-bracket` | Insert or wrap with black lenticular bracket. |
| `xah-insert-tortoise-shell-bracket` | Insert or wrap with tortoise shell bracket. |
| `xah-delete-backward-char-or-bracket-text` | Delete one character or a bracketed/quoted expression; prefix changes bracket-only behavior. |
| `xah-delete-backward-bracket-text` | Delete the matching brackets/quotes to the left of cursor, including the inner text. |
| `xah-delete-backward-bracket-pair` | Delete the matching brackets/quotes to the left of cursor. |
| `xah-delete-forward-bracket-pairs` | Delete the matching brackets/quotes to the right of cursor. |
| `xah-goto-matching-bracket` | Jump to the matching bracket or ascend the surrounding expression. |

#### `emacstools/c_cpp_templates.el`

| Command or mode | Purpose |
|---|---|
| `template-insert-time` | Insert time into current buffer using time format FORMAT. |

#### `emacstools/ascii-table.el`

| Command or mode | Purpose |
|---|---|
| `ascii-table` | Print the ascii table (up to char 127). |
| `ascii-table-octal` | Print the ascii table up to LIMIT (default is 0177). |
| `ascii-table-hex` | Print the ascii table up to LIMIT (default is 0x7f). |

#### `emacstools/my-pair-editing.el`

| Command | Purpose |
|---|---|
| `my/delete-pair-backward` | Remove the matching pair with its closer at or just before point, including shell `${...}` inside strings; preserve enclosed text |

#### `emacstools/my-buffer-reload.el`

| Command | Purpose |
|---|---|
| `my/reload-buffer` | Reload the visited file from disk, preserving logical cursor/scroll positions and asking before discarding edits; Ctrl+F5 |

#### `emacstools/my-deadgrep-recursion.el`

| Command | Purpose |
|---|---|
| `my/deadgrep-toggle-recursive` | Toggle recursion and rerun this Deadgrep search; uppercase R |
| `my/deadgrep-hide-result` | Hide the result, whole file group or error at point; z. |
| `my/deadgrep-unhide-result` | Restore the last manually hidden item; u. |
| `my/deadgrep-unhide-all-results` | Restore all manually hidden items in this results buffer; U. |
| `my/deadgrep-diagnose` | Report the search root, recursion state and actual launched command. |

#### `emacstools/my-device-font.el`

| Command | Purpose |
|---|---|
| `my/apply-device-font` | Apply the hostname-selected editing font to current and future graphical frames. |

#### `emacstools/my-startup-performance.el`

| Command | Purpose |
|---|---|
| `my/startup-report` | Show initialization, ready/terminal timing, startup GC count and restored threshold. |
| `my/startup-profile-report` | Show the optional wall-time profile; collect it with `EMACS_STARTUP_PROFILE=1`. |

#### `emacstools/my-helm-files.el`

| Command | Purpose |
|---|---|
| `my/helm-files-origin-directory` | Return the active file chooser to its source buffer's directory; C-c C-b. |

### Personal options index

Defaults are source expressions, not evaluated live values. The main init may override them; the current session-retention override matches its default (10).

| Option | Source default | Meaning |
|---|---|---|
| `my/geometry-debug-file` | `(expand-file-name "frame-geometry-debug.log" user-emacs-directory)` | File used to log frame geometry information. |
| `my/geometry-file` | `(expand-file-name "frame-geometry.el" user-emacs-directory)` | File containing saved frame dimensions. |
| `my/geometry-default` | `'(:width 1511 :height 931)` | Default frame dimensions in pixels. |
| `my/session-root` | `(expand-file-name "sessions/" user-emacs-directory)` | Directory containing saved Emacs sessions. |
| `my/session-max-count` | `10` | Maximum number of saved sessions. |
| `my/session-save-on-exit` | `t` | Whether to save the current session on exit. |
| `my/editing-line-numbers-excluded-modes` | `'(special-mode dired-mode helm-major-mode comint-mode term-mode vterm-mode eshell-mode image-mode doc-view-mode pdf-view-mode)` | Modes and their descendants that should not display line numbers. |
| `my/bookmark-orange` | `"DarkOrange1"` | Original bookmark orange, used for the ribbon and line tint. |
| `my/bookmark-line-tint` | `0.18` | Orange fraction blended into the hl-line background (0 to 1). |
| `my/device-font-family` | `"JetBrains Mono"` | Graphical editing font family. |
| `my/device-font-sizes` | `(("N900D9658" . 9) ("mp-linux" . 11))` | Case-insensitive short hostname → point-size mapping. |
| `my/device-font-default-size` | `11` | Font size on unmatched devices. |
| `my/helm-files-wide-window` | `t` | Full-width bottom file chooser while preserving editor splits. |
| `my/helm-files-window-height` | `0.35` | Desired chooser height as a fraction of frame height. |
| `my/helm-files-edit-in-minibuffer` | `t` | Visible, wrapping path input for Helm file browsing. |
| `my/startup-terminal-query-timeout` | `0.2` | Synchronous terminal capability-query wait cap; nil uses Emacs's default. |
| `my/startup-wsl-native-executable-lookups` | `t` | WSL-only startup optimization for native tool probes. |
| `my/startup-wsl-windows-directory-regexp` | Windows-drive directory pattern; see startup guide/source | Identifies Windows-mounted executable directories to skip for native startup probes. |
| `my/startup-wsl-keep-exec-directories` | `nil` | Exceptions containing native Linux tools that should be probed at startup. |
| `my/deadgrep-friendly-error-summary` | `t` | Explain ripgrep code 2 while preserving error details and matches. |

Additional tunable `defvar` values include `my/eglot-max-start-attempts` (10), `my/eglot-stable-seconds` (60), `my/wayland-clipboard-timeout` (3 seconds) and `current-date-time-format` (`%a %b %H:%M:%S %Y`). `my/session-save-on-exit` is enabled in the main init. The complete 20-option breadcrumb and 5-option Markdown customization tables are preserved in their respective detailed guides below.

### Complete configured Tempo tags

Type the tag and use `M-RET` in a configured C/C++ buffer. C and C++ tag lists are distinct; generated function names follow `tempo-template-NAME`. Some legacy tags include trailing spaces, shown explicitly as `␠` below.

| Tag | C | C++ | Description |
|---|---|---|---|
| `ifdef` | yes | yes | insert a #ifdef #else #endif statement |
| `ifndef` | yes | yes | insert a #ifndef #define #endif statement |
| `if` | yes | yes | insert if statement |
| `else` | yes | yes | insert else statement |
| `ifelse` | yes | yes | insert if else statement |
| `elseif␠` | yes | yes | insert else if statement |
| `while` | yes | yes | insert while statement |
| `for` | yes | yes | insert for statement |
| `fori` | yes | yes | insert loop statement: for(int x = 0;x < ..;++x) |
| `switch` | yes | yes | insert switch statement |
| `case` | yes | yes | insert case statement |
| `class` | — | yes | insert a class statement |
| `namespace` | — | yes | insert a namespace statement |
| `stv` | — | yes | insert a std::vector |
| `try` | — | yes | insert a try catch |
| `throw` | — | yes | insert a throw exception |
| `fheader` | yes | yes | insert a File header |
| `hheader` | yes | yes | insert a header File header |
| `pheader` | yes | yes | insert a Function header |
| `hfile` | yes | yes | insert header file template with preprocessor locks |
| `include` | yes | yes | insert #include <buffer name> |

## Configuration declaration reference

The following source-level reference preserves active top-level settings, hooks and advice in the main init and smaller configuration modules. It is intended for exact variable names and values that complement the prose. It is **not** a transcript of runtime values: expressions under conditional forms still depend on their conditions, quoted lambdas run later, and later module loads can override earlier assignments. Commented code is excluded. Settings inside named functions or callback lambdas are documented in the feature explanations rather than listed as unconditional startup settings.

The large breadcrumb/Markdown internals and local vendor-library internals are not duplicated here; their public options/commands are documented above and in their complete guides. Source expressions are copied as data, not evaluated for this document.

### Declarations in `.emacs`

```elisp
(setq-default create-lockfiles nil)
(setq undo-outer-limit 128000000)
(setq treesit-max-buffer-size (* 100 1024 1024))
(setq select-active-regions nil)
(setq select-enable-clipboard 't)
(setq select-enable-primary nil)
(setq interprogram-cut-function #'gui-select-text)
(setq use-short-answers t)
(setq ring-bell-function #'ignore)
(setq inhibit-startup-message t inhibit-startup-echo-area-message t inhibit-startup-screen t inhibit-startup-buffer-menu t initial-scratch-message nil)
(add-to-list 'default-frame-alist '(alpha-background . 87))
(setq frame-icon-title-format "Emacs" frame-title-format '("%S " (:eval (system-name)) " @ " (:eval (or (buffer-file-name) (and (boundp 'dired-directory) dired-directory) "%b"))))
(setq display-time-day-and-date t display-time-24hr-format t)
(load-file "~/emacstools/my-device-font.el")
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/") ("melpa-stable" . "https://stable.melpa.org/packages/") ("melpa" . "https://melpa.org/packages/")))
(setq use-package-always-ensure t)
(setq use-package-always-ensure t quelpa-upgrade-interval 7)
(add-hook 'emacs-startup-hook #'my/schedule-quelpa-weekly-upgrade)
(setq quelpa-use-package-inhibit-loading-quelpa t)
(setq alect-display-class '((class color) (min-colors 256)))
(add-hook 'after-init-hook (lambda nil (set-face-attribute 'font-lock-string-face nil :foreground "#FF5252")))
(add-hook 'enable-theme-functions #'my/line-number-match-editor-background)
(add-hook 'after-make-frame-functions #'my/line-number-match-editor-background)
(add-hook 'minibuffer-setup-hook #'my/minibuffer-match-editor-background)
(add-hook 'enable-theme-functions #'my/minibuffer-match-editor-background)
(add-hook 'after-make-frame-functions #'my/minibuffer-match-editor-background)
(add-hook 'after-init-hook #'my/minibuffer-match-editor-background)
(add-hook 'prog-mode-hook #'my/prog-setup)
(add-hook 'text-mode-hook #'my/prog-setup)
(add-hook 'conf-mode-hook #'my/prog-setup)
(setq drag-stuff-modifier '(meta shift))
(setq cua-delete-copy-to-register-0 nil)
(setq delete-selection-save-to-register nil)
(setq custom-file "~/.emacs.d/custom.el")
(setq projectile-ignored-directories '("/media/*" "/mnt/*"))
(setq projectile-globally-ignored-directories '("/media/*" "/mnt/*"))
(setq-default ediff-highlight-all-diffs nil)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)
(setq ediff-split-window-function 'split-window-horizontally)
(setq recentf-max-saved-items 500)
(setq recentf-max-menu-items 60)
(setq undo-limit 80000000)
(setq undo-strong-limit 120000000)
(setq undo-outer-limit 360000000)
(setq vundo-glyph-alist vundo-unicode-symbols)
(setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
(setq undo-fu-session-directory (expand-file-name "undo-fu-session/" user-emacs-directory))
(setq undo-fu-session-compression 'zst)
(setq helm-M-x-fuzzy-match t helm-bookmark-show-location t helm-buffers-fuzzy-matching t helm-completion-in-region-fuzzy-match t helm-file-cache-fuzzy-match t helm-imenu-fuzzy-match t helm-mode-fuzzy-match t helm-locate-fuzzy-match t helm-quick-update t helm-recentf-fuzzy-match t helm-gtags-fuzzy-match t helm-semantic-fuzzy-match t helm-split-window-inside-p t helm-move-to-line-cycle-in-source t helm-ff-search-library-in-sexp t helm-scroll-amount 8 helm-ff-file-name-history-use-recentf t helm-echo-input-in-header-line t helm-buffer-max-length 40)
(add-hook 'helm-minibuffer-set-up-hook 'spacemacs//helm-hide-minibuffer-maybe)
(setq helm-google-suggest-use-curl-p t)
(setq helmg-gtags-ignore-case t helm-gtags-use-input-at-cursor t helm-gtags-pulse-at-cursor t helm-gtags-suggested-key-mapping t helm-gtags-direct-helm-completing t)
(add-hook hook #'helm-gtags-mode)
(add-to-list 'load-path (expand-file-name "~/emacstools" user-emacs-directory))
(setq my/session-max-count 10)
(setq my/session-save-on-exit t)
(setq company-backends '(company-capf))
(add-to-list 'load-path "~/emacstools/ws-butler")
(setq my/context-breadcrumb-show-file nil my/context-breadcrumb-else-hints 'always)
(setq my/context-breadcrumb-show-macro-calls nil my/context-breadcrumb-detail 'always)
(setq my/context-breadcrumb-background 'editor my/context-breadcrumb-border nil)
(setq ff-search-directories '("." "../../" "../" "../inc" "./inc" "../include" "../src" "./src"))
(setq-default truncate-lines nil)
(setq-default truncate-partial-width-windows nil)
(setq kill-ring-max 500)
(setq query-replace-highlight t)
(setq search-highlight t)
(setq vc-make-backup-files t)
(setq backup-directory-alist `(("." . "~/.emacs.d/backups/")))
(setq version-control t kept-new-versions 10 kept-old-versions 2 delete-old-versions t backup-by-copying t)
(add-hook 'before-save-hook #'my/force-backup-on-save)
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-saves/" t)))
(setq auto-save-interval 2000)
(setq font-lock-maximum-decoration t)
(add-hook 'find-file-hook #'font-lock-ensure)
(setq dtrt-indent-verbosity 0)
(setq clean-aindent-is-simple-indent t)
(setq yaml-font-lock-keywords (assq-delete-all 'my/yaml-font-lock-block-literals (assq-delete-all 'yaml-font-lock-block-literals yaml-font-lock-keywords)))
(add-to-list 'load-path "~/emacstools/emacs-libvterm")
(add-to-list 'auto-mode-alist '("\\.log\\'" . syslog-mode))
(add-to-list 'auto-mode-alist '("\\.clog\\'" . syslog-mode))
(add-hook 'syslog-mode-hook #'syslog-disable-multiline-strings)
(add-hook 'syslog-mode-hook 'my-syslog-font-lock-setup)
(setq syslog-highlight-keywords t)
(setq syslog-highlight-prompt t)
(setq font-lock-maximum-decoration t)
(setq font-lock-support-mode 'jit-lock-mode)
(setq magit-log-color-graph-limit nil)
(setq magit-log-arguments '("--graph" "--decorate" "--color"))
(setopt ellama-auto-scroll t)
(setq treesit-language-source-alist '((c "https://github.com/tree-sitter/tree-sitter-c" "v0.23.6") (cpp "https://github.com/tree-sitter/tree-sitter-cpp" "v0.23.4") (python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.6") (bash "https://github.com/tree-sitter/tree-sitter-bash" "v0.23.3") (cmake "https://github.com/uyha/tree-sitter-cmake" "v0.7.4") (json "https://github.com/tree-sitter/tree-sitter-json" "v0.24.8") (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.3")))
(setq treesit-font-lock-level 4)
(add-hook 'c++-ts-mode-hook (lambda nil (font-lock-flush) (font-lock-ensure)))
(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-mode))
(add-to-list 'interpreter-mode-alist '("\\.lua\\'" . lua-mode))
(add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)CMakeLists\\.txt\\'" . cmake-ts-mode))
(setq interprogram-cut-function #'gui-select-text interprogram-paste-function #'gui-selection-value)
(setq interprogram-paste-function #'my/wayland-clipboard-paste)
(setq wl-copy-process nil)
(setq interprogram-cut-function 'wl-copy)
(setq interprogram-paste-function 'wl-paste)
(setq-default tab-width 4)
(setq-default standard-indent 4)
(setq eglot-sync-connect nil)
(setq eglot-extend-to-xref t)
(add-to-list 'eglot-server-programs '((c-mode c++-mode c-ts-mode c++-ts-mode) "clangd-20" "-j=16" "--background-index" "--clang-tidy=false" "--header-insertion=never"))
(add-to-list 'eglot-server-programs `((python-mode python-ts-mode) "npx" "pyright-langserver" "--stdio"))
(add-to-list 'eglot-server-programs '((sh-mode bash-ts-mode) "npx" "bash-language-server" "start"))
(setq eglot-autoshutdown t)
(setq eglot-events-buffer-config (list :size 0 :format 'full))
```

### Declarations in `.emacs.d/early-init.el`

```elisp
(add-to-list 'load-path "~/emacstools")
(setq initial-frame-alist '((left . 26) (top . 23) (width . 180) (height . 53)))
```

### Declarations in `emacstools/my-emacs-sessions.el`

```elisp
(setq desktop-restore-frames nil)
(add-hook 'kill-emacs-hook #'my/session-exit-hook)
```

### Declarations in `emacstools/my-eglot-retry-limit.el`

```elisp
(advice-add 'eglot--connect :around #'my/eglot-limit-starts)
(advice-add 'eglot--on-shutdown :before #'my/eglot-stop-retry-loop)
(advice-add 'jsonrpc--process-sentinel :after #'my/eglot-clean-events-after-exit)
(add-hook 'eglot-connect-hook #'my/eglot-reset-after-stable-connection)
(add-hook 'eglot-server-initialized-hook #'my/eglot-track-starting-server)
```

### Declarations in `emacstools/my-yaml-ts-font-lock.el`

```elisp
(add-hook 'yaml-ts-mode-hook #'my/yaml-ts-font-lock-setup)
```

### Declarations in `emacstools/my-buffer-navigation.el`

```elisp
(setq switch-to-prev-buffer-skip #'my/buffer-navigation-skip-p)
```

### Declarations in `emacstools/bookmarks_config.el`

```elisp
(setq bm-cycle-all-buffers t)
(setq bm-highlight-style 'bm-highlight-line-and-fringe)
(add-hook 'enable-theme-functions #'my/bookmarks-refresh-appearance)
(add-hook 'after-make-frame-functions #'my/bookmarks-refresh-appearance)
```

### Declarations in `emacstools/python_config.el`

```elisp
(setq elpy-enable t)
(setq python-shell-interpreter "python3" python-shell-interpreter-args "-i")
(setq elpy-rpc-python-command "python3")
(setq elpy-rpc-virtualenv-path `current)
(add-hook 'python-mode-hook (lambda nil (setq indent-tabs-mode nil) (setq tab-width 4) (setq python-indent-offset 4) (company-mode) (my/context-breadcrumb-mode 1) (define-key python-mode-map (kbd "C-c <left>") 'python-indent-shift-left) (define-key python-mode-map (kbd "C-c <right>") 'python-indent-shift-right)))
(add-hook 'python-hook (lambda nil (setq company-backends '(company-eglot))))
```

### Declarations in `emacstools/c_mode_config.el`

```elisp
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)
(add-hook 'c++-mode-common-hook 'my-c-mode-common-hook)
(setq auto-mode-alist (append '(("\\.cc$" . c++-mode) ("\\.hh$" . c++-mode) ("\\.hpp$" . c++-mode) ("\\.ipp$" . c++-mode) ("\\.tcc$" . c++-mode) ("\\.c$" . c-mode) ("\\.C$" . c-mode) ("\\.h$" . c-mode) ("\\.H$" . c-mode)) auto-mode-alist))
(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c++-hook (lambda nil (setq company-backends '(company-eglot))))
(add-hook 'c-mode-hook 'company-mode)
(add-hook 'c-hook (lambda nil (setq company-backends '(company-eglot))))
(add-hook 'c-mode-common-hook #'my-c-mode-common-hook)
(add-hook 'c++-mode-common-hook #'my-c-mode-common-hook)
(add-to-list 'auto-mode-alist '("\\.cc\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hh\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.ipp\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.tcc\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.c\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.C\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.H\\'" . c++-mode))
(add-hook 'c-mode-hook #'my/c-like-keys)
(add-hook 'c++-mode-hook #'my/c-like-keys)
(add-hook 'c-ts-mode-hook #'my/c-like-keys)
(add-hook 'c++-ts-mode-hook #'my/c-like-keys)
(setq treesit-simple-indent-debug t)
(add-hook 'c-ts-mode-hook #'my-c-ts-bsd-style)
(add-hook 'c++-ts-mode-hook #'my-c-ts-bsd-style)
(setq major-mode-remap-alist '((c-mode . c-ts-mode) (c++-mode . c++-ts-mode) (c-or-c++-mode . c-or-c++-ts-mode)))
```

### Declarations in `emacstools/org_config.el`

```elisp
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-hook 'org-mode-hook 'org-indent-mode)
(setq org-agenda-files '("~/Documents/org"))
(setq org-log-done 'time)
(setq org-return-follows-link t)
(setq org-log-done t)
(setq org-superstar-headline-bullets-list '("â" "â" "â¸" "â¿"))
(setq org-hide-emphasis-markers t)
(setq org-pretty-entities t)
(setq org-startup-with-inline-images t org-image-actual-width '(600))
(setq org-src-fontify-natively t)
(setq org-src-tab-acts-natively t)
(setq org-src-window-setup 'current-window)
(setq org-edit-src-content-indentation 2)
```

## Detailed breadcrumb guide

Integrated from [my-context-breadcrumb.md](docs/my-context-breadcrumb.md), reviewed with the current implementation. The standalone guide remains available for focused use. Historical validation counts below describe those feature checks, not a new full startup or graphical test run performed for this documentation task.

Documentation reviewed against `~/emacstools/my-context-breadcrumb.el` on 2026-11-13, including native Org and Emacs Lisp support, split-window compression, measured bottom-footer sizing and YAML activation fixes.

### Files and startup

| Path | Purpose |
|---|---|
| `~/emacstools/my-context-breadcrumb.el` | Implementation, options, commands, faces, keymap |
| `~/emacstools/my-context-breadcrumb-tests.el` | ERT regression suite |
| `~/.emacs` | Personal settings, loading and global activation |
| `~/emacstools/c_mode_config.el` | Local activation in C/C++ configuration |
| `~/emacstools/python_config.el` | Local activation in Python configuration |
| `~/Documents/codex/emacs/my-context-breadcrumb.md` | This reference |

This local feature provides `my-context-breadcrumb`. It is separate from the package named `breadcrumb`. The old line that disables that package's `breadcrumb-mode` is currently commented out in your init; it is not an active startup action.

The current personal setup in `.emacs` is:

```elisp
;;(when (bound-and-true-p breadcrumb-mode) (breadcrumb-mode -1))
(setq my/context-breadcrumb-show-file nil
      my/context-breadcrumb-else-hints 'always)
(setq my/context-breadcrumb-show-macro-calls nil
      my/context-breadcrumb-detail 'always)
(setq my/context-breadcrumb-background 'editor
      my/context-breadcrumb-border nil)
(load-file "~/emacstools/my-context-breadcrumb.el")
(my/context-breadcrumb-global-mode 1)
```

Other settings retain their module defaults unless separately customized. Initial placement is at the top. Runtime changes do not automatically persist to `.emacs`.

### Purpose and displayed context

The bar follows the cursor's enclosing syntax, outermost first: optional file, namespace, class, function, control-flow branches and an optional innermost leaf statement. Sections use `›` separators; the innermost is bold. Each window uses its own cursor position and visible area, including split windows showing the same buffer.

Examples, omitting most icons:

```text
LEO::Eeprom_tool › explode_parameter_set › for (auto const & parameter : parameters.m_leo_parameters) › if(!is_o_parameter_name(key)) › else  if(is_valid_legacy_parameter_value(value))
main › catch(std::exception const & e) › if(!in_initrd)
main › try › else if(command_line_config->command == LEe::Command::Verify)
```

The path represents the active branch:

- Inside `catch`, the corresponding `try` body is omitted. Python `except` and `finally` similarly supersede their associated `try` section.
- Direct C/C++ `else if` chains produce one active `else if(condition)` section, without previous alternatives or structural `else` wrappers.
- A genuine nested `if` inside `else { ... }` remains separate.
- C++ range-based `for` loops are included between functions and inner branches.
- Namespaces use the class icon and their name, without the word `namespace`. Anonymous namespaces show `(anonymous)`.
- Only the innermost recognized leaf statement is appended; siblings are not listed.

Recognized categories include classes/structs/enums, namespaces/modules, functions/methods/constructors, if/elif/else, exception handlers, switch/match/cases, loops, try, with and synchronized blocks. Selected leaf nodes include returns, raises, throws, breaks, continues, expression statements, assignments and certain declarations. Actual coverage depends on grammar node names. Generic C++ `declaration` nodes are not currently leaf sections.

### Org context

`org-mode` and modes derived from it are supported using Org's own element parser. No Tree-sitter grammar or Eglot server is needed. Global breadcrumb mode explicitly includes Org buffers, even though they derive from text-mode.

For this document:

```org
* Project
** Implementation
*** Details
Text under Details.
```

The path is `Project › Implementation › Details`. Headings use the title from Org's parsed raw value: TODO keywords, priorities and tags are excluded, while title markup such as links or statistics cookies may remain. Skipped heading levels still produce the correct ancestor path. Before the first heading, the path is empty unless the file section is enabled.

Inside a source block, an optional final section shows its language and name:

```text
Project › Implementation › src emacs-lisp: snippet
```

Source-block sections require `my/context-breadcrumb-show-statements` to be non-nil. Clicking one jumps to its `#+begin_src` line, after any affiliated `#+name` metadata. Embedded source code does not add language-specific inner forms while editing in the main Org buffer. Other block types, tables, drawers and individual prose paragraphs do not currently add sections.

Heading entries use `nf-cod-list_tree` (, U+EB86) with the color of `org-level-1`; its heading font size, weight and style are ignored. The same fixed breadcrumb typography is used throughout the hierarchy. Source-block entries use `nf-cod-file_code` (, U+EAE9) with `font-lock-keyword-face`. Narrow-window compression, tooltips, Helm and the file-display option work as in the other backends.

Use clicks, `C-c . j`, `C-c . h`, numbered shortcuts or `C-c . u` to navigate the current heading path. `C-c . s` targets the current source block when present. Function/class shortcuts do not target Org headings. Jumps call Org's folding-context reveal function so folded destinations become visible; xref return remains available with `C-c . b`. The picker shows the current ancestry, not every heading in the document.

Narrowing is respected: ancestors starting before the accessible region are omitted. Org's element cache supplies the ancestry without reparsing the entire document through a new grammar. Debug logging identifies this backend as `parser=native-org` and lists selected sections.

### Emacs Lisp context

Support covers `emacs-lisp-mode`, `lisp-interaction-mode` and modes derived from them. This includes `.el` files, the extensionless `.emacs` init file and Lisp interaction buffers such as `*scratch*`. Global mode activates it automatically. No Elisp grammar is installed or created, and the current major mode is preserved.

Example:

```elisp
(defun my/demo (input)
  (let ((value input))
    (when (stringp value)
      (message "value=%s" value))))
```

With the cursor on the `message` call and leaf statements disabled, the path is:

```text
my/demo › (let ((value input))) › (when (stringp value))
```

When leaf statements are enabled, the innermost call can be appended as `(message "value=%s" value)`. The shared detail/compression options still apply to branch labels, so visible source headers may use short labels under the offscreen policy.

Recognized context includes:

| Lisp constructs | Breadcrumb representation |
|---|---|
| `defun`, `cl-defun`, `defsubst`, inline functions, methods/generics and mode-defining forms | Defined name with function icon |
| `defmacro`, `cl-defmacro` | Defined name with function icon; definitions stay visible when macro-call filtering is off |
| `lambda`, including function-quoted lambdas | `lambda` with function icon |
| Local definitions inside `cl-flet`, `cl-labels`, `cl-macrolet` | Local function/macro name with function icon |
| `cl-defstruct`, `defclass`, `cl-defclass` | Class/structure name with class icon |
| `defgroup` | Group name using the namespace presentation |
| `defvar`, `defvar-local`, `defconst`, `defcustom` | Defined variable using the property/key presentation |
| `let`, `let*`, binding conditionals, loops, `when`, `unless`, `if`, `and`, `or` | Parenthesized control header including the associated expression/bindings |
| `with-*`, `save-*` forms | Parenthesized scope header |
| `cond`, `pcase`, case/typecase forms | Enclosing conditional plus active clause/pattern |
| `condition-case` and handlers, `catch`, `unwind-protect`, grouping forms | Recognized enclosing control context |
| Other recognized symbolic-headed calls | One innermost optional leaf statement |

The else part of `(if TEST THEN ELSE...)` is shown as `else`, rather than falsely showing the true branch. The existing else-hint policy can append the associated `(if TEST)` explanation, with the hierarchy-sub icon. `cond`'s `t` clause is displayed as `else` without inventing a single-condition hint.

Argument lists and let binding lists are not treated as function calls. Definitions inside wrappers such as `use-package` do not acquire a misleading outer-call leaf after the definition name. Quoted/backquoted data and vector literals do not produce fake definitions or nested control scopes. Explicit `(function (lambda ...))` and `#'(lambda ...)` are treated as executable lambda context. Backquote/unquote expansion is not interpreted; quoted-data detection deliberately suppresses that subtree.

Implementation uses `syntax-ppss`, comment-aware list traversal and bounded `scan-sexps` source extraction. It never evaluates the edited forms. Unfinished forms use available source ranges so context can remain useful while typing. This is syntactic context, not macro expansion or runtime evaluation: arbitrary user macros may appear as ordinary leaf calls, and `with-*`/`save-*` scope recognition is a naming heuristic.

Clicks, numbered navigation, parent/function/class jumps, xref return, Helm, tooltips, top/bottom placement and smart compression all use the shared entry format. Variable definitions can be selected through the picker/Helm or parent navigation; the function/class shortcuts target their respective kinds. The debug log identifies this backend as `parser=native-elisp`, with ancestor starts, form descriptions and selected labels.

### JSON context

`json-ts-mode` is supported using the installed JSON grammar. Breadcrumbs show quoted object keys and zero-based array indices, for example `"users" › [1] › "name"` when editing the name of the second user. Nested arrays show an index for each level. JSON keys are preserved as source text, including quotes and escape sequences; scalar values are not copied into the path. The root container has no extra section, so the path may be empty at the root when file display is disabled.

Property entries use `nf-cod-symbol_key` (, U+EA93) with `font-lock-property-name-face`; array entries use `nf-cod-symbol_array` (, U+EA8A) with `font-lock-number-face`. Both are scope entries, independent of show-statements. Clicks, the full picker, numbered jumps and parent navigation work as for other sections. Function/class/statement shortcuts do not target JSON keys or array indices.

### YAML context

Both `yaml-ts-mode` and classic `yaml-mode` are supported using the installed YAML grammar. The classic mode keeps its existing highlighting while the breadcrumb feature creates a parser if needed.

The path includes mapping keys and zero-based sequence indices, for example:

```text
flav › script › [3]
services › [1] › image
matrix › [1] › name
```

Block mappings/sequences and flow collections (`{...}` and `[...]`) are supported. Quoted keys retain their source quotes. Comments do not count as sequence items. Mapping keys use the property/key icon and face; sequence entries use the array icon and face, as in JSON. Both remain visible independently of show-statements.

Inside a multiline `|` or `>` scalar, the breadcrumb stays on its YAML key/sequence item. It does not parse embedded shell statements into additional scopes. Anchors and aliases are not expanded into another location's ancestry. YAML's shorthand flow-sequence mapping entries (`[key: value]`) show their key without a separate index on that same entry. Root containers have no extra section.

Clicks, the picker, numbered shortcuts and parent navigation work for keys and items. Function/class/statement shortcuts do not target YAML keys or items. For `.gitlab-ci.yml`, the tested `ELBE_HASH` block under `flav` produces `flav › script › [3]`.

### Requirements and parser selection

This feature uses Org's element parser for Org buffers, native Emacs Lisp syntax parsing for Elisp buffers, and Emacs Tree-sitter for the other supported languages. It does not obtain context from Eglot/LSP; Eglot need not be running. Tree-sitter languages require an installed grammar. Org and Emacs Lisp require no extra grammar or external package. The local installation uses Emacs 31.1.50. `nerd-icons` is optional; the installed icon font is `Symbols Nerd Font Mono`.

For Tree-sitter languages, parser selection reuses the feature's valid cached parser, otherwise the major mode's primary parser, otherwise an existing buffer parser. If necessary, it creates a parser from the following map, using only already installed grammars. It never downloads a grammar or changes the major mode.

### Supported modes

The following modes are supported. Org uses its built-in element parser and Elisp uses built-in Lisp syntax parsing; the other entries require their listed Tree-sitter grammar. Eglot is not required.

| Modes | Parser / grammar |
|---|---|
| `org-mode` | Native Org element parser; no grammar required |
| `emacs-lisp-mode`, `lisp-interaction-mode` | Native Emacs Lisp syntax; no grammar required |
| `python-ts-mode`, `python-mode` | `python` |
| `c++-ts-mode`, `c++-mode` | `cpp` |
| `c-ts-mode`, `c-mode` | `c` |
| `rust-ts-mode`, `rust-mode` | `rust` |
| `bash-ts-mode`, `sh-mode` | `bash` |
| `js-ts-mode` | `javascript` |
| `typescript-ts-mode` | `typescript` |
| `tsx-ts-mode` | `tsx` |
| `java-ts-mode` | `java` |
| `go-ts-mode` | `go` |
| `json-ts-mode` | `json` |
| `yaml-ts-mode`, `yaml-mode` | `yaml` |

The Tree-sitter entries in `my/context-breadcrumb-language-alist` control parser creation, not exhaustive language coverage. Org and Elisp are detected directly through their major-mode ancestry and do not need entries in that map. Existing parsers can also be reused outside the map. Classic modes can keep their own fontification and Eglot setup while the bar uses a parser. Global activation targets Org buffers, programming buffers and modes explicitly listed in the parser map, including YAML modes derived from text-mode, and excludes minibuffers. For modes other than Org and Elisp, the local mode disables itself when no parser is available. Org and Elisp remain enabled using their native parsing backends without Tree-sitter grammars. Disabling deletes only a parser created by this feature, preserving parsers owned by the major mode.

### Enable, disable and reload

Available through `M-x` or Emacs Lisp:

```elisp
(my/context-breadcrumb-mode 1)          ; Enable current buffer
(my/context-breadcrumb-mode -1)         ; Disable current buffer
(my/context-breadcrumb-global-mode 1)   ; Enable global activation
(my/context-breadcrumb-global-mode -1)  ; Disable global activation
```

The local minor mode has no mode-line lighter. Reload implementation changes with `M-:`:

```elisp
(progn
  (load-file "~/emacstools/my-context-breadcrumb.el")
  (my/context-breadcrumb-refresh))
```

Reloading the module does not evaluate changes elsewhere in `.emacs`. Evaluate changed settings separately. Refresh reapplies placement/appearance, clears rendering caches in every enabled buffer and updates existing bottom footers using their actual text/mode-line dimensions.

When applying an activation change to already-open buffers (particularly the YAML activation fix), re-enable the global mode after loading:

```elisp
(progn
  (load-file "~/emacstools/my-context-breadcrumb.el")
  (my/context-breadcrumb-global-mode -1)
  (my/context-breadcrumb-global-mode 1))
```

This rebuilds activation for eligible open buffers. Future YAML buffers activate automatically with global mode enabled; no separate YAML hook is required.

### Complete customization reference

Use `M-x customize-group RET my-context-breadcrumb RET`. Most options automatically refresh through Customize. After `setq`, call `my/context-breadcrumb-refresh`.

| Variable | Module default | Values / meaning |
|---|---|---|
| `my/context-breadcrumb-position` | `top` | `top` header line or `bottom` separate row above the normal mode line |
| `my/context-breadcrumb-detail` | `offscreen` | `always`, `offscreen`, `compact`; branch expansion |
| `my/context-breadcrumb-else-hints` | `offscreen` | `always`, `offscreen`, `off`; inline plain-else hints |
| `my/context-breadcrumb-compression` | `smart` | `smart`: preserve label start/end; `truncate`: preserve only the start |
| `my/context-breadcrumb-max-section-width` | `48` | Initial column budget per section; use a positive integer |
| `my/context-breadcrumb-icons` | `t` | Enable Nerd Font icons |
| `my/context-breadcrumb-show-file` | `t` | Include file in the bar and picker |
| `my/context-breadcrumb-show-statements` | `t` | Include innermost recognized leaf statement or the current Org source block |
| `my/context-breadcrumb-show-macro-calls` | `t` | Include macro-like C/C++ calls; also requires show-statements |
| `my/context-breadcrumb-macro-name-regexp` | ALL_CAPS pattern below | Heuristic for macro-like calls |
| `my/context-breadcrumb-font-family` | `nil` | Frame editing font family; a string overrides it, preserving Nerd Font icons |
| `my/context-breadcrumb-font-size` | `nil` | Frame editing size; integer in tenths of a point, e.g. `110` = 11 pt |
| `my/context-breadcrumb-face-attributes` | `nil` | Face plist for color, weight, italic, underline and other text attributes |
| `my/context-breadcrumb-current-weight` | `bold` | Innermost weight; `nil` uses the same style as other sections |
| `my/context-breadcrumb-frame-opacity` | `nil` | Follow current frame opacity; integer 0–100 explicitly changes the entire frame |
| `my/context-breadcrumb-background` | `editor` | `editor`, `theme`, or color string |
| `my/context-breadcrumb-border` | `nil` | `nil`, `theme`, color string, or face box plist |
| `my/context-breadcrumb-debug` | `nil` | Diagnostic logging |
| `my/context-breadcrumb-debug-max-lines` | `3000` | Retained log limit; use a positive integer |
| `my/context-breadcrumb-language-alist` | Map above | Parser creation map; no automatic refresh setter |

#### Branch detail

- `always`: expand branch conditions/headers, even when visible in the source.
- `offscreen`: expand if the section header is outside the window or folded; otherwise use its short label.
- `compact`: use short labels such as `if`, `for` or compact catch text.

Names and non-branch entries use full labels before width fitting. Tooltips and the section picker retain extracted full labels.

#### Else hints

A plain `else` can show `else  if(condition)`. The hierarchy-sub marker identifies explanatory context, not an active true branch. Hint text uses the `shadow` face. With icons disabled or unavailable, the marker is `↳`.

- `always`: show whenever an associated condition is available.
- `offscreen`: show only if the associated conditional header is outside the window or folded. This checks the conditional header, not the else header.
- `off`: omit inline hints.

Your setting is `always`. Hint policy is independent of branch-detail policy. The tooltip retains the associated condition even when inline hints are off. In a chain, the tooltip describes the conditional as starting with the shown if; it does not calculate the negation of all alternatives. Else clauses without a parent condition receive no invented hint.

A hint belongs to the else section: clicking it jumps to else. It is not a separate picker or numbered-navigation entry. Width fitting can shorten it or suppress it entirely when space is limited, even with `always` selected.

#### Statements and macro filtering

Your configuration hides macro-like leaf calls while retaining their enclosing loops/branches. The default macro regexp as an Emacs Lisp string is:

```elisp
"\\`[A-Z_][A-Z0-9_]*\\'"
```

Recognition examines C/C++ expression statements and their called function names. Tree-sitter cannot resolve arbitrary macro definitions in included headers, so uppercase ordinary functions can also match. This filter affects breadcrumbs, not parsing or syntax highlighting. Setting show-statements to nil hides all leaf statements, including macros, but keeps enclosing control-flow sections.

### Icon reference

| Section | Symbol | Nerd Font name | Code point |
|---|---|---|---|
| File fallback |  | `nf-cod-file_code` | U+EAE9 |
| Class / struct / enum |  | `nf-cod-symbol_class` | U+EB5B |
| Namespace / module |  | `nf-cod-symbol_class` | U+EB5B |
| Function / method |  | `nf-cod-symbol_method` | U+EA8C |
| Control flow |  | `nf-cod-source_control` | U+EA68 |
| Leaf statement |  | `nf-cod-symbol_event` | U+EA86 |
| Macro-like call |  | `nf-cod-symbol_constant` | U+EB5D |
| JSON / YAML key |  | `nf-cod-symbol_key` | U+EA93 |
| JSON array / YAML sequence item |  | `nf-cod-symbol_array` | U+EA8A |
| Org heading |  | `nf-cod-list_tree` | U+EB86 |
| Org source block |  | `nf-cod-file_code` | U+EAE9 |
| Explanatory hint |  | `nf-cod-type_hierarchy_sub` | U+EBBA |

Private-use symbols can appear as boxes in viewers without a Nerd Font.

File icons first use a known filename/regexp or extension mapping from Nerd Icons. Otherwise they use the current major mode or its parents. Without either mapping they fall back to `nf-cod-file_code`. File icons require show-file and icons to be enabled; your file section is currently disabled. Non-file mappings live in the internal constant `my/context-breadcrumb--icons`; there is no individual icon Customize option.

### Faces and appearance

| Content | Color source |
|---|---|
| Function | `my/context-breadcrumb-name`, inherits `font-lock-function-name-face` |
| Class | `font-lock-type-face` |
| Namespace | `font-lock-constant-face`, matching the local C++ Tree-sitter namespace identifier face |
| Branch | `my/context-breadcrumb-branch`, inherits `font-lock-keyword-face` |
| Org heading | `org-level-1` |
| Org source block | `font-lock-keyword-face` |
| Other text | `my/context-breadcrumb-text`, neutral inheritance |
| Innermost section | Weight from `my/context-breadcrumb-current-weight` (default bold) |
| Separator / hint text | `shadow` |
| Hover | `my/context-breadcrumb-hover`, underline and no box |

Syntax faces supply **colors only**. Their family, height, bold, italic, underline and boxes do not propagate into the bar. The default is the same normal editing font and size used in C/C++ buffers (your frame configuration uses JetBrains Mono at 9 pt on N900D9658 and 11 pt on mp-linux, with 11 pt as the fallback), with syntax colors and the innermost section bold. Org heading scaling, variable-pitch remaps and buffer text zoom do not resize the breadcrumb. Nerd Font icons keep their own symbol font and use the configured absolute size.

Use `M-x customize-group RET my-context-breadcrumb RET` to adjust the new typography options. `nil` font family/size means the frame's `default` face, resolved without buffer-local remaps. Changing the frame font deliberately changes this default; set a family and integer size to fix it independently. `my/context-breadcrumb-face-attributes` takes priority over the basic font options; `my/context-breadcrumb-current-weight` overrides its weight for the innermost section. Set current-weight to nil for uniform styling. Syntax colors can still be changed with `customize-face`; a foreground in face-attributes overrides all syntax colors.

```elisp
;; Example customization; defaults already match the normal C/C++ font.
(setq my/context-breadcrumb-font-family "JetBrains Mono"
      my/context-breadcrumb-font-size 110
      my/context-breadcrumb-face-attributes
      '(:weight normal :slant normal :underline nil)
      my/context-breadcrumb-current-weight 'bold)
(my/context-breadcrumb-refresh)
```

For italic blue text, for example, use `(:foreground "LightSkyBlue" :slant italic)`. `:weight bold`, `:underline t`, `:overline t` and `:strike-through t` are also accepted. Use the separate background and border options for a continuous row.

The bar uses a continuous background without separate section boxes. `editor` background matches the editing background; `theme` retains the theme bar background; a color string supplies a custom background.

#### Line-number gutter background

The separate init helper `my/line-number-match-editor-background` makes the backgrounds of `line-number`, `line-number-current-line`, `line-number-major-tick` and `line-number-minor-tick` match each graphical frame's `default` background. Number foreground colors and other emphasis remain theme-controlled. The helper runs after theme enable and frame creation; terminals retain their existing appearance. Run it interactively after manually changing the default background; it also forces a display repaint.

This setting is independent of breadcrumb activation. Like the breadcrumb, it requests a matching color and relies on the frame's `alpha-background`; it does not introduce independent gutter opacity or change the frame transparency. The graphical transparency still needs verification in the running session.

#### Minibuffer and echo-area background

The init helper `my/minibuffer-match-editor-background` applies matching editor backgrounds to minibuffer input buffers and both internal echo-area buffers, as they become available. A background-only `my/minibuffer-editor-background` face holds each graphical frame's own color, so shared minibuffer buffers can render correctly across frames. Buffer-local face remaps preserve input typography; `minibuffer-prompt` keeps its foreground and other theme attributes. Hooks cover minibuffer entry, theme enable, frame creation and initialization. Existing frame opacity is left unchanged. No independent minibuffer alpha is available, and graphical results require verification in the running session.

Run `M-x my/minibuffer-match-editor-background` after manually changing the editor background; it reapplies the colors and repaints the display. These settings work independently of breadcrumb activation.

#### Background opacity

Your default remains `my/context-breadcrumb-background 'editor` and `my/context-breadcrumb-frame-opacity nil`: match the editor color and follow its existing transparency. Your init now requests `alpha-background` 87 for both the initial frame and new frames: 87% opaque / 13% transparent. Lower values mean more transparency. This is a frame-wide setting covering the editor, breadcrumb, line-number gutter and minibuffer; it does not establish independently adjustable opacity for these areas. The local PGTK renderer source uses the frame alpha when painting face backgrounds. This establishes intended renderer behavior, not verified transparency in your running breadcrumb. An opaque-looking bar needs a graphical check; the frame alpha parameter alone does not prove that the bar was painted transparently. Refresh now forces a full display repaint to clear stale background pixels. If the issue persists after reloading and refreshing, run `M-x my/context-breadcrumb-diagnose-appearance` in the affected source window and share the `*Breadcrumb Appearance*` report. It records actual frame alpha, backend, source/header faces and remaps, configured appearance, and footer properties when applicable.

Emacs has no independent face or header-line opacity attribute. `theme` and custom backgrounds change color, not opacity. A numeric `my/context-breadcrumb-frame-opacity`, for example 90, explicitly changes `alpha-background` for the selected frame when the bar is enabled/refreshed, **including the entire editing area**. Other frames keep their current value until enabled/refreshed there; the option does not rewrite `default-frame-alist`. Returning to nil stops setting opacity and leaves the last frame value in place. To restore a chosen value directly, use `(set-frame-parameter nil 'alpha-background 87)`. Graphical backend/compositor support is required; terminals do not provide Emacs-controlled background alpha. No per-row opacity is simulated by changing colors.

Border nil removes the row box. `theme` retains the theme box. A color string gives a one-pixel border; a face box plist allows custom attributes.

Top placement replaces the buffer header line. Bottom placement adds a separate breadcrumb row directly above the normal status mode line. The status fields remain visible, with no breadcrumb text replacing them. Switching back to top or disabling removes the footer and restores the source window's original mode-line window parameter. Saved header/mode-line values are restored only where the feature still owns the format, so unrelated changes are preserved.

Top appearance uses buffer-local face remapping of header-line faces, including active/inactive variants where present. Bottom appearance is applied inside its dedicated footer buffer; the normal mode-line faces are not remapped. Global theme faces are not changed. Only the feature's own remaps are removed when disabling or switching. Refresh after a theme change if the old editor background remains.

```elisp
(setq my/context-breadcrumb-position 'top
      my/context-breadcrumb-background 'editor
      my/context-breadcrumb-border nil)
(my/context-breadcrumb-refresh)
```

### Keyboard and mouse navigation

Press `C-c`, then `.`, then the final key.

| Shortcut | Command | Action |
|---|---|---|
| `C-c . h` | `my/context-breadcrumb-helm` | Helm picker for the full path |
| `C-c . j` | `my/context-breadcrumb-choose` | Completion picker for the full path |
| `C-c . u` | `my/context-breadcrumb-parent` | Nearest enclosing section whose start precedes point |
| `C-c . f` | `my/context-breadcrumb-function` | Innermost function or method |
| `C-c . c` | `my/context-breadcrumb-class` | Innermost class/struct/enum; not namespace |
| `C-c . s` | `my/context-breadcrumb-statement` | Innermost branch, statement, macro or Org source block |
| `C-c . b` | `xref-go-back` | Return to the previous position |
| `C-c . 1` through `C-c . 9` | Indexed jump closures | Sections 1–9 in the full path, outermost first |
| `C-c . t` | `my/context-breadcrumb-toggle-position` | Toggle top/bottom globally |
| `C-c . d` | `my/context-breadcrumb-debug-toggle` | Toggle debug logging |
| `C-c . D` | `my/context-breadcrumb-debug-show` | Open debug log |

Breadcrumb jumps push the previous location onto the shared xref marker stack. Standard `M-,` also returns through xref in the standard Emacs setup. Other xref navigation can add to the same history.

Mouse button 1 on a section jumps to its source start, recenters and briefly highlights the line. The tooltip shows the extracted label, hint if present, line and click action. A merged else-if jump lands on the else keyword. Targets use markers to survive intervening edits. Navigation attempts to reveal folded overlays that provide `isearch-open-invisible` support.

The clickable `…` opens the full path picker, including width-hidden ancestors. Picker labels are unshortened extracted labels with line numbers. Number keys address the full path, not just visible segments. Enabling file display shifts indices; filters remove entries from both display and navigation. Parent navigation visits recognized section headers, not arbitrary syntax nodes. Missing targets produce user errors.

### Helm navigation

Use `C-c . h` or `M-x my/context-breadcrumb-helm` to browse the full current path in `*Helm Breadcrumbs*`. Helm is loaded on demand; ordinary breadcrumbs and the existing `C-c . j` completion picker remain usable without it. If Helm is unavailable, the command explains how to use the ordinary picker.

Candidates are ordered outermost to innermost and show their path index, indentation, optional Nerd Font icon, full extracted label, section kind and source line. Width-hidden ancestors are included. File/macro/statement filters still apply. Else hints follow the configured hint policy and use the hierarchy-sub marker, with `↳` as a text fallback. This picker searches the current breadcrumb path, not every function or sibling section in the file.

Type to filter, use standard Helm movement (for example `C-n` / `C-p`), and press `RET` to jump to the selected section. `C-g` cancels without jumping. Persistent actions deliberately do not preview or move the source, so browsing does not add intermediate xref history entries. Existing personal Helm keybindings continue to apply.

The jump returns to the originating source buffer/window, reveals supported folded overlays, recenters, pulses the target line and pushes the previous source location onto xref history. Return with `C-c . b` or standard `M-,`. Targets use markers so intervening edits do not invalidate their positions. Closing the source buffer before selecting produces a user error. The ordinary picker and mouse ellipsis keep their existing completion interface; Helm has its own explicit shortcut.

### Bottom placement implementation

Emacs has no native footer-line-format above its mode line. Bottom placement therefore creates a small dedicated footer window for each visible source window. Its text row contains the breadcrumb; its mode line dynamically formats the source buffer's normal status format using that source window and buffer. No extra frame is created. The source buffer's mode-line-format remains intact; only the source window's mode-line display is temporarily hidden to avoid duplication.

Each footer contains two rows, adding one breadcrumb row to the existing status area. Graphical frames measure the actual breadcrumb text and mode-line height, then reserve two extra pixels to avoid clipping. This sizing also applies to existing footers after reloading; terminal frames retain an exact two-row allocation. It follows cursor movement, source edits and window changes. Separate source windows get separate paths and matching-width footers. Clicking a breadcrumb routes navigation back to its source window. Footer windows are skipped by other-window navigation, and focus returns to the source after interacting with them. Changing the source buffer, disabling the feature or returning to top placement removes obsolete footer windows and buffers. The previous per-window mode-line parameter is restored.

A source window must be at least six rows tall when a footer is created. Smaller windows keep their ordinary mode line without a footer until enough height is available. Bottom layout uses real auxiliary windows, so window-management packages and mouse actions designed specifically for ordinary mode lines may need integration; the displayed status is evaluated for the source buffer, while the physical status row belongs to the footer window.

### Limited space

The bar adapts independently to each window, including half-width splits. It stays on one row; automatic wrapping is not implemented. The top header is a native single-row surface, and wrapping would require a different layout and additional editing space.

Fitting first applies the per-section width limit. If the path still exceeds the window, it suppresses optional inline else hints and outer icons while retaining the innermost icon. If necessary, it assigns compact budgets to outer sections and a larger budget to the innermost section, preserving catch bindings when possible. It hides outermost ancestors only when those compact budgets cannot fit. Remaining columns are assigned from innermost outward, so nearby scopes stay visible before distant names expand.

Smart compression preserves both the start and end of a label, including recognizable control keywords when space permits. For example, a 28-column label can become `else if(comm…ommand::Verify)` rather than losing the final `Verify` value. This is display shortening, not a rewrite or interpretation of the condition. Extremely narrow windows can still truncate keywords or bindings. Set `my/context-breadcrumb-compression` to `truncate` to retain only label beginnings instead; adaptive scope budgeting still applies.

Hidden ancestors use clickable `… ›`. Under 12 columns the ellipsis is omitted to preserve innermost text. Full extracted labels and original navigation targets remain available through tooltips, `C-c . j` and the Helm picker (`C-c . h`), regardless of compression. Inline hints return when the window is wide enough; `always` is a preference subject to available space.

Catch shortening preserves the binding when possible:

```text
catch(std::exception const & e) → catch(… & e)
```

The final window width can still shorten this form. Tooltips/picker retain extracted labels. Long hints are part of their section's width budget until the first pressure-reduction step removes them.

The current budget targets are up to 18 columns for the innermost entry, 10 for an outer function and 8 for other outer sections, capped by the text actually needed. Catch entries instead request enough room for their compact binding form. These are internal allocation targets, not guaranteed minimums: extremely narrow windows can force further shortening. The maximum-section-width setting is the initial upper limit, not a required width for every section.

To keep smart compression explicitly selected:

```elisp
(setq my/context-breadcrumb-compression 'smart)
(my/context-breadcrumb-refresh)
```

For label beginnings only, set the same option to `'truncate`. The rest of the adaptive layout still applies. To see a complete path without using additional permanent editing rows, use the Helm picker or ordinary completion picker. Neither automatic wrapping nor a horizontal-scrolling bar is currently implemented.

### Debugging

Toggle with `C-c . d`, reproduce the issue by moving the cursor, and open `*Breadcrumb Debug*` with `C-c . D`. Toggle again to stop. `M-x my/context-breadcrumb-debug-clear` clears queued and recorded diagnostics. Toggle/show shortcuts also work in the debug buffer.

The log records buffer/file, mode, cursor and line, window bounds/width, parser language, ancestor types/ranges, candidate and skipped scopes, active-branch filtering, selected labels and expansion reasons, faces/icons, filename/mode/fallback file-icon selection, else-hint policy/header position, catch compaction, fitting decisions (including hint/icon suppression, desired widths and weighted budgets), hidden ancestors, final output, cache use and rendering errors.

Logging is off by default. Rendering queues entries; a 0.1-second idle timer flushes them outside redisplay. The queue holds at most 1000 entries; excess pending entries are dropped. The retained log defaults to 3000 lines. Repeated identical rendering inputs are suppressed per window. No log file is automatically saved. Logs may contain filenames and source text.

A useful issue report includes source excerpt, exact cursor location, expected/actual path, options, major mode and corresponding log entries.

### Implementation and limitations

`my/context-breadcrumb-entries` accepts an optional source position and returns outer-to-inner entries. `my/context-breadcrumb-render` accepts an optional window. Entries contain kind, full/short labels, start/end and optional hint metadata. The public collector dispatches to Org elements, native Lisp syntax or Tree-sitter according to the major mode. Internal helpers use the double-hyphen naming convention.

Tree-sitter and native Lisp syntax-field text is whitespace-normalized and limited to 240 source characters. Org heading labels use the parsed title directly. Generic headers use only the first source line, capped at 200 characters. Thus a full label is an extracted label, not an unlimited multiline source copy. Multiline generic loop/with headers may be partial. Incomplete source and differing grammar node names can affect results.

The renderer caches window cursor, buffer modification tick, viewport, width, filename, major mode and relevant options. Cursor commands and edits invalidate caches and request redisplay. Literal string indirection protects source `%` characters from mode-line escape interpretation. Render errors yield an empty bar; debug mode records `RENDER ERROR` details.

Placement is shared across enabled buffers; context is window-specific. Packages that replace header-line-format can compete for the top row. Bottom uses auxiliary windows and mirrors the source mode-line format; packages that assume a particular window layout may require integration.

### Troubleshooting

| Symptom | Action |
|---|---|
| No bar | Check local/global activation. Org and Emacs Lisp use built-in parsing; other supported modes need a Tree-sitter parser/grammar. |
| Missing construct | Inspect ancestor node types in debug log; descriptor coverage may need extending |
| Unwanted macro leaves | Disable show-macro-calls or refine the regexp, then refresh |
| Missing file icon | Enable show-file and icons; file display is disabled in your configuration |
| Icon boxes | Check Nerd Font and nerd-icons installation, or disable icons |
| Unexpected else hint | Change else-hints to offscreen or off; the marker distinguishes explanatory context |
| Short labels | Check detail policy, section width and total window width; inspect fit decisions |
| Old appearance | Run `my/context-breadcrumb-refresh`, especially after changing themes |
| Return after a click | `C-c . b` or standard `M-,` |
| Bottom row clipped after reloading | Reload the current implementation and run refresh; existing footers are measured and resized, with two pixels of graphical padding. |
| YAML mode stays inactive | Reload and re-enable global mode using the activation expression above; YAML is explicitly eligible even though it derives from text-mode. |
| Breadcrumb too long in a split | Use smart compression; full labels remain in tooltips and `C-c . h`. Hints/outer icons may disappear to preserve scope text. |
| Bottom footer absent | Ensure the source window has at least six rows; run refresh after resizing. The normal mode line stays available. |

### Validation and maintenance

Run:

```sh
emacs -Q --batch -l /home/mp/emacstools/my-context-breadcrumb-tests.el
```

The test file runs ERT and exits Emacs itself. The latest implementation run passed all 48 tests. Appearance coverage includes explicit refresh repaint and the diagnostic report. It also checks fixed Org typography under heading remaps and text zoom, explicit size/family/color/weight/italic/underline overrides, Nerd Font preservation, innermost weight and opt-in frame opacity. Other coverage includes native Org heading ancestry, metadata-free titles, source blocks, activation without a grammar, narrowing and folded-target navigation, both native Elisp modes, definitions/macros/classes/variables, local functions, if/else/cond, quoted and vector data, function-quoted lambdas, incomplete forms, native navigation and leaf tooltips, smart label suffix/keyword preservation, nearby scope retention, hint removal before scope loss, automatic activation in both YAML modes, separate bottom/footer status rows, footer click routing, split-window ownership and cleanup on buffer changes, Helm full-path candidates, cancellation without movement, marker targets and return navigation, missing-context handling, YAML block/flow paths, comments, classic-mode support and the actual GitLab CI file, JSON property/index ancestry and navigation, C++ scopes/cases, catch paths and compaction, else-if flattening, genuine nested else/if, range loops, hint policies, filename/mode/fallback icons, Python branches, classic-mode parser ownership, debug decisions/bounds, split windows, narrow fitting, navigation/clicks after edits, literal percent signs, appearance restoration and top/bottom placement. Batch tests do not establish graphical font rendering quality in the running session.

Before editing an existing file, make a timestamped backup (`.bak-YYYYMMDD-HHMMSS-microseconds`) and verify identical bytes. Store implementation and test backups in `~/emacstools/backup/`; store `.emacs.bak*` there as well. Store Markdown documentation backups in `~/Documents/codex/emacs/backups/`. Keep this document synchronized with behavior and personal settings. Avoid leaving a stale `.elc` beside the implementation when testing source changes; compile a temporary copy if needed.

## Detailed Markdown preview guide

Integrated from [my-markdown-preview.md](docs/my-markdown-preview.md), reviewed with the current implementation. The standalone guide remains available for focused use. Historical validation counts below describe those feature checks, not a new full startup or graphical test run performed for this documentation task.

Documentation checked against the local implementation on 2026-11-11.

### What the feature does

`markdown-preview` uses Livedown for a live browser preview. It prefers embedded xwidget WebKit when available in the current graphical Emacs frame and otherwise opens an external browser. Edits update automatically after a short idle delay; saving refreshes immediately.

HTML exports use the same Markdown parser and plugins as Livedown. Preview and export include tables, embedded Nerd Font symbols, dark/light styling and a theme chooser. Dark is the initial default; a previously saved browser choice can override it.

This is local configuration layered onto `markdown-mode`, not a separate Markdown major mode. It does not require Eglot or Tree-sitter. It does not enable or replace `markdown-live-preview-mode`.

### Files and initialization

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

### Requirements and installed tools

Required: `markdown-mode`, Node.js, Livedown and the bundled font/theme assets. Embedded browsing additionally requires an Emacs build with xwidget WebKit and a graphical frame.

At setup time the installed Livedown was version 2.1.1, located at:

```text
~/.nvm/versions/node/v24.21.0/bin/livedown
```

The executable is discovered through Emacs' executable path, then an NVM installation path if necessary. Node is located beside the Livedown executable when possible, falling back to `executable-find`. If Node is only available through a shell's NVM setup, the sibling lookup avoids relying on interactive shell startup.

For export, the renderer resolves the real Livedown executable path and loads `markdown-it` and its task-checkbox, emoji and GitHub-heading plugins from that installation. It supports GitHub-style tables and preserves raw HTML. Livedown is a preview server, so it is not used directly as a stdin-to-HTML converter. The old `/usr/bin/markdown` converter is no longer used by this configuration.

### Start, stop and reload

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

### Browser selection

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

### Complete customization reference

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

### Automatic update behavior

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

### Dark/light theme chooser

The chooser is pinned to the top-left corner, with extra space above document content. It is visible at the top of the page, hides as soon as you scroll below the top, and reappears when you return to the very top.

The controls are native Dark/Light radio buttons. Dark is the default when there is no saved choice. JavaScript stores your selection under the browser local-storage key `emacs-markdown-theme`, retains it across live updates and removes duplicate controls. It moves the active chooser outside Livedown's replaced article so the toolbar survives content refreshes.

The scroll listener uses the window's vertical scroll offset and the control's `hidden` attribute. CSS explicitly honors that attribute even though the chooser normally uses flex layout.

Theme colors cover page backgrounds, body text, links, code, syntax highlighting, tables, borders and blockquotes. The chooser is hidden when printing.

CSS `:has()` selectors allow theme switching through the native controls even without the theme script in browsers supporting that selector. JavaScript supplies persistence and automatic scroll hiding; those extras are unavailable when scripts are blocked. Browsers without `:has()` require the JavaScript path to switch colors.

Both JavaScript-enabled and CSS-only Dark → Light → Dark switching were checked in headless Firefox. This does not guarantee identical behavior on every embedded WebKit version. If a page has old controls after an update, restart the preview and refresh it.

### Nerd Font icons and portable export

Private-use characters such as ``, `` and `` require a font containing those glyphs. Installing the font only in Emacs or WSL does not make it available to a separate Windows browser.

The integration embeds the WOFF2 font as a base64 `data:font/woff2` URL in `@font-face`. The CSS font family is `Emacs Nerd Symbols`, restricted to private-use Unicode ranges. Regular prose and code use system/monospace fallback fonts; the Nerd Font supplies the icons. Code elements also include the icon font in their stack.

The local WOFF2 asset was generated from `~/.local/share/fonts/NFM.ttf` (Symbols Nerd Font Mono). Its glyph map was checked for every breadcrumb icon. Font CSS is cached by path and modification time; changing the font file invalidates that cache.

Exported HTML contains the font, CSS, controls and scripts, so no Nerd Font installation or font CDN is needed by the recipient's browser. Images and linked documents are not embedded automatically and still need their normal paths/resources. The embedded font also increases output size.

### Export commands

| Command | Result |
|---|---|
| `M-x markdown-export` | Export HTML, normally beside the source with `.html` extension |
| `M-x markdown-export-and-preview` | Export, then open the HTML through markdown-mode's browser handling |
| `M-x markdown-standalone` | Generate standalone HTML in an output buffer |
| `M-x markdown-preview` | Start the Livedown live preview instead of static export |

`markdown-command` is set to `my/markdown-render`; `markdown-command-needs-filename` is nil. Rendering accepts a buffer region on stdin and writes HTML into markdown-mode's output buffer.

An around-advice on `markdown-standalone` adds the embedded font/theme to `markdown-xhtml-header-content` and the controls to `markdown-xhtml-body-preamble`, preserving existing configured content. Export continues to use markdown-mode's normal file handling. The live-preview promise not to save the source applies to the Livedown preview; export uses markdown-mode's own save/restore behavior.

### Xwidget WebKit navigation

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

### Logs and troubleshooting

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

### Validation and maintenance

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

## Detailed package startup guide

Integrated from [emacs-package-startup.md](docs/emacs-package-startup.md), reviewed with the current implementation. The standalone guide remains available for focused use. Historical validation counts below describe those feature checks, not a new full startup or graphical test run performed for this documentation task.

### Repeated Quelpa no-upgrade messages

`Newer package has been installed. Not upgrading.` comes from `quelpa-build`. A `:quelpa` use-package declaration normally calls Quelpa on each evaluation, even when the package is already installed. A checkout/version comparison can then decide that there is nothing to install and print this message. `[4 times]` is Emacs combining repeated identical messages; it is not a count of newly installed packages.

In `~/.emacs`, the `quelpa-use-package` declaration now sets this built-in option in `:init`, before the integration is loaded:

```elisp
(setq quelpa-use-package-inhibit-loading-quelpa t)
```

The integration checks `package-installed-p` and skips the startup Quelpa call for installed packages. Missing packages still follow their configured recipes. This avoids unnecessary package operations rather than hiding messages or errors. Existing package configuration and mode activation still run.

Startup declarations do not monitor recipe changes. To update intentionally, use `M-x quelpa-upgrade` for one package or `M-x quelpa-upgrade-all` for cached Quelpa recipes. Existing update messages and errors remain available. After changing a recipe for an installed package, explicitly invoke Quelpa with that recipe and `:upgrade t`; startup skips it while the package remains installed.

The option takes effect on the next startup. Setting it in the running session affects declarations expanded afterward; it does not rewrite declarations already expanded or delayed during the current startup.

The original init was backed up in `~/emacstools/backup/` before editing. Verification uses the installed integration's actual handler with installed/missing package cases and checks that the configured recipe is passed through unchanged. No full init evaluation or network package update is needed.

### Weekly update check

`quelpa-upgrade-interval` is set to `7`. The startup hook schedules `quelpa-upgrade-all-maybe` after 15 idle seconds, allowing the main init to finish first. It does nothing if the previous weekly run is less than seven days old. When due, it checks and upgrades cached Quelpa packages using normal version checks, including Quelpa itself according to its existing self-upgrade setting. This is limited to Quelpa-managed packages, not all ELPA packages.

Quelpa persists the run date in `~/.emacs.d/quelpa/last_upgrade`. With no timestamp, the first eligible startup runs the check. Once the call completes, the timestamp prevents the same weekly check on subsequent startups. Messages about unchanged versions can still appear during that weekly run. Errors are not hidden; an error that exits the upgrade call prevents the timestamp write and allows a later startup to retry. Individual errors handled internally by Quelpa may still allow the overall call to complete.

No destructive `force` argument is passed: local changes are not deliberately discarded. This is a check on startup, not a background service or a weekly timer while one Emacs session stays open indefinitely. If Emacs was closed on the due date, the next startup checks after the idle delay. Reloading the scheduling function cancels any previous pending timer before scheduling another.

Verification exercises Quelpa's installed timestamp logic with a mocked upgrade operation: first run, repeat within seven days, overdue run and error/retry behavior. No network update was performed during verification.

## Detailed terminal colors guide

Integrated from [terminal-colors.md](docs/terminal-colors.md), reviewed with the current implementation. The standalone guide remains available for focused use. Historical validation counts below describe those feature checks, not a new full startup or graphical test run performed for this documentation task.

### Configuration

The Alect theme defaults to `alect-display-class` of `((type graphic))`, so `alect-black` was not styling terminal Emacs. `~/.emacs` now sets the class to `((class color) (min-colors 256))` before loading the theme. Alect builds theme face specifications in a macro, so its compiled theme file already freezes the graphical-only class. The load is therefore wrapped in `(let ((load-suffixes '(".el"))) ...)` to expand the installed theme source using the current display class; package files are not edited. It also removes the old terminal-only colors for the default face, current-line highlight, region, Man and Company. The same theme palette and shared customizations now apply in graphical and sufficiently capable terminal frames. Very limited terminals remain unthemed by this setting.

The old `(setq xterm-tmux-extra-capabilities '(RGB))` was removed: that option controls terminal interaction/keyboard features and does not enable truecolor. No shell environment or terminal application settings have been changed.

### Exact RGB colors

Start a fresh terminal Emacs, then inspect `M-: (display-color-cells)`. `16777216` means 24-bit truecolor; `256` means theme RGB values are approximated by a smaller palette. The terminal and any SSH/multiplexer layer must actually support the selected capability.

For a terminal and multiplexer known to support 24-bit color, this launch command advertises it before Emacs initializes its terminal:

```sh
COLORTERM=truecolor emacs -nw
```

This Emacs build's terminal initialization explicitly recognizes `COLORTERM=truecolor`. Setting it inside `.emacs` is too late for initial terminal setup. `TERM=xterm-direct` is another terminfo-based approach, but only use it when it accurately describes the terminal and its supported escape sequences; it is not set globally here.

A plain 256-color terminal cannot reproduce every GUI RGB value exactly. Fonts, Nerd Font glyphs and italics also depend on the terminal's configured fonts and rendering. Terminal background opacity is controlled by the terminal application; Emacs's graphical `alpha-background` setting does not control it. Matching RGB settings does not imply identical perceived appearance when GUI and terminal transparency differ.

### Apply and verify

Restart terminal Emacs to remove previously loaded terminal-only face overrides cleanly. The theme class must be configured before the theme is created/loaded. Manual updates to an already-loaded theme can leave old face specifications, so restarting is preferred for this change.

The original init was backed up under `~/emacstools/backup/`. Verification loads the installed Alect theme in isolated terminal Emacs processes without running the full init or updating packages, and compares applied default, keyword, string, region and hl-line colors with the theme's RGB specifications. Full init source readability is checked separately.

### Neutral main text color

The main `default` face foreground is now neutral light gray `#B8B8B8`, replacing Alect Black's yellow-beige `#b2af95`. It is set through the high-priority `user` theme after loading `custom.el`, so it applies to graphical and terminal frames and persists across color-theme changes. Only the foreground is specified; font, background, opacity and explicitly colored syntax faces are preserved. Faces that inherit the default foreground naturally become gray too. Truecolor is needed to reproduce this RGB value exactly in a terminal.

Apply immediately with `M-:`:

```elisp
(custom-theme-set-faces 'user '(default ((t (:foreground "#B8B8B8")))))
```

## Detailed editing line numbers guide

Integrated from [line-numbers.md](docs/line-numbers.md), reviewed with the current implementation. The standalone guide remains available for focused use. Historical validation counts below describe those feature checks, not a new full startup or graphical test run performed for this documentation task.

`~/.emacs` loads `~/emacstools/my-editing-line-numbers.el` and enables `my/editing-line-numbers-mode` globally. This replaces separate programming/text/config/YAML/syslog hooks with one policy.

Text file buffers receive line numbers even when their extension is unrecognized and they use `fundamental-mode`, such as `~/.bash_history_backup`. Read-only text files also receive numbers. Editable non-file programming, text, configuration and fundamental buffers are included, including `*scratch*`.

Helm, minibuffers, internal buffers (including breadcrumb footers), and utility modes are excluded. The default excluded mode list includes `special-mode` and its descendants (Help, compilation output and many other interfaces), Dired, Comint/shell, terminal, Vterm, Eshell, image, Doc View and PDF View modes. Helm modes and buffers named `*helm…` are excluded as well. New buffers and major-mode changes are handled by the globalized minor mode. This is a buffer policy: two windows showing the same buffer share its line-number setting.

Customize exclusions with `M-x customize-group RET my-editing-line-numbers RET`, then run `M-x my/editing-line-numbers-refresh`. Toggle the policy with `M-x my/editing-line-numbers-mode`. The normal `display-line-numbers-mode` command can still toggle the current buffer; the policy is reapplied on mode changes or explicit refresh. Existing line-number type, colors and background settings are preserved.

Apply the new configuration to an existing session with `M-:`:

```elisp
(load-file "~/emacstools/my-editing-line-numbers.el")
```

The initial fix backs up `~/.emacs` under `~/emacstools/backup/`. No contents of the history file are read or modified. Eligibility is checked with file/fundamental, programming, scratch, read-only text, Helm, Help, Dired, shell, internal, minibuffer and mode-transition cases.

## Detailed buffer navigation guide

Integrated from [buffer-navigation.md](docs/buffer-navigation.md), reviewed with the current implementation. The standalone guide remains available for focused use. Historical validation counts below describe those feature checks, not a new full startup or graphical test run performed for this documentation task.

`~/.emacs` loads `~/emacstools/my-buffer-navigation.el`. The built-in `next-buffer` and `previous-buffer` commands keep their normal key bindings and ordering, but skip buffer names hidden by Helm Mini's default buffer filter.

The helper uses the live values of `helm-boring-buffer-regexp-list` and `helm-white-buffer-regexp-list` when Helm is loaded. Before that it uses Helm's standard exclusions: names starting with a space, `*helm`, `*Echo Area` or `*Minibuf`. Minibuffers and dead buffers are always excluded. Whitelisted ordinary buffers can override matching name exclusions. Normal named buffers, including `*scratch*`, `*Messages*`, shells and Help buffers, remain reachable just as they can be in Helm Mini; this is not restricted to file buffers or editing modes.

The setting is `switch-to-prev-buffer-skip`, using `my/buffer-navigation-skip-p`. The same built-in option also influences window buffer replacement after burying, quitting or killing a buffer. If there is no eligible alternative, normal navigation does not deliberately fall back to a hidden buffer. Helm's own list ordering, source configuration and display are unchanged.

Helm deliberately sets its candidate display buffer writable while initializing it, so it can rebuild the candidate list. The fix filters navigation rather than forcing Helm buffers read-only, which could interfere with Helm updates. Explicitly choosing an internal buffer by name remains possible; this policy applies to next/previous buffer navigation and related window replacement.

Apply without restarting using `M-:`:

```elisp
(load-file "~/emacstools/my-buffer-navigation.el")
```

To customize which buffer names are hidden, adjust Helm's boring-buffer patterns or whitelist. `~/.emacs` was backed up under `~/emacstools/backup/` before editing. Verification covers matching and whitelists, ordinary non-file buffers, actual previous/next-buffer navigation, and retaining the current buffer when all alternatives are hidden.


## Detailed Deadgrep guide

Integrated from [deadgrep.md](docs/deadgrep.md).

`~/.emacs` loads `~/emacstools/my-deadgrep-recursion.el` from the Deadgrep package configuration. The installed package files are unchanged.

### Controls

The results header now contains **Recursive: on off**, using the same clickable-button style as Deadgrep's other settings. The active choice is plain text; click the other choice to switch. The choices are ordinary Emacs text buttons; they can also be activated at point. Press uppercase **R** in a Deadgrep results buffer to toggle and rerun the search.

- **on**: include subdirectories; this is the default for new results buffers.
- **off**: search only direct child files of the displayed search directory, using ripgrep `--max-depth=1`.

The directory is Deadgrep's displayed search root, which may be the project root rather than the current source file's directory. Use **D** or the Directory button to change it. Existing file-type, glob, case, context, hidden-file and ignore settings still apply. Toggling changes only the recursion state in that results buffer; other search buffers keep their own state. Reusing the same results buffer preserves its state, consistent with Deadgrep's other per-buffer search settings. **g** reruns the current settings.

### Hiding results while reviewing a search

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

### Implementation and compatibility

`my/deadgrep-recursive-p` is a buffer-local boolean, initially t. `my/deadgrep-toggle-recursive` is the interactive command; `my/deadgrep-set-recursive` is the common button/command helper. A heading advice adds the row, an argument advice applies the depth policy, and a scoped process-launch safeguard enforces the same policy on the actual ripgrep invocation. Reloading the extension does not stack duplicate advice.

The UI owns depth limits. A `:filter-return` argument advice processes the final argument list produced by Deadgrep, rather than temporarily rebinding `deadgrep-extra-arguments`. It removes manually supplied `--max-depth`, `--maxdepth` and `-d` forms from the options before `--`, preserves unrelated options such as `--no-config`, and adds `--max-depth=1` only when recursion is off. Search text and paths after `--` are preserved verbatim. Neither the input argument list nor the extra-arguments variable is destructively modified. Other custom finite depths are not represented by this on/off control. Reloading explicitly removes the earlier `:around` advice before installing the new filter.

The launch safeguard captures the results buffer and its recursion setting around `deadgrep--start`. It filters `start-file-process` arguments only during that call and only for that target buffer. It therefore also works when the argument-builder advice is bypassed; unrelated process launches are unchanged. The actual executable and arguments are stored buffer-locally in `my/deadgrep--last-command`, and `deadgrep--debug-command` is refreshed from that captured invocation. `M-x my/deadgrep-diagnose` reports the search directory, recursion state and captured command.

The extension integrates with the installed Deadgrep private heading/argument/start/sentinel/reset/navigation functions. If a future package upgrade changes those interfaces, this local extension may need adjustment. A postponed search remains postponed according to Deadgrep's normal behavior; use **g** to start it.

### Reload without restarting Emacs

Evaluate with `M-:`:

```elisp
(load-file "~/emacstools/my-deadgrep-recursion.el")
```

In an already-open Deadgrep results buffer, press **g** to rebuild the header and rerun the search with the visible recursion state. New searches receive the control automatically. No new global shortcut is added: `M-s` continues to open Deadgrep and **R** is local to Deadgrep buffers.

### Validation

Checks cover reversible result/file/error hiding, boundaries between file groups and diagnostics, buffer isolation, cleanup on rerun/mode changes, navigation over hidden matches, interaction with file folding, the default recursive state, clickable header actions, keyboard binding, independent buffers, reinitialization, idempotent reload, removal of old depth arguments and preservation of unrelated arguments. A temporary ripgrep fixture verifies that a matching file in a subdirectory is included with recursion on and excluded with recursion off. Configuration/documentation backups are kept in the established backup folders.

The regression suite is `~/emacstools/my-deadgrep-recursion-tests.el`. The current run passes all sixteen tests, including real asynchronous searches and clicking the header control. Recheck after an upgrade with:

```sh
emacs -Q --batch -l ~/emacstools/my-deadgrep-recursion-tests.el
```

Package updates do not overwrite this extension, its tests, your init load statement or these guides: they are stored outside the package installation directory. Compatibility still depends on the heading/argument/start/sentinel/reset/navigation interfaces described above.

### Search root, permission errors and verifying the actual command

The search directory is the **Directory** shown in the results header. Ripgrep's final `.` is relative to that directory: for `Directory: /home/mp/`, it searches `/home/mp/`. Use **D** to change this root. A recursive search can encounter unreadable files or subdirectories anywhere in that tree; ripgrep returns exit code 2 for errors. The file-type filter selects matching files; it does not grant access to directories. Nonrecursive mode avoids descending into subdirectories, but an unreadable file directly in the root can still cause an error.

Earlier versions could show recursion off while the reported command contained no depth limit. The process-launch safeguard now enforces the limit even if the argument-builder advice is bypassed. After loading the updated extension and pressing **g**, run `M-x my/deadgrep-diagnose`: with recursion off, the captured command must include `--max-depth=1`. `M-: deadgrep--debug-command` also reports that invocation. The regression suite checks the actual `process-command`, including a word/log search with an unreadable subdirectory and the argument-builder advice deliberately disabled. Permission messages are not suppressed or permissions changed by the extension.

If exit code 2 persists with `--max-depth=1` present, inspect the accompanying `rg:` error lines to identify the remaining error; exit code alone does not identify its cause. A no-match search normally returns exit code 1.

### Continuing past unreadable paths

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

## Maintenance and reload

### Apply one module without re-running the entire startup

Use `M-x load-file` and select the relevant file, or evaluate a narrow `load-file` expression with `M-:`. For example:

```elisp
(load-file "~/emacstools/my-buffer-navigation.el")
(load-file "~/emacstools/my-editing-line-numbers.el")
(load-file "~/emacstools/bookmarks_config.el")
```

For breadcrumb settings, reload the module and run `my/context-breadcrumb-refresh`. For Markdown, use the start/stop/reload procedures in its detailed guide. Reloading the whole `~/.emacs` can re-run mode toggles, hooks, package setup and external integration startup, so a targeted reload is preferable for routine adjustments. Theme/terminal capability changes are best checked in a fresh Emacs process; terminal color detection occurs before the ordinary init.

### Inspect effective behavior

| Tool | What it checks |
|---|---|
| `C-h k KEY` | Actual key binding in the current buffer |
| `C-h m` | Active major/minor modes and mode help |
| `C-h v VARIABLE` | Live value, local/global status and variable documentation |
| `C-h f COMMAND` | Command documentation and source link |
| `M-x describe-char` | Character, syntax, properties and overlays at point |
| `M-x list-faces-display` / `list-colors-display` | Face/color inspection |
| `M-x font-lock-flush`, then `font-lock-ensure` | Refresh syntax highlighting |
| `M-x revert-buffer` | Reload a file from disk; consider unsaved edits before confirming |
| `M-,` / `xref-go-back` | Return from a breadcrumb/xref jump |
| `M-x my/context-breadcrumb-diagnose-appearance` | Frame/background/font/header/footer settings report |
| `M-x my/context-breadcrumb-debug-toggle` / `debug-show` | Dynamic breadcrumb inputs and formatting decisions |
| `M-x my/eglot-reset-retries`, then `eglot` | Clear retry budget and explicitly reconnect |
| `M-: (display-color-cells)` | Actual terminal color capacity |

### Scope and validation of this reference

The reference was assembled by reading the main init, early init, Customize file, directly loaded personal modules and their local dependencies. It includes all 52 active package declarations, interactive personal/library command definitions, 37 Tempo template declarations grouped by tag, public custom options and all nine focused feature guides, including the later Helm and startup-performance extensions. Older commented setups and merely selected packages are distinguished from active configuration. Documentation generation did not load the full init, start Eglot/preview/AI services, upgrade packages or change the Emacs implementation.

The 13 November update also audited all 89 interactive command/mode and custom-option definitions found in the main init and the 15 personal `my-*.el` modules: all are named in this reference. The central shortcut table, command registry and options index now include the recent Deadgrep, Helm, device-font and startup additions. Internal helper functions and upstream package APIs are explained where relevant rather than reproduced as full manuals.

Checks for this documentation cover source/module coverage, local links, table/fence structure, key reassignment notes, current opacity/color/bookmark values and absence of credential examples. This document is a snapshot; future implementation changes should update the relevant standalone guide and this consolidated reference. The source-level declaration appendix supports checking settings without turning old comments into claims of active behavior.

## ASCII reference buffer protection

`emacstools/my-ascii-table.el` is personal integration for the bundled legacy ASCII table library. C/C++ `F10` opens the hexadecimal reference. Decimal, octal and hexadecimal views default to values 0–255 (explicit limits are honored) and are read-only; `q` runs `quit-window` to return to editing. Reopening a table refreshes it normally. The wrapper uses a dedicated `special-mode` derivative and leaves the upstream library unchanged.
