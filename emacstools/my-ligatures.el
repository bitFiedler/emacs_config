;;; my-ligatures.el --- Personal JetBrains Mono ligature setup -*- lexical-binding: t; -*-

;; Prefer an installed library; otherwise use the existing upstream checkout.
(unless (locate-library "ligature")
  (let ((checkout (expand-file-name "~/emacstools/ligature.el")))
    (when (file-readable-p (expand-file-name "ligature.el" checkout))
      (add-to-list 'load-path checkout))))
(require 'ligature)
(require 'font-lock)
(require 'seq)

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

(defcustom my/ligatures-in-c-comments nil
  "Whether C/C++ comments may use ligature shaping and arrow gaps.
Comment colors are always preserved, regardless of this option.
Run `my/apply-ligatures' after changing this option."
  :type 'boolean :group 'my/ligatures)

(defun my/ligatures--face-inherits-p (face bases &optional seen)
  "Whether FACE inherits one of BASES, without following inheritance cycles."
  (cond
   ((memq face bases) t)
   ((and (symbolp face) (facep face) (not (memq face seen)))
    (my/ligatures--face-inherits-p (face-attribute face :inherit nil) bases
                                  (cons face seen)))
   ((listp face)
    (seq-some (lambda (item) (my/ligatures--face-inherits-p item bases seen)) face))))

(defun my/ligatures--context-p (start end slot faces)
  "Recognize START..END using syntax SLOT or any inherited FACES."
  (save-match-data
    (save-excursion
      (or (nth slot (syntax-ppss start))
          (nth slot (syntax-ppss end))
          (let ((position start) found)
            (while (and (< position end) (not found))
              (setq found
                    (or (my/ligatures--face-inherits-p
                         (get-text-property position 'face) faces)
                        (my/ligatures--face-inherits-p
                         (get-text-property position 'font-lock-face) faces)))
              (setq position (next-property-change position nil end)))
            found)))))

(defun my/ligatures--comment-p (start end)
  "Recognize comments by syntax or inherited comment/documentation faces."
  (my/ligatures--context-p start end 4
                          '(font-lock-comment-face font-lock-comment-delimiter-face
                            font-lock-doc-face font-lock-doc-markup-face)))

(defun my/ligatures--string-p (start end)
  "Recognize strings by syntax or inherited string faces in any mode."
  (my/ligatures--context-p start end 3 '(font-lock-string-face)))

(defun my/ligatures--c-comment-p (start end)
  "Whether START..END belongs to a C/C++ comment, including its opener."
  (and (not my/ligatures-in-c-comments)
       (derived-mode-p 'c-mode 'c++-mode 'c-ts-mode 'c++-ts-mode 'objc-mode)
       (save-match-data
         (save-excursion
           ;; Looking past two characters includes /* and // delimiters.
           (or (nth 4 (syntax-ppss start))
               (nth 4 (syntax-ppss (min end (+ start 2)))))))))

(defun my/ligatures--org-heading-marker-p (start end)
  "Whether START..END overlaps the leading stars of an Org heading."
  (and (derived-mode-p 'org-mode)
       (save-match-data
         (save-excursion
           (goto-char start)
           (beginning-of-line)
           (and (looking-at "\\(\\*+\\)[ \t]")
                (< start (match-end 1))
                (> end (match-beginning 1)))))))

(defun my/ligatures--compose (original function from to font string direction)
  "Suppress configured ligatures in C/C++ comments and Org heading markers."
  (unless (and (null string)
               (eq function 'font-shape-gstring)
               (or (my/ligatures--c-comment-p from to)
                   (my/ligatures--org-heading-marker-p from to))
               (member (buffer-substring-no-properties from to)
                       my/ligature-sequences))
    (funcall original function from to font string direction)))

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
                 (gap (unless (my/ligatures--c-comment-p (match-beginning 0) (match-end 0))
                        (make-overlay position (1+ position)))))
            (when gap
              (overlay-put gap 'my/ligature-gap t)
              (overlay-put gap 'evaporate t)
              (overlay-put gap 'before-string
                           (propertize " " 'display
                                       `(space :width ,my/ligature-arrow-gap)))))))))
  ;; This matcher manages overlays; it does not apply a text face.
  nil)

