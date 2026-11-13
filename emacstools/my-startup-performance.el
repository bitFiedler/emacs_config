;;; my-startup-performance.el --- Bounded startup GC and timing -*- lexical-binding: t; -*-

(defvar my/startup--normal-gc-threshold gc-cons-threshold)
(defvar my/startup--normal-gc-percentage gc-cons-percentage)
(defvar my/startup--initial-gcs gcs-done)
(defvar my/startup--gc-boost-active nil)
(defvar my/startup--gc-count nil)
(defvar my/startup--ready-seconds nil)
(defvar my/startup--terminal-seconds nil)
(defvar xterm-query-timeout)
(defvar xterm-query-redisplay-timeout)
(defvar my/startup--profile-data nil)
(defvar my/startup--profile-child-time nil)
(defvar my/startup--profile-active nil)
(defvar my/startup--wsl-skipped-dirs nil)

(defun my/startup--profile-call (original kind label arguments)
  "Time ORIGINAL called with ARGUMENTS as KIND and LABEL.
Record inclusive and self wall time without storing command arguments."
  (let ((parent my/startup--profile-child-time)
        (my/startup--profile-child-time (list 0.0))
        (started (float-time)))
    (unwind-protect
        (apply original arguments)
      (let* ((elapsed (- (float-time) started))
             (key (list kind label))
             (stats (or (gethash key my/startup--profile-data)
                        (puthash key (vector 0 0.0 0.0) my/startup--profile-data))))
        (aset stats 0 (1+ (aref stats 0)))
        (aset stats 1 (+ (aref stats 1) elapsed))
        (aset stats 2 (+ (aref stats 2)
                         (max 0.0 (- elapsed (car my/startup--profile-child-time)))))
        (when parent (setcar parent (+ (car parent) elapsed)))))))

(defun my/startup--profile-load (original &rest arguments)
  (my/startup--profile-call original "load" (car arguments) arguments))
(defun my/startup--profile-require (original &rest arguments)
  (my/startup--profile-call original "require" (symbol-name (car arguments)) arguments))
(defun my/startup--profile-executable (original &rest arguments)
  (my/startup--profile-call original "executable-find" (car arguments) arguments))
(defun my/startup--profile-process (original &rest arguments)
  (my/startup--profile-call original "process" (car arguments) arguments))

(defconst my/startup--profile-advices
  '((load . my/startup--profile-load)
    (require . my/startup--profile-require)
    (executable-find . my/startup--profile-executable)
    (call-process . my/startup--profile-process)
    (process-file . my/startup--profile-process)))

(defun my/startup--profile-start ()
  "Start optional startup wall-time profiling."
  (unless my/startup--profile-active
    (setq my/startup--profile-data (make-hash-table :test #'equal)
          my/startup--profile-active t)
    (dolist (entry my/startup--profile-advices)
      (advice-add (car entry) :around (cdr entry)))))

(defun my/startup--profile-stop ()
  "Remove startup profiling advice, keeping the collected measurements."
  (dolist (entry my/startup--profile-advices)
    (advice-remove (car entry) (cdr entry)))
  (setq my/startup--profile-active nil))

(defun my/startup-profile-report ()
  "Show startup loads, executable lookups and synchronous process timings.
Enable for one launch with EMACS_STARTUP_PROFILE=1 emacs -nw."
  (interactive)
  (unless my/startup--profile-data
    (user-error "Restart with EMACS_STARTUP_PROFILE=1 emacs -nw to collect timings"))
  (let ((buffer (get-buffer-create "*Emacs Startup Profile*")) rows)
    (maphash (lambda (key stats) (push (list key stats) rows)) my/startup--profile-data)
    (setq rows (sort rows (lambda (a b) (> (aref (cadr a) 2) (aref (cadr b) 2)))))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Startup profile: %s, Emacs %s, TERM=%s\n\n"
                        (system-name) emacs-version (or (getenv "TERM") "unset"))
                "Sorted by self wall time. Includes = nested measured work.\n"
                "Do not add inclusive times: parent and child calls overlap.\n"
                "Only library/program names are recorded; command arguments are omitted.\n\n"
                (format "WSL startup lookup: %d Windows-drive directories skipped for native tool probes.\n\n"
                        (length my/startup--wsl-skipped-dirs))
                (format "%9s %9s %6s  %-16s %s\n" "Self ms" "Incl. ms" "Calls" "Kind" "Name"))
        (dolist (row rows)
          (let ((key (car row)) (stats (cadr row)))
            (insert (format "%9.2f %9.2f %6d  %-16s %s\n"
                            (* 1000 (aref stats 2)) (* 1000 (aref stats 1))
                            (aref stats 0) (car key) (cadr key)))))
        (goto-char (point-min))
        (special-mode)))
    (pop-to-buffer buffer)))

