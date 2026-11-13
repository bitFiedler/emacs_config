;;; my-emacs-sessions-tests.el --- Session restoration checks -*- lexical-binding: t; -*-
(require 'package)
(package-initialize)
(require 'ert)
(load-file (expand-file-name "my-emacs-sessions.el"
                             (file-name-directory load-file-name)))

(defmacro my-session-test-fixture (&rest body)
  (declare (indent 0))
  `(save-window-excursion
     (let* ((root (make-temp-file "session-tests-" t))
            (dir (expand-file-name "saved/" root))
            (temporary-file-directory root)
            (one (expand-file-name "first.txt" root))
            (two (expand-file-name "second.txt" root))
            (desktop-dirname dir)
            (desktop-file-modtime 'original-modtime)
            (desktop-file-checksum 'original-checksum)
            (desktop-path '("original-path"))
            (my/session-dir "original-save-destination")
            (desktop-restore-eager 0))
       (unwind-protect
           (progn
             (make-directory dir)
             (with-temp-file one (insert "first file"))
             (with-temp-file two (insert "second file"))
             (with-temp-file (my/session-desktop-file dir)
               (dolist (file (list one two))
                 (prin1 `(desktop-create-buffer
                          208 ,file ,(file-name-nondirectory file)
                          'fundamental-mode nil 1 '(nil nil) nil nil nil nil)
                        (current-buffer))
                 (insert "\n")))
             ;; Simulate a saved session already owned by this Emacs.
             (with-temp-file (desktop-full-lock-name dir)
               (insert (number-to-string (emacs-pid))))
             ,@body)
         (dolist (file (list one two))
           (when-let* ((buffer (get-file-buffer file))) (kill-buffer buffer)))
         (delete-directory root t)))))

(ert-deftest my-session-locked-snapshot-restores-files-eagerly ()
  (my-session-test-fixture
    (let ((original (with-temp-buffer
                      (insert-file-contents-literally (my/session-desktop-file dir))
                      (buffer-string)))
          (noninteractive nil))
      (should (my/restore-session dir))
      (should (get-file-buffer one))
      (should (get-file-buffer two))
      (should-not desktop-buffer-args-list)
      (should (= (desktop-owner dir) (emacs-pid)))
      (should (equal original (with-temp-buffer
                                (insert-file-contents-literally (my/session-desktop-file dir))
                                (buffer-string))))
      (should (equal desktop-dirname dir))
      (should (equal desktop-path '("original-path")))
      (should (eq desktop-file-modtime 'original-modtime))
      (should (eq desktop-file-checksum 'original-checksum))
      (should (equal my/session-dir "original-save-destination"))
      (should-not (directory-files root nil "emacs-session-restore-")))))

(ert-deftest my-session-refusal-never-reports-success ()
  (my-session-test-fixture
    (let (messages)
      (cl-letf (((symbol-function 'desktop-read) (lambda (&rest _) nil))
                ((symbol-function 'message)
                 (lambda (format &rest args) (push (apply #'format format args) messages))))
        (should-error (my/restore-session dir) :type 'user-error))
      (should-not (cl-some (lambda (message) (string-prefix-p "Restored Emacs" message)) messages))
      (should-not (directory-files root nil "emacs-session-restore-"))
      (should (= (desktop-owner dir) (emacs-pid))))))

(ert-deftest my-session-quit-cleans-snapshot ()
  (my-session-test-fixture
    (cl-letf (((symbol-function 'desktop-read) (lambda (&rest _) (signal 'quit nil))))
      (condition-case nil (my/restore-session dir) (quit nil)))
    (should-not (directory-files root nil "emacs-session-restore-"))
    (should (= (desktop-owner dir) (emacs-pid)))))

(ert-run-tests-batch-and-exit)
