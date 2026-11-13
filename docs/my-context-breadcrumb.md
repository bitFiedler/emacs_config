# My Context Breadcrumb

Documentation reviewed against `~/emacstools/my-context-breadcrumb.el` on 2026-11-13, including native Org and Emacs Lisp support, split-window compression, measured bottom-footer sizing and YAML activation fixes.

## Files and startup

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

## Purpose and displayed context

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

## Org context

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

## Emacs Lisp context

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

## JSON context

`json-ts-mode` is supported using the installed JSON grammar. Breadcrumbs show quoted object keys and zero-based array indices, for example `"users" › [1] › "name"` when editing the name of the second user. Nested arrays show an index for each level. JSON keys are preserved as source text, including quotes and escape sequences; scalar values are not copied into the path. The root container has no extra section, so the path may be empty at the root when file display is disabled.

Property entries use `nf-cod-symbol_key` (, U+EA93) with `font-lock-property-name-face`; array entries use `nf-cod-symbol_array` (, U+EA8A) with `font-lock-number-face`. Both are scope entries, independent of show-statements. Clicks, the full picker, numbered jumps and parent navigation work as for other sections. Function/class/statement shortcuts do not target JSON keys or array indices.

## YAML context

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

## Requirements and parser selection

This feature uses Org's element parser for Org buffers, native Emacs Lisp syntax parsing for Elisp buffers, and Emacs Tree-sitter for the other supported languages. It does not obtain context from Eglot/LSP; Eglot need not be running. Tree-sitter languages require an installed grammar. Org and Emacs Lisp require no extra grammar or external package. The local installation uses Emacs 31.1.50. `nerd-icons` is optional; the installed icon font is `Symbols Nerd Font Mono`.

For Tree-sitter languages, parser selection reuses the feature's valid cached parser, otherwise the major mode's primary parser, otherwise an existing buffer parser. If necessary, it creates a parser from the following map, using only already installed grammars. It never downloads a grammar or changes the major mode.

## Supported modes

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

## Enable, disable and reload

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

## Complete customization reference

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

### Branch detail

- `always`: expand branch conditions/headers, even when visible in the source.
- `offscreen`: expand if the section header is outside the window or folded; otherwise use its short label.
- `compact`: use short labels such as `if`, `for` or compact catch text.

Names and non-branch entries use full labels before width fitting. Tooltips and the section picker retain extracted full labels.

### Else hints

A plain `else` can show `else  if(condition)`. The hierarchy-sub marker identifies explanatory context, not an active true branch. Hint text uses the `shadow` face. With icons disabled or unavailable, the marker is `↳`.

- `always`: show whenever an associated condition is available.
- `offscreen`: show only if the associated conditional header is outside the window or folded. This checks the conditional header, not the else header.
- `off`: omit inline hints.

Your setting is `always`. Hint policy is independent of branch-detail policy. The tooltip retains the associated condition even when inline hints are off. In a chain, the tooltip describes the conditional as starting with the shown if; it does not calculate the negation of all alternatives. Else clauses without a parent condition receive no invented hint.

A hint belongs to the else section: clicking it jumps to else. It is not a separate picker or numbered-navigation entry. Width fitting can shorten it or suppress it entirely when space is limited, even with `always` selected.

### Statements and macro filtering

Your configuration hides macro-like leaf calls while retaining their enclosing loops/branches. The default macro regexp as an Emacs Lisp string is:

