;;; my-context-breadcrumb.el --- Clickable syntax context -*- lexical-binding: t; -*-

;; C-c . h: Helm picker
;; C-c . j: choose section   u: parent   f: function   c: class
;;       s: statement       b: back     t: top/bottom 1..9: section
;;       d: debug on/off    D: show debug log
;; M-x customize-group RET my-context-breadcrumb RET

(require 'cl-lib)
(require 'subr-x)
(require 'treesit)
(require 'xref)
(require 'pulse)
(require 'face-remap)
(require 'nerd-icons nil t)

(defvar my/context-breadcrumb--icons)

(declare-function helm "helm" (&rest args))
(declare-function helm-make-source "helm-source" (name class &rest args))
(declare-function org-element-context "org-element" (&rest args))
(declare-function org-element-type "org-element" (element))
(declare-function org-element-property "org-element" (property element))
(declare-function org-fold-show-context "org-fold" (&optional key))

(defgroup my-context-breadcrumb nil
  "Clickable class, function, and control-flow context."
  :group 'convenience)

(defun my/context-breadcrumb--set-option (symbol value)
  (set-default symbol value)
  (when (fboundp 'my/context-breadcrumb-refresh)
    (my/context-breadcrumb-refresh)))

(defcustom my/context-breadcrumb-position 'top
  "Where to show context: header at top, or a separate footer at bottom.
Bottom places a breadcrumb row above the normal mode line.
Switching back or disabling the mode restores the previous formats."
  :type '(choice (const top) (const bottom))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-detail 'offscreen
  "When to include the condition or expression of control-flow sections.
Class and function names are always shown.  Offscreen also expands folded
headers.  Full text remains available in tooltips and the section picker."
  :type '(choice (const offscreen) (const always) (const compact))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-else-hints 'offscreen
  "When to show the associated conditional beside a plain else section.
The hierarchy-sub icon marks explanatory text, not an active if branch.
Offscreen includes folded conditional headers.  Tooltips retain the hint."
  :type '(choice (const :tag "Always" always)
                 (const :tag "Conditional header offscreen" offscreen)
                 (const :tag "Off" off))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-max-section-width 48
  "Maximum width of one breadcrumb before adapting to the window width."
  :type 'integer :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-compression 'smart
  "How to shorten section labels in narrow windows.
Smart preserves both the start and end, keeping condition values and name
suffixes readable.  Truncate keeps only the beginning.  Full labels remain
in tooltips, the section picker and Helm."
  :type '(choice (const smart) (const truncate))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-icons t
  "Use Nerd Font Codicons, including the VS Code symbol icons."
  :type 'boolean :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-show-file t
  "Show the file name as the first breadcrumb section.
When nil, the bar and section picker start with the enclosing syntax scope."
  :type 'boolean :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-show-statements t
  "Include the innermost leaf statement, in addition to enclosing scopes."
  :type 'boolean :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-show-macro-calls t
  "Include macro-like C/C++ calls as leaf statements.
Tree-sitter cannot resolve preprocessor definitions in other headers, so
this uses `my/context-breadcrumb-macro-name-regexp' as a naming heuristic.
This option also requires `my/context-breadcrumb-show-statements'."
  :type 'boolean :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-macro-name-regexp "\\`[A-Z_][A-Z0-9_]*\\'"
  "Names of C/C++ calls treated as macros for breadcrumb filtering.
An ordinary function named in ALL_CAPS is also matched by the default."
  :type 'regexp :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-font-family nil
  "Text font family, or nil to use the frame's normal editing font.
Nerd Font icons retain their own symbol font.  Org and buffer face remaps
never supply the breadcrumb font."
  :type '(choice (const :tag "Frame editing font" nil) string)
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-font-size nil
  "Absolute text height in tenths of a point, or nil for the frame default.
For example, 110 means 11 points.  Heading scaling and buffer text zoom
are ignored; the same size is used in every supported major mode."
  :type '(choice (const :tag "Frame editing size" nil) (integer :tag "Tenths of a point"))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-face-attributes nil
  "Face attribute plist overriding the breadcrumb's normal text style.
For example, (:foreground \"LightSkyBlue\" :weight bold :slant italic
:underline t).  Default nil uses normal weight and slant with syntax
colors, as in C/C++ buffers.  Font family overrides do not replace the
Nerd Font used for icons.  Use the background and border options for the
whole row instead of per-text boxes."
  :type 'plist :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-current-weight 'bold
  "Weight of the innermost section, or nil to use the normal text style."
  :type '(choice (const :tag "Same as other sections" nil)
                 (const normal) (const bold) (const semibold) (const light))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-frame-opacity nil
  "Optional frame-wide background opacity, from 0 to 100.
Nil leaves existing frame transparency unchanged, following its
`alpha-background' parameter.  Emacs has no per-face background alpha:
a number explicitly changes the ENTIRE frame, including editing areas.
Returning to nil leaves that frame parameter at its last value."
  :type '(choice (const :tag "Follow existing frame opacity" nil)
                 (integer :tag "Whole frame opacity (0–100)"))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-background 'editor
  "Background of the entire breadcrumb row.
Use `editor' to match the editing background, `theme' for the normal
header/mode-line color, or a color string.  Applied only in enabled buffers."
  :type '(choice (const :tag "Editor background" editor)
                 (const :tag "Theme bar background" theme)
                 (color :tag "Custom background"))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-border nil
  "Border around the breadcrumb row.
Nil removes it, `theme' uses the theme border, and a color string creates
a one-pixel border.  A custom face box plist is also accepted."
  :type '(choice (const :tag "No border" nil)
                 (const :tag "Theme border" theme)
                 (color :tag "Border color")
                 (sexp :tag "Custom face box"))
  :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-debug nil
  "Log syntax inputs and formatting decisions to *Breadcrumb Debug*.
Toggle at runtime with C-c . d; open the log with C-c . D.
Logs are queued during redisplay and written afterward, without echoing
each update in the minibuffer.  Repeated identical states are omitted."
  :type 'boolean :set #'my/context-breadcrumb--set-option)
(defcustom my/context-breadcrumb-debug-max-lines 3000
  "Maximum number of lines retained in the breadcrumb debug buffer."
  :type 'integer)
(defcustom my/context-breadcrumb-language-alist
  '((python-ts-mode . python) (python-mode . python)
    (c++-ts-mode . cpp) (c++-mode . cpp) (c-ts-mode . c) (c-mode . c)
    (rust-ts-mode . rust) (rust-mode . rust)
    (bash-ts-mode . bash) (sh-mode . bash)
    (js-ts-mode . javascript) (typescript-ts-mode . typescript)
    (json-ts-mode . json) (yaml-ts-mode . yaml) (yaml-mode . yaml)
    (tsx-ts-mode . tsx) (java-ts-mode . java) (go-ts-mode . go))
  "Languages to use when a supported buffer does not yet have a parser.
Only already installed grammars are used; no downloads or mode changes."
  :type '(alist :key-type symbol :value-type symbol))

(defface my/context-breadcrumb-name '((t :inherit font-lock-function-name-face))
  "Names of functions and methods.")
(defface my/context-breadcrumb-branch '((t :inherit font-lock-keyword-face))
  "Control-flow sections.")
(defface my/context-breadcrumb-current '((t :weight bold))
  "Innermost section, which is preserved first when space is limited.")
(defface my/context-breadcrumb-text '((t :inherit nil))
  "Neutral text inheriting the bar background, not the full default face.")
(defface my/context-breadcrumb-hover '((t :underline t :box nil))
  "Mouse-over indication without a separate background or box.")

(cl-defstruct (my/context-breadcrumb--entry
               (:constructor my/context-breadcrumb--entry-create))
  kind label short start end hint hint-label hint-start)
(defvar-local my/context-breadcrumb--cache nil)
(defvar-local my/context-breadcrumb--debug-last-key nil)
(defvar my/context-breadcrumb--tracing nil)
(defvar my/context-breadcrumb--debug-queue nil)
(defvar my/context-breadcrumb--debug-queue-size 0)
(defvar my/context-breadcrumb--debug-timer nil)
(defconst my/context-breadcrumb--debug-buffer "*Breadcrumb Debug*")

(defmacro my/context-breadcrumb--log (format-string &rest arguments)
  "Queue a diagnostic only while tracing; skip argument evaluation otherwise."
  `(when my/context-breadcrumb--tracing
     (my/context-breadcrumb--debug-enqueue (format ,format-string ,@arguments))))

(defun my/context-breadcrumb--debug-enqueue (text)
  ;; Never insert into buffers or display messages from mode-line :eval.
  (when (< my/context-breadcrumb--debug-queue-size 1000)
    (push (format "[%s] [%s] %s\n" (format-time-string "%H:%M:%S.%3N")
                  (buffer-name) text)
          my/context-breadcrumb--debug-queue)
    (cl-incf my/context-breadcrumb--debug-queue-size))
  (unless (timerp my/context-breadcrumb--debug-timer)
    (setq my/context-breadcrumb--debug-timer
          (run-with-idle-timer 0.1 nil #'my/context-breadcrumb--debug-flush))))

(defun my/context-breadcrumb--debug-get-buffer ()
  (or (get-buffer my/context-breadcrumb--debug-buffer)
      (with-current-buffer (get-buffer-create my/context-breadcrumb--debug-buffer)
        (special-mode)
        (setq-local truncate-lines t)
        (local-set-key (kbd "C-c . d") #'my/context-breadcrumb-debug-toggle)
        (local-set-key (kbd "C-c . D") #'my/context-breadcrumb-debug-show)
        (current-buffer))))

(defun my/context-breadcrumb--debug-flush ()
  "Write queued diagnostics outside redisplay, keeping the log bounded."
  (when (timerp my/context-breadcrumb--debug-timer)
    (cancel-timer my/context-breadcrumb--debug-timer))
  (setq my/context-breadcrumb--debug-timer nil)
  (when my/context-breadcrumb--debug-queue
    (let ((lines (nreverse my/context-breadcrumb--debug-queue)))
      (setq my/context-breadcrumb--debug-queue nil
            my/context-breadcrumb--debug-queue-size 0)
      (with-current-buffer (my/context-breadcrumb--debug-get-buffer)
        (let ((inhibit-read-only t) (follow (= (point) (point-max))))
          (save-excursion
            (goto-char (point-max))
            (insert (apply #'concat lines))
            (goto-char (point-max))
            (forward-line (- (max 1 my/context-breadcrumb-debug-max-lines)))
            (delete-region (point-min) (point)))
          (when follow (goto-char (point-max)))
          (set-buffer-modified-p nil))))))

(defun my/context-breadcrumb-debug-toggle ()
  "Toggle breadcrumb tracing on/off at runtime, without restarting Emacs."
  (interactive)
  (my/context-breadcrumb--debug-flush)
  (setq my/context-breadcrumb-debug (not my/context-breadcrumb-debug))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (setq my/context-breadcrumb--debug-last-key nil)))
  (my/context-breadcrumb-refresh)
  (message "Breadcrumb debug %s; C-c . D shows the log"
           (if my/context-breadcrumb-debug "ON" "OFF")))

(defun my/context-breadcrumb-debug-show ()
  "Show the syntax-context and formatting decision log."
  (interactive)
  (my/context-breadcrumb--debug-flush)
  (pop-to-buffer (my/context-breadcrumb--debug-get-buffer)))

(defun my/context-breadcrumb-debug-clear ()
  "Clear queued and recorded breadcrumb diagnostics."
  (interactive)
  (when (timerp my/context-breadcrumb--debug-timer)
    (cancel-timer my/context-breadcrumb--debug-timer))
  (setq my/context-breadcrumb--debug-timer nil
        my/context-breadcrumb--debug-queue nil
        my/context-breadcrumb--debug-queue-size 0)
  (when-let* ((buffer (get-buffer my/context-breadcrumb--debug-buffer)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t)) (erase-buffer))))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer (setq my/context-breadcrumb--debug-last-key nil)))
  (message "Breadcrumb debug log cleared"))
(defvar-local my/context-breadcrumb--display "")
(put 'my/context-breadcrumb--display 'risky-local-variable t)
(defvar-local my/context-breadcrumb--saved nil)
(defvar-local my/context-breadcrumb--face-cookies nil)
(defvar-local my/context-breadcrumb--parser nil)
(defvar-local my/context-breadcrumb--owns-parser nil)
(defvar my/context-breadcrumb-mode nil)
(defconst my/context-breadcrumb--format
  '(:eval (progn
            (setq my/context-breadcrumb--display (my/context-breadcrumb-render))
            ;; A symbol's string value is literal: source-code % signs are safe.
            'my/context-breadcrumb--display)))

(defun my/context-breadcrumb--parser ()
  (or (and my/context-breadcrumb--parser
           (memq my/context-breadcrumb--parser (treesit-parser-list))
           my/context-breadcrumb--parser)
      (setq my/context-breadcrumb--parser
            (or (and (boundp 'treesit-primary-parser) treesit-primary-parser)
                (car (treesit-parser-list))
                (let ((lang (alist-get major-mode my/context-breadcrumb-language-alist)))
                  (when (and lang (treesit-available-p)
                             (treesit-language-available-p lang))
                    (setq my/context-breadcrumb--owns-parser t)
                    (treesit-parser-create lang)))))))

(defun my/context-breadcrumb--text (node)
  (when node
    (string-trim
     (replace-regexp-in-string
      "[\n\r\t ]+" " "
      (buffer-substring-no-properties (treesit-node-start node)
                                     (min (treesit-node-end node)
                                          (+ (treesit-node-start node) 240)))))))

(defun my/context-breadcrumb--field (node &rest fields)
  (cl-loop for field in fields
           for child = (treesit-node-child-by-field-name node field)
           when child return child))

(defun my/context-breadcrumb--name (node)
  (let ((name (my/context-breadcrumb--field node "name" "declarator")))
    ;; C/C++ declarators can wrap the actual name several times.
    (while (and name (treesit-node-child-by-field-name name "declarator"))
      (setq name (treesit-node-child-by-field-name name "declarator")))
    (or (my/context-breadcrumb--text name)
        (car (split-string (my/context-breadcrumb--text node) "[({\n]" t)))))

(defun my/context-breadcrumb--macro-call-p (node)
  (when (derived-mode-p 'c-mode 'c++-mode 'c-ts-mode 'c++-ts-mode)
    (let* ((call (treesit-node-child node 0 t))
           (function (and call (treesit-node-child-by-field-name call "function")))
           (name (my/context-breadcrumb--text function)))
      (and name (string-match-p my/context-breadcrumb-macro-name-regexp name)))))

(defun my/context-breadcrumb--catch-labels (node)
  "Describe NODE's catch parameter and a compact form retaining its binding."
  (let* ((parameters (my/context-breadcrumb--field node "parameters"))
         (parameter (and parameters (treesit-node-child parameters 0 t)))
         (declarator (and parameter (my/context-breadcrumb--field parameter "declarator")))
         (binding (my/context-breadcrumb--text declarator)))
    (list 'branch (concat "catch" (or (my/context-breadcrumb--text parameters) "(…)"))
          (concat "catch(…" (when binding (concat " " binding)) ")"))))

(defun my/context-breadcrumb--else-if-p (node)
  "Whether NODE is the direct if in an else-if, without an intervening block."
  (let ((parent (treesit-node-parent node)))
    (and (member (treesit-node-type node) '("if_statement" "if_expression"))
         parent (equal (treesit-node-type parent) "else_clause")
         (treesit-node-eq node (treesit-node-child parent 0 t)))))

(defun my/context-breadcrumb--describe-json (node)
  "Describe a JSON property or zero-based array element at NODE."
  (let ((parent (treesit-node-parent node)))
    (cond
     ((equal (treesit-node-type node) "pair")
      (let ((key (my/context-breadcrumb--text
                  (treesit-node-child-by-field-name node "key"))))
        (when key (list 'property key key))))
     ((and parent (equal (treesit-node-type parent) "array"))
      (let ((index 0) (sibling (treesit-node-prev-sibling node t)))
        (while sibling
          (setq index (1+ index) sibling (treesit-node-prev-sibling sibling t)))
        (let ((label (format "[%d]" index)))
          (list 'array-item label label)))))))

(defun my/context-breadcrumb--describe-yaml (node)
  "Describe YAML mapping keys and zero-based sequence items at NODE."
  (let* ((type (treesit-node-type node))
         (parent (treesit-node-parent node))
         (sequence-types (if (equal type "block_sequence_item")
                             '("block_sequence_item") '("flow_node" "flow_pair"))))
    (cond
     ((member type '("block_mapping_pair" "flow_pair"))
      (when-let* ((key (my/context-breadcrumb--text
                       (treesit-node-child-by-field-name node "key"))))
        (list 'property key key)))
     ((or (equal type "block_sequence_item")
          (and parent (equal (treesit-node-type parent) "flow_sequence")
               (equal type "flow_node")))
      (let ((index 0) (sibling (treesit-node-prev-sibling node t)))
        (while sibling
          ;; Comments do not occupy a sequence index.
          (when (member (treesit-node-type sibling) sequence-types)
            (setq index (1+ index)))
          (setq sibling (treesit-node-prev-sibling sibling t)))
        (let ((label (format "[%d]" index)))
          (list 'array-item label label)))))))

(defun my/context-breadcrumb--describe (node)
  "Return (KIND FULL-LABEL SHORT-LABEL) for a meaningful NODE."
  (let* ((type (treesit-node-type node))
         (condition (my/context-breadcrumb--text
                     (my/context-breadcrumb--field node "condition" "subject" "value")))
         (header (save-excursion
                   (goto-char (treesit-node-start node))
                   (string-trim (buffer-substring-no-properties
                                 (point) (min (line-end-position) (treesit-node-end node)
                                              (+ (point) 200)))))))
    (cond
     ((eq (treesit-language-at (treesit-node-start node)) 'json)
      (my/context-breadcrumb--describe-json node))
     ((eq (treesit-language-at (treesit-node-start node)) 'yaml)
      (my/context-breadcrumb--describe-yaml node))
     ((member type '("class_definition" "class_specifier" "struct_specifier"
                     "class_declaration" "struct_item" "enum_specifier" "enum_item"))
      (list 'class (my/context-breadcrumb--name node) "class"))
     ((member type '("namespace_definition" "namespace_declaration" "mod_item"))
      (let ((name (or (my/context-breadcrumb--text
                       (my/context-breadcrumb--field node "name")) "(anonymous)")))
        (list 'namespace name name)))
     ((member type '("function_definition" "function_declaration" "function_item"
                     "method_definition" "method_declaration" "constructor_declaration"))
      (list 'function (my/context-breadcrumb--name node) "function"))
     ((member type '("if_statement" "if_expression" "elif_clause"))
      (let ((word (cond ((equal type "elif_clause") "elif")
                        ((my/context-breadcrumb--else-if-p node) "else if")
                        (t "if"))))
        (list 'branch (if condition
                          (concat word (if (string-prefix-p "(" condition) "" " ") condition)
                        header) word)))
     ((equal type "catch_clause") (my/context-breadcrumb--catch-labels node))
     ((equal type "else_clause")
      (let* ((parent (treesit-node-parent node))
             (test (my/context-breadcrumb--text
                    (my/context-breadcrumb--field parent "condition"))))
        (list 'branch "else" "else"
              (when test (concat "Else branch; conditional starts with if " test))
              (when test (concat "if" (if (string-prefix-p "(" test) "" " ") test))
              (when test (treesit-node-start parent)))))
     ((member type '("case_statement" "case_clause" "case_item" "match_arm"))
      (let* ((pattern (my/context-breadcrumb--text
                       (or (my/context-breadcrumb--field node "value" "pattern")
                           (treesit-node-child node 0 t))))
             (default (string-match-p "\\`default\\_>" header)))
        (list 'branch (if default "default" (concat "case " (or pattern "?")))
              (if default "default" "case"))))
     ((member type '("switch_statement" "match_statement" "match_expression" "case_statement_bash"))
      (let ((word (if (string-prefix-p "match" type) "match" "switch")))
        (list 'branch (concat word " " (or condition "")) word)))
     ((member type '("for_statement" "for_range_loop" "for_in_statement" "for_expression"
                     "while_statement" "while_expression" "do_statement"
                     "try_statement" "except_clause" "finally_clause"
                     "with_statement" "synchronized_statement"))
      (list 'branch (string-trim-right header "[{: ]+")
            (car (split-string type "_"))))
     ((member type '("return_statement" "raise_statement" "throw_statement"
                     "break_statement" "continue_statement" "expression_statement"
                     "assignment" "lexical_declaration" "local_variable_declaration"))
      (list (if (and (equal type "expression_statement")
                     (my/context-breadcrumb--macro-call-p node)) 'macro 'statement)
            (string-trim-right header ";[ ]*")
            (car (split-string type "_")))))))

(defun my/context-breadcrumb--elisp-p ()
  (derived-mode-p 'emacs-lisp-mode 'lisp-interaction-mode))

(defun my/context-breadcrumb--elisp-end (start)
  "Return the end of the sexp at START, including unfinished forms safely."
  (condition-case nil (or (scan-sexps start 1) (point-max))
    (scan-error (point-max))))

(defun my/context-breadcrumb--elisp-text (start)
  "Extract bounded Lisp source text at START without reading or evaluating it."
  (when start
    (string-trim
     (replace-regexp-in-string
      "[\n\r\t ]+" " "
      (buffer-substring-no-properties
       start (min (my/context-breadcrumb--elisp-end start) (+ start 240)))))))

(defun my/context-breadcrumb--elisp-children (start)
  "Return positions of direct elements in the list at START."
  (save-excursion
    (goto-char (1+ start))
    (let ((limit (my/context-breadcrumb--elisp-end start)) result)
      (while (and (< (point) limit)
                  (progn (forward-comment (point-max))
                         (and (< (point) limit) (not (eq (char-after) ?\))))))
        (push (point) result)
        (let ((next (my/context-breadcrumb--elisp-end (point))))
          (goto-char (max (1+ (point)) next))))
      (nreverse result))))

(defun my/context-breadcrumb--elisp-head (start)
  (when start
    (my/context-breadcrumb--elisp-text
     (car (my/context-breadcrumb--elisp-children start)))))

(defconst my/context-breadcrumb--elisp-functions
  '("defun" "cl-defun" "defmacro" "cl-defmacro" "defsubst" "cl-defsubst"
    "define-inline" "cl-defgeneric" "cl-defmethod" "define-derived-mode"
    "define-minor-mode" "define-globalized-minor-mode" "define-skeleton"))

(defun my/context-breadcrumb--elisp-local-definition-p (start)
  (let* ((parent (nth 1 (syntax-ppss start)))
         (grandparent (and parent (nth 1 (syntax-ppss parent)))))
    (and grandparent
         (member (my/context-breadcrumb--elisp-head grandparent)
                 '("cl-flet" "cl-labels" "cl-macrolet"))
         (eq parent (nth 1 (my/context-breadcrumb--elisp-children grandparent))))))

(defun my/context-breadcrumb--elisp-structural-list-p (start)
  "Whether START is an argument/binding list rather than a function call."
  (let* ((parent (nth 1 (syntax-ppss start)))
         (head (and parent (my/context-breadcrumb--elisp-head parent)))
         (children (and parent (my/context-breadcrumb--elisp-children parent)))
         (grandparent (and parent (nth 1 (syntax-ppss parent)))))
    (or (and (or (member head my/context-breadcrumb--elisp-functions)
                 (equal head "lambda")
                 (and parent (my/context-breadcrumb--elisp-local-definition-p parent)))
             (eq start (nth (if (equal head "lambda") 1 2) children)))
        (and (member head '("let" "let*" "cl-flet" "cl-labels" "cl-macrolet"))
             (eq start (nth 1 children)))
        (and grandparent
             (member (my/context-breadcrumb--elisp-head grandparent) '("let" "let*"))
             (eq parent (nth 1 (my/context-breadcrumb--elisp-children grandparent)))))))

(defun my/context-breadcrumb--describe-elisp (start position)
  "Describe the Lisp form at START for the active POSITION."
  (let* ((children (my/context-breadcrumb--elisp-children start))
         (head (my/context-breadcrumb--elisp-text (car children)))
         (argument (my/context-breadcrumb--elisp-text (nth 1 children)))
         (parent (nth 1 (syntax-ppss start)))
         (parent-head (and parent (my/context-breadcrumb--elisp-head parent)))
         (parent-children (and parent (my/context-breadcrumb--elisp-children parent))))
    (cond
     ((member head '("quote" "function")) nil)
     ((member head my/context-breadcrumb--elisp-functions)
      (list 'function (or argument head) (or argument head)))
     ((my/context-breadcrumb--elisp-local-definition-p start)
      (list 'function head head))
     ((equal head "lambda") (list 'function "lambda" "lambda"))
     ((member head '("cl-defstruct" "defclass" "cl-defclass"))
      (let* ((name-start (nth 1 children))
             (name (if (and name-start (eq (char-after name-start) ?\())
                       (my/context-breadcrumb--elisp-head name-start) argument)))
        (list 'class (or name head) (or name head))))
     ((equal head "defgroup") (list 'namespace (or argument head) (or argument head)))
     ((member head '("defvar" "defvar-local" "defconst" "defcustom"))
      (list 'property (or argument head) (or argument head)))
     ((my/context-breadcrumb--elisp-structural-list-p start) nil)
     ;; Lisp has no else node.  The fourth and later elements of if are else.
     ((equal head "if")
      (if (and (nth 3 children) (>= position (nth 3 children)))
          (list 'branch "else" "else"
                (concat "Else branch of (if " (or argument "…") ")")
                (concat "(if " (or argument "…") ")") start)
        (list 'branch (concat "(if " (or argument "…") ")") "(if)")))
     ((and parent (member parent-head '("cond" "pcase" "cl-case" "cl-ecase" "cl-typecase"))
           (memq start (nthcdr (if (equal parent-head "cond") 1 2) parent-children)))
      (list 'branch (if (equal head "t") "else" (or head "case")) "case"))
     ((and parent (member parent-head '("condition-case" "condition-case-unless-debug"))
           (memq start (nthcdr 3 parent-children)))
      (list 'branch (or head "handler") "handler"))
     ((or (member head '("let" "let*" "when" "unless" "while" "dolist" "dotimes"
                        "cl-loop" "cl-flet" "cl-labels" "cl-macrolet" "and" "or"
                        "pcase-let" "pcase-let*" "if-let" "if-let*" "when-let" "when-let*"
                        "condition-case" "condition-case-unless-debug" "catch"))
          (and head (or (string-prefix-p "with-" head) (string-prefix-p "save-" head))))
      (list 'branch (concat "(" head (when argument (concat " " argument)) ")")
            (concat "(" head ")")))
     ((member head '("cond" "pcase" "cl-case" "cl-ecase" "cl-typecase"
                    "progn" "prog1" "prog2" "unwind-protect" "ignore-errors"))
      (list 'branch (concat "(" head ")") (concat "(" head ")")))
     ((and head (string-match-p "\\`[[:alpha:]_+*/<>=!?-][^()\" \t\n]*\\'" head))
      (list 'statement (or (my/context-breadcrumb--elisp-text start) head) head)))))

(defun my/context-breadcrumb--elisp-entries (&optional position)
  "Collect Lisp context using native syntax parsing, without a grammar."
  (save-excursion
    (let* ((pos (min (max (point-min) (or position (point))) (point-max)))
           (syntax (syntax-ppss pos))
           (open (if (and (not (nth 8 syntax)) (eq (char-after pos) ?\())
                     pos (nth 1 syntax)))
           opens entries leaf literal)
      (while open
        (push open opens)
        (setq open (nth 1 (syntax-ppss open))))
      (my/context-breadcrumb--log "parser=native-elisp; ancestor starts=%S" opens)
      (dolist (start opens)
        (let ((head (and (eq (char-after start) ?\()
                         (my/context-breadcrumb--elisp-head start))))
          (when (or (not (eq (char-after start) ?\())
                    (equal head "quote")
                    (save-excursion
                      (goto-char start) (forward-comment (- (point-max)))
                      (memq (char-before) '(?' ?`))))
            ;; #'(lambda ...) is executable context, unlike quoted data.
            (unless (and (equal head "lambda")
                         (eq (char-before start) ?')
                         (> start (1+ (point-min))) (eq (char-before (1- start)) ?#))
              (setq literal t)))
          (when-let* ((description (and (not literal)
                                       (my/context-breadcrumb--describe-elisp start pos))))
            (my/context-breadcrumb--log "native-elisp start=%d description=%S" start description)
            (let ((entry (my/context-breadcrumb--entry-create
                          :kind (nth 0 description) :label (nth 1 description)
                          :short (nth 2 description) :hint (nth 3 description)
                          :hint-label (nth 4 description) :hint-start (nth 5 description)
                          :start start :end (my/context-breadcrumb--elisp-end start))))
              (if (eq (car description) 'statement)
                  (when my/context-breadcrumb-show-statements (setq leaf entry))
                ;; An enclosing ordinary call is not a leaf inside a new scope.
                (setq leaf nil)
                (push entry entries))))))
      (setq entries (nreverse entries))
      (when leaf (setq entries (append entries (list leaf))))
      (when my/context-breadcrumb-show-file
        (push (my/context-breadcrumb--entry-create
               :kind 'file :label (file-name-nondirectory (or buffer-file-name (buffer-name)))
               :short "file" :start (point-min) :end (point-max)) entries))
      (my/context-breadcrumb--log "native-elisp selected scopes=%S"
                                  (mapcar #'my/context-breadcrumb--entry-label entries))
      entries)))

(defun my/context-breadcrumb--org-entries (&optional position)
  "Collect Org headings and an optional source block using Org's parser."
  (require 'org-element)
  (save-excursion
    (goto-char (min (max (point-min) (or position (point))) (point-max)))
    (let ((node (org-element-context)) entries)
      (while node
        (let* ((type (org-element-type node))
               (start (org-element-property :begin node))
               (end (org-element-property :end node))
               (heading (eq type 'headline))
               (block (and my/context-breadcrumb-show-statements (eq type 'src-block))))
          (when (and (or heading block) start end (>= start (point-min)))
            (let* ((language (and block (org-element-property :language node)))
                   (name (and block (org-element-property :name node)))
                   (label (if heading (or (org-element-property :raw-value node) "Heading")
                            (concat "src" (when language (concat " " language))
                                    (when name (concat ": " name))))))
              (push (my/context-breadcrumb--entry-create
                     :kind (if heading 'heading 'block) :label label :short label
                     :start (if block (or (org-element-property :post-affiliated node) start) start)
                     :end end)
                    entries))))
        (setq node (org-element-property :parent node)))
      (when my/context-breadcrumb-show-file
        (push (my/context-breadcrumb--entry-create
               :kind 'file :label (file-name-nondirectory (or buffer-file-name (buffer-name)))
               :short "file" :start (point-min) :end (point-max)) entries))
      (my/context-breadcrumb--log "parser=native-org; selected scopes=%S"
                                  (mapcar #'my/context-breadcrumb--entry-label entries))
      entries)))

(defun my/context-breadcrumb-entries (&optional position)
  "Collect outer-to-inner context at POSITION with the appropriate parser."
  (cond ((my/context-breadcrumb--elisp-p) (my/context-breadcrumb--elisp-entries position))
        ((derived-mode-p 'org-mode) (my/context-breadcrumb--org-entries position))
        (t (my/context-breadcrumb--treesit-entries position))))

(defun my/context-breadcrumb--treesit-entries (&optional position)
  "Collect outer-to-inner context at POSITION, optionally including the file.
Use the actual branch containing point, not a sibling's condition."
  (when-let* ((parser (my/context-breadcrumb--parser)))
    (let* ((pos (min (max (point-min) (or position (point))) (point-max)))
           (node (treesit-node-at (if (and (= pos (point-max)) (> pos (point-min)))
                                     (1- pos) pos) parser t))
           nodes entries leaf-statement)
      (while node
        (push node nodes)
        (setq node (treesit-node-parent node)))
      (my/context-breadcrumb--log "parser=%s; ancestor nodes=%S"
                                  (treesit-parser-language parser)
                                  (mapcar #'treesit-node-type nodes))
      (cl-loop for tail on nodes
               for current = (car tail)
               for child = (cadr tail)
               for description = (my/context-breadcrumb--describe current)
               for superseded =
               (cond ((and (member (treesit-node-type current) '("if_statement" "if_expression"))
                           child (member (treesit-node-type child) '("elif_clause" "else_clause")))
                      "active elif/else supersedes if")
                     ((and (equal (treesit-node-type current) "else_clause")
                           child (my/context-breadcrumb--else-if-p child))
                      "else wrapper merged into active else if")
                     ((and (equal (treesit-node-type current) "try_statement")
                           child (member (treesit-node-type child)
                                         '("catch_clause" "except_clause" "finally_clause")))
                      "active handler supersedes try"))
               for enabled = (pcase (car description)
                               ('macro (and my/context-breadcrumb-show-statements
                                            my/context-breadcrumb-show-macro-calls))
                               ('statement my/context-breadcrumb-show-statements)
                               (_ t))
               do (my/context-breadcrumb--log
                   "node=%s range=%d..%d => %s; description=%S"
                   (treesit-node-type current) (treesit-node-start current)
                   (treesit-node-end current)
                   (cond (superseded (concat "skip: " superseded))
                         ((and description (not enabled)) "skip: leaf/macro display disabled")
                         (description "candidate") (t "skip: not a context section"))
                   description)
               when (and description enabled (not superseded))
               do (let ((entry (my/context-breadcrumb--entry-create
                                :kind (nth 0 description) :label (nth 1 description)
                                :short (nth 2 description) :hint (nth 3 description)
                                :hint-label (nth 4 description) :hint-start (nth 5 description)
                                :start (treesit-node-start
                                        (if (my/context-breadcrumb--else-if-p current)
                                            (treesit-node-parent current) current))
                                :end (treesit-node-end current))))
                    (if (memq (car description) '(statement macro))
                        (setq leaf-statement entry)
                      (push entry entries))))
      (setq entries (nreverse entries))
      (when leaf-statement (setq entries (append entries (list leaf-statement))))
      (my/context-breadcrumb--log "selected scopes=%S; filename=%s"
                                  (mapcar #'my/context-breadcrumb--entry-label entries)
                                  (if my/context-breadcrumb-show-file "included" "excluded"))
      (if my/context-breadcrumb-show-file
          (cons (my/context-breadcrumb--entry-create
                 :kind 'file :label (file-name-nondirectory (or buffer-file-name (buffer-name)))
                 :short "file" :start (point-min) :end (point-max)) entries)
        entries))))

(defun my/context-breadcrumb--jump (entry &optional buffer window)
  (setq window (my/context-breadcrumb--source-window window))
  (when (buffer-live-p (or buffer (current-buffer)))
    (when (window-live-p window) (select-window window))
    (unless (eq (current-buffer) (or buffer (current-buffer))) (switch-to-buffer buffer))
    (xref-push-marker-stack)
    (goto-char (my/context-breadcrumb--entry-start entry))
    (when (derived-mode-p 'org-mode) (org-fold-show-context))
    (dolist (overlay (overlays-at (point)))
      (when-let* ((open (overlay-get overlay 'isearch-open-invisible)))
        (funcall open overlay)))
    (recenter)
    (pulse-momentary-highlight-one-line (point))))

(defun my/context-breadcrumb--pick (entries &optional window)
  (setq window (my/context-breadcrumb--source-window window))
  (when (window-live-p window) (select-window window))
  (unless entries (user-error "No syntax context at point"))
  (let* ((choices (cl-loop for entry in entries for i from 1
                           collect (cons (format "%d  %s  [line %d]" i
                                                 (my/context-breadcrumb--entry-label entry)
                                                 (line-number-at-pos
                                                  (my/context-breadcrumb--entry-start entry))) entry)))
         (choice (completing-read "Jump to context: " choices nil t)))
    (my/context-breadcrumb--jump (cdr (assoc choice choices)))))

(defun my/context-breadcrumb-choose ()
  "Choose any section of the full, unshortened breadcrumb path."
  (interactive)
  (my/context-breadcrumb--pick (my/context-breadcrumb-entries)))

(defun my/context-breadcrumb-helm ()
  "Navigate the full current breadcrumb path using Helm.
Select with RET; C-g cancels without jumping.  Return with C-c . b.
Helm is loaded on demand and is not required for the ordinary picker."
  (interactive)
  (unless (and (require 'helm nil t) (require 'helm-source nil t))
    (user-error "Helm is unavailable; use C-c . j for the ordinary picker"))
  (let ((entries (my/context-breadcrumb-entries))
        (buffer (current-buffer))
        (window (selected-window)))
    (unless entries (user-error "No syntax context at point"))
    (let* ((candidates
            (cl-loop for entry in entries for index from 1
                     for target = (copy-my/context-breadcrumb--entry entry)
                     for kind = (my/context-breadcrumb--entry-kind entry)
                     for icon = (when (and my/context-breadcrumb-icons
                                           (fboundp 'nerd-icons-codicon))
                                  (if (eq kind 'file)
                                      (my/context-breadcrumb--file-icon 'shadow)
                                    (nerd-icons-codicon
                                     (alist-get kind my/context-breadcrumb--icons))))
                     do (setf (my/context-breadcrumb--entry-start target)
                              (copy-marker (my/context-breadcrumb--entry-start entry)))
                     collect
                     (cons (format "%d %s%s%s  [%s · line %d]%s"
                                   index (make-string (* 2 (1- index)) ?\s)
                                   (if (stringp icon) (concat icon " ") "")
                                   (my/context-breadcrumb--entry-label entry) kind
                                   (line-number-at-pos (my/context-breadcrumb--entry-start entry))
                                   (if (my/context-breadcrumb--hint-visible-p entry window)
                                       (concat "  "
                                               (if (and my/context-breadcrumb-icons
                                                        (fboundp 'nerd-icons-codicon))
                                                   (nerd-icons-codicon "nf-cod-type_hierarchy_sub"
                                                                       :face 'shadow)
                                                 "↳")
                                               " " (my/context-breadcrumb--entry-hint-label entry))
                                     ""))
                           target)))
           (source
            (helm-make-source
             "Breadcrumb context (outermost → innermost)" 'helm-source-sync
             :candidates candidates
             :persistent-action #'ignore
             :persistent-help "RET jumps; C-g cancels"
             :action (list (cons "Jump to section"
                                 (lambda (entry)
                                   (unless (buffer-live-p buffer)
                                     (user-error "Breadcrumb source buffer was closed"))
                                   (my/context-breadcrumb--jump entry buffer window)))))))
      (helm :sources (list source) :buffer "*Helm Breadcrumbs*"
            :prompt "Breadcrumb: "))))

(defun my/context-breadcrumb-parent ()
  "Jump to the nearest enclosing section header before point."
  (interactive)
  (let ((entry (car (last (cl-remove-if-not
                           (lambda (e) (< (my/context-breadcrumb--entry-start e) (point)))
                           (my/context-breadcrumb-entries))))))
    (unless entry (user-error "Already at the outermost section"))
    (my/context-breadcrumb--jump entry)))

(defun my/context-breadcrumb--jump-kind (kind)
  (let ((entry (car (last (cl-remove-if-not
                           (lambda (e) (eq (my/context-breadcrumb--entry-kind e) kind))
                           (my/context-breadcrumb-entries))))))
    (unless entry (user-error "No enclosing %s" kind))
    (my/context-breadcrumb--jump entry)))
(defun my/context-breadcrumb-function ()
  "Jump to the enclosing function or method." (interactive)
  (my/context-breadcrumb--jump-kind 'function))
(defun my/context-breadcrumb-class ()
  "Jump to the enclosing class or struct." (interactive)
  (my/context-breadcrumb--jump-kind 'class))
(defun my/context-breadcrumb-statement ()
  "Jump to the innermost control-flow or statement header." (interactive)
  (let ((entry (car (last (cl-remove-if-not
                           (lambda (e) (memq (my/context-breadcrumb--entry-kind e)
                                             '(branch statement macro block)))
                           (my/context-breadcrumb-entries))))))
    (unless entry (user-error "No enclosing statement"))
    (my/context-breadcrumb--jump entry)))

(defconst my/context-breadcrumb--icons
  '((file . "nf-cod-file_code") (class . "nf-cod-symbol_class")
    (namespace . "nf-cod-symbol_class") (function . "nf-cod-symbol_method")
    (branch . "nf-cod-source_control") (statement . "nf-cod-symbol_event")
    (macro . "nf-cod-symbol_constant")
    (property . "nf-cod-symbol_key") (array-item . "nf-cod-symbol_array")
    (heading . "nf-cod-list_tree") (block . "nf-cod-file_code")))

(defun my/context-breadcrumb--file-icon (face)
  "Choose a known filename icon, then a known major-mode icon, then Codicon."
  (let* ((args (list :face face :height 0.9 :v-adjust 0.0))
         (name (and buffer-file-name (file-name-nondirectory buffer-file-name)))
         (extension (and name (file-name-extension name)))
         (known-file
          (and name (fboundp 'nerd-icons-icon-for-file)
               (or (nerd-icons-match-to-alist name nerd-icons-regexp-icon-alist)
                   (and extension (assoc (downcase extension) nerd-icons-extension-icon-alist)))))
         (known-mode
          (and (fboundp 'nerd-icons-icon-for-mode)
               (cl-some (lambda (mode) (assq mode nerd-icons-mode-icon-alist))
                        (nerd-icons--mode-parents major-mode))))
         (icon (or (and known-file (apply #'nerd-icons-icon-for-file buffer-file-name args))
                   (and known-mode (apply #'nerd-icons-icon-for-mode major-mode args)))))
    (my/context-breadcrumb--log "file icon: filename=%S mode=%s source=%s"
                                name major-mode (cond (known-file 'filename)
                                                     (known-mode 'mode) (t 'fallback)))
    (if (and (stringp icon) (not (string-empty-p icon))) icon
      (apply #'nerd-icons-codicon "nf-cod-file_code" args))))

(defun my/context-breadcrumb--hint-visible-p (entry window)
  "Whether ENTRY's explanatory hint belongs in WINDOW's bar."
  (and (my/context-breadcrumb--entry-hint-label entry)
       (pcase my/context-breadcrumb-else-hints
         ('always t)
         ('offscreen
          (let ((start (my/context-breadcrumb--entry-hint-start entry)))
            (and start (or (invisible-p start)
                           (not (pos-visible-in-window-p start window))))))
         (_ nil))))

(defvar my/context-breadcrumb--compact-render nil)

(defun my/context-breadcrumb--shorten (label width)
  "Fit LABEL into WIDTH columns, retaining identifying suffixes."
  (setq width (max 1 width))
  (cond ((<= (string-width label) width) label)
        ((or (< width 4) (eq my/context-breadcrumb-compression 'truncate))
         (truncate-string-to-width label width nil nil "…"))
        (t
         (let* ((available (1- width))
                (keyword (and (string-match
                               "\\`\\(else if\\|if\\|for\\|while\\|switch\\|return\\|throw\\|raise\\|except\\|catch\\|with\\|case\\|match\\)\\_>" label)
                              (1+ (length (match-string 1 label)))))
                (head (min (1- available)
                           (max (or keyword 1) (floor (* available 0.45)))))
                (tail (- available head))
                (length (string-width label)))
           (concat (truncate-string-to-width label head)
                   "…" (truncate-string-to-width label length (- length tail)))))))

(defun my/context-breadcrumb--face-value (face attribute &optional frame)
  "Resolve ATTRIBUTE in a text FACE specification without buffer remaps."
  (cond
   ((null face) nil)
   ((facep face)
    (let ((value (face-attribute face attribute frame t)))
      (unless (eq value 'unspecified) value)))
   ((keywordp (car-safe face))
    (if (plist-member face attribute) (plist-get face attribute)
      (my/context-breadcrumb--face-value (plist-get face :inherit) attribute frame)))
   ((listp face)
    (cl-loop for part in face
             thereis (my/context-breadcrumb--face-value part attribute frame)))))

(defun my/context-breadcrumb--font (&optional frame)
  "Return explicit, mode-independent font attributes for the current frame."
  (append (copy-sequence my/context-breadcrumb-face-attributes)
          (list :family (or my/context-breadcrumb-font-family
                            (face-attribute 'default :family frame t))
                :height (or my/context-breadcrumb-font-size
                            (face-attribute 'default :height frame t))
                :weight 'normal :slant 'normal :width 'normal
                :underline nil :overline nil :strike-through nil
                :inverse-video nil :box nil)))

(defun my/context-breadcrumb--normalize-text (text &optional frame)
  "Give TEXT fixed typography, retaining syntax colors and icon families."
  (let ((start 0) (base (my/context-breadcrumb--font frame)))
    (while (< start (length text))
      (let* ((end (next-property-change start text (length text)))
             (face (get-text-property start 'face text))
             (family (my/context-breadcrumb--face-value face :family frame))
             (color (my/context-breadcrumb--face-value face :foreground frame))
             (style (copy-sequence base)))
        ;; Only symbol strings explicitly carry a font family.  Syntax
        ;; face families (Org headings in particular) must never leak in.
        (when (get-text-property start 'my/context-breadcrumb-icon text)
          (when family (setq style (plist-put style :family family))))
        (unless (plist-member my/context-breadcrumb-face-attributes :foreground)
          (setq style (plist-put style :foreground
                                 (or color (face-foreground 'default frame t)))))
        (when (and my/context-breadcrumb-current-weight
                   (get-text-property start 'my/context-breadcrumb-current text))
          (setq style (plist-put style :weight my/context-breadcrumb-current-weight)))
        (put-text-property start end 'face style text)
        (setq start end))))
  text)

(defun my/context-breadcrumb--segment (entry width window current)
  (let* ((kind (my/context-breadcrumb--entry-kind entry))
         (reason (cond ((not (eq kind 'branch)) 'scope-or-statement)
                       ((eq my/context-breadcrumb-detail 'always) 'always-expanded)
                       ((not (eq my/context-breadcrumb-detail 'offscreen)) 'compact-policy)
                       ((invisible-p (my/context-breadcrumb--entry-start entry)) 'folded-header)
                       ((not (pos-visible-in-window-p
                              (my/context-breadcrumb--entry-start entry) window)) 'offscreen-header)
                       (t 'visible-header)))
         (detail (not (memq reason '(compact-policy visible-header))))
         (label (if detail (my/context-breadcrumb--entry-label entry)
                  (my/context-breadcrumb--entry-short entry)))
         (face (pcase kind ('function 'my/context-breadcrumb-name)
                      ('class 'font-lock-type-face)
                      ('namespace 'font-lock-constant-face)
                      ('property 'font-lock-property-name-face)
                      ('array-item 'font-lock-number-face)
                      ('heading 'org-level-1)
                      ('block 'font-lock-keyword-face)
                      ('branch 'my/context-breadcrumb-branch)
                      (_ 'my/context-breadcrumb-text)))
         (icon (when (and my/context-breadcrumb-icons
                          (or current (not my/context-breadcrumb--compact-render))
                          (fboundp 'nerd-icons-codicon))
                 (if (eq kind 'file) (my/context-breadcrumb--file-icon face)
                   (nerd-icons-codicon (alist-get kind my/context-breadcrumb--icons)
                                       :face face :height 0.9 :v-adjust 0.0))))
         (hint-visible (and (not my/context-breadcrumb--compact-render)
                            (my/context-breadcrumb--hint-visible-p entry window)))
         (hint (when hint-visible
                 (concat " "
                         (if (and my/context-breadcrumb-icons (fboundp 'nerd-icons-codicon))
                             (propertize (nerd-icons-codicon "nf-cod-type_hierarchy_sub"
                                                 :face 'shadow :height 0.9 :v-adjust 0.0)
                                         'my/context-breadcrumb-icon t)
                           "↳")
                         " " (propertize (my/context-breadcrumb--entry-hint-label entry)
                                           'face 'shadow))))
         (compact-catch
          (and (string-prefix-p "catch(" label)
               (> (+ (string-width label) (if (stringp icon) (+ 1 (string-width icon)) 0)) width)
               (my/context-breadcrumb--entry-short entry)))
         (text (truncate-string-to-width
                (concat (when (stringp icon)
                          (concat (propertize icon 'my/context-breadcrumb-icon t) " "))
                        (propertize
                         (my/context-breadcrumb--shorten
                          (or compact-catch label "?")
                          (- width (if (stringp icon) (+ 1 (string-width icon)) 0)))
                         'face face) hint)
                (max 1 width) nil nil "…"))
         (map (make-sparse-keymap))
         (buffer (current-buffer))
         ;; Markers survive edits made between redisplay and a mouse click.
         (marker (copy-marker (my/context-breadcrumb--entry-start entry)))
         (action (lambda (event)
                   (interactive "e")
                   (when (marker-buffer marker)
                     (let ((target (copy-my/context-breadcrumb--entry entry)))
                       (setf (my/context-breadcrumb--entry-start target) marker)
                       (my/context-breadcrumb--jump target buffer
                                                   (posn-window (event-start event))))))))
    (my/context-breadcrumb--log
     "section kind=%s full=%S chosen=%S reason=%s face=%s icons=%s budget=%d output=%S"
     kind (my/context-breadcrumb--entry-label entry) label reason face
     (and (stringp icon) t) width (substring-no-properties text))
    (when (my/context-breadcrumb--entry-hint entry)
      (my/context-breadcrumb--log "else hint: policy=%s header=%S shown=%s text=%S"
                                  my/context-breadcrumb-else-hints
                                  (my/context-breadcrumb--entry-hint-start entry)
                                  hint-visible hint))
    (when compact-catch
      (my/context-breadcrumb--log "catch shortening: preserve binding via %S" compact-catch))
    (dolist (key '([header-line mouse-1] [mode-line mouse-1] [mouse-1]))
      (define-key map key action))
    (add-text-properties 0 (length text)
                         (list 'local-map map 'mouse-face 'my/context-breadcrumb-hover
                               'help-echo (format "%s%s · line %d · click to jump"
                                                  (my/context-breadcrumb--entry-label entry)
                                                  (if-let* ((hint (my/context-breadcrumb--entry-hint entry)))
                                                      (concat " · " hint) "")
                                                  (line-number-at-pos
                                                   (my/context-breadcrumb--entry-start entry)))) text)
    (when current
      (put-text-property 0 (length text) 'my/context-breadcrumb-current t text))
    (my/context-breadcrumb--normalize-text text (window-frame window))))

(defun my/context-breadcrumb--fit (entries width window)
  "Fit ENTRIES in WIDTH, preserving the innermost context first."
  (let* ((visible entries) (hidden nil)
         (my/context-breadcrumb--compact-render nil)
         (widths (mapcar (lambda (_) my/context-breadcrumb-max-section-width) entries))
         (separator (propertize " › " 'face 'shadow))
         (segments nil)
         (ellipsis (propertize (if (< width 12) "" "… › ") 'face 'shadow)))
    (cl-labels ((build ()
                  (setq segments
                        (cl-loop for entry in visible for size in widths
                                 collect (my/context-breadcrumb--segment
                                          entry size window (eq entry (car (last entries)))))))
                (total () (+ (if hidden (string-width ellipsis) 0)
                             (string-width (mapconcat #'identity segments separator)))))
      (build)
      (my/context-breadcrumb--log "fit: available=%d initial=%d section-limit=%d"
                                  width (total) my/context-breadcrumb-max-section-width)
      (when (> (total) width)
        ;; Remove optional explanations and outer icons before losing scope.
        (setq my/context-breadcrumb--compact-render t)
        (my/context-breadcrumb--log "fit: suppress inline hints and outer icons under pressure")
        (build))
      (when (> (total) width)
        (let* ((desired (mapcar #'string-width segments))
               (minimum
                (cl-loop for entry in visible for wanted in desired
                         collect
                         (min wanted
                              (cond
                               ((string-prefix-p "catch(" (my/context-breadcrumb--entry-label entry))
                                (+ (string-width (my/context-breadcrumb--entry-short entry))
                                   (if (and my/context-breadcrumb-icons
                                            (eq entry (car (last entries)))) 2 0)))
                               ((eq entry (car (last entries))) 18)
                               ((eq (my/context-breadcrumb--entry-kind entry) 'function) 10)
                               (t 8))))))
          (my/context-breadcrumb--log
           "fit: shorten outer sections first; weighted budgets=%S desired=%S" minimum desired)
          (setq widths (copy-sequence minimum))
          (build)
          ;; Keep immediate ancestors before spending space on full outer names.
          (while (and (> (total) width) (> (length visible) 1))
            (my/context-breadcrumb--log "fit: hide outer section %S"
                                        (my/context-breadcrumb--entry-label (car visible)))
            (push (pop visible) hidden)
            (pop desired)
            (pop widths)
            (build))
          (when (> (total) width)
            (setq widths (list (max 1 (- width (if hidden (string-width ellipsis) 0)))))
            (build))
          ;; Give spare columns to the innermost labels first.  Rebuild after
          ;; each allocation because compact catch forms can use less space.
          (cl-loop for index downfrom (1- (length visible)) to 0
                   for spare = (max 0 (- width (total)))
                   do (setf (nth index widths)
                            (+ (nth index widths)
                               (min spare (max 0 (- (nth index desired) (nth index widths))))))
                   do (build))))
      (when (and hidden (not (string-empty-p ellipsis)))
        (let ((map (make-sparse-keymap))
              (buffer (current-buffer)))
          (dolist (key '([header-line mouse-1] [mode-line mouse-1] [mouse-1]))
            (define-key map key (lambda (_event) (interactive "e")
                                  (with-current-buffer buffer
                                    (my/context-breadcrumb--pick entries window)))))
          (add-text-properties 0 (length ellipsis)
                               (list 'local-map map 'mouse-face 'my/context-breadcrumb-hover
                                     'help-echo "Click for all sections, including hidden ancestors") ellipsis)))
      (let ((result (truncate-string-to-width
                     (concat (when hidden ellipsis) (mapconcat #'identity segments separator))
                     (max 1 width) nil nil "…")))
        (my/context-breadcrumb--log "fit result: visible=%S hidden=%S width=%d/%d text=%S"
                                    (mapcar #'my/context-breadcrumb--entry-label visible)
                                    (mapcar #'my/context-breadcrumb--entry-label (reverse hidden))
                                    (string-width result) width (substring-no-properties result))
        (my/context-breadcrumb--normalize-text result (window-frame window))))))

(defun my/context-breadcrumb-render (&optional window)
  "Render context for WINDOW's own point and visible region."
  (let* ((window (or window (selected-window)))
         (pos (window-point window))
         (width (max 1 (- (window-body-width window) 2)))
         (key (list pos (buffer-chars-modified-tick) (window-start window)
                    (window-end window) width my/context-breadcrumb-detail
                    my/context-breadcrumb-compression
                    my/context-breadcrumb-max-section-width my/context-breadcrumb-icons
                    buffer-file-name major-mode my/context-breadcrumb-show-file
                    my/context-breadcrumb-else-hints
                    my/context-breadcrumb-position my/context-breadcrumb-debug
                    my/context-breadcrumb-background my/context-breadcrumb-border
                    (my/context-breadcrumb--font (window-frame window)) my/context-breadcrumb-current-weight
                    (frame-parameter (window-frame window) 'alpha-background)
                    my/context-breadcrumb-show-statements my/context-breadcrumb-show-macro-calls
                    my/context-breadcrumb-macro-name-regexp)))
    (unless my/context-breadcrumb--cache
      (setq my/context-breadcrumb--cache (make-hash-table :test #'eq :weakness 'key)))
    (when (and my/context-breadcrumb-debug (not my/context-breadcrumb--debug-last-key))
      (setq my/context-breadcrumb--debug-last-key (make-hash-table :test #'eq :weakness 'key)))
    (let* ((my/context-breadcrumb--tracing
            (and my/context-breadcrumb-debug
                 (not (equal key (gethash window my/context-breadcrumb--debug-last-key)))))
           (cached (gethash window my/context-breadcrumb--cache)))
      (when my/context-breadcrumb--tracing
        (puthash window key my/context-breadcrumb--debug-last-key))
      (my/context-breadcrumb--log
       "RENDER file=%S mode=%s point=%d line=%d window=%S visible=%d..%S width=%d placement=%s detail=%s show-file=%s"
       buffer-file-name major-mode pos (line-number-at-pos pos) window
       (window-start window) (window-end window) width my/context-breadcrumb-position
       my/context-breadcrumb-detail my/context-breadcrumb-show-file)
      (my/context-breadcrumb--log "appearance: background=%S border=%S font=%S frame-opacity=%S"
                                  my/context-breadcrumb-background my/context-breadcrumb-border
                                  (my/context-breadcrumb--font)
                                  (frame-parameter (window-frame window) 'alpha-background))
      (my/context-breadcrumb--log "leaf filters: statements=%s macro-calls=%s macro-pattern=%S"
                                  my/context-breadcrumb-show-statements my/context-breadcrumb-show-macro-calls
                                  my/context-breadcrumb-macro-name-regexp)
      (if (equal key (car cached))
          (progn (my/context-breadcrumb--log "cache: reuse previous formatted result") (cdr cached))
        (my/context-breadcrumb--log "cache: recompute syntax context and formatting")
        (let ((text (condition-case err
                        (if-let* ((entries (my/context-breadcrumb-entries pos)))
                            (concat " " (my/context-breadcrumb--fit entries width window))
                          (my/context-breadcrumb--log "no sections: no parser or no enclosing syntax scope")
                          "")
                      (error (my/context-breadcrumb--log "RENDER ERROR: %s" (error-message-string err))
                             ""))))
          (puthash window (cons key (or text "")) my/context-breadcrumb--cache)
          (or text ""))))))

(defvar my/context-breadcrumb--bottom-windows (make-hash-table :test #'eq))
(defvar my/context-breadcrumb--bottom-updating nil)
(defvar-local my/context-breadcrumb--bottom-source nil)
(defvar-local my/context-breadcrumb--bottom-status "")
(put 'my/context-breadcrumb--bottom-status 'risky-local-variable t)

(defun my/context-breadcrumb--source-window (window)
  (or (and (window-live-p window)
           (window-parameter window 'my/context-breadcrumb-source)) window))

(defun my/context-breadcrumb--bottom-mode-line ()
  "Format the source window's normal mode line below its breadcrumb."
  (let ((source my/context-breadcrumb--bottom-source))
    (when (window-live-p source)
      (let* ((state (gethash source my/context-breadcrumb--bottom-windows))
             (buffer (window-buffer source))
             (format (or (plist-get state :mode-line-parameter)
                         (buffer-local-value 'mode-line-format buffer)))
             (active (eq (selected-window) source)))
        (with-selected-window source
          (format-mode-line (unless (eq format 'none) format)
                            (if active 'mode-line 'mode-line-inactive) source buffer))))))

(defun my/context-breadcrumb--bottom-remove (source state)
  "Remove a footer and restore SOURCE's window parameters."
  (remhash source my/context-breadcrumb--bottom-windows)
  (when (window-live-p source)
    (set-window-parameter source 'mode-line-format (plist-get state :mode-line-parameter)))
  (let ((footer (plist-get state :window)) (buffer (plist-get state :buffer)))
    (when (window-live-p footer)
      (condition-case nil (delete-window footer) (error nil)))
    (when (buffer-live-p buffer) (kill-buffer buffer))))

(defun my/context-breadcrumb--bottom-create (source)
  "Allocate a two-row footer for SOURCE, if its window is tall enough."
  (when (>= (window-total-height source) 6)
    (let* ((buffer (generate-new-buffer " *Breadcrumb Footer*"))
           (old-parameter (window-parameter source 'mode-line-format))
           footer)
      (condition-case err
          (progn
            (let ((window-min-height 2) (window-size-fixed nil)
                  (window-resize-pixelwise t)
                  (graphical (display-graphic-p (window-frame source))))
              ;; The mode-line border needs two pixels beyond two text rows.
              ;; Terminal windows retain their exact two-row allocation.
              (setq footer
                    (split-window source
                                  (if graphical
                                      (- (+ (* 2 (frame-char-height (window-frame source))) 2))
                                    -2)
                                  'below graphical)))
            (with-current-buffer buffer
              (setq-local my/context-breadcrumb--bottom-source source
                          mode-line-format
                          '((:eval (progn
                                     (setq my/context-breadcrumb--bottom-status
                                           (my/context-breadcrumb--bottom-mode-line))
                                     'my/context-breadcrumb--bottom-status)))
                          header-line-format nil tab-line-format nil
                          display-line-numbers nil cursor-type nil
                          truncate-lines t buffer-read-only t
                          window-size-fixed 'height
                          buffer-undo-list t)
              (local-set-key (kbd "<mouse-1>") #'ignore))
            (set-window-buffer footer buffer)
            (set-window-parameter footer 'my/context-breadcrumb-source source)
            (set-window-parameter footer 'no-other-window t)
            (set-window-parameter footer 'no-delete-other-windows t)
            (set-window-dedicated-p footer t)
            (set-window-fringes footer 0 0)
            (set-window-margins footer 0 0)
            (set-window-parameter source 'mode-line-format 'none)
            (puthash source (list :window footer :buffer buffer
                                  :source-buffer (window-buffer source)
                                  :pixel-height (window-pixel-height footer)
                                  :mode-line-parameter old-parameter)
                     my/context-breadcrumb--bottom-windows))
        (error
         (when (window-live-p footer) (delete-window footer))
         (when (buffer-live-p buffer) (kill-buffer buffer))
         (message "Breadcrumb footer: %s" (error-message-string err)))))))

(defun my/context-breadcrumb--bottom-fit (footer state)
  "Size FOOTER using its actual text and mode-line metrics.
Update STATE after resizing so synchronization preserves the fitted height.
This also corrects existing footers immediately after reloading the code."
  (when (display-graphic-p (window-frame footer))
    (let* ((measured (cdr (window-text-pixel-size footer nil nil nil nil 'mode-line)))
           (minimum (+ (window-default-line-height footer)
                       (window-mode-line-height footer)))
           (height (+ 2 (max measured minimum)))
           (delta (- height (window-pixel-height footer))))
      (unless (zerop delta)
        (let ((window-resize-pixelwise t))
          (condition-case err
              (window-resize footer delta nil t t)
            (error
             (my/context-breadcrumb--log "footer resize: %s" (error-message-string err))))))
      (setf (plist-get state :pixel-height) (window-pixel-height footer)))))

(defun my/context-breadcrumb--bottom-draw (source state)
  (let ((buffer (plist-get state :buffer))
        (footer (plist-get state :window))
        text background box font)
    (with-selected-window source
      (setq font (my/context-breadcrumb--font)
            text (my/context-breadcrumb-render source)
            background (pcase my/context-breadcrumb-background
                         ('editor (face-background 'default nil t))
                         ('theme (face-background 'header-line nil t))
                         (color color))
            box (pcase my/context-breadcrumb-border
                  ('theme (face-attribute 'header-line :box nil t))
                  ((pred stringp) (list :line-width 1 :color my/context-breadcrumb-border))
                  (value value))))
    (with-current-buffer buffer
      (let ((inhibit-read-only t)
            (line (concat text (propertize " " 'face font 'display '(space :align-to right))))
            (remap `((default (:background ,background :box ,box) default))))
        (unless (equal face-remapping-alist remap)
          (setq-local face-remapping-alist remap))
        (unless (equal-including-properties (buffer-string) line)
          (erase-buffer)
          (insert line)
          (set-buffer-modified-p nil))
        (set-window-start footer (point-min))
        (set-window-point footer (point-min))
        (my/context-breadcrumb--bottom-fit footer state)
        (force-mode-line-update)))))

(defun my/context-breadcrumb--bottom-sync (&rest _)
  "Maintain separate breadcrumb/status footers for all bottom source windows."
  (unless my/context-breadcrumb--bottom-updating
    (let ((my/context-breadcrumb--bottom-updating t) stale)
      (let ((source (window-parameter (selected-window) 'my/context-breadcrumb-source)))
        (when (window-live-p source) (select-window source)))
      (maphash
       (lambda (source state)
         (unless (and (window-live-p source)
                      (window-live-p (plist-get state :window))
                      (buffer-live-p (plist-get state :buffer))
                      (let ((source-edges (window-edges source))
                            (footer-edges (window-edges (plist-get state :window))))
                        (and (= (nth 0 source-edges) (nth 0 footer-edges))
                             (= (nth 2 source-edges) (nth 2 footer-edges))
                             (= (nth 3 source-edges) (nth 1 footer-edges))
                             (equal (window-pixel-height (plist-get state :window))
                                    (plist-get state :pixel-height))))
                      (eq (window-buffer source) (plist-get state :source-buffer))
                      (with-current-buffer (window-buffer source)
                        (and my/context-breadcrumb-mode
                             (eq my/context-breadcrumb-position 'bottom))))
           (push (cons source state) stale)))
       my/context-breadcrumb--bottom-windows)
      (dolist (item stale) (my/context-breadcrumb--bottom-remove (car item) (cdr item)))
      (dolist (frame (frame-list))
        (dolist (window (window-list frame 'no-minibuffer))
          (when (and (not (window-parameter window 'my/context-breadcrumb-source))
                     (with-current-buffer (window-buffer window)
                       (and my/context-breadcrumb-mode
                            (eq my/context-breadcrumb-position 'bottom))))
            (unless (gethash window my/context-breadcrumb--bottom-windows)
              (my/context-breadcrumb--bottom-create window)))))
      (maphash (lambda (source state) (my/context-breadcrumb--bottom-draw source state))
               my/context-breadcrumb--bottom-windows))))

(defun my/context-breadcrumb--restore ()
  (when my/context-breadcrumb--saved
    (cl-loop for (variable local value) in my/context-breadcrumb--saved
             when (equal (symbol-value variable) (list my/context-breadcrumb--format))
             do (if local (set (make-local-variable variable) value)
                  (kill-local-variable variable)))))

(defun my/context-breadcrumb--clear-face-remaps ()
  (mapc #'face-remap-remove-relative my/context-breadcrumb--face-cookies)
  (setq my/context-breadcrumb--face-cookies nil))

(defun my/context-breadcrumb--style ()
  "Apply appearance to the entire row without changing global theme faces."
  (my/context-breadcrumb--clear-face-remaps)
  (let* ((background
          (pcase my/context-breadcrumb-background
            ('editor (face-background 'default nil t))
            ('theme 'unspecified)
            (color color)))
         (box (pcase my/context-breadcrumb-border
                ('theme 'unspecified)
                ((pred stringp) (list :line-width 1 :color my/context-breadcrumb-border))
                (value value)))
         (faces (if (eq my/context-breadcrumb-position 'top)
                    '(header-line header-line-active header-line-inactive)
                  nil)))
    (when (and (integerp my/context-breadcrumb-frame-opacity)
               (<= 0 my/context-breadcrumb-frame-opacity 100))
      (set-frame-parameter nil 'alpha-background my/context-breadcrumb-frame-opacity))
    (dolist (face faces)
      (when (facep face)
        (push (apply #'face-remap-add-relative face
                     (append (list :background background :box box)
                             (my/context-breadcrumb--font)))
              my/context-breadcrumb--face-cookies)))))

(defun my/context-breadcrumb--place ()
  (my/context-breadcrumb--restore)
  (when (eq my/context-breadcrumb-position 'top)
    (setq-local header-line-format (list my/context-breadcrumb--format)))
  (my/context-breadcrumb--style)
  (setq my/context-breadcrumb--cache nil
        my/context-breadcrumb--debug-last-key nil)
  (my/context-breadcrumb--bottom-sync)
  (force-mode-line-update))

(defun my/context-breadcrumb-refresh ()
  "Apply changed breadcrumb preferences in all enabled buffers."
  (interactive)
  (dolist (buffer (buffer-list))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (when my/context-breadcrumb-mode (my/context-breadcrumb--place)))))
  ;; A mode-line update alone can leave old background pixels in place.
  ;; This is an explicit preference refresh, not a cursor-motion hook.
  (redraw-display))

(defun my/context-breadcrumb-diagnose-appearance ()
  "Show the current source window's actual frame and breadcrumb settings."
  (interactive)
  (let* ((source (my/context-breadcrumb--source-window (selected-window)))
         (frame (window-frame source))
         (report
          (with-current-buffer (window-buffer source)
            (list :emacs emacs-version :window-system (window-system frame)
                  :source-buffer (buffer-name) :mode major-mode
                  :enabled my/context-breadcrumb-mode
                  :position my/context-breadcrumb-position
                  :frame-alpha (frame-parameter frame 'alpha)
                  :frame-alpha-background (frame-parameter frame 'alpha-background)
                  :frame-background (frame-parameter frame 'background-color)
                  :configured-background my/context-breadcrumb-background
                  :configured-frame-opacity my/context-breadcrumb-frame-opacity
                  :font (my/context-breadcrumb--font frame)
                  :header-line-format header-line-format
                  :source-face-remaps face-remapping-alist
                  :faces
                  (mapcar (lambda (face)
                            (list face (face-all-attributes face frame)))
                          (cl-remove-if-not
                           #'facep '(default header-line header-line-active
                                     header-line-inactive mode-line)))
                  :footer
                  (when-let* ((state (gethash source my/context-breadcrumb--bottom-windows))
                              (buffer (plist-get state :buffer))
                              ((buffer-live-p buffer)))
                    (with-current-buffer buffer
                      (list :remaps face-remapping-alist
                            :text-properties (and (> (point-max) (point-min))
                                                  (text-properties-at (point-min))))))))))
    (with-help-window "*Breadcrumb Appearance*"
      (princ "Breadcrumb appearance report (run after reproducing the issue)\n\n")
      (pp report))))

(defun my/context-breadcrumb--update ()
  "Refresh after cursor movement, edits, or folding commands."
  (setq my/context-breadcrumb--cache nil)
  (force-mode-line-update))

(defun my/context-breadcrumb-toggle-position ()
  "Switch all breadcrumb bars between the top and bottom."
  (interactive)
  (setq my/context-breadcrumb-position
        (if (eq my/context-breadcrumb-position 'top) 'bottom 'top))
  (my/context-breadcrumb-refresh)
  (message "Breadcrumb position: %s" my/context-breadcrumb-position))

(defvar my/context-breadcrumb-mode-map
  (let ((map (make-sparse-keymap)) (prefix (make-sparse-keymap)))
    (define-key map (kbd "C-c .") prefix)
    (dolist (binding '(("j" . my/context-breadcrumb-choose)
                       ("h" . my/context-breadcrumb-helm)
                       ("u" . my/context-breadcrumb-parent)
                       ("f" . my/context-breadcrumb-function)
                       ("c" . my/context-breadcrumb-class)
                       ("s" . my/context-breadcrumb-statement)
                       ("b" . xref-go-back)
                       ("t" . my/context-breadcrumb-toggle-position)
                       ("d" . my/context-breadcrumb-debug-toggle)
                       ("D" . my/context-breadcrumb-debug-show)))
      (define-key prefix (kbd (car binding)) (cdr binding)))
    (dotimes (i 9)
      (let ((index i))
        (define-key prefix (number-to-string (1+ i))
                    (lambda () (interactive)
                      (let ((entry (nth index (my/context-breadcrumb-entries))))
                        (unless entry (user-error "No section %d" (1+ index)))
                        (my/context-breadcrumb--jump entry))))))
    map))

;; Also install new bindings when reloading into an already running session.
(define-key my/context-breadcrumb-mode-map (kbd "C-c . h") #'my/context-breadcrumb-helm)
(define-key my/context-breadcrumb-mode-map (kbd "C-c . d") #'my/context-breadcrumb-debug-toggle)
(define-key my/context-breadcrumb-mode-map (kbd "C-c . D") #'my/context-breadcrumb-debug-show)

(define-minor-mode my/context-breadcrumb-mode
  "Show clickable syntax context with C-c . navigation shortcuts."
  :lighter nil :keymap my/context-breadcrumb-mode-map
  (if my/context-breadcrumb-mode
      (if (not (or (my/context-breadcrumb--elisp-p)
                   (derived-mode-p 'org-mode)
                   (my/context-breadcrumb--parser)))
          (setq my/context-breadcrumb-mode nil)
        (unless my/context-breadcrumb--saved
          (setq my/context-breadcrumb--saved
                (mapcar (lambda (variable)
                          (list variable (local-variable-p variable) (symbol-value variable)))
                        '(header-line-format mode-line-format))))
        (my/context-breadcrumb--place)
        (add-hook 'post-command-hook #'my/context-breadcrumb--update nil t)
        (add-hook 'after-change-functions #'my/context-breadcrumb--after-change nil t))
    (my/context-breadcrumb--restore)
    (my/context-breadcrumb--clear-face-remaps)
    (setq my/context-breadcrumb--saved nil my/context-breadcrumb--cache nil)
    (remove-hook 'post-command-hook #'my/context-breadcrumb--update t)
    (remove-hook 'after-change-functions #'my/context-breadcrumb--after-change t)
    (when (and my/context-breadcrumb--owns-parser my/context-breadcrumb--parser)
      (treesit-parser-delete my/context-breadcrumb--parser)
      (setq my/context-breadcrumb--parser nil my/context-breadcrumb--owns-parser nil))
    (my/context-breadcrumb--bottom-sync)
    (force-mode-line-update)))

(defun my/context-breadcrumb--after-change (&rest _)
  (my/context-breadcrumb--update))

(defun my/context-breadcrumb--turn-on ()
  (when (and (or (derived-mode-p 'prog-mode 'org-mode)
                 (assq major-mode my/context-breadcrumb-language-alist))
             (not (minibufferp)))
    (my/context-breadcrumb-mode 1)))
(define-globalized-minor-mode my/context-breadcrumb-global-mode
  my/context-breadcrumb-mode my/context-breadcrumb--turn-on)

(add-hook 'post-command-hook #'my/context-breadcrumb--bottom-sync)
(add-hook 'window-state-change-functions #'my/context-breadcrumb--bottom-sync)

(provide 'my-context-breadcrumb)
;;; my-context-breadcrumb.el ends here
