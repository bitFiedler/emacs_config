;;; my-yaml-ts-font-lock-tests.el --- YAML color regression tests -*- lexical-binding: t; -*-
(require 'ert)
(load-file (expand-file-name "my-yaml-ts-font-lock.el"
                             (file-name-directory load-file-name)))

(defmacro my-yaml-test-buffer (text &rest body)
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,text)
     (setq-local treesit-font-lock-level 4)
     (yaml-ts-mode)
     (font-lock-ensure)
     ,@body))

(defun my-yaml-test-face (text)
  (goto-char (point-min))
  (search-forward text)
  (get-text-property (1- (point)) 'face))

(ert-deftest my-yaml-plain-vs-quoted-values ()
  (my-yaml-test-buffer "plain: build\nquoted: \"hello\"\n'key': 'value'\nnumber: 42\nflag: true\n# comment\n"
    (should-not (eq (my-yaml-test-face "build") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "hello") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "value") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "key") 'font-lock-property-use-face))
    (should (eq (my-yaml-test-face "42") 'font-lock-number-face))
    (should (eq (my-yaml-test-face "true") 'font-lock-constant-face))
    (should (eq (my-yaml-test-face "comment") 'font-lock-comment-face))))

(ert-deftest my-yaml-script-quotes-bounded-to-scalar ()
  (my-yaml-test-buffer "script:\n  - |\n    NAME=\"hello\"\n    echo '$NAME'\n    broken=\"unfinished\nnext: build\nother: \"safe\"\ninline: echo \"inline quote\"\n"
    (should-not (eq (my-yaml-test-face "NAME=") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "hello") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "$NAME") 'font-lock-string-face))
    (should-not (eq (my-yaml-test-face "build") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "safe") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "inline quote") 'font-lock-string-face))
    (goto-char (point-min)) (search-forward "hello")
    (delete-region (- (point) 5) (point)) (insert "changed")
    (font-lock-ensure)
    (should (eq (my-yaml-test-face "changed") 'font-lock-string-face))))

(ert-deftest my-yaml-real-gitlab-ci ()
  (with-temp-buffer
    (insert-file-contents "/home/mp/sourcen/leo/leo/.gitlab-ci.yml")
    (yaml-ts-mode)
    (font-lock-ensure)
    (should-not (eq (my-yaml-test-face "ELBE_HASH=") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "initvm-${ELBE_HASH}.tar.zstd") 'font-lock-string-face))
    (should-not (eq (my-yaml-test-face "      mkdir -p") 'font-lock-string-face))
    (should (eq (my-yaml-test-face "1 week") nil))))

(ert-run-tests-batch-and-exit)
