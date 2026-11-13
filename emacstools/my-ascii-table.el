;;; my-ascii-table.el --- Protect ASCII reference buffers -*- lexical-binding: t; -*-

(define-derived-mode my/ascii-table-mode special-mode "ASCII"
  "Read-only ASCII reference; press q to quit the window."
  (setq-local truncate-lines t))

(defun my/ascii-table-read-only (original &rest arguments)
  "Let ORIGINAL refresh its table, then protect the displayed reference."
  (let ((inhibit-read-only t))
    (prog1 (apply original (cons (or (car arguments) 255) (cdr arguments)))
      (my/ascii-table-mode)
      (set-buffer-modified-p nil))))

(with-eval-after-load 'ascii-table
  (unless (advice-member-p #'my/ascii-table-read-only 'ascii-table)
    (advice-add 'ascii-table :around #'my/ascii-table-read-only)))

(provide 'my-ascii-table)
;;; my-ascii-table.el ends here
