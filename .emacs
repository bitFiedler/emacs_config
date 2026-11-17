; my emacs config  -*- lexical-binding: t; -*-

;; use that for benchmarking starting 
;; (use-package benchmark-init
;;   :ensure t
;;   :config
;;   (benchmark-init/activate))
;; (require 'benchmark-init)
;; (benchmark-init/activate)

;; use benchmark-init/deactivate, to stop benchmarking -> or M-x benchmark-init/deactivate
;; use benchmark-init/show-durations-tabulated od benchmark-init/show-durations-tree to see the benchmark

;; fix lockfile warning
(setq-default create-lockfiles nil)
;;(setq max-lisp-eval-depth 100000)

;; increase undo limit 128MB
(setq undo-outer-limit 128000000)
;; Tree-sitter maximum buffer size: 100 MiB.
(setq treesit-max-buffer-size (* 100 1024 1024))

;;;;;;;;;;;;;;; fix wsl2 clipboard yanking ....
;; problem is Emacs pgtk backend
;; more info: https://www.lukas-barth.net/blog/emacs-wsl-copy-clipboard/
;;
(setq select-active-regions nil)
(setq select-enable-clipboard 't)
(setq select-enable-primary nil)
(setq interprogram-cut-function #'gui-select-text)
;;
;;;;;;;;;;;;;;; wsl2 fix end

;;(setq debug-on-error t)
;;(setq debug-on-load t)

;;(set-face-attribute 'default nil :foreground "#b2af95")

;; Get rid of yes-or-no questions
(setq use-short-answers t)
(fset 'yes-or-no-p 'y-or-n-p)

;; Disable bells
(setq ring-bell-function #'ignore)

;; Startup cleanup
(setq inhibit-startup-message t
      inhibit-startup-echo-area-message t
      inhibit-startup-screen t
      inhibit-startup-buffer-menu t
      initial-scratch-message nil)

(defun display-startup-echo-area-message () (message ""))


;; don't show ever a menu bar
(menu-bar-mode -1)

(if (display-graphic-p)
    (progn
      (scroll-bar-mode -1)
      (tool-bar-mode -1)
      ;; 87% opaque / 13% transparent; keep initial and new frames equal.
      (set-frame-parameter nil 'alpha-background 87)
      (add-to-list 'default-frame-alist '(alpha-background . 87))
      ))

;; Use the theme's colors in terminal frames too.  Truecolor capability
;; must be advertised by the terminal before Emacs starts; setting the
;; tmux keyboard-capability variable to RGB does not enable color support.
(unless (display-graphic-p)
  (set-terminal-parameter nil 'background-mode 'dark))

(blink-cursor-mode -1)
(column-number-mode t)
;; must be deactivated, otherwise we could not add ', ", (, ...
(delete-selection-mode -1)
;; global electric pair 
(electric-pair-mode 1)

;; Titlebar
(setq frame-icon-title-format "Emacs"
      frame-title-format
      '("%S "
        ;; hostname
        (:eval (system-name))
        " @ "
        ;; Buffer identity (file path, dired dir, or buffer name)
        (:eval (or (buffer-file-name)
                   (and (boundp 'dired-directory) dired-directory)
                   "%b"))

        ))

;; Highlight line globally
(global-hl-line-mode 1)

;; Date + time
(setq display-time-day-and-date t
      display-time-24hr-format t)
;; (display-time) ; enable if you want it visible always

;; ---------------------------------------------------------------------------
;; Font configuration
;; ---------------------------------------------------------------------------
(load-file "~/emacstools/my-device-font.el")


;; ---------------------------------------------------------------------------
;; Package setup
;; ---------------------------------------------------------------------------
(require 'package)

(setq package-archives
      '(("gnu"          . "https://elpa.gnu.org/packages/")  ;; <- add GNU ELPA
        ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("melpa"        . "https://melpa.org/packages/")
        ))

;; Initialize package system
(unless package--initialized (package-initialize))

;; Refresh package list if empty
(unless package-archive-contents
  (package-refresh-contents))

(setq use-package-always-ensure t)

;; (use-package quelpa :defer t)
;; (use-package quelpa-use-package :after quelpa)

(use-package quelpa
  :ensure t
  :config
  ;;(setq use-package-ensure-function 'quelpa) ;; if GNU packages fails, comment this line out !!!
  (setq use-package-always-ensure t
        quelpa-upgrade-interval 7)
  )

;; Check after startup only when seven days have elapsed since the last run.
;; Use ordinary upgrades: never discard local changes with a force argument.
(defvar my/quelpa-weekly-upgrade-timer nil)
(defun my/schedule-quelpa-weekly-upgrade ()
  "Schedule the due-date check after 15 idle seconds, once per startup."
  (when (timerp my/quelpa-weekly-upgrade-timer)
    (cancel-timer my/quelpa-weekly-upgrade-timer))
  (setq my/quelpa-weekly-upgrade-timer
        (run-with-idle-timer 15 nil #'quelpa-upgrade-all-maybe)))
(add-hook 'emacs-startup-hook #'my/schedule-quelpa-weekly-upgrade)

(use-package quelpa-use-package
  :ensure t
  :init
  ;; Installed :quelpa packages need no checkout/build attempt at startup.
  ;; Missing packages still install; explicit Quelpa upgrades still work.
  (setq quelpa-use-package-inhibit-loading-quelpa t)
  )


(use-package alect-themes
  :ensure t
  :init
  ;; Alect defaults to graphical displays only.  Use the same palette on
  ;; 256-color and truecolor terminals (256-color displays approximate RGB).
  (setq alect-display-class '((class color) (min-colors 256)))
  :config
  ;; The compiled theme freezes alect-display-class at package build time.
  ;; Expand its source with our current display class instead.
  (let ((load-suffixes '(".el")))
    (load-theme 'alect-black t))
  
  (add-hook 'after-init-hook
          (lambda ()
            ;; use nice read color for strings 
            (set-face-attribute 'font-lock-string-face nil :foreground "#FF5252")
            ;;(set-face-attribute 'font-lock-preprocessor-face nil :italic t)
            )
          )
)


;; ---------------------------------------------------------------------------
;; Line numbers + fill-column + auto-fill in programming, text, config modes
;; ---------------------------------------------------------------------------
;; Match the editor color instead of the theme's separate number gutter.
;; PGTK background alpha belongs to the frame, not to individual faces.
(defun my/line-number-match-editor-background (&rest _)
  "Match line-number backgrounds to each frame's editing background.
Keep the theme's foreground colors and current-line emphasis intact."
  (interactive)
  (dolist (frame (frame-list))
    (when (display-graphic-p frame)
      (let ((background (face-background 'default frame t)))
        (dolist (face '(line-number line-number-current-line
                       line-number-major-tick line-number-minor-tick))
          (when (and (facep face) (stringp background))
            (set-face-background face background frame))))))
  (when (called-interactively-p 'interactive) (redraw-display)))

(add-hook 'enable-theme-functions #'my/line-number-match-editor-background)
(add-hook 'after-make-frame-functions #'my/line-number-match-editor-background)
(my/line-number-match-editor-background)

;; Minibuffer input and echo messages follow the same frame background.
(require 'face-remap)
(defface my/minibuffer-editor-background
  '((t (:inverse-video nil :stipple nil)))
  "Background-only face used in minibuffer and echo-area buffers."
  :group 'minibuffer)
(defvar-local my/minibuffer-editor-background--cookie nil)

(defun my/minibuffer-match-editor-background (&rest _)
  "Match minibuffer and echo-area backgrounds to the editor.
Use per-frame face colors, preserving input fonts and prompt foregrounds.
This follows existing frame alpha; it does not change frame opacity."
  (interactive)
  (let (buffers graphical)
    (dolist (frame (frame-list))
      (when (display-graphic-p frame)
        (setq graphical t)
        (let ((background (face-background 'default frame t)))
          (when (stringp background)
            (set-face-background 'my/minibuffer-editor-background background frame)
            (set-face-background 'minibuffer-prompt background frame)))
        (push (window-buffer (minibuffer-window frame)) buffers)))
    (when graphical
      ;; Echo-area buffers are internal and may be created lazily.
      (dolist (buffer (buffer-list))
        (when (string-match-p
               "\\` \\*\\(?:Minibuf-[0-9]+\\|Echo Area [01]\\)\\*\\'"
               (buffer-name buffer))
          (push buffer buffers)))
      (dolist (buffer (delete-dups buffers))
        (when (buffer-live-p buffer)
          (with-current-buffer buffer
            (unless my/minibuffer-editor-background--cookie
              (setq my/minibuffer-editor-background--cookie
                    (face-remap-add-relative
                     'default 'my/minibuffer-editor-background))))))))
  (when (called-interactively-p 'interactive) (redraw-display)))

(add-hook 'minibuffer-setup-hook #'my/minibuffer-match-editor-background)
(add-hook 'enable-theme-functions #'my/minibuffer-match-editor-background)
(add-hook 'after-make-frame-functions #'my/minibuffer-match-editor-background)
(add-hook 'after-init-hook #'my/minibuffer-match-editor-background)
(my/minibuffer-match-editor-background)

(defun my/prog-setup ()
  (setq fill-column 150)
  ;; auto-fill-mode is not ok if line is > 150 automatically add a newline and that is not good!
  ;;(auto-fill-mode 1)
  )

(add-hook 'prog-mode-hook #'my/prog-setup)
(add-hook 'text-mode-hook #'my/prog-setup)
(add-hook 'conf-mode-hook #'my/prog-setup)

;; Include unrecognized file types, with utility buffers excluded.
(load-file "~/emacstools/my-editing-line-numbers.el")
(load-file "~/emacstools/my-buffer-navigation.el")
(load-file "~/emacstools/my-buffer-reload.el")
(load-file "~/emacstools/my-project-build.el")

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
  ;; Register-0 replacement tracking creates a persistent highlight overlay
  ;; after replacing an entire buffer in this Emacs build.
  (setq cua-delete-copy-to-register-0 nil)
  (setq delete-selection-save-to-register nil)
  (cua-selection-mode 1))



;; ────────────────────────────────────────────────────────────────
;; Doom modeline
;; Requirements:
;;   M-x all-the-icons-install-fonts
;;   M-x nerd-icons-install-fonts
;; ────────────────────────────────────────────────────────────────
;;(defvar all-the-icons-p "~/.emacs.d/all-the-icons-fonts/")
;;(defvar nerd-icons-p "~/.emacs.d/nerd-icons-fonts/")

(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode)
  :custom
  ;; General appearance
  (doom-modeline-height 18)
  (doom-modeline-bar-width 4)
  (doom-modeline-hud nil)
  (doom-modeline-window-width-limit nil)

  ;; File & project info
  (doom-modeline-buffer-file-name-style 'relative-to-project)
  (doom-modeline-project-detection 'ffip) ; or 'project
  (doom-modeline-vcs-max-length 60)

  ;; Misc info
  (doom-modeline-indent-info t)
  (all-the-icons-scale-factor 1.0)

  :config
  (size-indication-mode 1)

  ;; Custom modeline layout
  (doom-modeline-def-modeline 'main
    '(bar         ;; left side
      matches
      buffer-info
      remote-host
      buffer-position
      parrot
      selection-info)
    '(misc-info    ;; right side
      minor-modes
      input-method
      buffer-encoding
      major-mode
      process
      vcs
      "  "))
  )


(setq custom-file "~/.emacs.d/custom.el")
(load custom-file t)  ;; load silently, no error if missing

;; Neutral gray main text in GUI and terminal; keep syntax colors, font
;; and background supplied by their existing settings.  The user theme
;; has priority over color themes and also applies to newly created frames.
(custom-theme-set-faces 'user
                       '(default ((t (:foreground "#B8B8B8")))))

;; projectile should not check external drives
;; because causes hanging emacs -> Doom Mode Line -> project detection
(setq projectile-ignored-directories '("/media/*" "/mnt/*" ))
(setq projectile-globally-ignored-directories '("/media/*" "/mnt/*"))


;;; ========================= ediff ============================================
;(add-hook 'ediff-cleanup-hook '(ediff-janitor t))
;(add-hook 'ediff-cleanup-hook 'ediff-janitor)
;;(setq ediff-diff-options "-w") ;; ignore only whitespace regions
(setq-default ediff-highlight-all-diffs nil) ;; only hilight current diff
(setq ediff-window-setup-function 'ediff-setup-windows-plain)
(setq ediff-split-window-function 'split-window-horizontally) ;; split
;; windows horizontally (add-hook 'ediff-startup-hook
;; 			       'ediff-toggle-wide-display) ;; wide by default 
;===============================================================================

(defun my-prev-window ()
  (interactive)
  (other-window -1))

(defun goto-line-and-column (lc-cond)
  "Allow a specification of
   LINE:COLUMN or LINE,COLUMN instead of
   just COLUMN.  Just :COLUMN or ,COLUMN moves to the specified
   column on the current line.  LINE alone still moves to the
   beginning of the specified line (like LINE:0 or LINE,0).  The
   default value of the COLUMN is decrement by -1 because all
   compilers consider the number of COLUMN from 1 (just for
   copy-past)"
  (interactive "sLine:Column:: ")
  (let (line delim column max-lines)
    (setq max-lines (count-lines (point-min) (point-max)))
    (save-match-data
      (string-match "^\\([0-9]*\\)\\([,:]?\\)\\([0-9]*\\)$" lc-cond)
      (setq line (string-to-number (match-string 1 lc-cond)))
      (setq delim (match-string 2 lc-cond))
      (setq column (string-to-number (match-string 3 lc-cond)))
      (if (not (equal delim "")) (if (> column 0) (setq column (1- column))))
      (if (= 0 line) (setq line (line-number-at-pos)))
      (if (> line max-lines) (setq line max-lines))
      (goto-line line)
      (move-to-column column)
      (message "Marker set to line %d column %s" (line-number-at-pos) (current-column))
      )))

;; ========  buffer kill with no question y/n ==================================
;; disables undo-tree history saving
;; removes its kill hook buffer-locally
;; guarantees no prompt and no hang
(defun my-buffer-kill ()
  (interactive)
  (let ((buffer (current-buffer)))
    ;; Prevent undo-tree from doing anything expensive
    (when (bound-and-true-p undo-tree-mode)
      (set-buffer-modified-p nil)
      ;;(setq-local undo-tree-auto-save-history nil)
      (remove-hook 'kill-buffer-hook #'undo-tree-save-history-from-hook t))
    (if view-mode
        (View-quit)
      (kill-buffer buffer))))
;; =============================================================================



;; ================================== dos2unix =================================
(global-set-key [(f5)]  'dos2unix)

(defun dos2unix ()
  "Convert this entire buffer from MS-DOS text file format to UNIX."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (replace-regexp "\r$" "" nil)
    (goto-char (1- (point-max)))
    (if (looking-at "\C-z")
        (delete-char 1))))
;; ============================================================================


;; recentf
;; Bind M-F12 to recentf-open-files
;; (require 'recentf)
;; (recentf-mode 1)
;; (setq recentf-max-saved-items 500)
;; (setq recentf-max-menu-items 60)

(use-package recentf
  :ensure t
  :config
  (setq recentf-max-saved-items 500)
  (setq recentf-max-menu-items 60)
  )
;; use helm-mini to show last open files M-x b


;; ########## undo tree #######
;; (use-package undo-tree
;;   :ensure t
;;   :diminish undo-tree-mode
;;   :hook (after-init . global-undo-tree-mode)
;;   :custom
;;   ;;(undo-tree-visualizer-diff t)
;;   ;;(undo-tree-visualizer-timestamps t)
;;   (undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
;;   (undo-tree-auto-save-history t)

;;   ;; Optional: still limit memory usage
;;   (setq undo-limit 800000
;;       undo-strong-limit 12000000))

;; ;; ########## undo tree end #######

(use-package vundo
  :ensure t
  :bind ("C-c u" . vundo)
  :init
  (setq undo-limit 80000000)        ;; 80 MB before soft limit
  (setq undo-strong-limit 120000000) ;; 120 MB before more aggressive trimming
  (setq undo-outer-limit 360000000)  ;; 360 MB hard cap
  :config
  ;; nicer visualizes with unicode glyphs
  (setq vundo-glyph-alist vundo-unicode-symbols)
  (set-face-attribute 'vundo-default nil
                      :font "JetBrains Mono NL ExtraBold"
                      :family "JetBrains Mono NL")
  )
;; ########## vundo mode end #######

(use-package undo-fu-session
  :ensure t
  :config
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
  (setq undo-fu-session-directory (expand-file-name "undo-fu-session/" user-emacs-directory))
  ;; Enable compression
  (setq undo-fu-session-compression 'zst) ;; or 'gzip
  
  (undo-fu-session-global-mode))


;;########## multiple cursors #######
(use-package multiple-cursors
  :ensure t
  :bind (("C-c C-s" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-M->" . mc/skip-to-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-M-<" . mc/skip-to-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this))
  )
;;########## multiple cursors end #######

;; now we use autopair because it fits much better my needs 
;;(add-to-list 'load-path "~/emacstools") ;; comment if autopair.el is in standard load path
;; (load-file "~/emacstools/autopair.el")
;; (use-package autopair
;;   :ensure nil
;;   :hook (after-init . autopair-global-mode) ;; Enable autopair globally
;;   :config
;;   ;; (defun my/autopair-c++-mode-setup ()
;;   ;; "Add angle bracket pairing for C++."
;;   ;; (autopair-add-pair ?< ?>))  ;; Add the pair for < >

;;   ;; (add-hook 'c++-mode-hook 'my/autopair-c++-mode-setup)
;;   )  


;;(load-file "~/emacstools/helm_config.el")
(use-package all-the-icons
  :ensure t)

;; Use the installed library or existing upstream checkout without downloading.
;; On a new machine, fetch directly from Git rather than depending on archive metadata.
(if (or (locate-library "ligature")
        (file-readable-p (expand-file-name "~/emacstools/ligature.el/ligature.el")))
    (load-file "~/emacstools/my-ligatures.el")
  (use-package ligature
    :ensure nil
    :quelpa (ligature :fetcher github :repo "mickeynp/ligature.el")
    :config
    (load-file "~/emacstools/my-ligatures.el")))

(use-package nerd-icons
  :ensure t)

(use-package svg-lib
  :ensure t)

;; ---------------------------------------------------------------------------
;; Helm main configuration
;; ---------------------------------------------------------------------------
(use-package helm
  :ensure t
  :diminish
  :init
  (setq
   helm-M-x-fuzzy-match t
   helm-bookmark-show-location t
   helm-buffers-fuzzy-matching t
   helm-completion-in-region-fuzzy-match t
   helm-file-cache-fuzzy-match t
   helm-imenu-fuzzy-match t
   helm-mode-fuzzy-match t
   helm-locate-fuzzy-match t
   helm-quick-update t
   helm-recentf-fuzzy-match t
   helm-gtags-fuzzy-match t
   helm-semantic-fuzzy-match t
   helm-split-window-inside-p t
   helm-move-to-line-cycle-in-source t
   helm-ff-search-library-in-sexp t
   helm-scroll-amount 8
   helm-ff-file-name-history-use-recentf t
   helm-echo-input-in-header-line t
   helm-buffer-max-length 40
   )

  :config
  (helm-mode 1)
  (load-file "~/emacstools/my-helm-files.el")
  
  ;; Key bindings
  (global-set-key (kbd "C-c h") 'helm-command-prefix)
  (global-unset-key (kbd "C-x c"))
  (global-set-key (kbd "M-x") #'helm-M-x)
  (global-set-key (kbd "C-x r b") #'helm-filtered-bookmarks)
  (global-set-key (kbd "C-x C-f") #'helm-find-files)
  (global-set-key (kbd "C-x b") 'helm-mini)
  (global-set-key (kbd "M-y") 'helm-show-kill-ring)

  ;; Rebind keys in helm
  (define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action)
  (define-key helm-map (kbd "C-i") 'helm-execute-persistent-action)
  (define-key helm-map (kbd "C-z") 'helm-select-action)

  (defun spacemacs//helm-hide-minibuffer-maybe (&rest ignore)
    "Hide minibuffer in Helm session if we use the header line as input field."
    (when (with-helm-buffer helm-echo-input-in-header-line)
      (let ((ov (make-overlay (point-min) (point-max) nil nil t)))
        (overlay-put ov 'window (selected-window))
        (overlay-put ov 'face
                     (let ((bg-color (face-background 'default nil)))
                       `(:background ,bg-color :foreground ,bg-color)))
        (setq-local cursor-type nil))))

  (add-hook 'helm-minibuffer-set-up-hook
            'spacemacs//helm-hide-minibuffer-maybe)

  (when (executable-find "curl")
    (setq helm-google-suggest-use-curl-p t))
  
  ;; show icons in helm-find-file
  (helm-ff-icon-mode 1)
  ;; set extension color 
  (set-face-attribute 'helm-ff-file-extension nil 
                      :foreground "cyan")
  
  ;; check faces with M-x list-faces-display
  ;; show color options M-x list-colors-display
  )

;; ---------------------------------------------------------------------------
;; Helm gtags configuration
;; ---------------------------------------------------------------------------
(use-package helm-gtags
  :ensure t
  :after helm
  :hook ((dired-mode eshell-mode c-ts-mode c++-ts-mode
                     c-mode c++-mode asm-mode) . helm-gtags-mode)
  :init
  (setq
   helmg-gtags-ignore-case t
   helm-gtags-use-input-at-cursor t
   helm-gtags-pulse-at-cursor t
   helm-gtags-suggested-key-mapping t
   helm-gtags-direct-helm-completing t
   ;; helm-gtags-auto-update t
   )
  :config
  ;; Key bindings for gtags
  (define-key helm-gtags-mode-map (kbd "C-.") 'helm-gtags-dwim)
  (define-key helm-gtags-mode-map (kbd "C-,") 'helm-gtags-pop-stack)
  (define-key helm-gtags-mode-map (kbd "M-.") 'xref-find-definitions)
  (define-key helm-gtags-mode-map (kbd "s-<backspace>") 'helm-all-mark-rings)
  (define-key helm-gtags-mode-map (kbd "C-t") 'transpose-chars)
  )

;; ---------------------------------------------------------------------------
;; Helm xref integration
;; ---------------------------------------------------------------------------
(use-package helm-xref
  :ensure t
  :after helm)

;; ---------------------------------------------------------------------------
;; Helm ripgrep
;; ---------------------------------------------------------------------------
(use-package helm-rg
  :ensure t
  :commands (helm-rg helm-rg-from-isearch helm-rg-display-help)
  :after helm
  )

;; ---------------------------------------------------------------------------
;; Helm ls git
;; ---------------------------------------------------------------------------
(use-package helm-ls-git
  :ensure t
  :commands helm-ls-git
  :after helm
  )

(use-package helm-descbinds
  :ensure t
  :config
  :after helm
  (helm-descbinds-mode))

(use-package helm-company
  :ensure t
  :commands helm-company
  :after helm
  )

(use-package helm-flycheck
  :ensure t
  :commands helm-flycheck
  :after helm
  )

(use-package helm-fuzzy
  :ensure t
  :commands helm-fuzzy-mode
  :after helm
  )

(use-package helm-lsp
  :ensure t
  :commands (helm-lsp-workspace-symbol helm-lsp-global-workspace-symbol
                                     helm-lsp-code-actions helm-lsp-diagnostics)
  :after helm
  )

(use-package helm-ispell
  :ensure t
  :commands helm-ispell
  :after helm
  )

;; (use-package helm-org
;;   :ensure t
;;   :after helm
;;   )

(use-package helm-bm
  :ensure t
  :commands helm-bm
  :after helm
  )

;; (advice-add 'global-set-key :before
;;   (lambda (key def)
;;     (when (equal key (kbd "M-s"))
;;       (message "M-s rebound to %S from:\n%s" def
;;                (with-output-to-string (backtrace))))))

;; (advice-add 'define-key :before
;;   (lambda (map key def &rest _)
;;     (when (and (equal key (kbd "M-s")) (not (eq map deadgrep-mode-map)))
;;       (message "M-s set on %S -> %S\n%s" map def
;;                (with-output-to-string (backtrace))))))


;; Make custom Lisp files available.
(add-to-list 'load-path
             (expand-file-name "~/emacstools" user-emacs-directory))

(require 'my-emacs-geometry)
(require 'my-emacs-sessions)

;; Keep the last 10 saved sessions.
(setq my/session-max-count 10)

;; Save automatically when Emacs exits.
(setq my/session-save-on-exit t)

;; Enable session management.
(my-emacs-sessions-mode 1)

;; Keyboard shortcuts.
;;(global-set-key (kbd "C-c C-s") #'my/helm-sessions)
;;(global-set-key (kbd "C-c C-r") #'my/restore-last-session)


;; find string in other files
;;(require 'deadgrep) -> use ripgrep
;; sudo apt-get install ripgrep
(use-package deadgrep
  :ensure t
  :bind ("M-s" . deadgrep)
  :config
  (load-file "~/emacstools/my-deadgrep-recursion.el")
  )

;; for debugging searching who has bind M-s key
;;(lookup-key global-map (kbd "M-s"))     ; what global-map currently holds
;;(key-binding (kbd "M-s"))               ; what actually fires, considering all maps

;;; ======================== Global Keybindings ===============================
;; global indent-code-riggidly or left
(global-set-key (kbd "C-c <left>") 'indent-rigidly-left)
(global-set-key (kbd "C-c <right>") 'indent-rigidly-right)

;; Delete all whitespace backward (C backspace)
(global-set-key (kbd "C-<backspace>") 'c-hungry-backspace)

;; Shifted pair deletion; lowercase C-d and M-d retain their normal bindings.
(load-file "~/emacstools/my-pair-editing.el")

;; Jump to line + column
(global-set-key (kbd "M-g") #'goto-line-and-column)

;; Move between windows
(global-set-key (kbd "C-q")   #'my-prev-window)
(global-set-key (kbd "C-S-q") #'other-window)

;; Kill buffer
(global-set-key (kbd "C-x k") #'my-buffer-kill)

;; Convert tabs to spaces
(global-set-key (kbd "M-T") #'untabify)

;; Terminal (fix wrong key syntax)
(global-set-key (kbd "C-*") #'vterm)

;; Use M-; for comment-dwim as usual — no override

;; Undo (fix duplicate C-z binding)
(global-set-key (kbd "C-z")   #'undo-only)
(global-set-key (kbd "C-S-z") #'undo-redo)

;;; ------------------------------ HEXL MODE ----------------------------------

(global-set-key (kbd "C-h C-h") #'hexl-mode)
(global-set-key (kbd "C-h C-e") #'hexl-mode-exit)
(global-set-key (kbd "C-h C-i") #'hexl-insert-hex-string)

;;; ----------------------------- DIFF / EDIFF --------------------------------

(global-set-key (kbd "C-c f") #'ediff-files)
(global-set-key (kbd "C-c b") #'ediff-buffers)

;;; ------------------------------ PRINTING -----------------------------------

(global-set-key (kbd "C-c p") #'ps-print-buffer-with-faces)
(global-set-key (kbd "C-c P") #'ps-print-region-with-faces)
(global-set-key (kbd "C-c l") #'pr-toggle-landscape)

(global-set-key (kbd "<f12>") #'a2ps-buffer)
(global-set-key (kbd "<f11>") #'a2ps-region)



(use-package company
  :ensure t
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.1)   ;; quick completion
  (company-minimum-prefix-length 1)
  (company-tooltip-align-annotations t)
  :config
  ;; Use completion-at-point-functions (includes elisp)
  (setq company-backends '(company-capf))

  ;;(add-hook 'elsip-mode-hook 'company-mode)
  )

;; Package: ws-butler
;; git clone https://github.com/lewang/ws-butler.git
(add-to-list 'load-path "~/emacstools/ws-butler")
(use-package ws-butler
  :ensure nil
  :hook ((c-mode c++-mode pthon-mode) . ws-butler-mode)
  )

;;(setq header-line-format nil)
;; (load-file "~/emacstools/breadcrumb/breadcrumb.el")
;; (use-package breadcrumb
;;   :ensure t
;;   :defer t
;;   :config
;;   (setq breadcrumb-project-max-length 0)
;;   (setq which-func-functions #'(breadcrumb-imenu-crumbs)))

;; Syntax breadcrumbs: C-c . j/u/f/c/s/b/t and C-c . 1..9.
;; Customize via M-x customize-group RET my-context-breadcrumb RET.
;;(when (bound-and-true-p breadcrumb-mode) (breadcrumb-mode -1))
(setq my/context-breadcrumb-show-file nil
      my/context-breadcrumb-else-hints 'always)
(setq my/context-breadcrumb-show-macro-calls nil
      my/context-breadcrumb-detail 'always)
(setq my/context-breadcrumb-background 'editor
      my/context-breadcrumb-border nil)
(load-file "~/emacstools/my-context-breadcrumb.el")
(my/context-breadcrumb-global-mode 1)

(load-file "~/emacstools/bookmarks_config.el")
(load-file "~/emacstools/json_config.el")
(load-file "~/emacstools/python_config.el")
(load-file "~/emacstools/c_mode_config.el")
(load-file "~/emacstools/org_config.el")
(load-file "~/emacstools/xah_extension.el")

;; (load-file "~/emacstools/dictionary_config.el")
;; (load-file "~/emacstools/php_sgml_config.el")


;; ;; ########### auto load

;; (setq auto-mode-alist
;;       (append
;;        '(("\\.m$"    . objc-mode)
;;          ("\\.java$" . java-mode)
;;          ("\\.js$" . java-mode)
;;          ("\\.proto$"    . protobuf-mode)
;;          ("\\.PROTO$"    . protobuf-mode)
;;          ("\\.cfs$"    . conf-windows-mode)
;;          ("\\.robot\\'" . robot-mode)
;;          ("\\.tsv\\'" . robot-mode)
;;          ) auto-mode-alist))
;; ;; ######## auto load end 

(setq ff-search-directories
      '("." "../../" "../" "../inc" "./inc" "../include" "../src" "./src" ))

;; (custom-set-variables
;;  ;; custom-set-variables was added by Custom.
;;  ;; If you edit it by hand, you could mess it up, so be careful.
;;  ;; Your init file should contain only one such instance.
;;  ;; If there is more than one, they won't work right.
;;  '(minimap-window-location 'right)
;;  '(package-selected-packages nil)
;;  '(show-paren-mode t)
;;  '(text-mode-hook
;;    '(turn-on-auto-fill text-mode-hook-identify display-line-numbers-mode))
;;  '(transient-mark-mode t))

;; ;; avoid buffer split to vertical in compilation mode -> gdialog
;; (setq split-width-threshold nil)

;; ;; set longlines for emacs
;; ;; (setq-default truncate-lines t)

;; set no longlines for emacs
(setq-default truncate-lines nil)

;; trucate even when screen is split into multiple windows
(setq-default truncate-partial-width-windows nil)

;; default kill ring buffer is 60 now we want at least 500 entries 
(setq kill-ring-max 500)

;; highlight during query
(setq query-replace-highlight t)        

; highlight incremental search
(setq search-highlight t)

;; no backupfiles
;;(setq make-backup-files nil)

;; By default, Emacs never backs up versioned files. Since we’re going
;; to be backing up intermediate copies, we want to backup versioned
;; files too, since we don’t commit on every save:
(setq vc-make-backup-files t)
;; save all backup files into 
(setq backup-directory-alist `(("." . "~/.emacs.d/backups/")))
;; add more versions of backups and do version controlling
(setq version-control t ;; Use version numbers for backups.
      kept-new-versions 10 ;; Number of newest versions to keep.
      kept-old-versions 2 ;; Number of oldest versions to keep.
      delete-old-versions t ;; Don't ask to delete excess backup versions.
      backup-by-copying t) ;; Copy all files, don't rename them.

;; Force a backup every time we save by resetting `buffer-backed-up`

(defun my/force-backup-on-save ()
  "Reset `buffer-backed-up` only if the file is smaller than 20MB.
This forces Emacs to create a new backup on the next save,
but avoids huge-file slowdowns."
  (when (and buffer-file-name
             (file-exists-p buffer-file-name)
             (< (file-attribute-size (file-attributes buffer-file-name))
                (* 20 1024 1024)))  ;; 20 MB in bytes
    (setq buffer-backed-up nil)))

;; register to the hook
(add-hook 'before-save-hook #'my/force-backup-on-save)

(setq auto-save-file-name-transforms
      '((".*" "~/.emacs.d/auto-saves/" t)))

;; autosave intervall
(setq auto-save-interval 2000)

;; Always enable syntax highlighting
(setq font-lock-maximum-decoration t)
(global-font-lock-mode t)
;; force font-lock-mode to all files/buffers, because somehow it's broken
(add-hook 'find-file-hook #'font-lock-ensure)

;; turn on tags case sensitiv, very important !!!
(set-default 'tags-case-fold-search nil)

;; https://github.com/domtronn/all-the-icons.el#installing-fonts
;; M-x all-the-icons-install-fonts

;; Package: dtrt-indent
;; git clone https://github.com/jscheid/dtrt-indent.git
(use-package dtrt-indent
  :quelpa (dtrt-indent :fetcher github :repo "jscheid/dtrt-indent")
  :ensure t
  :config
  ;; no messages
  (setq dtrt-indent-verbosity 0)
  (load-file "~/emacstools/my-shell-indentation.el")
  (dtrt-indent-global-mode 1)
  )

;; Package: clean-aindent-mode
;; git clone https://github.com/pmarinov/clean-aindent-mode.git
;;(add-to-list 'load-path "~/emacstools/clean-aindent-mode")
(use-package clean-aindent-mode
  :quelpa (clean-aindent-mode :fetcher github :repo "pmarinov/clean-aindent-mode")
  :hook (prog-mode . clean-aindent-mode)
  :config
  (setq clean-aindent-is-simple-indent t)
  )


;; yaml-mode handling
;; git clone https://github.com/yoshiki/yaml-mode
(use-package yaml-mode
  :quelpa (yaml-mode :fetcher github :repo "yoshiki/yaml-mode")
  :mode ("\\.yml\\'" . yaml-mode)  ;; automatically adds to auto-mode-alist
  :hook (yaml-mode . (lambda ()
                       ;; Make Enter key indent properly
                       (local-set-key (kbd "RET") #'newline-and-indent)))
  :config
  ;; Keep quotes highlighted inside CI scripts instead of coloring entire
  ;; YAML block scalars as strings.  This also avoids yaml-mode's block
  ;; properties suppressing quote highlighting on the first content line.
  (setq yaml-font-lock-keywords
        (assq-delete-all 'my/yaml-font-lock-block-literals
                         (assq-delete-all 'yaml-font-lock-block-literals
                                          yaml-font-lock-keywords)))
  )

;; Live Markdown previews and self-contained Nerd Font HTML exports.
(load-file "~/emacstools/my-markdown-preview.el")

;; Match classic YAML quote colors without painting CI script blocks red.
(load-file "~/emacstools/my-yaml-ts-font-lock.el")

;; ========================== enable flyspell ==================================
;; install hunspell spellchecker for windows:
;; winget install fsfhu.hunspell
;(use-package flyspell
;  :custom
;  (ispell-program-name "c:/Users/POPPJ/AppData/Local/Microsoft/WinGet/Links/hunspell.exe")
;  (ispell-local-dictionary "en_US")
;  (ispell-local-dictionary-alist '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))
;  :init
;  (setenv "LANG" "en_US")
;  (setenv "DICPATH" "~/.emacs.d/dict/")
;  (setenv "DICTIONARY" "en_US")
;  (setopt
;   ispell-hunspell-dict-paths-alist '(("en_US" "~/.emacs.d/dict/en_US.aff"))
;   )
;  (setq hunspell-default-dict "~/.emacs.d/dict/en_US.aff")
;  )

(defun flyspell-english ()
  (interactive)
  (flyspell-mode t)
  (ispell-change-dictionary "american")
  (flyspell-buffer))
;; =============================================================================

;; Originally from stevey, adapted to support moving to a new directory.
(defun rename-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive
   (progn
     (if (not (buffer-file-name))
         (error "Buffer '%s' is not visiting a file!" (buffer-name)))
     ;; Disable ido auto merge since it too frequently jumps back to the original
     ;; file name if you pause while typing. Reenable with C-z C-z in the prompt.
     (let ((ido-auto-merge-work-directories-length -1))
       (list (read-file-name (format "Rename %s to: " (file-name-nondirectory
                                                       (buffer-file-name))))))))
  (if (equal new-name "")
      (error "Aborted rename"))
  (setq new-name (if (file-directory-p new-name)
                     (expand-file-name (file-name-nondirectory
                                        (buffer-file-name))
                                       new-name)
                   (expand-file-name new-name)))
  ;; Only rename if the file was saved before. Update the
  ;; buffer name and visited file in all cases.
  (if (file-exists-p (buffer-file-name))
      (rename-file (buffer-file-name) new-name 1))
  (let ((was-modified (buffer-modified-p)))
    ;; This also renames the buffer, and works with uniquify
    (set-visited-file-name new-name)
    (if was-modified
        (save-buffer)
      ;; Clear buffer-modified flag caused by set-visited-file-name
      (set-buffer-modified-p nil)))

  (setq default-directory (file-name-directory new-name))

  (message "Renamed to %s." new-name))

(add-to-list 'load-path "~/emacstools/emacs-libvterm")
(use-package vterm
  :ensure nil
  )


;; copy buffer name to clibborad
(defun copy-buffer-name ()
  "Read buffer file name and copy it to clipboard."
  (interactive)
  (kill-new (buffer-file-name)))

;; enable rust mode 
(use-package rust-mode
  :ensure t)

;; ;; ;; install packages
;; ;;  ;;  alect-themes       0.9           installed             Configurable light, dark and black themes for Emacs 24 or later
;; ;;  ;;  cmake-mode         3.20.0pre5    installed             major-mode for editing CMake sources
;; ;;  ;;  drag-stuff         0.3.0         installed             Drag stuff (lines, words, region, etc...) around
;; ;;  ;;  flymake            1.1.1         installed             A universal on-the-fly syntax checker
;; ;;  ;;  flymake-json       0.1           installed             A flymake handler for json using jsonlint
;; ;;  ;;  ggtags             0.9.0         installed             emacs frontend to GNU Global source code tagging system
;; ;;  ;;  helm-ag            0.64          installed             The silver searcher with helm interface
;; ;;  ;;  helm-directory     0.6.4         installed             selecting directory before select the file
;; ;;  ;;  helm-flycheck      0.4           installed             Show flycheck errors with helm
;; ;;  ;;  helm-fuz           1.3.0         installed             Integrate Helm and Fuz
;; ;;  ;;  helm-gtags         1.5.7         installed             GNU GLOBAL helm interface
;; ;;  ;;  helm-pydoc         0.7           installed             pydoc with helm interface
;; ;;  ;;  helm-selector      0.6.1         installed             Helm buffer selector
;; ;;  ;;  json-mode          1.7.0         installed             Major mode for editing JSON files
;; ;;  ;;  json-reformat      0.0.6         installed             Reformatting tool for JSON
;; ;;  ;;  minimap            1.4           installed             Sidebar showing a "mini-map" of a buffer
;; ;;  ;;  mmm-mode           0.5.8         installed             Allow Multiple Major Modes in a buffer
;; ;;  ;;  paredit            24            installed             minor mode for editing parentheses
;; ;;  ;;  paredit-everywhere 0.4           installed             Enable some paredit features in non-lisp buffers
;; ;;  ;;  psgml              1.3.4         installed             SGML-editing mode with parsing support
;; ;;  ;;  yasnippet          0.14.0        installed             Yet another snippet extension for Emacs
;; ;;  ;;  async              1.9.4         dependency            Asynchronous processing in Emacs
;; ;;  ;;  auto-compile       1.6.1         dependency            automatically compile Emacs Lisp libraries
;; ;;  ;;  auto-complete      1.5.1         dependency            Auto Completion for GNU Emacs
;; ;;  ;;  connection         1.11          dependency            TCP-based client connection
;; ;;  ;;  dash               2.18.1        dependency            A modern list library for Emacs
;; ;;  ;;  deadgrep           0.9           dependency            fast, friendly searching with ripgrep
;; ;;  ;;  dictionary         1.11          dependency            Client for rfc2229 dictionary servers
;; ;;  ;;  eldoc              1.11.0        dependency            Show function arglist or variable docstring in echo area
;; ;;  ;;  epl                0.9           dependency            Emacs Package Library
;; ;;  ;;  flx                0.6.1         dependency            fuzzy matching with good sorting
;; ;;  ;;  flycheck           31            dependency            On-the-fly syntax checking
;; ;;  ;;  flycheck-pycheckers 0.15          dependency            multiple syntax checker for Python, using Flycheck
;; ;;  ;;  flymake-easy       0.10          dependency            Helpers for easily building flymake checkers
;; ;;  ;;  fuz                1.3.0         dependency            Fast and precise fuzzy scoring/matching utils
;; ;;  ;;  helm               3.7.1         dependency            Helm is an Emacs incremental and narrowing framework
;; ;;  ;;  helm-c-yasnippet   0.6.7         dependency            helm source for yasnippet.el
;; ;;  ;;  helm-core          3.7.1         dependency            Development files for Helm
;; ;;  ;;  helm-fuzzy         0.1.6         dependency            Fuzzy matching for helm source
;; ;;  ;;  helm-ispell        0.1           dependency            ispell-complete-word with helm interface
;; ;;  ;;  json-snatcher      1.0.0         dependency            Grabs the path to JSON values in a JSON file
;; ;;  ;;  link               1.11          dependency            Hypertext links in text buffers
;; ;;  ;;  mc-extras          1.2.4         dependency            Extra functions for multiple-cursors mode.
;; ;;  ;;  multiple-cursors   1.4.0         dependency            Multiple cursors for Emacs.
;; ;;  ;;  ov                 1.0.6         dependency            Overlay library for Emacs Lisp
;; ;;  ;;  packed             3.0.2         dependency            package manager agnostic Emacs Lisp package utilities
;; ;;  ;;  pkg-info           0.6           dependency            Information about packages
;; ;;  ;;  popup              0.5.8         dependency            Visual Popup User Interface
;; ;;  ;;  s                  1.12.0        dependency            The long lost Emacs string manipulation library.
;; ;;  ;;  spinner            1.7.3         dependency            Add spinners and progress-bars to the mode-line for ongoing operations
;; ;;  ;;  undo-tree          0.7.5         dependency            Treat undo history as a tree
;; ;;  ;;  yasnippet-snippets 0.23          dependency            Collection of yasnippet snippets
;; ;;  ;; cmake-mode         3.20.0pre5    obsolete              major-mode for editing CMake sources
;; ;;  ;;  aa-edit-mode       0.0.2         incompat   melpa-stable Major mode for editing AA(S_JIS Art) and .mlt file
;; ;;  ;;  ac-helm            2.1           incompat   melpa-stable Auto Complete with Helm
;; ;;  ;;  alan-mode          1.0.0         incompat   melpa-stable Major mode for editing M-industries Alan files
;; ;;  ;;  amd-mode           2.8           incompat   melpa-stable Minor mode for handling JavaScript AMD module requirements.
;; ;;  ;;  auto-shell-command 1.0.2         incompat   melpa-stable Run the shell command asynchronously that you specified when you save the file.
;; ;;  ;;  bbdb-              0.0.2         incompat   melpa-stable provide interface for more easily search/choice than BBDB.
;; ;;  ;;  butler             0.2.4         incompat   melpa-stable Emacs client for Jenkins
;; ;;  ;;  call-graph         0.1.0         incompat   melpa-stable Library to generate call graph for cpp functions
;; ;;  ;;  cerbere            0.1.0         incompat   melpa-stable Unit testing in Emacs for several programming languages
;; ;;  ;;  ctxmenu            0.3.0         incompat   melpa-stable Provide a context menu like right-click.
;; ;;  ;;  ddskk-posframe     1.0.0         incompat   melpa-stable Show Henkan tooltip for ddskk via posframe
;; ;;  ;;  define-it          0.2.4         incompat   melpa-stable Define, translate, wiki the word
;; ;;  ;;  describe-number    0.3.1         incompat   melpa-stable Describe arbitrarily large number at point.
;; ;;  ;;  dionysos           0.6.0         incompat   melpa-stable Dionysos, a music player for Emacs
;; ;;  ;;  dired-sidebar      0.2.0         incompat   melpa-stable Tree browser leveraging dired
;; ;;  ;;  ede-php-autoload-composer-installers 0.1.0         incompat   melpa-stable Composer installers support for ede-php-autoload
;; ;;  ;;  ein                0.16.2.3      incompat   melpa-stable Emacs IPython Notebook
;; ;;  ;;  emr                0.4           incompat   melpa-stable Emacs refactoring system.
;; ;;  ;;  es-mode            4.3.0         incompat   melpa-stable A major mode for editing Elasticsearch queries
;; ;;  ;;  ess-R-data-view    1.0           incompat   melpa-stable Data viewer for GNU R
;; ;;  ;;  ewal-spacemacs-themes 0.2.1         incompat   melpa-stable Ride the rainbow spaceship
;; ;;  ;;  flycheck-eldev     1.1           incompat   melpa-stable Eldev support in Flycheck
;; ;;  ;;  flycheck-vdm       0.0.4         incompat   melpa-stable Syntax checking for vdm-mode
;; ;;  ;;  git-gutter-fringe+ 0.1           incompat   melpa-stable Fringe version of git-gutter+.el
;; ;;  ;;  gkroam             2.4.3         incompat   melpa-stable A lightweight org-mode Roam Research replica
;; ;;  ;;  hasky-extensions   0.2.0         incompat   melpa-stable Toggle Haskell language extensions
;; ;;  ;;  helm-spaces        0.4           incompat   melpa-stable helm sources for spaces
;; ;;  ;;  julia-snail        1.0.0pre5     incompat   melpa-stable Julia Snail
;; ;;  ;;  julia-vterm        0.11          incompat   melpa-stable A mode for Julia REPL using vterm
;; ;;  ;;  jump               2.5           incompat   melpa-stable build functions which contextually jump between files
;; ;;  ;;  lastfm             1.2           incompat   melpa-stable Last.fm API for Emacs Lisp
;; ;;  ;;  leaf-manager       1.0.0         incompat   melpa-stable Configuration manager for leaf based init.el
;; ;;  ;;  line-reminder      0.4.5         incompat   melpa-stable Line annotation for changed and saved lines
;; ;;  ;;  lsp-grammarly      0.2.1         incompat   melpa-stable LSP Clients for Grammarly
;; ;;  ;;  lsp-origami        1.0.0         incompat   melpa-stable origami.el support for lsp-mode
;; ;;  ;;  markdown-mode+     0.8           incompat   melpa-stable extra functions for markdown-mode
;; ;;  ;;  md4rd              0.3.1         incompat   melpa-stable Mode for reddit (browse it).
;; ;;  ;;  mhc                1.2.4         incompat   melpa-stable Message Harmonized Calendaring system.
;; ;;  ;;  monkeytype         0.1.5         incompat   melpa-stable Mode for speed typing
;; ;;  ;;  ob-ess-julia       1.0.0         incompat   melpa-stable Org babel support for Julia language
;; ;;  ;;  org-babel-eval-in-repl 1.6           incompat   melpa-stable Eval org-mode babel code blocks in various REPLs.
;; ;;  ;;  org-gnome          0.3           incompat   melpa-stable Orgmode integration with the GNOME desktop
;; ;;  ;;  org-recent-headings 0.1           incompat   melpa-stable Jump to recently used Org headings
;; ;;  ;;  org-runbook        1.1.4         incompat   melpa-stable Org mode for runbooks
;; ;;  ;;  org2web            0.9.1         incompat   melpa-stable A static site generator based on org mode.
;; ;;  ;;  orgit-forge        0.1.0         incompat   melpa-stable Org links to Forge issue buffers
;; ;;  ;;  origami-predef     1.0           incompat   melpa-stable Apply folding when finding (opening) files
;; ;;  ;;  pass               2.0           incompat   melpa-stable Major mode for password-store.el
;; ;;  ;;  pinboard-popular   0.1.2         incompat   melpa-stable Displays links from the pinboard.in popular page.
;; ;;  ;;  pocket-lib         0.1           incompat   melpa-stable Library for accessing getpocket.com API
;; ;;  ;;  pocket-reader      0.2.1         incompat   melpa-stable Client for Pocket reading list
;; ;;  ;;  poetry             0.1.0         incompat   melpa-stable poetry in Emacs
;; ;;  ;;  psci               0.0.6         incompat   melpa-stable Major mode for purescript repl psci
;; ;;  ;;  pubmed             0.5           incompat   melpa-stable Interface to PubMed
;; ;;  ;;  python-pytest      3.0.0         incompat   melpa-stable helpers to run pytest
;; ;;  ;;  rtags-xref         2.38          incompat   melpa-stable RTags backend for xref.el
;; ;;  ;;  shr-tag-pre-highlight 2             incompat   melpa-stable Syntax highlighting code block in HTML
;; ;;  ;;  snapshot-timemachine-rsnapshot 0.4           incompat   melpa-stable rsnapshot backend for snapshot-timemachine
;; ;;  ;;  solidity-flycheck  0.1.10        incompat   melpa-stable Flycheck integration for solidity emacs mode
;; ;;  ;;  sprintly-mode      0.0.4         incompat   melpa-stable Major mode for dealing with sprint.ly
;; ;;  ;;  symex              1.0           incompat   melpa-stable An evil way to edit Lisp symbolic expressions as trees
;; ;;  ;;  syslog-mode        2.3           incompat   melpa-stable Major-mode for viewing log files
;; ;;  ;;  traad              3.1.1         incompat   melpa-stable emacs interface to the traad refactoring server.
;; ;;  ;;  vdiff-magit        0.3.2         incompat   melpa-stable magit integration for vdiff
;; ;;  ;;  vim-region         0.3.0         incompat   melpa-stable Select region as vim
;; ;;  ;;  vuiet              1.0           incompat   melpa-stable The music player and explorer for Emacs
;; ;;  ;;  zel                0.1.2         incompat   melpa-stable Access frecent files easily

;; (custom-set-faces
;;  ;; custom-set-faces was added by Custom.
;;  ;; If you edit it by hand, you could mess it up, so be careful.
;;  ;; Your init file should contain only one such instance.
;;  ;; If there is more than one, they won't work right.
;;  '(highlight-indentation-face ((t (:inherit fringe)))))

;; ;;(benchmark-init/deactivate)
;; (put 'scroll-left 'disabled nil)

;; ;; (setf completion-styles '(basic flex)
;; ;;       completion-auto-select t ;; Show completion on first call
;; ;;       completion-auto-help 'visible ;; Display *Completions* upon first request
;; ;;       completions-format 'one-column ;; Use only one column
;; ;;       completions-sort 'historical ;; Order based on minibuffer history
;; ;;       completions-max-height 20 ;; Limit completions to 15 (completions start at line 5)
;; ;;       completion-ignore-case t)

;; ;; (setq global-completion-preview-mode t)

(use-package ov
  :quelpa (ov :fetcher github :repo "emacsorphanage/ov")
  ;;:ensure t
  )

(use-package hide-lines
  :quelpa (hide-lines :fetcher github :repo "vapniks/hide-lines")
  :ensure t
  )

;; new config for syslog-mode, pulled from git
;; manually config syslog-mode
;; (use-package syslog-mode
;;   :quelpa (syslog-mode :fetcher github :repo "vapniks/syslog-mode")
;;   :after (ov hide-lines)
;;   :init
;;   (add-to-list 'auto-mode-alist '("\\.log\\'" . syslog-mode))
;;   (add-to-list 'auto-mode-alist '("\\.clog\\'" . syslog-mode))
;;   (add-hook 'syslog-mode-hook #'my-syslog-disable-multiline-strings)
;; 
;;   :config
;;   ;; ---------------- Faces ----------------
;;   (defface syslog-emerg-face
;;     '((t (:foreground "red" :weight bold :background "black"))) "")
;;   (defface syslog-alert-face
;;     '((t (:foreground "red" :weight bold))) "")
;;   (defface syslog-crit-face
;;     '((t (:foreground "red" :weight bold))) "")
;;   (defface syslog-err-face
;;     '((t (:foreground "firebrick1" :weight bold))) "")
;;   (defface syslog-warning-face
;;     '((t (:foreground "orange" :weight bold))) "")
;;   (defface syslog-notice-face
;;     '((t (:foreground "yellow"))) "")
;;   (defface syslog-info-face
;;     '((t (:foreground "spring green"))) "")
;;   (defface syslog-debug-face
;;     '((t (:foreground "magenta"))) "")
;;   (defface syslog-programm-face
;;     '((t (:foreground "light blue"))) "")
;;   (defface syslog-kernel-face
;;     '((t (:foreground "light blue"))) "")

;;   ;; ---------------- Fix multiline string issue ----------------
;;   (defun my-syslog-disable-multiline-strings ()
;;     "Disable syntax-based string parsing in syslog buffers."
;;     (when (derived-mode-p 'syslog-mode)
;;       ;; Make quotes punctuation → no multi-line string parsing
;;       (let ((st (copy-syntax-table (syntax-table))))
;;         (modify-syntax-entry ?\" "." st)
;;         (modify-syntax-entry ?\' "." st)
;;         (set-syntax-table st))

;;       ;; Fully disable syntactic fontification (IMPORTANT)
;;       (setq-local font-lock-syntactic-face-function #'ignore)

;;       ;; Refresh font-lock
;;       (font-lock-flush)
;;       (font-lock-ensure)))

;;   ;; ---------------- Font-lock rules ----------------
;;   (defun my-syslog-font-lock-setup ()
;;     (when (derived-mode-p 'syslog-mode)
;;       (let ((keywords
;;              `(
;;                ;; Timestamp (multiple formats)
;;                ("^\\(?:[A-Z][a-z]\\{2,8\\} [ 0-9]\\{2\\} [0-9:.]+\\|[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9:.]+\\|[0-9]\\{8\\}_[0-9]\\{6\\}\\.[0-9]\\{3,6\\}[-+]?[0-9]\\{4\\}\\)"
;;                 0 font-lock-constant-face)

;;                ;; Hostname
;;                ("^\\(?:[A-Z][a-z]\\{2,8\\} [ 0-9]\\{2\\} [0-9:.]+\\) \\([A-Za-z0-9._:-]+\\) "
;;                 1 font-lock-variable-name-face)

;;                ;; Severity (syslog)
;;                ("\\b\\w+\\.emerg\\b"   . 'syslog-emerg-face)
;;                ("\\b\\w+\\.alert\\b"   . 'syslog-alert-face)
;;                ("\\b\\w+\\.crit\\b"    . 'syslog-crit-face)
;;                ("\\b\\w+\\.err\\b"     . 'syslog-err-face)
;;                ("\\b\\w+\\.warn\\b"    . 'syslog-warning-face)
;;                ("\\b\\w+\\.notice\\b"  . 'syslog-notice-face)
;;                ("\\b\\w+\\.info\\b"    . 'syslog-info-face)
;;                ("\\b\\w+\\.debug\\b"   . 'syslog-debug-face)

;;                ;; Severity (text logs)
;;                ("\\bFATAL\\b"   . 'syslog-emerg-face)
;;                ("\\bERROR\\b"   . 'syslog-err-face)
;;                ("\\bWARN\\b"    . 'syslog-warning-face)
;;                ("\\bINFO\\b"    . 'syslog-info-face)
;;                ("\\bDEBUG\\b"   . 'syslog-debug-face)
;;                ("\\bVERBOSE\\b" . 'syslog-notice-face)

;;                ;; PID
;;                ("\\[[0-9]+\\]" . font-lock-variable-name-face)

;;                ;; C++ symbols
;;                ("\\[[A-Za-z0-9_:]+@[0-9]+\\]" . font-lock-function-name-face)

;;                ;; Program name
;;                ("\\b\\([[:alpha:]][[:alnum:]_-]+\\)\\[[0-9]+\\]:"
;;                 . 'syslog-programm-face)

;;                ;; Kernel
;;                ("kernel:\\s-\\[ *[0-9.]+\\]" 0 'syslog-kernel-face)

;;                ;; Prefix
;;                ("\\b[[:alnum:]_-]+:" . font-lock-function-name-face)

;;                ;; IPs
;;                ("\\b[0-9]+\\(?:\\.[0-9]+\\)\\{3\\}\\b"
;;                 . font-lock-type-face)

;;                ;; Strings (single-line only, safe)
;;                ("\"[^\n\"]*\"" . font-lock-string-face)
;;                ("'[^'\n]*'" . font-lock-string-face)
;;                )))

;;         ;; IMPORTANT: clean font-lock setup
;;         (setq-local font-lock-defaults '(keywords nil t))
;;         (setq-local font-lock-syntactic-face-function #'ignore)

;;         ;; Apply highlighting
;;         (font-lock-flush)
;;         (font-lock-ensure))))

;;   (add-hook 'syslog-mode-hook #'my-syslog-font-lock-setup)

;;   ;; Misc
;;   (setq syslog-highlight-keywords t)
;;   (setq syslog-highlight-prompt t)
;;   (setq font-lock-maximum-decoration t)
;;   )

(use-package syslog-mode
  :quelpa (syslog-mode :fetcher github :repo "vapniks/syslog-mode")
  :after (ov hide-lines)
  ;;:ensure t
  :init
  (add-to-list 'auto-mode-alist '("\\.log\\'" . syslog-mode))
  (add-to-list 'auto-mode-alist '("\\.clog\\'" . syslog-mode))
  (add-hook 'syslog-mode-hook #'syslog-disable-multiline-strings)
  :config
  ;; --- Faces (define them before font-lock uses them) ---
  (defface syslog-emerg-face
    '((t (:foreground "red" :weight bold :background "black")))
    "Face for emerg messages.")
  (defface syslog-alert-face
    '((t (:foreground "red" :weight bold)))
    "Face for alert messages.")
  (defface syslog-crit-face
    '((t (:foreground "red" :weight bold)))
    "Face for crit messages.")
  (defface syslog-err-face
    '((t (:foreground "firebrick1" :weight bold)))
    "Face for err messages.")
  (defface syslog-warning-face
    '((t (:foreground "orange" :weight bold)))
    "Face for warning messages.")
  (defface syslog-notice-face
    '((t (:foreground "yellow")))
    "Face for notice messages.")
  (defface syslog-info-face
    '((t (:foreground "spring green")))
    "Face for info messages.")
  (defface syslog-debug-face
    '((t (:foreground "magenta")))
    "Face for debug messages.")
  (defface syslog-programm-face
    '((t (:foreground "light blue")))
    "Face for ledspot messages.")
  (defface syslog-kernel-face
    '((t (:foreground "light blue")))
    "Face for ledspot messages.")
  
  ;; Disable built-in multi-line string parsing
  (defun syslog-disable-multiline-strings ()
    "Prevent multi-line strings in syslog-mode."
    (when (derived-mode-p 'syslog-mode)
      ;; Make a buffer-local copy of the syntax table and modify that.
      (let ((st (copy-syntax-table (syntax-table))))
        (modify-syntax-entry ?\" "." st)  ;; make " punctuation
        (modify-syntax-entry ?\' "." st)  ;; make ' punctuation
        (set-syntax-table st))

      ;; Turn off syntactic fontification for this buffer to avoid
      ;; run-away multi-line string detection.
      (setq-local syntax-propertize-function nil)
      (setq-local parse-sexp-lookup-properties nil)
      (setq-local font-lock-syntactic-face-function (lambda (state) nil))
      
      ;; Refresh font-lock for the change to take effect immediately.
      (font-lock-flush)
      (font-lock-ensure)))
  
  (defconst my/syslog-record-start-regexp
    (rx line-start
        (or (seq upper (+ lower) " " (+ (any " " digit)) " "
                 (= 2 digit) ":" (= 2 digit) ":" (= 2 digit))
            (seq (= 4 digit) "-" (= 2 digit) "-" (= 2 digit)
                 (any " T") (= 2 digit) ":" (= 2 digit) ":" (= 2 digit))
            (seq (= 8 digit) "_" (= 6 digit))))
    "Timestamp prefixes that delimit independent syslog records.")

  (defun my/syslog-message-end ()
    "Return end of msg= value after its opening quote at point.
Stop at the next timestamped record even if the closing quote is missing."
    (save-excursion
      (save-match-data
        (let ((limit (save-excursion
                       (if (re-search-forward my/syslog-record-start-regexp nil t)
                           (match-beginning 0)
                         (point-max))))
              closed)
          ;; Consume escaped characters before considering a quote as closing.
          (while (and (not closed)
                      (re-search-forward (rx (or (seq "\\" anything) "\""))
                                         limit t))
            (setq closed (= (char-after (match-beginning 0)) ?\")))
          (if closed (point) limit)))))

  (defun my/syslog-match-message (bound)
    "Find a quoted msg= value before BOUND, bounded by its log record."
    (when (re-search-forward "\\_<msg=\"" bound t)
      (let ((start (1- (point)))
            (end (my/syslog-message-end)))
        (goto-char end)
        (set-match-data (list start end))
        t)))

  (defun my/syslog-extend-message-region ()
    "Include multiline messages when refreshing part of a log buffer."
    (let (changed)
      (save-excursion
        (goto-char font-lock-beg)
        (when (re-search-backward "\\_<msg=\"" nil t)
          (let ((start (line-beginning-position)))
            (goto-char (match-end 0))
            (when (> (my/syslog-message-end) font-lock-beg)
              (setq font-lock-beg start changed t))))
        (goto-char font-lock-end)
        (when (re-search-backward "\\_<msg=\"" nil t)
          (goto-char (match-end 0))
          (let ((end (my/syslog-message-end)))
            (when (> end font-lock-end)
              (setq font-lock-end end changed t)))))
      changed))

  ;; --- Highlighting rules ---
  ;; Set up font-lock
  (defun my-syslog-font-lock-setup ()
    "Set up font-lock keywords for syslog-mode only."
    (when (derived-mode-p 'syslog-mode)
      (let ((keywords
             `(
               ;; Timestamp: syslog, lios log and cLog
               ("^\\(?:[A-Z][a-z]\\{2,8\\} [ 0-9]\\{2\\} [0-9:.]+\\|[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9:.]+\\|[0-9]\\{8\\}_[0-9]\\{6\\}\\.[0-9]\\{3,6\\}[-+]?[0-9]\\{4\\}\\)"
                0 font-lock-constant-face)
               ;; ("^\\([A-Z][a-z]\\{2,8\\} [ 0-9]\\{2\\} [0-9:.]+\\)"
               ;;  1 font-lock-constant-face)
               ;; ;; Timestamp LiOS log
               ;; ("^\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9:.]+\\)" 1 font-lock-constant-face)
               ;; ;; Timestamp xLog/cLog
               ;; ("^[0-9]\\{8\\}_[0-9]\\{6\\}\\.[0-9]\\{3,6\\}[-+]?[0-9]\\{4\\}" 1 font-lock-constant-face)
               
               ;; Hostname / device immediately after timestamp (group 1)
               ;; Example: Oct 10 17:33:28.688 SkyPanel-X-0048487-04990 ...
               ("^\\(?:[A-Z][a-z]\\{2,8\\} [ 0-9]\\{2\\} [0-9:.]+\\) \\([A-Za-z0-9._:-]+\\) "
                1 font-lock-variable-name-face)

               ;; Severity field (facility.severity)
               ("\\b\\w+\\.emerg\\b"   . 'syslog-emerg-face)
               ("\\b\\w+\\.alert\\b"   . 'syslog-alert-face)
               ("\\b\\w+\\.crit\\b"    . 'syslog-crit-face)
               ("\\b\\w+\\.err\\b"     . 'syslog-err-face)
               ("\\b\\w+\\.warn\\b"    . 'syslog-warning-face)
               ("\\b\\w+\\.warning\\b" . 'syslog-warning-face)
               ("\\b\\w+\\.notice\\b"  . 'syslog-notice-face)
               ("\\b\\w+\\.info\\b"    . 'syslog-info-face)
               ("\\b\\w+\\.debug\\b"   . 'syslog-debug-face)
               ;; Severity levels
               ("\\bFATAL\\b"   . 'syslog-emerg-face)
               ("\\bERROR\\b"   . 'syslog-err-face)
               ("\\bWARN\\b"    . 'syslog-warning-face)
               ("\\bWARNING\\b" . 'syslog-warning-face)
               ("\\bINFO\\b"    . 'syslog-info-face)
               ("\\bDEBUG\\b"   . 'syslog-debug-face)
               ("\\bVERBOSE\\b" . 'syslog-notice-face)

               ;; Thread ID or PID in brackets
               ("\\[[0-9]+\\]" . font-lock-variable-name-face)
               
               ;; C++ symbol-like section [Namespace::Class::Function@line]
               ("\\[[A-Za-z0-9_:]+@[0-9]+\\]" . font-lock-function-name-face)
               
               ;; General program names with PID (ledSpot, Controlpanel, etc.)
               ("\\b\\([[:alpha:]][[:alnum:]_-]+\\)\\[[0-9]+\\]:" . 'syslog-programm-face)

               ;; Kernel messages
               ;; Highlight kernel program name and optional float in brackets
               ("kernel:\\s-\\[ *[0-9.]+\\]" 0 'syslog-kernel-face)

               ;; Message prefix (like "kernel:")
               ("\\b[[:alnum:]_-]+:" . font-lock-function-name-face)

               ;; IP address (if present)
               ("\\b[0-9]+\\(?:\\.[0-9]+\\)\\{3\\}\\b" . font-lock-type-face)

               ;; Add per-line quote highlighting, disable multiline support
               ;; Keep quoted strings on one line, allowing escaped characters.
               ("\"\\(?:[^\"\\\n]\\|\\\\[^\n]\\)*\"" 0 font-lock-string-face)

               ;; Option B: Explicitly excludes apostrophes in words (better for 'can't')
               ;; Check that the preceding character is NOT a word character (\W)
               ("\\W'[^\n']*'\\W" . font-lock-string-face) ; Requires surrounding non-word characters.
               ;; Structured timestamps take precedence over generic strings.
               ("\\_<time=\\(\"[^\"\n]*\"\\|[^ \t\n]+\\)"
                1 font-lock-constant-face t)
               ;; Messages override severity/number matches within their text.
               (my/syslog-match-message 0 font-lock-string-face t)
               )))
        ;; apply buffer locally
        ;; font-lock-defaults expects: (KEYWORDS ...optional-args...)
        ;; The second arg nil => not syntactic; third arg t => case-fold is nil by default
        (setq-local font-lock-defaults (list keywords nil t))
        (add-hook 'font-lock-extend-region-functions
                  #'my/syslog-extend-message-region nil t)
        ;; Refresh highlighting
        (font-lock-refresh-defaults)
        (font-lock-flush)
        (font-lock-ensure))))
  
  (add-hook 'syslog-mode-hook 'my-syslog-font-lock-setup)
  
  (setq syslog-highlight-keywords t)
  (setq syslog-highlight-prompt t)
  (setq font-lock-maximum-decoration t)
  (setq font-lock-support-mode 'jit-lock-mode)
  
 ) 

(use-package magit
  :ensure t
  :commands (magit-status magit-dispatch)
  :config
  ;; disable the limit entirely (always keep color)
  (setq magit-log-color-graph-limit nil)
  
  ; Wait until the log module is loaded
  (with-eval-after-load 'magit-log
    (setq magit-log-arguments '("--graph" "--decorate" "--color")))
  )

(use-package magit-gitflow
  :ensure t
  :after magit
  )



;; AI connection to ollama
(use-package ellama
  :ensure t
  :bind ("C-c e" . ellama-transient-main-menu)
  ;; send last message in chat buffer with C-c C-c
  :hook (org-ctrl-c-ctrl-c-final . ellama-chat-send-last-message)
  :init (setopt ellama-auto-scroll t)
  :config
  ;; show ellama context in header line in all buffers
  (ellama-context-header-line-global-mode +1)
  )

;; (setq treesit-language-source-alist
;;       '((c      "https://github.com/tree-sitter/tree-sitter-c"      "v0.20.8")
;;         (cpp    "https://github.com/tree-sitter/tree-sitter-cpp"    "v0.20.3")
;;         (python "https://github.com/tree-sitter/tree-sitter-python" "v0.20.4")
;;         (bash   "https://github.com/tree-sitter/tree-sitter-bash"   "v0.20.0")
;;         (cmake  "https://github.com/uyha/tree-sitter-cmake"         "v0.2.0")
;;         (json   "https://github.com/tree-sitter/tree-sitter-json")
;;         ))

;; emacs 31.1 suports ABI 13-14
;; take a look into src/parser.c -> #define LANGUAGE_VERSION
;; grep -R "LANGUAGE_VERSION" src/
(setq treesit-language-source-alist
      '((c      "https://github.com/tree-sitter/tree-sitter-c"      "v0.23.6")
        (cpp    "https://github.com/tree-sitter/tree-sitter-cpp"    "v0.23.4")
        (python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.6")
        (bash   "https://github.com/tree-sitter/tree-sitter-bash"   "v0.23.3")
        (cmake  "https://github.com/uyha/tree-sitter-cmake"         "v0.7.4")
        (json   "https://github.com/tree-sitter/tree-sitter-json"   "v0.24.8")
        (rust   "https://github.com/tree-sitter/tree-sitter-rust"   "v0.23.3")
        ))

;; remove treesit grammars
;; rm ~/.emacs.d/tree-sitter/libtree-sitter-*.so
;; reinstall or install all grammars
;; (dolist (lang '(c cpp python bash cmake json))
;;   (treesit-install-language-grammar lang))

(setq treesit-font-lock-level 4)

(add-hook 'c++-ts-mode-hook
          (lambda ()
            ;; Force font-lock to refresh
            (font-lock-flush)
            (font-lock-ensure)))

;; docker file support 
(use-package dockerfile-mode
  :defer t
  :ensure t
  )

;; lua file support 
(use-package lua-mode
  :defer t
  :ensure t
  :init
  (add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-mode))
  (add-to-list 'interpreter-mode-alist '("\\.lua\\'" . lua-mode))
  )

;; CMake file support (built into this Emacs).
(use-package cmake-ts-mode
  :defer t
  :ensure nil
  :init
  (add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)CMakeLists\\.txt\\'" . cmake-ts-mode))
  )

;; Use native graphical copying.  On Wayland, read fresh clipboard text
;; directly: PGTK's clipboard cache can otherwise leave an older yank item.
(when (display-graphic-p)
  (setq interprogram-cut-function #'gui-select-text
        interprogram-paste-function #'gui-selection-value)
  (when (and (getenv "WAYLAND_DISPLAY") (executable-find "wl-paste"))
    (load "~/emacstools/my-wayland-clipboard.el" nil t)
    (setq interprogram-paste-function #'my/wayland-clipboard-paste)))

;; Enable the terminal fallback by capability, not by device name.
;; Wayland and both clipboard executables are required, outside Zellij.
;; sudo apt-get install -y wl-clipboard
(when (and (getenv "WAYLAND_DISPLAY")
           (not (display-graphic-p))
           (not (getenv "ZELLIJ"))
           (executable-find "wl-copy")
           (executable-find "wl-paste"))
  ; Without this, copy and pasting from other wayland apps into
  ;; emacs-pgtk doesn't work.
  ;; https://www.emacswiki.org/emacs/CopyAndPaste#h5o-4
  (setq wl-copy-process nil)
  (defun wl-copy (text)
    (setq wl-copy-process (make-process :name "wl-copy"
                                        :buffer nil
                                :command '("wl-copy" "-f" "-n")
                                :connection-type 'pipe
                                :noquery t))
    (process-send-string wl-copy-process text)
    (process-send-eof wl-copy-process))
  (defun wl-paste ()
    (if (and wl-copy-process (process-live-p wl-copy-process))
        nil ; should return nil if we're the current paste owner
      (shell-command-to-string "wl-paste -n | tr -d \r")))
  (setq interprogram-cut-function 'wl-copy)
  (setq interprogram-paste-function 'wl-paste))

(setq-default tab-width 4)
(setq-default standard-indent 4)

;; (defun my/install-missing-grammars ()
;;   "Install tree-sitter grammars if they aren't already available."
;;   (interactive)
;;   (dolist (lang-info treesit-language-source-alist)
;;     (let ((lang (car lang-info)))
;;       (unless (treesit-language-available-p lang)
;;         (message "Installing tree-sitter grammar for %s..." lang)
;;         (treesit-install-language-grammar lang)))))

;; ;; Run it automatically on startup
;; (my/install-missing-grammars)

;; remap sh-mode to use bash-ts-mode
;; (add-to-list 'major-mode-remap-alist
;;              '(sh-mode . bash-ts-mode))

(use-package eglot-booster
  :quelpa (eglot-booster :fetcher github :repo "jdtsmith/eglot-booster")
  :after eglot
  :config
  (eglot-booster-mode 1)
  ;; (fset #'jsonrpc--log-event #'ignore)
  ;; (setq eglot-events-buffer-size 0)
  )

;; bash eglot support
;;
;; install npm
;; sudo apt install -y nodejs npm
;;
;; set proxy:
;; sudo npm config set proxy $http_proxy
;; sudo npm config set https-proxy $https_proxy
;; npm config set proxy $http_proxy
;; npm config set https-proxy $https_proxy
;;
;; could not be installd as root for all users!
;; npm install bash-language-server
;;
;; start
;; npx bash-language-server --version
(use-package eglot
  :ensure nil
  :commands eglot
  :hook ((c-mode c-ts-mode c++-mode c++-ts-mode python-mode python-ts-mode sh-mode bash-ts-mode
                 ) . eglot-ensure)
  :config
  (setq eglot-sync-connect nil)  ;; avoid blocking sync
  ;; Reuse the originating server for definitions in external libraries/stubs.
  (setq eglot-extend-to-xref t)
  ;; eglot-ensure manages connections; do not reconnect on major-mode changes.
  (load "~/emacstools/my-eglot-retry-limit.el" nil t)

  ;; c/c++
  ;; sudo apt install -y clang-20 clangd-20 lld-20
  ;; sudo ln -s /usr/bin/ld.lld-20 /usr/bin/ld.lld
  ;; sudo ln -s /usr/bin/llvm-ar-20 /usr/bin/llvm-ar
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode c-ts-mode c++-ts-mode) .
                 ("clangd-20"
                  "-j=16"
                  "--background-index"
                  "--clang-tidy=false"
                  "--header-insertion=never")))
  
  ;; ("clangd-20"
  ;;  "-j=16"
  ;;  "--log=verbose"
  ;;  "--all-scopes-completion"
  ;;  "--malloc-trim"
  ;;  ;;"--experimental-modules-support"
  ;;  "--pch-storage=memory"
  ;;  "--completion-style=detailed"
  ;;  "--limit-results=1000"
  ;;  "--limit-references=10000000"
  ;;  "--compile_args_from=filesystem"
  ;;  "--pch-storage=memory"
  ;;  "--header-insertion=never"
  ;;  "--completion-parse=always"
  ;;  "--function-arg-placeholders=1"
  ;;  "--enable-config"
  ;;  ;;"--include-ineligible-results"
  ;;  "--use-dirty-headers"
  ;;  ;;"--sync"
  ;;  "--header-insertion=iwyu"
  ;;  "--header-insertion-decorators=1"
  ;;  ;;"--pretty"
  ;;  ;;"--compile-commands-dir=/home/mp/sourcen/jupiter/main-application/build/Target_Default"
  ;;  ;;"--query-driver=/opt/orbiter-tiny/5.0.7/sysroots/cortexa7t2hf-neon-vfpv4-poky-linux-musleabi/usr/include,/opt/orbiter-tiny/5.0.7/sysroots/x86_64-pokysdk-linux/usr/bin/x86_64-pokysdk-linux-*"
  ;;  )))

  ;; python
  ;; sudo apt-get install -y python3-pylsp
  ;; (add-to-list 'eglot-server-programs
  ;;              `((python-mode python-ts-mode) . ("pylsp")))

  ;; use pyright, faster and better type checking
  ;; npm install pyright
  (add-to-list 'eglot-server-programs
               `((python-mode python-ts-mode) . ("npx" "pyright-langserver" "--stdio")))

  ;; bash
  ;; npm install bash-language-server
  (add-to-list 'eglot-server-programs
               '((sh-mode bash-ts-mode) . ("npx" "bash-language-server" "start")))


  (setq eglot-autoshutdown t)
  (setq eglot-events-buffer-config (list :size 0 :format 'full))
  )

(defun my/open-files ()
  "Return absolute paths of all open file buffers."
  (delete-dups
   (delq nil
         (mapcar (lambda (buf)
                   (buffer-local-value 'buffer-file-name buf))
                 (buffer-list)))))


(defun my/helm-find-files-recursive (&optional arg)
  "Recursively search filenames using ripgrep and Helm.

Initial search pattern:
- Active region: use selected text.
- Word/symbol at point: use symbol.
- Otherwise: start with an empty pattern.
- With prefix ARG (C-u): prompt for a pattern.

Search starts in `default-directory'."
  (interactive "P")
  (require 'helm)
  (require 'helm-source)

  (let* ((root default-directory)
         (initial-input
          (cond
           (arg
            (read-string "Filename pattern: "
                         (or (thing-at-point 'symbol t) "")))
           ((use-region-p)
            (buffer-substring-no-properties
             (region-beginning)
             (region-end)))
           ((thing-at-point 'symbol t))
           (t "")))
         (files
          (let ((default-directory root))
            (process-lines
             "rg" "--files" "--hidden"
             "--glob" "!.git"))))

    (helm
     :sources
     (helm-build-sync-source "Recursive files"
       :candidates files
       :fuzzy-match t
       :action
       (lambda (file)
         (find-file
          (expand-file-name file root))))
     :input initial-input
     :buffer "*helm recursive files*")))


(global-set-key (kbd "C-c f")
                #'my/helm-find-files-recursive)
