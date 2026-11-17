;;; my-project-build-tests.el --- Isolated build integration tests -*- lexical-binding: t; -*-
(require 'ert)
(load-file (expand-file-name "my-project-build.el" (file-name-directory (or load-file-name buffer-file-name))))

(ert-deftest my/build-native-and-docker-command-quoting ()
  (let* ((root (file-name-as-directory (make-temp-file "project space ' " t)))
         (task '("Build" :command "printf '%s' \"a;b\"" :docker-image "registry.example/image:tag" :container-root "/workspace")))
    (unwind-protect
        (progn
          (should (equal (my/project-build--command root '("Native" :command "make -j2")) "make -j2"))
          (let ((command (my/project-build--command root task)))
            ;; The shell must reconstruct every argument, including metacharacters.
            (should (equal (shell-command-to-string (concat "python3 -c " (shell-quote-argument "import sys; print(sys.argv[-1], end='')") " " command))
                           (plist-get (cdr task) :command))))
          (should-error (my/project-build--command root '("Bad" :command "make" :directory "../")))
          (should-error (my/project-build--command root '("Bad" :command "make" :docker-image "image"))))
      (delete-directory root t))))

(ert-deftest my/build-preview-does-not-start-a-process ()
  (let ((root (file-name-as-directory temporary-file-directory)))
    (cl-letf (((symbol-function 'compilation-start) (lambda (&rest _) (ert-fail "Preview started build"))))
      (save-window-excursion
        (my/project-build--preview root '("Check" :command "make" :docker-image "image" :container-root "/project"))
        (with-current-buffer "*Project Build Command*"
          (should (string-match-p "does not start a build" (buffer-string))))))))

(defun my/build-test--wait (buffer)
  (let ((deadline (+ (float-time) 8)))
    (while (and (get-buffer-process buffer) (< (float-time) deadline))
      (accept-process-output (get-buffer-process buffer) 0.05))
    (should-not (get-buffer-process buffer))))

(ert-deftest my/build-error-navigation-and-recompile ()
  (let* ((root (file-name-as-directory (make-temp-file "build navigation " t)))
         (file (expand-file-name "src/example.c" root))
         (my/project-build--last (make-hash-table :test #'equal))
         (task '("Simulated Docker" :command "unused" :docker-image "image" :container-root "/workspace"))
         (output "make: Entering directory '/workspace/src'\nexample.c:3:2: error: relative diagnostic\n/workspace/src/example.c:4:2: error: absolute diagnostic\n")
         buffer process)
    (make-directory (file-name-directory file) t)
    (with-temp-file file (insert "one\ntwo\nthree\nfour\n"))
    (unwind-protect
        (save-window-excursion
          (cl-letf (((symbol-function 'my/project-build--command)
                     (lambda (&rest _) (concat "printf %s " (shell-quote-argument output) "; exit 2"))))
            (setq buffer (my/project-build--start root task))
            (setq process (get-buffer-process buffer)))
          (my/build-test--wait buffer)
          (with-current-buffer buffer
            (should (derived-mode-p 'compilation-mode))
            (should (= (process-exit-status process) 2))
            (compilation-next-error-function 1 t))
          (set-buffer (window-buffer (selected-window)))
          (should (equal (buffer-file-name) file))
          (should (= (line-number-at-pos) 3))
          (with-current-buffer buffer (compilation-next-error-function 1))
          (set-buffer (window-buffer (selected-window)))
          (should (equal (buffer-file-name) file))
          (should (= (line-number-at-pos) 4))
          (with-current-buffer buffer (my/project-build-repeat))
          (my/build-test--wait buffer)
          (with-current-buffer buffer
            (should (equal my/project-build--mount "/workspace"))
            (compilation-next-error-function 1 t))
          (set-buffer (window-buffer (selected-window)))
          (should (= (line-number-at-pos) 3)))
      (when (buffer-live-p buffer) (kill-buffer buffer))
      (when-let* ((visited (get-file-buffer file))) (kill-buffer visited))
      (delete-directory root t))))

(ert-deftest my/build-path-map-is-local-and-can-be-cleared ()
  (let ((original (copy-tree (default-value 'compilation-transform-file-match-alist))))
    (with-temp-buffer
      (my/project-build-compilation-mode)
      (setq-local my/project-build--root "/host/project/")
      (setq-local my/project-build--mount "/workspace")
      (my/project-build--configure-output)
      (should (equal (my/project-build--map-file "/workspace/file.c") "/host/project/file.c"))
      (should (equal (my/project-build--map-file "/workspace-other/file.c") "/workspace-other/file.c"))
      (should (equal original (default-value 'compilation-transform-file-match-alist)))
      (setq-local my/project-build--mount nil)
      (my/project-build--configure-output)
      (should (equal original compilation-transform-file-match-alist)))))

(ert-deftest my/build-refuses-duplicate-running-task ()
  (let* ((root (file-name-as-directory (make-temp-file "build duplicate " t)))
         (task '("Waiting" :command "sleep 5")) buffer)
    (unwind-protect
        (save-window-excursion
          (setq buffer (my/project-build--start root task))
          (should-error (my/project-build--start root task) :type 'user-error))
      (when-let* ((process (and buffer (get-buffer-process buffer))))
        (set-process-query-on-exit-flag process nil) (delete-process process))
      (when (buffer-live-p buffer) (kill-buffer buffer))
      (delete-directory root t))))

(ert-run-tests-batch-and-exit)
