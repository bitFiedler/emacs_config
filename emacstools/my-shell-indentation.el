;;; my-shell-indentation.el --- Predictable shell indentation -*- lexical-binding: t; -*-
(require 'sh-script)
(require 'smie)
(declare-function dtrt-indent-mode "dtrt-indent" (&optional arg))

(defgroup my/shell-indentation nil "Predictable shell indentation." :group 'sh-script)
(defcustom my/shell-indent-offset 4
  "Default shell indentation step in display columns."
  :type 'integer :group 'my/shell-indentation)

(defcustom my/shell-indent-tabs 'detect
  "Whether shell indentation uses tabs or spaces.
With `detect', use the majority of indented code lines in the existing file.
Blank lines, comments and multiline string contents do not vote.  A tab in
leading whitespace counts as tab indentation, including tabs plus alignment
spaces.  Ties and files without indented code default to spaces.
Set to t to force tabs or nil to force spaces.  Explicit directory/file-local
indent-tabs-mode settings take precedence."
  :type '(choice (const :tag "Detect from existing code" detect)
                 (const :tag "Use tabs" t) (const :tag "Use spaces" nil))
  :group 'my/shell-indentation)

(defun my/shell-indent--detect-tabs ()
  "Return non-nil when indented shell code predominantly uses tabs."
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let ((tabs 0) (spaces 0))
        (while (re-search-forward "^\\([ \t]+\\)[^ \t\n]" nil t)
          (let* ((prefix (match-string-no-properties 1))
                 (start (match-end 1))
                 (comment (eq (char-after start) ?#))
                 (syntax (save-match-data (save-excursion (syntax-ppss start)))))
            (unless (or comment (nth 3 syntax) (nth 4 syntax))
              (if (string-match-p "\t" prefix)
                  (setq tabs (1+ tabs))
                (setq spaces (1+ spaces))))))
        (> tabs spaces)))))

(defun my/shell-indent--explicit-p (variable)
  "Whether VARIABLE has an explicit directory/file-local setting."
  (or (assq variable file-local-variables-alist)
      (assq variable dir-local-variables-alist)))

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
    (unless (my/shell-indent--explicit-p 'sh-basic-offset)
      (setq-local sh-basic-offset my/shell-indent-offset))
    (unless (my/shell-indent--explicit-p 'indent-tabs-mode)
      (setq-local indent-tabs-mode
                  (if (eq my/shell-indent-tabs 'detect)
                      (my/shell-indent--detect-tabs)
                    my/shell-indent-tabs)))
    (unless (my/shell-indent--explicit-p 'tab-width)
      (setq-local tab-width my/shell-indent-offset))))

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
