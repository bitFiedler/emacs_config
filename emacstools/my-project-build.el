;;; my-project-build.el --- Project build tasks with Helm -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'compile)
(require 'project)
(require 'subr-x)

(defgroup my/project-build nil "Project build task chooser." :group 'tools)
(defcustom my/project-build-tasks nil
  "Project-local named build tasks.
Each entry is (NAME :command SHELL-COMMAND :directory RELATIVE-DIRECTORY
:docker-image IMAGE :container-root MOUNT).  Only :command is required.
Omit Docker properties for a native task.  Directory defaults to the project
root.  Commands are executable project configuration: review local-variable
prompts before accepting them.  With nil, offer basic Make/CMake tasks."
  :type '(repeat (cons string plist)) :group 'my/project-build)
(put 'my/project-build-tasks 'risky-local-variable t)
(defcustom my/project-build-python "python3"
  "Python executable used for Docker task discovery and execution."
  :type 'string :group 'my/project-build)
(defconst my/project-build--runner
  (expand-file-name "my-project-build.py"
                    (file-name-directory (file-truename (or load-file-name buffer-file-name)))))
(defvar my/project-build--last (make-hash-table :test #'equal))
(defvar-local my/project-build--root nil)
(defvar-local my/project-build--mount nil)
(defvar-local my/project-build--configured-tasks nil)
(dolist (variable '(my/project-build--root my/project-build--mount my/project-build--configured-tasks))
  (put variable 'permanent-local t))

(defun my/project-build--project-root ()
  "Return the current project's canonical root."
  (or my/project-build--root
      (when-let* ((project (project-current nil)))
        (file-name-as-directory (file-truename (project-root project))))
      (user-error "Open a file in a project first")))

(defun my/project-build--tasks (root)
  "Return configured tasks or conservative defaults for ROOT."
  (or my/project-build-tasks my/project-build--configured-tasks
      (cond
       ((file-exists-p (expand-file-name "CMakeCache.txt" root))
        '(("CMake: build configured tree" :command "cmake --build .")))
       ((file-exists-p (expand-file-name "Makefile" root))
        '(("Make: incremental build" :command "make -j2")))
       (t (user-error "Configure my/project-build-tasks in this project's .dir-locals.el")))))

(defun my/project-build--command (root task)
  "Validate TASK and return its shell command for ROOT."
  (let* ((properties (cdr task))
         (command (plist-get properties :command))
         (directory (or (plist-get properties :directory) "."))
         (image (plist-get properties :docker-image))
         (mount (plist-get properties :container-root))
         (work (and (stringp directory) (expand-file-name directory root))))
    (unless (and (stringp (car task)) (stringp command) (not (string-empty-p command))
                 (stringp directory) (not (file-name-absolute-p directory))
                 (or (equal (directory-file-name work) (directory-file-name root))
                     (string-prefix-p (file-name-as-directory root) work)))
      (user-error "Task requires a name, command and directory inside the project"))
    (unless (file-directory-p work)
      (user-error "Task directory does not exist: %s" work))
    (when (or image mount)
      (unless (and (stringp image) (not (string-empty-p image))
                   (stringp mount) (file-name-absolute-p mount)
                   (equal mount (directory-file-name (expand-file-name mount "/"))))
        (user-error "Docker tasks require an image and a normalized absolute container root")))
    (if image
        (mapconcat #'shell-quote-argument
                   (list my/project-build-python my/project-build--runner
                         "--image" image "--host-root" (directory-file-name root)
                         "--container-root" mount "--directory" directory
                         "--command" command) " ")
      command)))

(defun my/project-build--map-file (filename)
  "Translate a container FILENAME into this build's host checkout."
  (if (and my/project-build--mount (stringp filename)
           (string-prefix-p (file-name-as-directory my/project-build--mount) filename))
      (concat my/project-build--root
              (substring filename (length (file-name-as-directory my/project-build--mount))))
    filename))

(defun my/project-build--configure-output ()
  "Install path translation before parsing this build's diagnostics."
  (setq-local compilation-parse-errors-filename-function #'my/project-build--map-file)
  (setq-local compilation-transform-file-match-alist
              (copy-tree (default-value 'compilation-transform-file-match-alist)))
  (when (and my/project-build--mount my/project-build--root)
    (setq-local compilation-transform-file-match-alist
                (cons (list (concat "\\`" (regexp-quote (file-name-as-directory my/project-build--mount)))
                            (replace-regexp-in-string "\\\\" "\\\\" my/project-build--root t t))
                      (default-value 'compilation-transform-file-match-alist)))))

(define-derived-mode my/project-build-compilation-mode compilation-mode "Project-Build"
  "Compilation mode with buffer-local Docker filename translation."
  (my/project-build--configure-output)
  (setq-local compilation-scroll-output 'first-error))

(defun my/project-build--preview (root task)
  "Show TASK's command without running it or contacting Docker."
  (let ((command (my/project-build--command root task)))
    (with-help-window "*Project Build Command*"
      (princ (format "Task: %s\nProject: %s\nDirectory: %s\n\n%s\n\n"
                     (car task) root (or (plist-get (cdr task) :directory) ".") command))
      (princ "Docker tasks select a running container by exact image and project bind mount.\n")
      (princ "This preview does not start a build or contact Docker.\n"))))

(defun my/project-build--start (root task)
  "Run TASK asynchronously for ROOT."
  (let* ((tasks (or my/project-build-tasks my/project-build--configured-tasks (list task)))
         (command (my/project-build--command root task))
         (default-directory (file-name-as-directory
                             (expand-file-name (or (plist-get (cdr task) :directory) ".") root)))
         (name (format "*build:%s:%s:%s*"
                       (file-name-nondirectory (directory-file-name root))
                       (substring (secure-hash 'sha1 root) 0 6) (car task)))
         (existing (get-buffer name)))
    (when (and existing (get-buffer-process existing)
               (process-live-p (get-buffer-process existing)))
      (user-error "This task is already running; switch to %s" name))
    (save-some-buffers nil (lambda () (and buffer-file-name
                                         (file-in-directory-p buffer-file-name root))))
    (let ((buffer (compilation-start command #'my/project-build-compilation-mode
                                     (lambda (_) name))))
      (with-current-buffer buffer
        (setq-local my/project-build--root root)
        (setq-local my/project-build--configured-tasks tasks)
        (setq-local my/project-build--mount (plist-get (cdr task) :container-root))
        (my/project-build--configure-output))
      (puthash root buffer my/project-build--last)
      buffer)))

;;;###autoload
(defun my/helm-project-build (&optional preview)
  "Choose a project build task in Helm.  With prefix PREVIEW, show its command.
Helm also offers a Preview command action through its action menu.
Fall back to ordinary completion when Helm is unavailable."
  (interactive "P")
  (let* ((root (my/project-build--project-root))
         (tasks (my/project-build--tasks root)))
    (if (require 'helm nil t)
        (helm :sources
              (helm-make-source "Project build tasks" 'helm-source-sync
                :candidates (mapcar (lambda (task) (cons (car task) task)) tasks)
                :action (if preview
                            (list (cons "Preview command" (lambda (task) (my/project-build--preview root task))))
                          (list (cons "Build" (lambda (task) (my/project-build--start root task)))
                                (cons "Preview command" (lambda (task) (my/project-build--preview root task))))))
              :buffer "*helm project build*")
      (let* ((name (completing-read "Build task: " tasks nil t))
             (task (assoc name tasks)))
        (if preview (my/project-build--preview root task)
          (my/project-build--start root task))))))

;;;###autoload
(defun my/project-build-repeat ()
  "Repeat the most recent task in the current project."
  (interactive)
  (let* ((root (my/project-build--project-root))
         (buffer (gethash root my/project-build--last)))
    (unless (buffer-live-p buffer) (user-error "No previous build for this project"))
    (when (and (get-buffer-process buffer) (process-live-p (get-buffer-process buffer)))
      (user-error "The previous task is still running"))
    (save-some-buffers nil (lambda () (and buffer-file-name
                                         (file-in-directory-p buffer-file-name root))))
    (with-current-buffer buffer (recompile))))

(declare-function helm "helm" (&rest args))
(declare-function helm-make-source "helm-source" (name class &rest args))
(defvar my/project-build-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "b") #'my/helm-project-build)
    (define-key map (kbd "p") (lambda () (interactive) (my/helm-project-build t)))
    (define-key map (kbd "r") #'my/project-build-repeat)
    map))
(global-set-key (kbd "C-c B") my/project-build-map)

(provide 'my-project-build)
;;; my-project-build.el ends here
