;; ;; early black theme
;; ;; diable things
;; (if (display-graphic-p)
;;     (progn
;;       (load-theme 'alect-black t)
;;       (menu-bar-mode -1)
;;       (scroll-bar-mode -1)
;;       (tool-bar-mode -1)
;;       (set-frame-parameter nil 'alpha-background 90) ; For current frame
;;       (add-to-list 'default-frame-alist '(alpha-background . 90)) ; For all new frames henceforth
;;       ;;(minimap-mode 1)
;;       )
;;   (progn
;;     (load-theme 'tsdh-dark t)
;;     )
;;   )

;; (blink-cursor-mode -1)
;; (column-number-mode t)
;; (delete-selection-mode 1)

;; ;; disable visual bell
;; (setq ring-bell-function 'ignore)

;; (setq inhibit-startup-message t)
;; (setq inhibit-startup-echo-area-message t)

;; ;; Get rid of yes-or-no questions
;; (fset 'yes-or-no-p 'y-or-n-p)  

;; ;;; automatic line numbes
;; ;; set max 150 char for text
;; (add-hook 'prog-mode-hook
;;           (lambda ()
;;             (display-line-numbers-mode 1)
;;             (setq fill-column 150)
;;             (auto-fill-mode 1)))

;; (add-hook 'conf-windows-mode-hook
;;           (lambda ()
;;             (display-line-numbers-mode 1)
;;             (setq fill-column 150)
;;             (auto-fill-mode 1)))

;; (add-hook 'text-mode-hook
;;           (lambda ()
;;             (display-line-numbers-mode 1)
;;             (setq fill-column 150)
;;             (auto-fill-mode 1)))

;; ;;(setq debug-on-signal t debug-on-error t)
;; ;; (setq gc-cons-threshold 100000000)
;; ;; (setq read-process-output-max (* 1024 1024)) ;; 1mb

;; ;; ============================== my window setting ============================
;; (setq frame-icon-title-format "Emacs")
;; (setq frame-title-format
;;       '("%S: " (buffer-file-name "%f" (dired-directory dired-directory "%b"))))


;; ;; (set-face-attribute 'default nil
;; ;;                   :family "JetBrainsMono Nerd Font"
;; ;;                   :height 100
;; ;;                   :weight 'normal
;; ;;                   :width 'normal)

;; ;; font & font size
;; (defun fontify-frame (frame)
;;   ;;(set-frame-parameter frame 'font "DejaVu Sans Mono-10"))
;;   (set-frame-parameter frame 'font "JetBrains Mono-10"))

;; ;; Fontify current frame
;; (fontify-frame nil)
;; ;; Fontify any future frames
;; (push 'fontify-frame after-make-frame-functions)

;; ;;(setq initial-frame-alist (quote ((top . 80) (left . 100) (width . 190) (height . 45))))
;; (setq initial-frame-alist (quote ((width . 190) (height . 45))))

;; (setq initial-scratch-message nil)          ;; Remove the message in the *scratch* buffer
;; (setq inhibit-startup-echo-area-message user-login-name)  ;; Suppress echo area messages
;; (setq inhibit-startup-buffer-menu t)        ;; Disable the buffer menu on startup
;; (setq inhibit-startup-message t)            ;; Disable the initial startup message
;; (setq inhibit-startup-screen t)             ;; Disable the splash screen
;; ;; Hide advertisement from minibuffer
;; (defun display-startup-echo-area-message ()
;;   (message ""))

;; ;; display date and time always
;; (setq display-time-day-and-date t
;;       display-time-24hr-format t)
;; ;;(display-time)

;; ;; highlight line 
;; (setq global-hl-line-mode t)

;; ;; Make some buffers immortal
;; (defun ndw-immortal-buffers ()
;;   (if (or (eq (current-buffer) (get-buffer "*scratch*"))
;;           (eq (current-buffer) (get-buffer "*Messages*")))
;;       (progn (bury-buffer)
;;              nil)
;;     t))


;; ;; load new packages from other source

;; (require 'package)
;; (add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)
;; ;;(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
;; ;;(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; (when (< emacs-major-version 27)
;;   (package-initialize))

;; (unless (package-installed-p 'use-package)
;;   (package-refresh-contents)
;;   (package-install 'use-package))

;; ;; (use-package quelpa
;; ;;   :ensure t
;; ;;   :config
;; ;;   (setq use-package-ensure-function 'quelpa)
;; ;;   (setq use-package-always-ensure t)

;; ;;   )

;; (use-package quelpa-use-package
;;   :ensure t
;;   )

;; ;;(setq use-package-ensure-function 'quelpa)
;; ;;(setq use-package-always-ensure t)
;; ;; Install and load `quelpa-use-package'.
;; ;; (package-install 'quelpa-use-package)
;; ;; (require 'quelpa-use-package)

;; ;; require drag-stuff
;; (drag-stuff-global-mode 1)
;; (setq drag-stuff-modifier '(meta shift))
;; (setq drag-stuff- '(meta shift))
;; (drag-stuff-define-keys)
;; (setq mouse-drag-and-drop-region t) 

;; ;; highlight line 
;; (global-hl-line-mode 1)

;; ;; enable cua selection modes -> better rectangle selection C-Return
;; ;; after selection hit "return" than it's possible to kill/yank or insert things
;; ;; ESC+n insert a decimal range 
;; (cua-selection-mode t)




;; ;;; init.el --- Improved configuration
;; (setq debug-on-error t)
;; (setq debug-on-load t)

;; (set-face-attribute 'default nil :foreground "#b2af95")

;; ;; ---------------------------------------------------------------------------
;; ;; Early UI settings (before packages load)
;; ;; ---------------------------------------------------------------------------


;; ;; Disable bells
;; (setq ring-bell-function #'ignore)

;; ;; Startup cleanup
;; (setq inhibit-startup-message t
;;       inhibit-startup-echo-area-message t
;;       inhibit-startup-screen t
;;       inhibit-startup-buffer-menu t
;;       initial-scratch-message nil)

;; (defun display-startup-echo-area-message () (message ""))


;; (if (display-graphic-p)
;;     (progn
;;       (menu-bar-mode -1)
;;       (scroll-bar-mode -1)
;;       (tool-bar-mode -1)
;;       (set-frame-parameter nil 'alpha-background 90)
;;       (add-to-list 'default-frame-alist '(alpha-background . 90))
;;       ))

;; (blink-cursor-mode -1)
;; (column-number-mode t)
;; (delete-selection-mode 1)

;; ;; Titlebar
;; (setq frame-icon-title-format "Emacs"
;;       frame-title-format
;;       '("%S: " (buffer-file-name "%f" (dired-directory dired-directory "%b"))))

;; ;; Default frame size
;; ;;(setq initial-frame-alist '((width . 190) (height . 45)))

;; ;; Highlight line globally
;; (global-hl-line-mode 1)

;; ;; Date + time
;; (setq display-time-day-and-date t
;;       display-time-24hr-format t)
;; ;; (display-time) ; enable if you want it visible always

;; ;; ---------------------------------------------------------------------------
;; ;; Font configuration
;; ;; ---------------------------------------------------------------------------
;; (defun my/fontify-frame (&optional frame)
;;   (set-frame-parameter frame 'font "JetBrains Mono-10"))

;; (my/fontify-frame nil)
;; (add-hook 'after-make-frame-functions #'my/fontify-frame)


;; ;; ---------------------------------------------------------------------------
;; ;; Package setup
;; ;; ---------------------------------------------------------------------------
;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa-stable" . "http://stable.melpa.org/packages/") t)

;; (when (< emacs-major-version 27)
;;   (package-initialize))

;; (unless (package-installed-p 'use-package)
;;   (package-refresh-contents)
;;   (package-install 'use-package))

;; (setq use-package-always-ensure t)

;; ;; (use-package quelpa :defer t)
;; ;; (use-package quelpa-use-package :after quelpa)

;; (use-package quelpa
;;   :ensure t
;;   :config
;;   (setq use-package-ensure-function 'quelpa)
;;   (setq use-package-always-ensure t)
;;   )

;; (use-package quelpa-use-package
;;   :ensure t
;;   )


;; (use-package alect-themes
;;   :ensure t
;;   :config
;;   (load-theme 'alect-black t))



;; ---------------------------------------------------------------------------
;; Line numbers + fill-column + auto-fill in programming, text, config modes
;; ---------------------------------------------------------------------------
(defun my/prog-setup ()
  (display-line-numbers-mode 1)
  (setq fill-column 150)
  (auto-fill-mode 1))

(add-hook 'prog-mode-hook #'my/prog-setup)
(add-hook 'text-mode-hook #'my/prog-setup)
(add-hook 'conf-mode-hook #'my/prog-setup)

;; ---------------------------------------------------------------------------
;; Drag Stuff
;; ---------------------------------------------------------------------------
(use-package drag-stuff
  :config
  (drag-stuff-global-mode 1)
  (setq drag-stuff-modifier '(meta shift))
  (drag-stuff-define-keys))

;; ---------------------------------------------------------------------------
;; Better rectangle selection via cua-selection-mode
;; ---------------------------------------------------------------------------
(use-package cua-base
  :ensure nil
  :config
  (cua-selection-mode 1))

;;; End of init.el
