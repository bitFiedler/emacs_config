;; -*- lexical-binding: t; -*-

;;; my-emacs-sessions.el --- Manual desktop session management -*- lexical-binding: t; -*-

;;; Commentary:
;; Save independent Emacs sessions automatically on exit.
;; Restore sessions only on explicit request using Helm.
;; Keep a configurable number of recently saved sessions.

;;; Code:

(require 'desktop)
(require 'cl-lib)
(require 'subr-x)
(require 'helm)
(require 'helm-source)

;; Do not restore frame geometry when loading a desktop session.
(setq desktop-restore-frames nil)

(defgroup my-emacs-sessions nil
  "Manage independent Emacs desktop sessions."
  :group 'convenience
  :prefix "my/session-")

(defcustom my/session-root
  (expand-file-name "sessions/" user-emacs-directory)
  "Directory containing saved Emacs sessions."
  :type 'directory
  :group 'my-emacs-sessions)

(defcustom my/session-max-count 10
  "Maximum number of saved sessions.
Set to nil to disable automatic cleanup."
  :type '(choice
          (integer :tag "Maximum sessions" 1)
          (const :tag "Unlimited" nil))
  :group 'my-emacs-sessions)

(defcustom my/session-save-on-exit t
  "Whether to save the current session on exit."
  :type 'boolean
  :group 'my-emacs-sessions)

(defvar my/session-dir nil
  "Directory assigned to the current Emacs instance.")

(defvar my/session-start-time
  (format-time-string "%Y%m%d-%H%M%S")
  "Timestamp identifying when this Emacs instance started.")

(defun my/session-initialize ()
  "Initialize the current Emacs session directory."
  (unless my/session-dir
    (setq my/session-dir
          (expand-file-name
           (format "session-%s-%d/"
                   my/session-start-time
                   (emacs-pid))
           my/session-root)))
  my/session-dir)

(defun my/session-desktop-file (dir)
  "Return the desktop file path for DIR."
  (expand-file-name desktop-base-file-name dir))

(defun my/session-valid-p (dir)
  "Return non-nil if DIR contains a saved desktop."
  (and (file-directory-p dir)
       (file-readable-p (my/session-desktop-file dir))))

(defun my/session-modification-time (dir)
  "Return modification time of the desktop in DIR."
  (file-attribute-modification-time
   (file-attributes (my/session-desktop-file dir))))

(defun my/session-directories ()
  "Return saved session directories, newest first, oldest last."
  (when (file-directory-p my/session-root)
    (sort
     (cl-remove-if-not
      #'my/session-valid-p
      (directory-files my/session-root t "\\`session-"))
     (lambda (a b)
       (let ((time-a (my/session-modification-time a))
             (time-b (my/session-modification-time b)))
         (if (equal time-a time-b)
             (string> a b)
           (time-less-p time-b time-a)))))))

(defun my/open-files ()
  "Return absolute paths of all open file buffers."
  (delete-dups
   (delq nil
         (mapcar
          (lambda (buf)
            (when (buffer-live-p buf)
              (let ((file
                     (buffer-local-value
                      'buffer-file-name buf)))
                (when file
                  (expand-file-name file)))))
          (buffer-list)))))

(defun my/save-session-files (dir)
  "Save absolute paths of open files in DIR/files.txt."
  (with-temp-file (expand-file-name "files.txt" dir)
    (dolist (file (my/open-files))
      (insert file "\n"))))

(defun my/session-files (dir)
  "Read absolute file paths from DIR/files.txt."
  (let ((file (expand-file-name "files.txt" dir)))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (split-string (buffer-string) "\n" t)))))

(defun my/session-update-latest ()
  "Point latest to the most recently saved session."
  (let* ((latest (expand-file-name "latest" my/session-root))
         (newest (car (my/session-directories))))
    (when (file-symlink-p latest)
      (delete-file latest))
    (when (file-exists-p latest)
      (user-error "%s exists and is not a symlink" latest))
    (when newest
      (make-symbolic-link newest latest t))))

(defun my/cleanup-sessions ()
  "Remove old sessions according to `my/session-max-count'."
  (interactive)
  (when my/session-max-count
    (let* ((sessions (my/session-directories))
           (old (nthcdr my/session-max-count sessions)))
      (dolist (dir old)
        (delete-directory dir t)
        (message "Deleted old Emacs session: %s" dir))))
  (my/session-update-latest))

(defun my/save-current-session ()
  "Save the current session only if files are open."
  (interactive)
  (let ((files (my/open-files)))
    (when files
      (my/session-initialize)
      (make-directory my/session-dir t)

      (desktop-save my/session-dir t)
      (my/save-session-files my/session-dir)
      (my/cleanup-sessions)

      (message "Saved Emacs session: %s" my/session-dir))))

(defun my/session-name (dir)
  "Return the display name of session DIR."
  (file-name-nondirectory
   (directory-file-name dir)))

(defun my/session-candidates ()
  "Build Helm candidates, excluding sessions without open files."
  (delq nil
        (mapcar
         (lambda (dir)
           (let ((files (my/session-files dir)))
             (when files
               (cons
                (concat
                 (my/session-name dir) "\n"
                 (mapconcat
                  (lambda (file)
                    (concat "  • " file))
                  files "\n")
                 "\n")
                dir))))
         (my/session-directories))))

(defun my/restore-session (dir)
  "Restore a snapshot of the Emacs desktop stored in DIR.
Leave the saved desktop and its lock untouched, even when another Emacs
owns it.  Restore eagerly so no deferred work depends on the snapshot."
  (interactive "DSession directory: ")
  (unless (my/session-valid-p dir)
    (user-error "No saved Emacs desktop in %s" dir))

  (let ((snapshot (make-temp-file "emacs-session-restore-" t)))
    (unwind-protect
        (progn
          (copy-file (my/session-desktop-file dir)
                     (my/session-desktop-file snapshot))
          ;; A nil initial dirname also avoids desktop-read's already-owned
          ;; desktop shortcut.  Only this disposable snapshot is claimed.
          (let ((desktop-dirname nil)
                (desktop-path (list snapshot))
                (desktop-load-locked-desktop 'check-pid)
                (desktop-restore-eager t)
                (desktop-restore-frames nil)
                (desktop-file-modtime desktop-file-modtime)
                (desktop-file-checksum desktop-file-checksum))
            (unless (eq t (desktop-read snapshot))
              (user-error "Emacs session was not restored: %s"
                          (my/session-name dir))))
          (message "Restored Emacs session: %s" (my/session-name dir))
          t)
      (delete-directory snapshot t))))

(defun my/restore-last-session ()
  "Restore the most recently saved Emacs session."
  (interactive)
  (let ((dir (car (my/session-directories))))
    (unless dir
      (user-error "No saved Emacs sessions found"))
    (my/restore-session dir)))

(defun my/helm-sessions ()
  "Select a saved Emacs session using Helm."
  (interactive)
  (let ((candidates (my/session-candidates)))
    (unless candidates
      (user-error "No saved Emacs sessions found"))
    (helm
     :sources
     (helm-build-sync-source "Emacs Sessions"
       :candidates candidates
       :multiline t
       :match-part (lambda (candidate)
                     (car candidate))
       :action
       '(("Restore session" . my/restore-session)))
     :buffer "*helm emacs sessions*")))

(defun my/session-exit-hook ()
  "Save session on exit when enabled."
  (when my/session-save-on-exit
    (my/save-current-session)))

;;;###autoload
(define-minor-mode my-emacs-sessions-mode
  "Global mode for manually restorable Emacs sessions."
  :global t
  :group 'my-emacs-sessions
  (if my-emacs-sessions-mode
      (progn
        (my/session-initialize)
        (add-hook 'kill-emacs-hook #'my/session-exit-hook))
    (remove-hook 'kill-emacs-hook #'my/session-exit-hook)))

(provide 'my-emacs-sessions)

;;; my-emacs-sessions.el ends here
