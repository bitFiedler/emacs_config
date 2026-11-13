;;; my-eglot-retry-limit.el --- Bound repeated Eglot starts -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'eglot)
(require 'project)

(defvar my/eglot-max-start-attempts 10
  "Maximum server starts per project/language before giving up.
Includes the initial start.  Reset after a stable connection or manually.")
(defvar my/eglot-stable-seconds 60
  "Seconds a connection must stay alive to reset its attempt count.")
(defvar my/eglot-start-attempts (make-hash-table :test #'equal))
(defvar my/eglot-stable-timers (make-hash-table :test #'equal))
(defvar my/eglot-starting-servers (make-hash-table :test #'equal)
  "Live server instances, including those still performing initialization.")

(defun my/eglot-retry-key (modes project)
  "Identify PROJECT and MODES independently of language server instances."
  (cons (expand-file-name (project-root project))
        (sort (mapcar #'symbol-name modes) #'string-lessp)))

(defun my/eglot-cancel-stable-timer (key)
  (when-let* ((timer (gethash key my/eglot-stable-timers)))
    (cancel-timer timer)
    (remhash key my/eglot-stable-timers)))

(defun my/eglot-limit-starts (original modes project &rest args)
  "Reuse live connections and limit ORIGINAL's starts for MODES and PROJECT."
  (let* ((key (my/eglot-retry-key modes project))
         (existing
          (or (let ((server (gethash key my/eglot-starting-servers)))
                (and server (jsonrpc-running-p server) server))
              (cl-find-if
               (lambda (server)
                 (and (equal key (my/eglot-retry-key
                                  (eglot--major-modes server)
                                  (eglot--project server)))
                      (jsonrpc-running-p server)))
               (gethash project eglot--servers-by-project)))))
    (if existing
        existing
      (let ((attempts (gethash key my/eglot-start-attempts 0)))
        (when (>= attempts my/eglot-max-start-attempts)
          (user-error "Eglot stopped after %d starts; inspect its stderr, then M-x my/eglot-reset-retries"
                      attempts))
        (my/eglot-cancel-stable-timer key)
        ;; Count before starting: synchronous startup errors also consume a try.
        (puthash key (1+ attempts) my/eglot-start-attempts)
        (apply original modes project args)))))

(defun my/eglot-track-starting-server (server)
  "Track SERVER before its asynchronous initialization handshake finishes."
  (puthash (my/eglot-retry-key (eglot--major-modes server)
                             (eglot--project server))
           server my/eglot-starting-servers))

(defun my/eglot-stop-retry-loop (server)
  "Stop SERVER's automatic restart when its project has exhausted its budget."
  (let ((key (my/eglot-retry-key (eglot--major-modes server)
                               (eglot--project server))))
    (when (eq (gethash key my/eglot-starting-servers) server)
      (remhash key my/eglot-starting-servers))
    (my/eglot-cancel-stable-timer key)
    (when (and (not (eglot--shutdown-requested server))
               (>= (gethash key my/eglot-start-attempts 0)
                   my/eglot-max-start-attempts))
      ;; Cancel Eglot's own reconnect-enabling timer, if still pending.
      (when (timerp (eglot--inhibit-autoreconnect server))
        (cancel-timer (eglot--inhibit-autoreconnect server)))
      (setf (eglot--inhibit-autoreconnect server) t)
      (message "Eglot stopped after %d starts for %s; inspect stderr, then M-x my/eglot-reset-retries"
               my/eglot-max-start-attempts (car key)))))

(defun my/eglot-reset-after-stable-connection (server)
  "Reset SERVER's budget only after it has remained running for a minute."
  (let ((key (my/eglot-retry-key (eglot--major-modes server)
                               (eglot--project server))))
    (my/eglot-cancel-stable-timer key)
    (puthash key
             (run-at-time
              my/eglot-stable-seconds nil
              (lambda ()
                (remhash key my/eglot-stable-timers)
                (when (jsonrpc-running-p server)
                  (remhash key my/eglot-start-attempts))))
             my/eglot-stable-timers)))

(defun my/eglot-reset-retries ()
  "Clear stopped Eglot start budgets.  Use M-x eglot to try connecting again."
  (interactive)
  (maphash (lambda (_key timer) (cancel-timer timer)) my/eglot-stable-timers)
  (clrhash my/eglot-stable-timers)
  (clrhash my/eglot-start-attempts)
  (message "Eglot retry limits reset; use M-x eglot to connect"))

(defun my/eglot-close-exited-event-buffers ()
  "Close finished Eglot events buffers containing the JSONRPC exit marker.
Preserve source buffers, stderr, and buffers used by a live server."
  (interactive)
  (let ((closed 0)
        (live-events
         (cl-loop for proc in (process-list)
                  for connection = (process-get proc 'jsonrpc-connection)
                  when (and (process-live-p proc) connection
                            (object-of-class-p connection 'eglot-lsp-server))
                  collect (jsonrpc--events-buffer connection))))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and (derived-mode-p 'jsonrpc-events-mode)
                   (string-prefix-p "*EGLOT " (buffer-name))
                   (not (memq buffer live-events))
                   (save-excursion
                     (goto-char (point-min))
                     (search-forward "----------b---y---e---b---y---e----------" nil t)))
          (when (kill-buffer buffer) (cl-incf closed)))))
    (when (called-interactively-p 'interactive)
      (message "Closed %d exited Eglot events buffer(s)" closed))
    closed))

(defun my/eglot-clean-events-after-exit (proc _change)
  "Schedule event cleanup after PROC's sentinel and reconnect have finished."
  (let ((connection (process-get proc 'jsonrpc-connection)))
    (when (and (not (process-live-p proc)) connection
               (object-of-class-p connection 'eglot-lsp-server))
      (run-at-time 0 nil #'my/eglot-close-exited-event-buffers))))

(advice-add 'eglot--connect :around #'my/eglot-limit-starts)
(advice-add 'eglot--on-shutdown :before #'my/eglot-stop-retry-loop)
(advice-add 'jsonrpc--process-sentinel :after #'my/eglot-clean-events-after-exit)
(add-hook 'eglot-connect-hook #'my/eglot-reset-after-stable-connection)
(add-hook 'eglot-server-initialized-hook #'my/eglot-track-starting-server)

(provide 'my-eglot-retry-limit)
;;; my-eglot-retry-limit.el ends here
