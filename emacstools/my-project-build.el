;;; my-project-build.el --- Project build tasks with Helm -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'compile)
(require 'project)
(require 'subr-x)

(defgroup my/project-build nil "Project build task chooser." :group 'tools)
(defcustom my/project-build-tasks nil
  "Project-local named build tasks.
Each entry is (NAME :command SHELL-COMMAND :directory RELATIVE-DIRECTORY
:docker-image IMAGE :container-root MOUNT :docker-auto-start BOOLEAN).
Only :command is required.
Omit Docker properties for a native task.  Directory defaults to the project
root.  Commands are executable project configuration: review local-variable
prompts before accepting them.  With nil, offer basic Make/CMake tasks."
  :type '(repeat (cons string plist)) :group 'my/project-build)
(put 'my/project-build-tasks 'risky-local-variable t)
(defcustom my/project-build-root nil
  "Optional absolute root for this project's build tasks.
Use in directory-local settings when sources are in a Git submodule but the
build scripts and Docker bind mount belong to a parent checkout.  With nil,
use the project.el root.  This does not change Eglot's project selection."
  :type '(choice (const :tag "Use project.el" nil) directory)
  :group 'my/project-build)
(put 'my/project-build-root 'risky-local-variable t)
(defcustom my/project-build-auto-start-docker t
  "Start a background build container if no matching container is running.
Reuse matching running containers.  Restart this integration's own matching
stopped container before creating a new one.  Previews never start containers.
A task's :docker-auto-start property overrides this setting."
  :type 'boolean :group 'my/project-build)
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
      (when my/project-build-root
        (unless (and (stringp my/project-build-root)
                     (file-name-absolute-p my/project-build-root)
                     (file-directory-p my/project-build-root))
          (user-error "my/project-build-root must be an existing absolute directory"))
        (file-name-as-directory (file-truename my/project-build-root)))
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
                   (append (list my/project-build-python my/project-build--runner
                                 "--image" image "--host-root" (directory-file-name root)
                                 "--container-root" mount "--directory" directory)
                           (when (if (plist-member properties :docker-auto-start)
                                     (plist-get properties :docker-auto-start)
                                   my/project-build-auto-start-docker)
                             (list "--auto-start"))
                           (list "--command" command)) " ")
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

(defun my/project-build--follow-filter (process output)
  "Insert OUTPUT from PROCESS, following only windows showing the live end.
A window scrolled into older output retains its point and scroll position.
Returning to the bottom resumes following, even without moving point to EOF."
  (let* ((buffer (process-buffer process))
         (filter (process-get process 'my/project-build-original-filter))
         (windows
          (when (buffer-live-p buffer)
            (with-current-buffer buffer
              (mapcar (lambda (window)
                        (list window (>= (or (window-end window t) 0) (point-max))
                              (window-point window) (window-start window)))
                      (get-buffer-window-list buffer nil t))))))
    (unwind-protect
        (funcall filter process output)
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          (dolist (state windows)
            (pcase-let ((`(,window ,following ,position ,start) state))
              (when (and (window-live-p window) (eq (window-buffer window) buffer))
                (if following
                    (with-selected-window window
                      (goto-char (point-max))
                      ;; Update the viewport immediately: another output chunk
                      ;; can arrive before redisplay has caught up with point.
                      (recenter -1))
                  (set-window-point window position)
                  (set-window-start window start t))))))))))

(defun my/project-build--install-follow-filter (process)
  "Wrap PROCESS's output filter once, preserving its normal output handling."
  (unless (eq (process-filter process) #'my/project-build--follow-filter)
    (process-put process 'my/project-build-original-filter (process-filter process))
    (set-process-filter process #'my/project-build--follow-filter)))

(defun my/project-build--setup-scrolling ()
  "Enable live-end following for this build, including an existing process."
  (setq-local compilation-scroll-output t)
  (setq-local compilation-auto-jump-to-first-error nil)
  (setq-local compilation-auto-jump-to-next nil)
  (add-hook 'compilation-start-hook #'my/project-build--install-follow-filter nil t)
  (when-let* ((process (get-buffer-process (current-buffer))))
    (my/project-build--install-follow-filter process)))

(define-derived-mode my/project-build-compilation-mode compilation-mode "Project-Build"
  "Compilation mode with Docker paths and pausable live-output following."
  (my/project-build--configure-output)
  (my/project-build--setup-scrolling))

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

;; Reloading this module also upgrades open build buffers without restarting
;; their modes, losing compiler diagnostics, or interrupting a running build.
(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (when (derived-mode-p 'my/project-build-compilation-mode)
      (my/project-build--setup-scrolling))))

(provide 'my-project-build)
;;; my-project-build.el ends here