(defgroup my-startup-performance nil
  "Startup timing and bounded terminal initialization waits."
  :group 'initialization)

(defcustom my/startup-wsl-native-executable-lookups t
  "Skip Windows-drive directories for native tool probes during WSL startup.
Only `executable-find' calls for bare names without an .exe suffix are
filtered.  Explicit paths, .exe names and remote lookups are unchanged.
The advice is removed at the startup checkpoint.  PATH and the global
`exec-path' are never changed.  Set nil before early init to opt out."
  :type 'boolean
  :group 'my-startup-performance)

(defcustom my/startup-wsl-windows-directory-regexp
  "\\`/mnt/[[:alpha:]]\\(?:/\\|\\'\\)"
  "Executable directories to skip for native startup probes under WSL."
  :type 'regexp
  :group 'my-startup-performance)

(defcustom my/startup-wsl-keep-exec-directories nil
  "Directories to keep probing even when they match the Windows-drive regexp.
Use exact directory entries from `exec-path' if native Linux tools live
on a Windows-mounted drive and must be detected during startup."
  :type '(repeat directory)
  :group 'my-startup-performance)

(defun my/startup--wsl-p ()
  "Whether this Emacs runs on a WSL Linux kernel."
  (and (eq system-type 'gnu/linux)
       (or (getenv "WSL_DISTRO_NAME") (getenv "WSL_INTEROP")
           (condition-case nil
               (with-temp-buffer
                 (insert-file-contents "/proc/sys/kernel/osrelease")
                 (goto-char (point-min))
                 (let ((case-fold-search t))
                   (re-search-forward "microsoft" nil t)))
             (file-error nil)))))

(defun my/startup--wsl-executable-find (original command &optional remote)
  "Find COMMAND using ORIGINAL, avoiding Windows drives for native probes.
REMOTE and explicitly named Windows commands retain normal lookup."
  (let ((case-fold-search t))
    (if (or remote (file-name-directory command)
            (string-match-p "\\.exe\\'" command))
        (funcall original command remote)
      (let ((exec-path
             (let (native)
               (dolist (directory exec-path (nreverse native))
                 (if (and (stringp directory)
                          (string-match-p my/startup-wsl-windows-directory-regexp directory)
                          (not (member directory my/startup-wsl-keep-exec-directories)))
                     (unless (member directory my/startup--wsl-skipped-dirs)
                       (push directory my/startup--wsl-skipped-dirs))
                   (push directory native))))))
        (funcall original command remote)))))

(defcustom my/startup-terminal-query-timeout 0.2
  "Maximum synchronous wait per terminal query during XTerm initialization.
Nil keeps Emacs's original wait.  This affects only initialization;
clipboard queries during editing retain their normal timeouts.
Unanswered initialization queries retain Emacs's asynchronous fallback."
  :type '(choice (const :tag "Use Emacs default" nil) (number :tag "Seconds"))
  :group 'my-startup-performance)

(defun my/startup--terminal-init (original &rest arguments)
  "Time terminal initialization ORIGINAL called with ARGUMENTS.
Bound synchronous capability-query waits without disabling detection."
  (let ((started (float-time)))
    (unwind-protect
        (if (null my/startup-terminal-query-timeout)
            (apply original arguments)
          (let ((xterm-query-timeout
                 (if (numberp xterm-query-timeout)
                     (min xterm-query-timeout my/startup-terminal-query-timeout)
                   xterm-query-timeout))
                (xterm-query-redisplay-timeout
                 (min xterm-query-redisplay-timeout
                      my/startup-terminal-query-timeout 0.05)))
            (apply original arguments)))
      (setq my/startup--terminal-seconds (- (float-time) started)))))

(unless (advice-member-p #'my/startup--terminal-init 'terminal-init-xterm)
  (advice-add 'terminal-init-xterm :around #'my/startup--terminal-init))

(defun my/startup-finish ()
  "Restore normal GC settings after the startup allocation burst."
  (when my/startup--profile-active (my/startup--profile-stop))
  (advice-remove 'executable-find #'my/startup--wsl-executable-find)
  (setq my/startup--ready-seconds
        (float-time (time-subtract (current-time) before-init-time)))
  (when my/startup--gc-boost-active
    (setq gc-cons-threshold my/startup--normal-gc-threshold
          gc-cons-percentage my/startup--normal-gc-percentage
          my/startup--gc-count (- gcs-done my/startup--initial-gcs)
          my/startup--gc-boost-active nil)))

(defun my/startup-report ()
  "Report this session's init time and recorded startup collections."
  (interactive)
  (message "Emacs initialization: %s; ready: %s; terminal init: %s; startup GC: %s; GC threshold: %s bytes"
           (emacs-init-time)
           (if my/startup--ready-seconds
               (format "%.3fs" my/startup--ready-seconds) "not recorded")
           (if my/startup--terminal-seconds
               (format "%.3fs" my/startup--terminal-seconds) "not recorded")
           (or my/startup--gc-count "not recorded")
           gc-cons-threshold))

;; Avoid leaving a startup boost enabled when loading this file manually.
(unless after-init-time
  (when (and my/startup-wsl-native-executable-lookups (my/startup--wsl-p)
             (not (advice-member-p #'my/startup--wsl-executable-find 'executable-find)))
    (advice-add 'executable-find :around #'my/startup--wsl-executable-find))
  (setq gc-cons-threshold (max gc-cons-threshold (* 64 1024 1024))
        gc-cons-percentage (max gc-cons-percentage 0.6)
        my/startup--gc-boost-active t)
  (add-hook 'emacs-startup-hook #'my/startup-finish 90))

(when (and (not after-init-time) (equal (getenv "EMACS_STARTUP_PROFILE") "1"))
  (my/startup--profile-start))

(provide 'my-startup-performance)
;;; my-startup-performance.el ends here