```elisp
"\\`[A-Z_][A-Z0-9_]*\\'"
```

Recognition examines C/C++ expression statements and their called function names. Tree-sitter cannot resolve arbitrary macro definitions in included headers, so uppercase ordinary functions can also match. This filter affects breadcrumbs, not parsing or syntax highlighting. Setting show-statements to nil hides all leaf statements, including macros, but keeps enclosing control-flow sections.

## Icon reference

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

## Faces and appearance

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

### Line-number gutter background

The separate init helper `my/line-number-match-editor-background` makes the backgrounds of `line-number`, `line-number-current-line`, `line-number-major-tick` and `line-number-minor-tick` match each graphical frame's `default` background. Number foreground colors and other emphasis remain theme-controlled. The helper runs after theme enable and frame creation; terminals retain their existing appearance. Run it interactively after manually changing the default background; it also forces a display repaint.

This setting is independent of breadcrumb activation. Like the breadcrumb, it requests a matching color and relies on the frame's `alpha-background`; it does not introduce independent gutter opacity or change the frame transparency. The graphical transparency still needs verification in the running session.

### Minibuffer and echo-area background

The init helper `my/minibuffer-match-editor-background` applies matching editor backgrounds to minibuffer input buffers and both internal echo-area buffers, as they become available. A background-only `my/minibuffer-editor-background` face holds each graphical frame's own color, so shared minibuffer buffers can render correctly across frames. Buffer-local face remaps preserve input typography; `minibuffer-prompt` keeps its foreground and other theme attributes. Hooks cover minibuffer entry, theme enable, frame creation and initialization. Existing frame opacity is left unchanged. No independent minibuffer alpha is available, and graphical results require verification in the running session.

Run `M-x my/minibuffer-match-editor-background` after manually changing the editor background; it reapplies the colors and repaints the display. These settings work independently of breadcrumb activation.

### Background opacity

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

## Keyboard and mouse navigation

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

## Helm navigation

Use `C-c . h` or `M-x my/context-breadcrumb-helm` to browse the full current path in `*Helm Breadcrumbs*`. Helm is loaded on demand; ordinary breadcrumbs and the existing `C-c . j` completion picker remain usable without it. If Helm is unavailable, the command explains how to use the ordinary picker.

Candidates are ordered outermost to innermost and show their path index, indentation, optional Nerd Font icon, full extracted label, section kind and source line. Width-hidden ancestors are included. File/macro/statement filters still apply. Else hints follow the configured hint policy and use the hierarchy-sub marker, with `↳` as a text fallback. This picker searches the current breadcrumb path, not every function or sibling section in the file.

Type to filter, use standard Helm movement (for example `C-n` / `C-p`), and press `RET` to jump to the selected section. `C-g` cancels without jumping. Persistent actions deliberately do not preview or move the source, so browsing does not add intermediate xref history entries. Existing personal Helm keybindings continue to apply.

The jump returns to the originating source buffer/window, reveals supported folded overlays, recenters, pulses the target line and pushes the previous source location onto xref history. Return with `C-c . b` or standard `M-,`. Targets use markers so intervening edits do not invalidate their positions. Closing the source buffer before selecting produces a user error. The ordinary picker and mouse ellipsis keep their existing completion interface; Helm has its own explicit shortcut.

## Bottom placement implementation

Emacs has no native footer-line-format above its mode line. Bottom placement therefore creates a small dedicated footer window for each visible source window. Its text row contains the breadcrumb; its mode line dynamically formats the source buffer's normal status format using that source window and buffer. No extra frame is created. The source buffer's mode-line-format remains intact; only the source window's mode-line display is temporarily hidden to avoid duplication.

Each footer contains two rows, adding one breadcrumb row to the existing status area. Graphical frames measure the actual breadcrumb text and mode-line height, then reserve two extra pixels to avoid clipping. This sizing also applies to existing footers after reloading; terminal frames retain an exact two-row allocation. It follows cursor movement, source edits and window changes. Separate source windows get separate paths and matching-width footers. Clicking a breadcrumb routes navigation back to its source window. Footer windows are skipped by other-window navigation, and focus returns to the source after interacting with them. Changing the source buffer, disabling the feature or returning to top placement removes obsolete footer windows and buffers. The previous per-window mode-line parameter is restored.

A source window must be at least six rows tall when a footer is created. Smaller windows keep their ordinary mode line without a footer until enough height is available. Bottom layout uses real auxiliary windows, so window-management packages and mouse actions designed specifically for ordinary mode lines may need integration; the displayed status is evaluated for the source buffer, while the physical status row belongs to the footer window.

## Limited space

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

## Debugging

Toggle with `C-c . d`, reproduce the issue by moving the cursor, and open `*Breadcrumb Debug*` with `C-c . D`. Toggle again to stop. `M-x my/context-breadcrumb-debug-clear` clears queued and recorded diagnostics. Toggle/show shortcuts also work in the debug buffer.

The log records buffer/file, mode, cursor and line, window bounds/width, parser language, ancestor types/ranges, candidate and skipped scopes, active-branch filtering, selected labels and expansion reasons, faces/icons, filename/mode/fallback file-icon selection, else-hint policy/header position, catch compaction, fitting decisions (including hint/icon suppression, desired widths and weighted budgets), hidden ancestors, final output, cache use and rendering errors.

Logging is off by default. Rendering queues entries; a 0.1-second idle timer flushes them outside redisplay. The queue holds at most 1000 entries; excess pending entries are dropped. The retained log defaults to 3000 lines. Repeated identical rendering inputs are suppressed per window. No log file is automatically saved. Logs may contain filenames and source text.

A useful issue report includes source excerpt, exact cursor location, expected/actual path, options, major mode and corresponding log entries.

## Implementation and limitations

`my/context-breadcrumb-entries` accepts an optional source position and returns outer-to-inner entries. `my/context-breadcrumb-render` accepts an optional window. Entries contain kind, full/short labels, start/end and optional hint metadata. The public collector dispatches to Org elements, native Lisp syntax or Tree-sitter according to the major mode. Internal helpers use the double-hyphen naming convention.

Tree-sitter and native Lisp syntax-field text is whitespace-normalized and limited to 240 source characters. Org heading labels use the parsed title directly. Generic headers use only the first source line, capped at 200 characters. Thus a full label is an extracted label, not an unlimited multiline source copy. Multiline generic loop/with headers may be partial. Incomplete source and differing grammar node names can affect results.

The renderer caches window cursor, buffer modification tick, viewport, width, filename, major mode and relevant options. Cursor commands and edits invalidate caches and request redisplay. Literal string indirection protects source `%` characters from mode-line escape interpretation. Render errors yield an empty bar; debug mode records `RENDER ERROR` details.

Placement is shared across enabled buffers; context is window-specific. Packages that replace header-line-format can compete for the top row. Bottom uses auxiliary windows and mirrors the source mode-line format; packages that assume a particular window layout may require integration.

## Troubleshooting

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

## Validation and maintenance

Run:

```sh
emacs -Q --batch -l /home/mp/emacstools/my-context-breadcrumb-tests.el
```

The test file runs ERT and exits Emacs itself. The latest implementation run passed all 48 tests. Appearance coverage includes explicit refresh repaint and the diagnostic report. It also checks fixed Org typography under heading remaps and text zoom, explicit size/family/color/weight/italic/underline overrides, Nerd Font preservation, innermost weight and opt-in frame opacity. Other coverage includes native Org heading ancestry, metadata-free titles, source blocks, activation without a grammar, narrowing and folded-target navigation, both native Elisp modes, definitions/macros/classes/variables, local functions, if/else/cond, quoted and vector data, function-quoted lambdas, incomplete forms, native navigation and leaf tooltips, smart label suffix/keyword preservation, nearby scope retention, hint removal before scope loss, automatic activation in both YAML modes, separate bottom/footer status rows, footer click routing, split-window ownership and cleanup on buffer changes, Helm full-path candidates, cancellation without movement, marker targets and return navigation, missing-context handling, YAML block/flow paths, comments, classic-mode support and the actual GitLab CI file, JSON property/index ancestry and navigation, C++ scopes/cases, catch paths and compaction, else-if flattening, genuine nested else/if, range loops, hint policies, filename/mode/fallback icons, Python branches, classic-mode parser ownership, debug decisions/bounds, split windows, narrow fitting, navigation/clicks after edits, literal percent signs, appearance restoration and top/bottom placement. Batch tests do not establish graphical font rendering quality in the running session.

Before editing an existing file, make a timestamped backup (`.bak-YYYYMMDD-HHMMSS-microseconds`) and verify identical bytes. Store implementation and test backups in `~/emacstools/backup/`; store `.emacs.bak*` there as well. Store Markdown documentation backups in `~/Documents/codex/emacs/backups/`. Keep this document synchronized with behavior and personal settings. Avoid leaving a stale `.elc` beside the implementation when testing source changes; compile a temporary copy if needed.