(defvar-local my/ligatures--font-lock-keywords nil
  "Legacy keyword rules to remove when reloading an older module version.")

(defvar-local my/ligatures--style-regexp nil
  "Regexp of configured sequences to style after syntax and semantic faces.")

(defun my/ligatures--fontify-after (original start end &optional loudly)
  "Run ORIGINAL, then style ligatures after all syntax/semantic fontification.
Preserve ORIGINAL's return value and expanded jit-lock bounds. This local
wrapper keeps Eglot's later semantic operator face from taking precedence."
  (let* ((result (funcall original start end loudly))
         (bounds (and (consp result) (eq (car result) 'jit-lock-bounds) result))
         (begin (max (point-min) (if bounds (nth 1 bounds) start)))
         (finish (min (point-max) (if bounds (cddr bounds) end))))
    (save-excursion
      (save-match-data
        (with-silent-modifications
          (when my/ligatures--style-regexp
            (goto-char begin)
            (while (re-search-forward my/ligatures--style-regexp finish t)
              (unless (or (derived-mode-p 'org-mode)
                          (my/ligatures--comment-p (match-beginning 0) (match-end 0))
                          (my/ligatures--string-p (match-beginning 0) (match-end 0)))
                (add-face-text-property (match-beginning 0) (match-end 0)
                                        'my/ligature-symbol))))
          (when my/ligatures--arrow-regexp
            (goto-char begin)
            (my/ligatures--space-matcher finish)))))
    result))

(defun my/ligatures--sync-style ()
  "Refresh this buffer's final ligature styling and display-only arrow spacing."
  (remove-function (local 'font-lock-fontify-region-function)
                   #'my/ligatures--fontify-after)
  (remove-function (local 'auto-composition-function) #'my/ligatures--compose)
  (when ligature-mode
    (add-function :around (local 'auto-composition-function) #'my/ligatures--compose))
  (when my/ligatures--font-lock-keywords
    (font-lock-remove-keywords nil my/ligatures--font-lock-keywords)
    (setq my/ligatures--font-lock-keywords nil))
  (save-restriction
    (widen)
    (remove-overlays (point-min) (point-max) 'my/ligature-gap t))
  (setq my/ligatures--arrow-regexp nil
        my/ligatures--style-regexp nil)
  (when (and ligature-mode my/ligature-sequences
             (or (eq my/ligature-modes t)
                 (apply #'derived-mode-p my/ligature-modes)))
    (when my/ligatures-highlight
      (setq my/ligatures--style-regexp (regexp-opt my/ligature-sequences)))
    (when (> my/ligature-arrow-gap 0)
      (let ((arrows (delq nil (mapcar (lambda (arrow)
					(and (member arrow my/ligature-sequences) arrow))
                                      '("->" "->>" "<-" "<->" "=>" "<=>")))))
        (when arrows
          (setq my/ligatures--arrow-regexp
                (concat (regexp-opt arrows) "\\(\\sw\\|\\s_\\)")))))
    (when (or my/ligatures--style-regexp my/ligatures--arrow-regexp)
      (font-lock-set-defaults)
      (add-function :around (local 'font-lock-fontify-region-function)
                    #'my/ligatures--fontify-after)))
  (when font-lock-mode
    (font-lock-flush)))

(defun my/ligatures--font-lock-state ()
  "Refresh local integration after font-lock toggles."
  (if font-lock-mode
      (my/ligatures--sync-style)
    (remove-function (local 'font-lock-fontify-region-function)
                     #'my/ligatures--fontify-after)
    (save-restriction
      (widen)
      (remove-overlays (point-min) (point-max) 'my/ligature-gap t))))

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
