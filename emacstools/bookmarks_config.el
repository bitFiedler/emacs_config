;;; bookmarks_config.el --- Orange bookmark styling -*- lexical-binding: t; -*-
(use-package bm
  :ensure t
  :config
  (global-set-key (kbd "<f2>") 'bm-toggle)
  (global-set-key (kbd "<C-f2>") 'bm-next)
  (global-set-key (kbd "<S-f2>") 'bm-previous)
  (global-set-key (kbd "<C-S-f2>") 'bm-remove-all-current-buffer)
  ;; Allow cross-buffer 'next'
  (setq bm-cycle-all-buffers t)
  (setq bm-highlight-style 'bm-highlight-line-and-fringe) ;; the first one
  )

;; Key Binding	Action
;; F2	            Toggle a bookmark on an off.
;; Shift F2	        Go Backward to previous bookmark.
;; Ctrl F2	        Go to next bookmark
;; Ctrl Shift F2	Clear all bookmarks in this file.
;; =============================================================================

(require 'hl-line)
(require 'color)
(require 'cl-lib)
(require 'term/tty-colors)

(defcustom my/bookmark-orange "DarkOrange1"
  "Original bookmark orange, used for the ribbon and line tint."
  :type 'color :group 'bm)
(defcustom my/bookmark-line-tint 0.18
  "Orange fraction blended into the hl-line background (0 to 1).
This is a color blend, not separate face opacity.  The actual background
opacity remains the same frame alpha used by hl-line.  After changing
this value, run `my/bookmarks-refresh-appearance'."
  :type 'float :group 'bm)

(defcustom my/bookmark-terminal-markers t
  "Show terminal ribbons and reserve a stable column in editing windows."
  :type 'boolean :group 'bm)
(defcustom my/bookmark-terminal-column-width 1
  "Minimum fixed terminal bookmark column width, in character cells.
Existing left margins are reused. A wider custom symbol may need more cells.
Run `my/bookmarks-refresh-appearance' after changing this value."
  :type 'integer :group 'bm)
(defcustom my/bookmark-terminal-symbol ""
  "Terminal bookmark ribbon (nf-fa-bookmark). The terminal needs a Nerd Font.
Use a simple character such as B if the terminal lacks that font."
  :type 'string :group 'bm)
(defcustom my/bookmark-terminal-low-color "yellow"
  "Bookmark fallback color for terminals with fewer than 256 colors."
  :type 'color :group 'bm)
(defface my/bookmark-terminal-marker
  '((t (:foreground "#FF7F00" :weight normal)))
  "Terminal ribbon with the same orange as the graphical bookmark."
  :group 'bm)

(defun my/bookmarks-color-rgb (name &optional frame)
  "Resolve NAME before terminal palette approximation, optionally on FRAME."
  (when (stringp name)
    (let ((standard (tty-color-standard-values (downcase name))))
      (if standard
          (mapcar (lambda (value) (/ value 65535.0)) standard)
        (color-name-to-rgb name (and (framep frame) frame))))))

(defun my/bookmarks-line-background (frame)
  "Return a subtle orange tint over FRAME's hl-line background."
  (let* ((base (or (my/bookmarks-color-rgb (face-background hl-line-face frame t) frame)
                   (my/bookmarks-color-rgb (face-background 'default frame t) frame)
                   '(0.0 0.0 0.0)))
         (orange (or (my/bookmarks-color-rgb my/bookmark-orange frame) '(1.0 0.5 0.0)))
         (amount (max 0.0 (min 1.0 my/bookmark-line-tint))))
    (apply #'color-rgb-to-hex
           (append (cl-mapcar (lambda (a b) (+ (* amount a) (* (- 1 amount) b)))
                              orange base)
                   '(2)))))

(defvar my/bookmarks--terminal-overlays nil
  "Window-specific terminal ribbons owned by this configuration.")
(defvar my/bookmarks--refreshing nil
  "Guard against recursive window changes during marker refresh.")

(defun my/bookmarks--terminal-margin (window active width)
  "Keep a stable WIDTH-column gutter on an ACTIVE WINDOW, reusing margins."
  (let* ((saved (window-parameter window 'my/bookmark-original-margins))
         (installed (window-parameter window 'my/bookmark-installed-margins))
         (current (window-margins window)))
    (if active
        (let* ((original (if (and saved (equal current installed)) (cdr saved) current))
               (desired (cons (max (or (car original) 0) width) (cdr original))))
          (set-window-parameter window 'my/bookmark-original-margins (cons t original))
          (set-window-parameter window 'my/bookmark-installed-margins desired)
          (unless (equal current desired)
            (set-window-margins window (car desired) (cdr desired))))
      (when saved
        (when (equal current installed)
          (set-window-margins window (cadr saved) (cddr saved)))
        (set-window-parameter window 'my/bookmark-original-margins nil)
        (set-window-parameter window 'my/bookmark-installed-margins nil)))))

(defun my/bookmarks--editing-window-p (window)
  "Whether WINDOW is an editing window that needs a stable marker column."
  (with-current-buffer (window-buffer window)
    (if (fboundp 'my/editing-line-numbers-buffer-p)
        (my/editing-line-numbers-buffer-p)
      (and (not (minibufferp))
           (not (string-prefix-p " " (buffer-name)))
           (not (string-prefix-p "*helm" (downcase (buffer-name))))
           (not (derived-mode-p 'special-mode 'dired-mode 'comint-mode
                                'term-mode 'vterm-mode 'eshell-mode))
           (or buffer-file-name
               (derived-mode-p 'prog-mode 'text-mode 'conf-mode 'fundamental-mode))))))

(defun my/bookmarks-refresh-terminal-markers (&rest _)
  "Refresh window-specific terminal ribbons while preserving existing margins."
  (unless my/bookmarks--refreshing
    (let ((my/bookmarks--refreshing t))
      (mapc #'delete-overlay my/bookmarks--terminal-overlays)
      (setq my/bookmarks--terminal-overlays nil)
      (dolist (frame (frame-list))
        (dolist (window (window-list frame 'no-minibuffer))
          (let ((bookmarks
                 (when (and my/bookmark-terminal-markers
                            (not (display-graphic-p frame)))
                   (with-current-buffer (window-buffer window)
                     (save-restriction
                       (widen)
                       (let ((lists (bm-lists))) (append (car lists) (cdr lists))))))))
            (my/bookmarks--terminal-margin
             window
             (and my/bookmark-terminal-markers (not (display-graphic-p frame))
                  (or bookmarks (my/bookmarks--editing-window-p window)))
             (max 1 my/bookmark-terminal-column-width
                  (string-width my/bookmark-terminal-symbol)))
            (dolist (bookmark bookmarks)
              (let* ((marker (make-overlay (overlay-start bookmark) (overlay-end bookmark)
                                            (overlay-buffer bookmark)))
                     (icon (propertize my/bookmark-terminal-symbol
                                       'face 'my/bookmark-terminal-marker)))
                (overlay-put marker 'window window)
                (overlay-put marker 'my/bookmark-terminal t)
                (overlay-put marker 'before-string
                             (propertize " " 'display `((margin left-margin) ,icon)))
                (push marker my/bookmarks--terminal-overlays)))))))))

(defun my/bookmarks--after-edit (_overlay after &rest _)
  "Follow the bookmark after its upstream edit hook adjusts its bounds."
  (when after (my/bookmarks-refresh-terminal-markers)))

(dolist (function '(bm-bookmark-add bm-bookmark-remove bm-redraw-bookmarks))
  (unless (advice-member-p #'my/bookmarks-refresh-terminal-markers function)
    (advice-add function :after #'my/bookmarks-refresh-terminal-markers)))
(dolist (function '(bm-freeze bm-freeze-in-front))
  (unless (advice-member-p #'my/bookmarks--after-edit function)
    (advice-add function :after #'my/bookmarks--after-edit)))
(add-hook 'window-state-change-functions #'my/bookmarks-refresh-terminal-markers)

;; Original orange ribbon; hl-line-like tint instead of a solid color slab.
(defun my/bookmarks-refresh-appearance (&rest _)
  "Apply bookmark colors and ribbon markers, including existing bookmarks."
  (interactive)
  ;; Apply future-frame defaults separately; nil would rewrite every frame.
  (dolist (frame (cons t (frame-list)))
    (let* ((limited (and (framep frame) (not (display-graphic-p frame))
                         (< (display-color-cells frame) 256)))
           (orange (apply #'color-rgb-to-hex
                          (append (or (my/bookmarks-color-rgb my/bookmark-orange frame)
                                      '(1.0 0.5 0.0)) '(2))))
           (background (if limited my/bookmark-terminal-low-color
                         (my/bookmarks-line-background frame)))
           (foreground (if limited "black" 'unspecified)))
      (dolist (face '(bm-face bm-persistent-face))
        (set-face-attribute face frame :background background :foreground foreground
                            :box nil :inverse-video nil))
      (dolist (face '(bm-fringe-face bm-fringe-persistent-face my/bookmark-terminal-marker))
        (set-face-attribute face frame
                            :foreground (if limited my/bookmark-terminal-low-color orange)
                            :background 'unspecified :box nil :inverse-video nil))))
  (set-face-attribute 'my/bookmark-terminal-marker nil :weight 'normal)
  (set-face-attribute 'my/bookmark-terminal-marker t :weight 'normal)
  ;; Fringe markers cannot display font glyphs.  This 8x16 bitmap is
  ;; rasterized from Nerd Font nf-fa-bookmark (U+F02E), NFM.ttf.
  ;; It fits the existing fringe without adding a margin or moving text.
  (when (fboundp 'define-fringe-bitmap)
    (dolist (marker '(bm-marker-left bm-marker-right))
      (define-fringe-bitmap marker
        [#x00 #x00 #xFF #xFF #xFF #xFF #xFF #xFF
         #xFF #xFF #xFF #xE7 #x81 #x00 #x00 #x00]
        16 8 'center)))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (> (bm-count) 0)
        (bm-redraw-bookmarks))))
  (my/bookmarks-refresh-terminal-markers)
  (force-mode-line-update t))

(add-hook 'enable-theme-functions #'my/bookmarks-refresh-appearance)
(add-hook 'after-make-frame-functions #'my/bookmarks-refresh-appearance)
(my/bookmarks-refresh-appearance)
