;; Enable elpy for python development  -*- lexical-binding: t; -*-
(use-package elpy
  :ensure t
  :commands (elpy-mode elpy-enable)
  :init
  (setq python-shell-interpreter "python3"
        python-shell-interpreter-args "-i")
  :config

  (setq elpy-enable t)
  ;; install elpy from emacs packet management
  ;; sudo apt install python3-jedi black python3-autopep8 yapf3 python3-yapf
  ;;(setq elpy-rpc-python-command "python3")
  (setq elpy-rpc-python-command "python3")
  (setq elpy-rpc-virtualenv-path `current)
  
  

  )



;; eglog support for python
;; pip3 install pre-commit
;; pip3 install hatch
;; pip3 inject hatch hatch-vcs
;; pip3 install pyright
;; pip3 install python-lsp-server
;; sudo apt-get update; sudo apt-get install make build-essential libssl-dev zlib1g-dev \
;; libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
;; curl https://pyenv.run | bash
;; pyenv install 3.10.13
(use-package pyvenv
  :ensure t
  :commands (pyvenv-activate pyvenv-deactivate pyvenv-workon)
  :init
  (setenv "WORKON_HOME" "~/.pyenv/versions"))

;; (use-package eglot-booster
;;   :ensure t
;;   :quelpa (eglot-booster :fetcher github :repo "jdtsmith/eglot-booster")
;;   :after eglot
;;   :config
;;   (eglot-booster-mode)
;;   (fset #'jsonrpc--log-event #'ignore)
;;   (setq eglot-events-buffer-size 0)
;;   )

;; (require 'eglot)
;; (setq eglot-booster-mode t)
;; (fset #'jsonrpc--log-event #'ignore)
;; (setq eglot-events-buffer-size 0)


;; (use-package eglot
;;   :ensure t
;;   :commands eglot
;;   :config
;;   ;; Define the formatter function inside Eglot's config block
;;   (defun my-eglot-breadcrumb-header-line-format ()
;;     "Generate the Eglot symbol path string for the header line."
;;     (let* ((symbol-path (eglot-get-current-workspace-symbol))
;;            (path-items nil))
      
;;       (when (and symbol-path (eq (car symbol-path) 'lsp--result))
;;         (setq symbol-path (cdr symbol-path)))

;;       (if symbol-path
;;           (progn
;;             (dolist (item symbol-path)
;;               (push (car item) path-items))
;;             (setq path-items (nreverse path-items))
            
;;             (concat 
;;              (propertize "  " 'face 'font-lock-keyword-face)
;;              (mapconcat 'identity path-items (propertize " / " 'face 'shadow))))
;;           nil)))

;;   (defun my-eglot-enable-breadcrumb-header-line ()
;;     "Enable the custom breadcrumb display in the header line."
;;     (message "1. ----> breadcrumb-header-line func...")
;;     ;; Now, Eglot is guaranteed to be loaded, so eglot-managed-p exists.
;;     (when (eglot-managed-p)
;;       (message "2. ----> Eglot activated! Setting header line...")
;;       (setq-local header-line-format
;;                   '((progn 
;;                      (my-eglot-breadcrumb-header-line-format)
;;                      )
;;                     "  "))))

;;   ;; The standard hook for when Eglot establishes a connection is the best choice.
;;   ;;(add-hook 'eglot-activated-hook 'my-eglot-enable-breadcrumb-header-line)
;;   (add-hook 'prog-mode-hook 'my-eglot-enable-breadcrumb-header-line)
  
;;   (add-to-list 'eglot-server-programs
;;                `(python-mode
;;                  . ,(eglot-alternatives '("pylsp"
;;                                           "jedi-language-server"
;;                                           ("pyright-langserver" "--stdio")))))
;;   (setq eglot-autoshutdown t))

;;(add-hook 'python-mode-hook 'eglot-ensure)

(progn
  (face-spec-set 'eglot-diagnostic-tag-unnecessary-face
			     '((t (:inherit default))))
  (face-spec-set 'eglot-diagnostic-tag-deprecated-face
			     '((t (:inherit default)))))

(use-package indent-bars
  :ensure t
  :hook ((python-mode yaml-mode) . indent-bars-mode)) ; or whichever modes you prefer

;; (require 'lsp-mode)
;; (add-hook 'c++-ts-mode-hook 'lsp)
(add-hook 'python-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (setq tab-width 4)
            (setq python-indent-offset 4)
            ;; Eglot starts once via the shared hooks in ~/.emacs.
            (company-mode)
            
            (my/context-breadcrumb-mode 1)
            
            ;; ============================== python key mode-map ============================
            ;; remap because of inconfinient keyboard shortcut
            (define-key python-mode-map (kbd "C-c <left>") 'python-indent-shift-left)
            (define-key python-mode-map (kbd "C-c <right>") 'python-indent-shift-right)
            ))
;;(add-hook 'python-mode-hook '(company-mode highlight-indentation-mode))
(add-hook 'python-hook (lambda () (setq company-backends '(company-eglot))))
