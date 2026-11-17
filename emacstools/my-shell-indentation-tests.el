;;; my-shell-indentation-tests.el --- Shell indentation regressions -*- lexical-binding: t; -*-
(require 'ert)
(require 'package)
(package-initialize)
(require 'dtrt-indent)
(load-file (expand-file-name "my-shell-indentation.el" (file-name-directory (or load-file-name buffer-file-name))))
(setq treesit-extra-load-path (list (expand-file-name "~/.emacs.d/tree-sitter/")))

(defconst my/shell-indent-test-text
  "if [ -n \"$force_color_prompt\" ]; then\nif [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null; then\ncolor_prompt=yes\nelse\n    color_prompt=\nfi\nfi\nif [ \"$color_prompt\" = yes ]; then\nPS1='prompt'\nelse\n\tPS1='plain'\nfi\n")

(ert-deftest my/shell-indent-nested-if-uses-four-spaces ()
  (dolist (mode '(sh-mode bash-ts-mode))
    (when (or (eq mode 'sh-mode) (treesit-language-available-p 'bash))
      (with-temp-buffer
        (insert my/shell-indent-test-text)
        (funcall mode)
        (dtrt-indent-mode 1)
        (should-not dtrt-indent-mode)
        (indent-region (point-min) (point-max))
        (dolist (entry '((2 . 4) (3 . 8) (4 . 4) (5 . 8) (6 . 4) (7 . 0) (9 . 4) (11 . 4)))
          (goto-char (point-min)) (forward-line (1- (car entry)))
          (should (= (current-indentation) (cdr entry))))))))

(ert-deftest my/shell-indent-repairs-previous-smie-guess-without-changing-text ()
  (with-temp-buffer
    (insert my/shell-indent-test-text)
    (sh-mode)
    ;; Reproduce the old behavior by bypassing the new guard once.
    (advice-remove 'dtrt-indent-mode #'my/shell-indent--guard-dtrt)
    (unwind-protect
        (dtrt-indent-mode 1)
      (advice-add 'dtrt-indent-mode :around #'my/shell-indent--guard-dtrt))
    (should smie-config--buffer-local)
    (set-buffer-modified-p nil)
    (let ((text (buffer-string)))
      (my/shell-indent-apply)
      (should-not smie-config--buffer-local)
      (should-not dtrt-indent-mode)
      (should-not (buffer-modified-p))
      (should (equal text (buffer-string))))
    (indent-region (point-min) (point-max))
    (goto-char (point-min)) (forward-line 1)
    (should (= (current-indentation) 4))))

(ert-deftest my/shell-indent-does-not-block-other-modes ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (let (called)
      (should (eq (my/shell-indent--guard-dtrt
                   (lambda (&rest args) (setq called args) 'result) 1) 'result))
      (should (equal called '(1))))))

(ert-run-tests-batch-and-exit)
