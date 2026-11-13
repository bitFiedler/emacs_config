;; -*- lexical-binding: t; -*-
(load-file "~/emacstools/c_cpp_templates.el")
;; ======== Tabs for C and config for C and C++ mode ===========================
;; (defun my-build-tab-stop-list (width)
;;   (let ((num-tab-stops (/ 80 width))
;; 	(counter 1)
;; 	(ls nil))
;;     (while (<= counter num-tab-stops)
;;       (setq ls (cons (* width counter) ls))
;;       (setq counter (1+ counter)))
;;     (set (make-local-variable 'tab-stop-list) (nreverse ls))))

(defvar current-date-time-format "%a %b %H:%M:%S %Y"
  "Format of date to insert with `insert-current-date-time' func
See help of `format-time-string' for possible replacements")

(defun insert-current-date-time ()
  "insert the current date and time into current buffer.
Uses `current-date-time-format' for the formatting the date/time."
  (interactive)
  (insert (format-time-string current-date-time-format (current-time)))
  )


;; search for new types in all visited files
;;(ctypes-auto-parse-mode 1) 

(defun my-c-mode-common-hook ()
  ;;   add my personal style and set it for the current buffer
  ;;(c-add-style "personal" mk-c-style t)
  (c-set-style "user")
  (setq tab-width 4
        indent-tabs-mode nil) ; ensure spaces instead of tabs
  (c-toggle-auto-newline 1)
  (c-toggle-hungry-state 1) 
  ;;(my-build-tab-stop-list tab-width)
  ;;(setq c-basic-offset tab-width)
  (c-set-offset 'case-label '+)
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'innamespace 0) ;; remove indent in an namespace
  (c-set-offset 'inline-open '0) ;; remove indent in class
  ;;(doxymacs-mode 1)
  (hs-minor-mode 1)
  (my/context-breadcrumb-mode 1)
  (ggtags-mode 1)
  ;; use c++ comment style in c-mode
  (setq comment-start "//"
        comment-end   "")
  )

;;; hook hs-minor-mode on the c-ts-mode
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)
(add-hook 'c++-mode-common-hook 'my-c-mode-common-hook)

(require 'cc-mode)
;;(autoload 'c++-ts-mode  "cc-mode" "C++ Editing Mode" t)
;;(autoload 'c-ts-mode    "cc-mode" "C Editing Mode" t)
(autoload 'objc-mode "cc-mode" "Objective-C Editing Mode" t)
(autoload 'java-mode "cc-mode" "Java Editing Mode" t)

(setq auto-mode-alist
      (append
       '(("\\.cc$"   . c++-mode)
         ("\\.hh$"   . c++-mode)
         ("\\.hpp$"  . c++-mode)
         ("\\.ipp$"  . c++-mode)
         ("\\.tcc$"  . c++-mode)
         ("\\.c$"    . c-mode)
         ("\\.C$"    . c-mode)
         ("\\.h$"    . c-mode)
         ("\\.H$"    . c-mode)
         ) auto-mode-alist))

;; ============================== c/cpp key mode-map ============================
;; comment einfügen oder markiertes auskommentieren
;; zuweisungen schön ausrichten !!!
;; (define-key c-mode-map (kbd "C-+")        'align)
;; (define-key c++-mode-map (kbd "C-+")      'align) 
;; ;; find includefile in ...
;; (define-key c-mode-map (kbd "C-f")        'ff-find-other-file)
;; (define-key c++-mode-map (kbd "C-f")      'ff-find-other-file)
;; ;; code automatisch einrücken, vorher markieren !!!
;; ;;(define-key c-mode-map (kbd "C-!")        'indent-region) 
;; ;;(define-key global-map [(f3)]             'indent-region) -> C-M \
;; (define-key global-map [(f4)]             'insert-current-date-time)
;; ;; new line ident
;; (define-key c-mode-map [(return)]         'newline-and-indent) 
;; (define-key c++-mode-map [(return)]       'newline-and-indent)
;; ;; show all funkt, var, inc from file 
;; (define-key c-mode-map (kbd "C-i")        'imenu)
;; (define-key c++-mode-map (kbd "C-i")        'imenu)
;; ;; tab indent
;; (define-key c-mode-map [(tab)]            'c-indent-command)
;; (define-key c++-mode-map [(tab)]          'c-indent-command)
;; for compile
;; (define-key c-mode-map [(f7)]             'compile-parent)
;; (define-key c++-mode-map [(f7)]           'compile-parent)
;; for recompile
;; (define-key c-mode-map [(f8)]             'recompile)
;; (define-key c++-mode-map [(f8)]           'recompile)

(load-file "~/emacstools/ascii-table.el")
(require 'ascii-table)
(load-file "~/emacstools/my-ascii-table.el")
(define-key c-mode-map [(f10)] 'ascii-table-hex)
(define-key c++-mode-map [(f10)] 'ascii-table-hex)

;; hide-ifdef-mode
;; C-c @ C-q hide-ifdef-toggle-read-only
;; C-c @ C-s show-ifdef-block
;; C-c @ C-d hide-ifdef-block
;; C-c @ s   show-ifdefs
;; C-c @ h   hide-ifdefs
;; C-c @ U   hide-ifdef-use-define-alist
;; C-c @ D   hide-ifdef-sef-define-alist
;; C-c @ u   hide-ifdef-undef
;; C-c @ d   hide-ifdef-define

;;C-M-a     Move to beginning of current or preceding defun (beginning-of-defun). 
;;C-M-e     Move to end of current or following defun (end-of-defun). 
;;C-M-h     Put region around whole current or following defun (mark-defun).
;;C-M-n     go to next } or )
;;C-M-p     go to next { or (
;; =============================================================================

;; ;; ========================== PRINTING IN WINDOWS ===========================
;; ;;; ========= Printing ======================================================
;; (setq printer-name "HP5100PS.CSR") ; printer name
;; ;; ;(setq printer-name "Laserjet_Color") ; printer name

;; (when (locate-library "ps-print")
;;   (require 'ps-print)
;;   (require 'ps-mule)
;;   (setq ps-multibyte-buffer 'bdf-font-except-latin
;;         ps-mule-font-info-database ps-mule-font-info-database-ps-bdf
;;         ps-print-color-p nil
;;         ps-paper-type 'a4
;;         ps-font-size 10.0
;;         ps-print-header t
;; ;;        ps-landscape-mode 1
;;         ps-lpr-command "lpr"
;;         ps-printer-name "LaserJet"
;;         printer-name "LaserJet"))

;; ;; (setenv "GS_LIB" "c:/Program Files/gs/gs8.71/lib;c:/Program Files/gs/gs8.71/fonts")
;; ;; (setq ps-lpr-command "c:/Program Files/gs/gs8.71/bin/gswin32c.exe")
;; ;; (setq ps-lpr-switches '("-q" "-dNOPAUSE" "-dBATCH" "-sDEVICE=mswinpr2"))
;; (setq ps-printer-name t)

;; ;; ;; Wenn du `M-x rs-ps-print-buffer RET' (bzw. `C-u M-x rs-ps-print-buffer
;; ;; ;; dateiname.ps RET') aufrufst, bekommst du andere Header.
;; ;; (defun mk-ps-left-header-line-1 ()
;; ;;   "Dummy-Text aus rs-ps-left-header-line-1")
;; ;; (defun mk-ps-left-header-line-2 ()
;; ;;   "Dummy-Text aus rs-ps-left-header-line-2")
;; ;; (defun mk-ps-print-buffer (&optional filename)
;; ;;   (interactive (list (ps-print-preprint current-prefix-arg)))
;; ;; (let ((ps-left-header (list 'rs-ps-left-header-line-1
;; ;; 			'rs-ps-left-header-line-2)))
;; ;;     (ps-print-buffer filename)))

;; ;;(define-key global-map "\C-cp" 'nt-ps-print-buffer-with-faces)
  ;; (setq ps-lpr-command "c:\\Program Files\\Ghostgum\\gsview\\gsprint.exe")

      ;; THis line causes ghostscript to query which printer to
      ;; use - which you may not need if, for example, you only
      ;; have one printer.
      ;; (setq ps-lpr-switches '("-query"))

      ;; (setq ps-printer-name t)


;; ;;; =========================================================================

;; ;;; ========= W3 settings ===================================================
 ;; (setq url-proxy-services '(("http" . "192.168.1.5:3128")
 ;;                            ("ftp"  . "192.168.1.5:3128")))
;; ;;; =========================================================================

 ;; ===== Automatically load abbreviations table ===============================

;; ;; Note that emacs chooses, by default, the filename
;; ;; "~/.abbrev_defs", so don't try to be too clever
;; ;; by changing its name

;; ;; (setq-default abbrev-mode t)
;; ;; (read-abbrev-file "~/.abbrev_defs")
;; ;; (setq save-abbrevs t)
;; ;; =============================================================================

;gtags -> gnu global tag files, better as ctag
;; (use-package ggtags
;;   :ensure t
;;   :config
;;   (add-hook 'c-ts-mode-common-hook
;;             (lambda ()
;;               (when (derived-mode-p 'c-ts-mode 'c++-ts-mode 'java-mode 'c++-mode 'c-mode)
;;                 (ggtags-mode 1))))
;;   )

(use-package ggtags
  :ensure t
  :hook ((c-mode          . ggtags-mode)
         (c++-mode        . ggtags-mode)
         (c-ts-mode       . ggtags-mode)
         (c++-ts-mode     . ggtags-mode)
         (java-mode       . ggtags-mode))
  :config
  ;; remove local key map to M-s because it is global mapped to deadrep
  (define-key ggtags-navigation-map (kbd "M-s") nil)
  )

;; (add-hook 'c++-mode-hook
;;           #'(lambda ()
;;               (push '(?< . ?>)
;;                     (getf autopair-extra-pairs :code))))


;; eglot support 


;; (require 'eglot)
;; (setq eglot-booster-mode t)
;; (fset #'jsonrpc--log-event #'ignore)

;; (use-package eglot
;;   :ensure t
;;   :commands eglot
;;   :config
;;   (setq eglot-events-buffer-size 0)
;;   (setq eglot-booster-mode t)
;;   (add-to-list 'eglot-server-programs
;;                '((c-mode c++-mode c-ts-mode c++-ts-mode)
;;                  . ("clangd-20"
;;                     "-j=16"
;;                     "--log=verbose"
;;                     "--all-scopes-completion"
;;                     "--malloc-trim"
;;                     "--experimental-modules-support"
;;                     "--pch-storage=memory"
;;                     "--completion-style=detailed"
;;                     "--limit-results=1000"
;;                     "--limit-references=10000000"
;;                     "--compile_args_from=filesystem"
;;                     "--pch-storage=memory"
;;                     "--header-insertion=never"
;;                     "--completion-parse=always"
;;                     "--function-arg-placeholders=1"
;;                     "--enable-config"
;;                     ;;"--include-ineligible-results"
;;                     "--use-dirty-headers"
;;                     ;;"--sync"
;;                     "--header-insertion=iwyu"
;;                     "--header-insertion-decorators=1"
;;                     ;;"--pretty"
;;                     ;;"--compile-commands-dir=/home/mp/sourcen/jupiter/main-application/build/Target_Default"
;;                     ;;"--query-driver=/opt/orbiter-tiny/5.0.7/sysroots/cortexa7t2hf-neon-vfpv4-poky-linux-musleabi/usr/include,/opt/orbiter-tiny/5.0.7/sysroots/x86_64-pokysdk-linux/usr/bin/x86_64-pokysdk-linux-*"
;;                     )))
;;   )



;; ;;"--include-cleaner-stdlib"
;; ;;"--compile_args_from=filesystem"
;; ;; "--background-index"
;; ;; "--clang-tidy"
;; ;;"--compile_args_from=filesystem"

;; (progn
;;   (face-spec-set 'eglot-diagnostic-tag-unnecessary-face
;; 			     '((t (:inherit default))))
;;   (face-spec-set 'eglot-diagnostic-tag-deprecated-face
;; 			     '((t (:inherit default)))))

;; ;; Prevent Indentation Conflicts in eglot by Disabling LSP Formatting
;; ;; on Return, important otherwise eglot reformats region on enter
;; (setq eglot-ignored-server-capabilities '(:documentFormattingProvider :documentOnTypeFormattingProvider))

(require 'company)
;; (require 'lsp-mode)
(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c++-hook (lambda () (setq company-backends '(company-eglot))))
(add-hook 'c-mode-hook 'company-mode)
(add-hook 'c-hook (lambda () (setq company-backends '(company-eglot))))


;; (add-hook 'c++-ts-mode-hook 'company-mode)
;; (add-hook 'c++-ts-mode-hook (lambda () (setq company-backends '(company-eglot))))

;; (add-hook 'c-mode-hook 'eglot-ensure)
;; (add-hook 'c++-mode-hook 'eglot-ensure)
;; (add-hook 'c-ts-mode-hook 'eglot-ensure)
;; (add-hook 'c++-ts-mode-hook 'eglot-ensure)





;; new config


;;; ----------------------------------------
;;; Insert current date/time
;;; ----------------------------------------

(defvar current-date-time-format "%a %b %H:%M:%S %Y"
  "Format used by `insert-current-date-time'.  
See `format-time-string' for details.")

(defun insert-current-date-time ()
  "Insert the current date/time at point."
  (interactive)
  (insert (format-time-string current-date-time-format)))

;;(global-set-key (kbd "<f4>") #'insert-current-date-time)

;;; ----------------------------------------
;;; ASCII Table
;;; ----------------------------------------

(load-file "~/emacstools/ascii-table.el")
(use-package ascii-table
  :ensure nil
  :config
  :hook ((c-mode       . my/ascii-table-keys)
         (c++-mode     . my/ascii-table-keys)
         (c-ts-mode    . my/ascii-table-keys)
         (c++-ts-mode  . my/ascii-table-keys))
  :config
  (defun my/ascii-table-keys ()
    (local-set-key (kbd "<f10>") #'ascii-table-hex))
  )


;;; ----------------------------------------
;;; C/C++ common setup
;;; ----------------------------------------

(defun my-c-mode-common-hook ()
  "Personal settings for all C-like modes."
  (c-set-style "user")

  (setq tab-width 4
        indent-tabs-mode nil   ; always spaces
        comment-start "//"
        comment-end "")

  (c-toggle-auto-newline 1)
  (c-toggle-hungry-state 1)

  ;; custom offsets
  (c-set-offset 'case-label '+)
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'innamespace 0)
  (c-set-offset 'inline-open 0)

  ;; useful minor modes
  (hs-minor-mode 1)
  (my/context-breadcrumb-mode 1)
  (ggtags-mode 1)

  ;; Use cc-mode indentation functions even in treesit-mode
  (setq-local indent-line-function 'c-indent-line)
  )

;; Classic cc-mode
(add-hook 'c-mode-common-hook   #'my-c-mode-common-hook)
(add-hook 'c++-mode-common-hook #'my-c-mode-common-hook)

;;; ----------------------------------------
;;; File associations
;;; ----------------------------------------

(add-to-list 'auto-mode-alist '("\\.cc\\'"  . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hh\\'"  . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.ipp\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.tcc\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.c\\'"   . c++-mode))
(add-to-list 'auto-mode-alist '("\\.C\\'"   . c++-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'"   . c++-mode))
(add-to-list 'auto-mode-alist '("\\.H\\'"   . c++-mode))


;;; ----------------------------------------
;;; C/C++ keybindings
;;; ----------------------------------------

(defun my/c-like-keys ()
  (local-set-key (kbd "C-+") #'align) ;; zuweisungen schön ausrichten !!!
  (local-set-key (kbd "C-f") #'ff-find-other-file)
  (local-set-key (kbd "C-i") #'imenu)
  ;; new line ident
  (local-set-key (kbd "<return>") #'newline-and-indent)
  ;; tab indent
  (local-set-key (kbd "<tab>") #'indent-for-tab-command)

  (local-set-key (kbd "C-+") #'align)
  ;; find includefile in ...
  (local-set-key (kbd "C-f") #'ff-find-other-file)
  (local-set-key (kbd "<f4>") #'insert-current-date-time)

  ;; for compile
  ;; (local-set-key (kbd "<f7>) #'compile-parent)
  ;; for recompile
  ;; (local-set-key (kbd "<f8>) #'recompile)

  )

;; Classic cc-mode
(add-hook 'c-mode-hook       #'my/c-like-keys)
(add-hook 'c++-mode-hook     #'my/c-like-keys)

;; Tree-sitter C/C++
(add-hook 'c-ts-mode-hook    #'my/c-like-keys)
(add-hook 'c++-ts-mode-hook  #'my/c-like-keys)


(setq treesit-simple-indent-debug t)

(defun my-c-ts-bsd-style ()
  ;; basic indentation
  (setq-local tab-width 4
              indent-tabs-mode nil
              treesit-simple-indent-offset 4)

  ;; BSD-style indentation rules
  (setq-local treesit-simple-indent-rules
              '((c
                 ((node-is "}") parent-bol 0)
                 ((node-is ")") parent-bol 0)
                 ((node-is "]") parent-bol 0)
                 ((node-is ">") parent-bol 0)
                 ((node-is "\\.") parent-bol ,offset)
                 
                 ;; top-level
                 ((parent-is "translation_unit") column-0)

                 ;; compound statement itself (BSD)
                 ((node-is "compound_statement") parent-bol 0)

                 ;; statements inside blocks
                 ((parent-is "compound_statement") parent-bol 4)

                 ;; control statements
                 ((parent-is "if_statement") parent-bol 4)
                 ((parent-is "for_statement") parent-bol 4)
                 ((parent-is "while_statement") parent-bol 4)

                 ;; enum class members: indent 4
                 ((parent-is "enumerator") parent-bol 4)
                 ((parent-is "enum_specifier") parent-bol 0)
                 
                 ;; switch / case
                 ((parent-is "switch_statement") parent-bol 4)
                 ((parent-is "case_statement") parent-bol 4)
                 ((parent-is "default_statement") parent-bol 4)

                 ;; namespaces (BSD)
                 ((parent-is "namespace_definition") parent-bol 0)
                 ((parent-is "namespace_definition") parent-bol 4)
                 ;;((node-is "namespace_definition") parent-bol 0)
                 )
                
                (cpp
                 ;; This rule matches if node at point is "}", ANCHOR is the
                 ;; parent node’s BOL, and offset is 0.
                 ((node-is "}") parent-bol 0)
                 ((node-is ")") parent-bol 0)
                 ((node-is "]") parent-bol 0)
                 ((node-is ">") parent-bol 0)
                 ((node-is "\\.") parent-bol ,offset)

                 ((parent-is "translation_unit") column-0)
                 ((node-is "compound_statement") parent-bol 0)
                 ((parent-is "compound_statement") parent-bol 4)
                 ((parent-is "if_statement") parent-bol 4)
                 ((parent-is "for_statement") parent-bol 4)
                 ((parent-is "while_statement") parent-bol 4)

                 ;; enum class members: indent 4
                 ((parent-is "enumerator") parent-bol 4)
                 ((parent-is "enum_specifier") parent-bol 0)
                 
                 ((parent-is "switch_statement") parent-bol 4)
                 ((parent-is "case_statement") parent-bol 4)
                 ((parent-is "default_statement") parent-bol 4)

                 ;;((node-is "jump_statement") parent-bol 4)
                 ;;((node-is "namespace_definition") parent-bol 0)

                 ((parent-is "namespace_definition") parent-bol 0)
                 ((parent-is "namespace_definition") parent-bol 4)
                 )))

  ;; BSD comments (// even in C)
  (setq-local comment-start "// "
              comment-end "")


  ;; Bind TAB to the generic indent command
  ;; This command automatically uses treesit-indent in ts-modes
  (local-set-key (kbd "<tab>") 'indent-for-tab-command)
  
  ;; features from your original setup
  (hs-minor-mode 1)
  (my/context-breadcrumb-mode 1)
  (ggtags-mode 1))


(add-hook 'c-ts-mode-hook #'my-c-ts-bsd-style)
(add-hook 'c++-ts-mode-hook #'my-c-ts-bsd-style)
 
;; remap c-mode and c++-mode to tree-sitter
(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (c-or-c++-mode . c-or-c++-ts-mode)))
