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

(defcustom my/bookmark-orange "DarkOrange1"
  "Original bookmark orange, used for the ribbon and line tint."
  :type 'color :group 'bm)
(defcustom my/bookmark-line-tint 0.18
  "Orange fraction blended into the hl-line background (0 to 1).
This is a color blend, not separate face opacity.  The actual background
opacity remains the same frame alpha used by hl-line.  After changing
this value, run `my/bookmarks-refresh-appearance'."
  :type 'float :group 'bm)

(defun my/bookmarks-line-background (frame)
  "Return a subtle orange tint over FRAME's hl-line background."
  (let* ((base (or (color-name-to-rgb (or (face-background hl-line-face frame t) ""))
                   (color-name-to-rgb (or (face-background 'default frame t) ""))
                   '(0.0 0.0 0.0)))
         (orange (or (color-name-to-rgb my/bookmark-orange) '(1.0 0.5 0.0)))
         (amount (max 0.0 (min 1.0 my/bookmark-line-tint))))
    (apply #'color-rgb-to-hex
           (append (cl-mapcar (lambda (a b) (+ (* amount a) (* (- 1 amount) b)))
                              orange base)
                   '(2)))))

;; Original orange ribbon; hl-line-like tint instead of a solid color slab.
(defun my/bookmarks-refresh-appearance (&rest _)
  "Apply bookmark colors and ribbon markers, including existing bookmarks."
  (interactive)
  (dolist (frame (cons nil (frame-list)))
    (dolist (face '(bm-face bm-persistent-face))
      (set-face-attribute face frame
                          :background (my/bookmarks-line-background frame)
                          :foreground 'unspecified :box nil :inverse-video nil))
    (dolist (face '(bm-fringe-face bm-fringe-persistent-face))
      (set-face-attribute face frame :foreground my/bookmark-orange
                          :background 'unspecified :box nil :inverse-video nil)))
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
  (force-mode-line-update t))

(add-hook 'enable-theme-functions #'my/bookmarks-refresh-appearance)
(add-hook 'after-make-frame-functions #'my/bookmarks-refresh-appearance)
(my/bookmarks-refresh-appearance)
