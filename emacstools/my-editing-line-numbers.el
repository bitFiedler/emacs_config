;;; my-editing-line-numbers.el --- Numbers in editing buffers -*- lexical-binding: t; -*-

(require 'display-line-numbers)

(defgroup my-editing-line-numbers nil
  "Line numbers in editing buffers, without numbers in utility interfaces."
  :group 'display-line-numbers)

(defcustom my/editing-line-numbers-excluded-modes
  '(special-mode dired-mode helm-major-mode comint-mode term-mode vterm-mode eshell-mode
    image-mode doc-view-mode pdf-view-mode)
  "Modes and their descendants that should not display line numbers.
Special mode covers Help, compilation output and most tool buffers.
After changing this list, run `my/editing-line-numbers-refresh'."
  :type '(repeat symbol) :group 'my-editing-line-numbers)

(defun my/editing-line-numbers-buffer-p ()
  "Whether the current buffer is used for editing or viewing a text file."
  (and (not (minibufferp))
       ;; Internal buffers include breadcrumb footers and echo areas.
       (not (string-prefix-p " " (buffer-name)))
       (not (string-match-p "\\`\\*helm" (downcase (buffer-name))))
       (not (apply #'derived-mode-p my/editing-line-numbers-excluded-modes))
       (or buffer-file-name
           (and (not buffer-read-only)
                (derived-mode-p 'prog-mode 'text-mode 'conf-mode 'fundamental-mode)))))

(defun my/editing-line-numbers-apply ()
  "Apply the editing-buffer policy in the current buffer."
  (display-line-numbers-mode (if (my/editing-line-numbers-buffer-p) 1 -1)))

(define-globalized-minor-mode my/editing-line-numbers-mode
  display-line-numbers-mode my/editing-line-numbers-apply
  :group 'my-editing-line-numbers)

(defun my/editing-line-numbers-refresh ()
  "Reapply the active policy to existing buffers."
  (interactive)
  (when my/editing-line-numbers-mode
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (my/editing-line-numbers-apply)))))

(my/editing-line-numbers-mode 1)
(my/editing-line-numbers-refresh)
(provide 'my-editing-line-numbers)
;;; my-editing-line-numbers.el ends here
