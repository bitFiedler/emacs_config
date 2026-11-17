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

(ert-deftest my/shell-indent-detects-space-and-tab-files ()
  (dolist (mode '(sh-mode bash-ts-mode))
    (when (or (eq mode 'sh-mode) (treesit-language-available-p 'bash))
      (dolist (tabs '(nil t))
        (with-temp-buffer
          (insert (if tabs
                      "if true; then\n\techo one\n\tif true; then\n\t\techo two\n\tfi\nfi\n"
                    "if true; then\n    echo one\n    if true; then\n        echo two\n    fi\nfi\n"))
          (funcall mode)
          (should (eq indent-tabs-mode tabs))
          (should-not smie-config--buffer-local)
          (indent-region (point-min) (point-max))
          (goto-char (point-min)) (forward-line 1)
          (should (looking-at (if tabs "\techo" "    echo"))))))))

(ert-deftest my/shell-indent-detection-ignores-strings-and-comments ()
  (with-temp-buffer
    (insert "value='\n\tquoted one\n\tquoted two\n\tquoted three\n'\nif true; then\n    echo value\n    # comment\n\t# another comment\nfi\n")
    (sh-mode)
    (should-not indent-tabs-mode)))

(ert-deftest my/shell-indent-detection-tie-and-explicit-style ()
  (with-temp-buffer
    (insert "if true; then\n\techo tabs\n    echo spaces\nfi\n")
    (sh-mode)
    (should-not indent-tabs-mode)
    (let ((my/shell-indent-tabs t))
      (my/shell-indent-apply)
      (should indent-tabs-mode))
    (setq-local file-local-variables-alist '((indent-tabs-mode . nil) (tab-width . 8)))
    (setq-local indent-tabs-mode nil tab-width 8)
    (let ((my/shell-indent-tabs t))
      (my/shell-indent-apply)
      (should-not indent-tabs-mode)
      (should (= tab-width 8)))))

(ert-deftest my/shell-indent-leaves-interactive-shell-mode-alone ()
  (require 'shell)
  (with-temp-buffer
    (shell-mode)
    (setq-local indent-tabs-mode t tab-width 8)
    (my/shell-indent-apply)
    (should indent-tabs-mode)
    (should (= tab-width 8))))

(ert-deftest my/shell-indent-detects-block-widths ()
  (dolist (mode '(sh-mode bash-ts-mode))
    (when (or (eq mode 'sh-mode) (treesit-language-available-p 'bash))
      (dolist (width '(2 3 4 8))
        (with-temp-buffer
          (let ((pad (make-string width ?\s)))
            (insert "if true; then\n" pad "echo one\n"
                    pad "for item in a b; do\n" pad pad "echo two\n"
                    pad "done\nfi\n"))
          (funcall mode)
          (should (= sh-basic-offset width))
          (should (= tab-width width))
          (should-not smie-config--buffer-local)
          (indent-region (point-min) (point-max))
          (goto-char (point-min)) (forward-line 3)
          (should (= (current-indentation) (* 2 width))))))))

(ert-deftest my/shell-indent-width-ignores-alignment-and-quoted-openers ()
  (with-temp-buffer
    (insert "echo \"then\"\n        echo aligned\n"
            "value='\nif true; then\n        quoted\n'\n"
            "# if true; then\n#         ignored\n"
            "if true; then # real block\n\n  # comment\n  echo one\n"
            "  echo command \\\n          argument\nfi\n"
            "function example() {\n  echo two\n}\n")
    (sh-mode)
    (should (= sh-basic-offset 2))))

(ert-deftest my/shell-indent-width-fallbacks ()
  (dolist (text '("echo plain\n"
                  "if true; then\necho broken\nfi\n"
                  "if true; then\n\techo tabs\nfi\n"
                  "if true; then\n  echo two\nelse\n    echo four\nfi\n"))
    (with-temp-buffer
      (insert text)
      (let ((my/shell-indent-offset 4))
        (sh-mode)
        (should (= sh-basic-offset 4))))))

(ert-deftest my/shell-indent-width-explicit-and-disabled ()
  (with-temp-buffer
    (insert "if true; then\n  echo two\nfi\n")
    (sh-mode)
    (should (= sh-basic-offset 2))
    (let ((my/shell-indent-detect-width nil) (my/shell-indent-offset 6))
      (my/shell-indent-apply)
      (should (= sh-basic-offset 6)))
    (setq-local file-local-variables-alist '((sh-basic-offset . 3)))
    (setq-local sh-basic-offset 3)
    (my/shell-indent-apply)
    (should (= sh-basic-offset 3))
    (should (= tab-width 3))
    (setq-local file-local-variables-alist nil)
    (setq-local dir-local-variables-alist '((sh-basic-offset . 8) (tab-width . 8)))
    (setq-local sh-basic-offset 8 tab-width 8)
    (my/shell-indent-apply)
    (should (= sh-basic-offset 8))
    (should (= tab-width 8))))

(ert-run-tests-batch-and-exit)
