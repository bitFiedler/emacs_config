;;; early-init.el --- Early frame geometry -*- lexical-binding: t; -*-

;; Make our modules available before normal initialization.
(add-to-list 'load-path "~/emacstools")
(require 'my-startup-performance)

;; default size
(setq initial-frame-alist
      '((left . 26)
        (top . 23)
        (width . 180)
        (height . 53)))

;; Load geometry management early.
(require 'my-emacs-geometry)

;; Restore geometry before the initial graphical frame is created.
;; The -2 adjustment is an empirically verified workaround for your environment.
;; The logs confirm it works, although they don't establish the underlying cause of the two-column offset.
(let ((geometry (my/geometry-load)))
  (setf (alist-get 'left initial-frame-alist) 26
        (alist-get 'top initial-frame-alist) 23
        (alist-get 'width initial-frame-alist)
        (max 1 (- (plist-get geometry :width) 2))
        (alist-get 'height initial-frame-alist)
        (plist-get geometry :height)))

;; check frame size: M-: (list :width  (frame-pixel-width) :height (frame-pixel-height) :left   (frame-parameter nil 'left) :top    (frame-parameter nil 'top))

;; (list
;;  :frame-width       (frame-width)
;;  :frame-height      (frame-height)
;;  :pixel-width       (frame-pixel-width)
;;  :pixel-height      (frame-pixel-height)
;;  :text-width        (frame-text-width)
;;  :text-height       (frame-text-height)
;;  :char-width        (frame-char-width)
;;  :char-height       (frame-char-height)
;;  :menu-bar-lines    (frame-parameter nil 'menu-bar-lines)
;;  :tool-bar-lines    (frame-parameter nil 'tool-bar-lines)
;;  :tab-bar-lines     (frame-parameter nil 'tab-bar-lines)
;;  :internal-border   (frame-parameter nil 'internal-border-width))


(defcustom my/geometry-debug-file
  (expand-file-name "frame-geometry-debug.log" user-emacs-directory)
  "File used to log frame geometry information."
  :type 'file
  :group 'my-emacs-geometry)

(defun my/geometry-debug-log (&optional stage)
  "Append current frame geometry to the debug log.
STAGE describes when the measurements were taken."
  (when (display-graphic-p)
    (let ((frame-data
           (list
            :frame-width     (frame-width)
            :frame-height    (frame-height)
            :pixel-width     (frame-pixel-width)
            :pixel-height    (frame-pixel-height)
            :text-width      (frame-text-width)
            :text-height     (frame-text-height)
            :char-width      (frame-char-width)
            :char-height     (frame-char-height)
            :menu-bar-lines  (frame-parameter nil 'menu-bar-lines)
            :tool-bar-lines  (frame-parameter nil 'tool-bar-lines)
            :tab-bar-lines   (frame-parameter nil 'tab-bar-lines)
            :internal-border (frame-parameter nil 'internal-border-width)))
          (initial-data
           (list
            :initial-width  (alist-get 'width initial-frame-alist)
            :initial-height (alist-get 'height initial-frame-alist)
            :actual-width   (frame-width)
            :actual-height  (frame-height))))

      (with-temp-buffer
        (insert
         (format "\n=== %s | %s | PID %d ===\n"
                 (format-time-string "%Y-%m-%d %H:%M:%S%z")
                 (or stage "manual")
                 (emacs-pid)))

        (insert "FRAME:\n")
        (pp frame-data (current-buffer))

        (insert "INITIAL:\n")
        (pp initial-data (current-buffer))

        (write-region
         (point-min)
         (point-max)
         my/geometry-debug-file
         t
         'silent)))))

;; (add-hook 'window-setup-hook
;;           (lambda ()
;;             (my/geometry-debug-log "startup")))

;; (add-hook 'kill-emacs-hook
;;           (lambda ()
;;             (my/geometry-debug-log "exit")))

;;; early-init.el ends here
