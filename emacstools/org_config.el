;; ;;;;Org mode configuration  -*- lexical-binding: t; -*-
;; ;; Enable Org mode
;; (require 'org)
;; (define-key global-map "\C-cl" 'org-store-link)
;; (define-key global-map "\C-ca" 'org-agenda)
;; (setq org-log-done t)

;; ;; (add-to-list 'load-path "~/emacstools/org-superstar-mode")
;; ;; (require 'org-superstar)
;; ;; (add-hook 'org-mode-hook (lambda () (org-superstar-mode 1)))

;; (use-package org-superstar
;;   :ensure t
;;   :config
;;   (add-hook 'org-mode-hook (lambda () (org-superstar-mode 1)))
;;   )


;; ;; This hides the slashes and stars that denote emphasis and bold text unless point is on said text.
;; (setq org-hide-emphasis-markers t)

;; ;; Visibly render mathematical symbols.
;; (setq org-pretty-entities t)

;; ;; Show linked images directly in my Org document. Don’t fully expand enormous images; instead, use imagemagick to display them at a manageable size.
;; (setq org-startup-with-inline-images t
;;       org-image-actual-width '(600))

;; ;;Use syntax highlighting in source blocks while editing.
;; (setq org-src-fontify-natively t)

;; ;;Make TAB act as if it were issued in a buffer of the language’s major mode.
;; (setq org-src-tab-acts-natively t)

;; ;; When editing a code snippet, use the current window rather than popping open a new one (which shows the same information).
;; (setq org-src-window-setup 'current-window)

;; ============================ Org Mode Setup ================================

;; Keep Org on demand; its commands and mode load their libraries on use.
(autoload 'org-mode "org" nil t)
(autoload 'org-store-link "ol" nil t)
(autoload 'org-agenda "org-agenda" nil t)
(autoload 'org-indent-mode "org-indent" nil t)
;; Associate all org files with org mode
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

;; Make the indentation look nicer
(add-hook 'org-mode-hook 'org-indent-mode)

;; Must do this so the agenda knows where to look for my files
(setq org-agenda-files '("~/Documents/org"))

;; ---------------------------- Keybindings -----------------------------------
;; Global keybindings for Org links and agenda
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)

;; When a TODO is set to a done state, record a timestamp
(setq org-log-done 'time)

;; Follow the links
(setq org-return-follows-link  t)

;; Automatically log when tasks are marked done
(setq org-log-done t)

;; ---------------------------- Visual Enhancements ---------------------------
;; Use Org Superstar for prettier bullets
(use-package org-superstar
  :ensure t
  :hook (org-mode . org-superstar-mode)
  :config
  ;; enable org tempo, use <s tab 
  (require 'org-tempo)
  
  ;; Optional customization
  (setq org-superstar-headline-bullets-list '("◉" "○" "✸" "✿")))

;; Hide emphasis markers (*bold*, /italic/, etc.) unless cursor is on them
(setq org-hide-emphasis-markers t)

;; Pretty render entities like →, ∑, π
(setq org-pretty-entities t)

;; Inline images
(setq org-startup-with-inline-images t
      org-image-actual-width '(600)) ;; display images at a manageable size

;; ---------------------------- Source Code Blocks ----------------------------
;; Syntax highlighting in source blocks
(setq org-src-fontify-natively t)

;; Make TAB act as if it were in the language’s major mode
(setq org-src-tab-acts-natively t)

;; Edit source blocks in the current window rather than opening a new one
(setq org-src-window-setup 'current-window)

;; Optional: Use indentation and smart formatting for editing source blocks
(setq org-edit-src-content-indentation 2)

;; Optional: Enable automatic evaluation confirmations for certain languages
;; (setq org-confirm-babel-evaluate nil)
