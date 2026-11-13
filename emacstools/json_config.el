;; ########## json mode #######  -*- lexical-binding: t; -*-
;; (defun json-compact ()
;;   "Collapse prettified json to a single line"
;;   (interactive)
;;   (save-excursion
;;     (shell-command-on-region (point-min)
;;                              (point-max)
;;                              "python3 -m json.tool --compact"
;;                              (buffer-name) t)))

;; (defun json-pretty ()
;;   "pretty print json"
;;   (interactive)
;;   (save-excursion
;;     (shell-command-on-region (point-min)
;;                              (point-max)
;;                              "python3 -m json.tool"
;;                              (buffer-name) t)))

;; ;; use prettyPrintJson.py to adjust the json file nicely
;; (defun json-super-pretty ()
;;   "Format json file with python script."
;;   (interactive)
;;   (shell-command (concat "python3 /home/mp/sourcen/python-tools/lios/prettyPrintJson.py " (buffer-file-name) " -sp"))
;;   )

;; ;; json file change indent level to 2, default is 4
;; (add-hook 'json-mode-hook
;;           (lambda ()
;;             (make-local-variable 'js-indent-level)
;;             (setq js-indent-level 2)
;;             ;; (local-key (kbd "C-c C-f") 'json-pretty)
;;             ;; (local-key (kbd "C-c C-c") 'json-compact)
;;             ))
;; ;; ;;(define-key helm-gtags-mode-map (kbd "C-c g a") 'helm-gtags-tags-in-this-function)
;; ;; ;;(define-key jsonc-mode-map (kbd "C-c C-f")        'json-pretty-print-buffer)

;; (use-package json-mode
;;   :ensure t
;;   )

;; (eval-after-load 'json-mode
;;   '(progn
;;      (define-key json-mode-map (kbd "C-c C-f") 'json-pretty)
;;      (define-key json-mode-map (kbd "C-c C-c") 'json-compact)))

;; ;; add arri caldata json support
;; (add-to-list 'auto-mode-alist '("\\.cfj\\'" . json-mode))
;; (add-to-list 'auto-mode-alist '("\\.jfav\\'" . json-mode))
;; (add-to-list 'auto-mode-alist '("\\.jset\\'" . json-mode))
;; (add-to-list 'auto-mode-alist '("\\.json\\'" . json-mode))
;; (add-to-list 'auto-mode-alist '("\\.jdmxp\\'" . json-mode))




;; ===========================
;; JSON UTILITIES
;; ===========================

(defun json-compact ()
  "Compact prettified JSON into a single line."
  (interactive)
  (save-excursion
    (shell-command-on-region
     (point-min) (point-max)
     "python3 -m json.tool --compact"
     (current-buffer) t)))

(defun json-pretty ()
  "Pretty-print JSON using Python."
  (interactive)
  (save-excursion
    (shell-command-on-region
     (point-min) (point-max)
     "python3 -m json.tool"
     (current-buffer) t)))

(defun json-super-pretty ()
  "Format JSON using custom prettyPrintJson.py script."
  (interactive)
  (let ((cmd (format "python3 /home/mp/sourcen/python-tools/lios/prettyPrintJson.py %s -sp"
                     (shell-quote-argument (buffer-file-name)))))
    (shell-command cmd)))

;; ===========================
;; JSON MODE
;; ===========================

(use-package json-mode
  :ensure t
  :mode (("\\.cfj\\'"   . json-mode)
         ("\\.jfav\\'"  . json-mode)
         ("\\.jset\\'"  . json-mode)
         ("\\.json\\'"  . json-mode)
         ("\\.jdmxp\\'" . json-mode))
  :hook ((json-mode . (lambda ()
                        ;; Use 2-space indent
                        (setq-local js-indent-level 2))))
  :bind (:map json-mode-map
              ;; Pretty
              ("C-c C-f" . json-pretty)
              ;; Compact
              ("C-c C-c" . json-compact)
              ;; Super pretty
              ("C-c C-s" . json-super-pretty)))

;; ########## json mode end #######
