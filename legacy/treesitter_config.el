
;; treesitter
(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
        (cmake "https://github.com/uyha/tree-sitter-cmake")
        (c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (css "https://github.com/tree-sitter/tree-sitter-css")
        (elisp "https://github.com/Wilfred/tree-sitter-elisp")
        (go "https://github.com/tree-sitter/tree-sitter-go")
        (html "https://github.com/tree-sitter/tree-sitter-html")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (make "https://github.com/alemuller/tree-sitter-make")
        (markdown "https://github.com/ikatyang/tree-sitter-markdown")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (toml "https://github.com/tree-sitter/tree-sitter-toml")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml")))


;; (use-package treesit
;;   :preface
;;   (defun mp-setup-install-grammars ()
;;     "Install Tree-sitter grammars if they are absent."
;;     (interactive)
;;     (dolist (grammar
;;              '((bash "https://github.com/tree-sitter/tree-sitter-bash")
;;                (cmake "https://github.com/uyha/tree-sitter-cmake")
;;                (c "https://github.com/tree-sitter/tree-sitter-c")
;;                (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
;;                (css "https://github.com/tree-sitter/tree-sitter-css")
;;                (elisp "https://github.com/Wilfred/tree-sitter-elisp")
;;                (go "https://github.com/tree-sitter/tree-sitter-go")
;;                (html "https://github.com/tree-sitter/tree-sitter-html")
;;                (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))
;;                (json "https://github.com/tree-sitter/tree-sitter-json")
;;                (make "https://github.com/alemuller/tree-sitter-make")
;;                (markdown "https://github.com/ikatyang/tree-sitter-markdown")
;;                (python "https://github.com/tree-sitter/tree-sitter-python")
;;                (toml "https://github.com/tree-sitter/tree-sitter-toml")
;;                (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
;;                (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
;;                (yaml "https://github.com/ikatyang/tree-sitter-yaml")))

;;       (add-to-list 'treesit-language-source-alist grammar)
;;       ;; Only install `grammar' if we don't already have it
;;       ;; installed. However, if you want to *update* a grammar then
;;       ;; this obviously prevents that from happening.
;;       (unless (treesit-language-available-p (car grammar))
;;         (treesit-install-language-grammar (car grammar)))))

;;   ;; Optional, but recommended. Tree-sitter enabled major modes are
;;   ;; distinct from their ordinary counterparts.
;;   ;;
;;   ;; You can remap major modes with `major-mode-remap-alist'. Note
;;   ;; that this does *not* extend to hooks! Make sure you migrate them
;;   ;; also
;;   (dolist (mapping '((python-mode . python-ts-mode)
;;                      (css-mode . css-ts-mode)
;;                      (typescript-mode . tsx-ts-mode)
;;                      (js-mode . js-ts-mode)
;;                      (css-mode . css-ts-mode)
;;                      (c-mode . c-ts-mode)
;;                      (c++-mode . c++-ts-mode)
;;                      (json-mode . json-ts-mode)
;;                      (yaml-mode . yaml-ts-mode)))
;;     (add-to-list 'major-mode-remap-alist mapping))

;;   :config
;;   (mp-setup-install-grammars)
;;   ;; Do not forget to customize Combobulate to your liking:
;;   ;;
;;   ;;  M-x customize-group RET combobulate RET
;;   ;;
;;   (use-package combobulate
;;     :preface
;;     ;; You can customize Combobulate's key prefix here.
;;     ;; Note that you may have to restart Emacs for this to take effect!
;;     (setq combobulate-key-prefix "C-c o")

;;     ;; Optional, but recommended.
;;     ;;
;;     ;; You can manually enable Combobulate with `M-x
;;     ;; combobulate-mode'.
;;     :hook ((python-ts-mode . combobulate-mode)
;;            (js-ts-mode . combobulate-mode)
;;            (css-ts-mode . combobulate-mode)
;;            (yaml-ts-mode . combobulate-mode)
;;            (typescript-ts-mode . combobulate-mode)
;;            (c-ts-mode . combobulate-mode)
;;            (c++-ts-mode . combobulate-mode)
;;            (c-or-c++-ts-mode . combobulate-mode)
;;            (tsx-ts-mode . combobulate-mode))
;;     ;; Amend this to the directory where you keep Combobulate's source
;;     ;; code.
;;     :load-path ("~/emacstools/combobulate")))



;; (setq eldoc-echo-area-use-multiline-p nil)

;; (require 'eglot)

;; (progn
;;   (customize-set-variable 'eglot-autoshutdown t)
;;   (customize-set-variable 'eglot-extend-to-xref t)
;;   (customize-set-variable 'eglot-ignored-server-capabilities
;;                           (quote (:documentFormattingProvider :documentRangeFormattingProvider)))

;;   (with-eval-after-load 'eglot
;;         (add-to-list 'eglot-server-programs
;;             '((c-mode c++-mode)
;;                  . ("clangd"
;;                        "-j=8"
;;                        "--log=error"
;;                        "--malloc-trim"
;;                        "--background-index"
;;                        "--clang-tidy"
;;                        "--cross-file-rename"
;;                        "--completion-style=detailed"
;;                        "--pch-storage=memory"
;;                        "--header-insertion=never"
;;                        "--header-insertion-decorators=0"))))

;; (add-hook 'c-mode-hook #'eglot-ensure)
;; (add-hook 'c++-mode-hook #'eglot-ensure)
;; (add-hook 'rustic-mode-hook #'eglot-ensure)
;;)
