;;; my-ligatures.el --- Personal JetBrains Mono ligature setup -*- lexical-binding: t; -*-

;; Prefer an installed library; otherwise use the existing upstream checkout.
(unless (locate-library "ligature")
  (let ((checkout (expand-file-name "~/emacstools/ligature.el")))
    (when (file-readable-p (expand-file-name "ligature.el" checkout))
      (add-to-list 'load-path checkout))))
(require 'ligature)

(defgroup my/ligatures nil
  "Display ligatures with the configured editing font."
  :group 'faces)

(defcustom my/ligatures-enabled t
  "Whether `my/apply-ligatures' enables ligature display."
  :type 'boolean :group 'my/ligatures)

(defcustom my/ligature-modes '(prog-mode text-mode conf-mode)
  "Modes whose buffers display ligatures, including their descendants.
Set to t for all major modes. Run `my/apply-ligatures' after changing."
  :type '(choice (const :tag "All modes" t) (repeat symbol))
  :group 'my/ligatures)

(defconst my/ligature-default-sequences
  '("->" "->>" "<-" "<->" "=>" "==" "===" "!=" "!=="
    "<=" ">=" "<=>" "::" ":=" "&&" "||" "++" "--" "**"
    "<<" ">>" "<<=" ">>=" "..." ".." "<!--" "-->" "</" "/>" "://")
  "Full personal JetBrains Mono ligature set.")

(defcustom my/ligature-sequences my/ligature-default-sequences
  "Character sequences offered to the font's ligature shaping engine.
Only combinations supported by the font can be shaped. Buffer text is
unchanged. Run `my/apply-ligatures' after changing this list."
  :type '(repeat string) :group 'my/ligatures)

(defface my/ligature-symbol
  '((t (:foreground "#D0D0D0" :weight bold)))
  "Face for configured ligature sequences; preserves font family and background."
  :group 'my/ligatures)

(defcustom my/ligatures-highlight t
  "Whether configured ligature sequences use `my/ligature-symbol'.
Run `my/apply-ligatures' after changing this option."
  :type 'boolean :group 'my/ligatures)

(defcustom my/ligature-arrow-gap 0.2
  "Extra display width after an arrow immediately followed by a word.
Measured in character widths; 0 disables the gap. This inserts no text.
Run `my/apply-ligatures' after changing the value. Fractional spacing
is intended for graphical Emacs; terminals may round its width."
  :type 'number :group 'my/ligatures)

(defvar-local my/ligatures--arrow-regexp nil
  "Regexp matching an enabled arrow followed immediately by a word.")

(defun my/ligatures--space-matcher (limit)
  "Refresh display-only arrow gaps in the fontification region to LIMIT."
  (when my/ligatures--arrow-regexp
    (save-excursion
      ;; Include nearby arrows when an edit splits or rejoins a boundary.
      (let ((start (max (point-min) (- (point) 4)))
            (end (min (point-max) (+ limit 4))))
        (remove-overlays start end 'my/ligature-gap t)
        (goto-char start)
        (while (re-search-forward my/ligatures--arrow-regexp end t)
          (let* ((position (match-beginning 1))
                 (gap (make-overlay position (1+ position))))
            (overlay-put gap 'my/ligature-gap t)
            (overlay-put gap 'evaporate t)
            (overlay-put gap 'before-string
                         (propertize " " 'display
                                     `(space :width ,my/ligature-arrow-gap))))))))
  ;; This matcher manages overlays; it does not apply a text face.
  nil)

(defvar-local my/ligatures--font-lock-keywords nil
  "Font-lock rules currently installed by this module.")

(defun my/ligatures--sync-style ()
  "Refresh this buffer's ligature face and display-only arrow spacing."
  (when my/ligatures--font-lock-keywords
    (font-lock-remove-keywords nil my/ligatures--font-lock-keywords)
    (setq my/ligatures--font-lock-keywords nil))
  (remove-overlays (point-min) (point-max) 'my/ligature-gap t)
  (setq my/ligatures--arrow-regexp nil)
  (when (and ligature-mode my/ligature-sequences
             (or (eq my/ligature-modes t)
                 (apply #'derived-mode-p my/ligature-modes)))
    (when my/ligatures-highlight
      (push `(,(regexp-opt my/ligature-sequences) (0 'my/ligature-symbol prepend))
            my/ligatures--font-lock-keywords))
    (when (> my/ligature-arrow-gap 0)
      (let ((arrows (delq nil (mapcar (lambda (arrow)
                                       (and (member arrow my/ligature-sequences) arrow))
                                     '("->" "->>" "<-" "<->" "=>" "<=>")))))
        (when arrows
          (setq my/ligatures--arrow-regexp
                (concat (regexp-opt arrows) "\\(\\sw\\|\\s_\\)"))
          (push '(my/ligatures--space-matcher (0 nil))
                my/ligatures--font-lock-keywords))))
    (when my/ligatures--font-lock-keywords
      (font-lock-add-keywords nil (reverse my/ligatures--font-lock-keywords) 'append)))
  (when font-lock-mode
    (font-lock-flush)))

(defun my/ligatures--font-lock-state ()
  "Remove display gaps when font-lock is disabled."
  (unless font-lock-mode
    (remove-overlays (point-min) (point-max) 'my/ligature-gap t)))

(add-hook 'font-lock-mode-hook #'my/ligatures--font-lock-state)

(add-hook 'ligature-mode-hook #'my/ligatures--sync-style)

(defun my/ligatures-use-full-set ()
  "Restore the full ligature set and enable its light gray, bold styling."
  (interactive)
  (setq my/ligature-sequences (copy-sequence my/ligature-default-sequences)
        my/ligatures-enabled t
        my/ligatures-highlight t)
  (my/apply-ligatures))

(defvar my/ligatures--registered-modes nil
  "The mode selector previously registered by this module.")

(defun my/apply-ligatures ()
  "Apply personal ligature settings to existing and future buffers.
Use `ligature-mode' to toggle an individual buffer, or
`global-ligature-mode' to toggle the upstream mode globally."
  (interactive)
  (when my/ligatures--registered-modes
    (setq ligature-composition-table
          (assoc-delete-all my/ligatures--registered-modes
                            ligature-composition-table #'equal)))
  (setq my/ligatures--registered-modes (copy-tree my/ligature-modes))
  (when my/ligature-modes
    (ligature-set-ligatures my/ligature-modes my/ligature-sequences))
  ;; Rebuild buffer-local composition tables when settings change.
  (when global-ligature-mode (global-ligature-mode -1))
  (global-ligature-mode (if my/ligatures-enabled 1 -1)))

(my/apply-ligatures)

(provide 'my-ligatures)
;;; my-ligatures.el ends here
