;;; my-shell-indentation.el --- Predictable shell indentation -*- lexical-binding: t; -*-
(require 'sh-script)
(require 'smie)
(declare-function dtrt-indent-mode "dtrt-indent" (&optional arg))

(defgroup my/shell-indentation nil "Predictable shell indentation." :group 'sh-script)
(defcustom my/shell-indent-offset 4
  "Default number of spaces per shell indentation level."
  :type 'integer :group 'my/shell-indentation)

(defun my/shell-indent-apply ()
  "Restore normal shell indentation instead of rules learned from broken layout.
This does not reindent or save buffer text.  Explicit directory/file-local
indentation variables can still override these mode-hook defaults."
  (when (derived-mode-p 'sh-base-mode)
    (when (bound-and-true-p dtrt-indent-mode)
      (dtrt-indent-mode -1))
    ;; dtrt-indent delegates shell indentation guessing to smie-config-guess.
    ;; Merely turning dtrt-indent off does not remove its learned SMIE rules.
    (setq-local smie-config--buffer-local nil)
    (setq-local sh-basic-offset my/shell-indent-offset)
    (setq-local indent-tabs-mode nil)
    (setq-local tab-width my/shell-indent-offset)))

(defun my/shell-indent--guard-dtrt (original &rest arguments)
  "Keep automatic indentation guessing out of shell buffers.
Other major modes continue using ORIGINAL with ARGUMENTS unchanged."
  (if (derived-mode-p 'sh-base-mode)
      (when (bound-and-true-p dtrt-indent-mode)
        (funcall original -1))
    (apply original arguments)))

(with-eval-after-load 'dtrt-indent
  (unless (advice-member-p #'my/shell-indent--guard-dtrt 'dtrt-indent-mode)
    (advice-add 'dtrt-indent-mode :around #'my/shell-indent--guard-dtrt)))
(add-hook 'sh-base-mode-hook #'my/shell-indent-apply)

;; A targeted reload repairs already open shell buffers without restarting Eglot
;; or changing the text or modified state of any buffer.
(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (my/shell-indent-apply)))

(provide 'my-shell-indentation)
;;; my-shell-indentation.el ends here
