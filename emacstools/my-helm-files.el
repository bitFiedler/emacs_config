;;; my-helm-files.el --- Safe retained buffers and wider file browsing -*- lexical-binding: t; -*-

(require 'helm)
(require 'helm-files)

(defgroup my-helm-files nil
  "Helm result protection and file-picker layout."
  :group 'helm)

(defcustom my/helm-files-wide-window t
  "Use a full-width bottom window for Helm file browsing.
Editor windows remain visible above it."
  :type 'boolean
  :group 'my-helm-files)

(defcustom my/helm-files-window-height 0.35
  "Height of the full-width file picker, as a frame-height fraction."
  :type 'float
  :group 'my-helm-files)

(defcustom my/helm-files-edit-in-minibuffer t
  "Edit file paths in the visible minibuffer, allowing long input to wrap.
Other Helm commands keep their existing header-line input setting."
  :type 'boolean
  :group 'my-helm-files)

(defvar my/helm-files--active nil)

(defun my/helm-files-origin-directory ()
  "Return Find Files input to the directory of the originating buffer.
Ignore a filename guessed from text at point.  For non-file buffers,
use their `default-directory'."
  (interactive)
  (unless (and helm-alive-p my/helm-files--active)
    (user-error "Use this command inside Helm Find Files"))
  (let ((origin (and helm-current-buffer (get-buffer helm-current-buffer))))
    (unless (buffer-live-p origin)
      (user-error "The originating buffer no longer exists"))
    (helm-set-pattern
     (with-current-buffer origin
       (file-name-as-directory
        (expand-file-name (if buffer-file-name
                              (file-name-directory buffer-file-name)
                            default-directory)))))))
(put 'my/helm-files-origin-directory 'helm-only t)

(defun my/helm-lock-finished-results ()
  "Protect the results buffer when the current Helm session finishes.
Helm recreates it writable at the next session for internal updates."
  (when-let* ((buffer (get-buffer helm-buffer)))
    (with-current-buffer buffer
      (when (derived-mode-p 'helm-major-mode)
        (setq-local buffer-read-only t)))))

(defun my/helm-lock-inactive-results ()
  "Protect existing inactive Helm results buffers when loading this module."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and (derived-mode-p 'helm-major-mode)
                 (not (and helm-alive-p (equal (buffer-name) helm-buffer))))
        (setq-local buffer-read-only t)))))

(defun my/helm-files-display-buffer (buffer &optional _resume)
  "Display file-picker BUFFER across the bottom of the frame."
  (let ((window (display-buffer
                 buffer `((display-buffer-in-side-window)
                          (side . bottom) (slot . 0)
                          (window-height . ,my/helm-files-window-height)))))
    (run-hooks 'helm-window-configuration-hook)
    window))

(defun my/helm-files--session (original &rest arguments)
  "Call file-picker ORIGINAL with ARGUMENTS and session-local presentation."
  (let ((my/helm-files--active t)
        (helm-display-function (if my/helm-files-wide-window
                                   #'my/helm-files-display-buffer helm-display-function))
        (helm-full-frame (if my/helm-files-wide-window nil helm-full-frame))
        (helm-echo-input-in-header-line (if my/helm-files-edit-in-minibuffer
                                           nil helm-echo-input-in-header-line)))
    (apply original arguments)))

(defun my/helm-files--minibuffer-setup ()
  "Let long file paths wrap in the active file-picker minibuffer."
  (when (and my/helm-files--active my/helm-files-edit-in-minibuffer)
    (setq-local truncate-lines nil
                truncate-partial-width-windows nil
                word-wrap nil
                resize-mini-windows t
                max-mini-window-height 0.25)))

;; Keep candidate labels compact; C-] remains Helm's built-in toggle.
(setq helm-ff-transformer-show-only-basename t
      helm-ff-show-dot-file-path nil)
(define-key helm-find-files-map (kbd "C-c C-b") #'my/helm-files-origin-directory)
(add-hook 'helm-cleanup-hook #'my/helm-lock-finished-results)
(add-hook 'helm-minibuffer-set-up-hook #'my/helm-files--minibuffer-setup)
(unless (advice-member-p #'my/helm-files--session 'helm-find-files-1)
  (advice-add 'helm-find-files-1 :around #'my/helm-files--session))
(my/helm-lock-inactive-results)

(provide 'my-helm-files)
;;; my-helm-files.el ends here
