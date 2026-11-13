;;; my-wayland-clipboard.el --- Read fresh clipboard text -*- lexical-binding: t; -*-

(require 'subr-x)

(defvar my/wayland-clipboard-timeout 3
  "Maximum seconds to wait for clipboard text from wl-paste.")

(defun my/wayland-read-clipboard ()
  "Read current Wayland text, preserving Unicode and trailing newlines.
Normalize Windows CRLF line endings to LF; preserve standalone CR bytes.
Do not infer ownership from a wl-copy process or cache previous clipboard
values.  Report failures instead of silently falling back to old text."
  (let ((output (generate-new-buffer " *wayland-clipboard-output*"))
        (errors (generate-new-buffer " *wayland-clipboard-errors*"))
        process)
    (unwind-protect
        (progn
          (setq process
                (make-process :name "wayland-clipboard-read"
                              :command '("wl-paste" "--no-newline" "--type" "text")
                              :buffer output :stderr errors
                              :coding 'utf-8-unix :connection-type 'pipe
                              :sentinel #'ignore
                              :noquery t))
          (let ((deadline (+ (float-time) my/wayland-clipboard-timeout)))
            (while (and (process-live-p process) (< (float-time) deadline))
              (accept-process-output process 0.05)))
          (when (process-live-p process)
            (user-error "Wayland clipboard read timed out; paste cancelled"))
          (unless (and (eq (process-status process) 'exit)
                       (zerop (process-exit-status process)))
            (user-error "Wayland clipboard unavailable: %s"
                        (with-current-buffer errors (string-trim (buffer-string)))))
          (with-current-buffer output
            (when (zerop (buffer-size))
              (user-error "Wayland clipboard has no text; paste cancelled"))
            (replace-regexp-in-string
             "\r\n" "\n"
             (buffer-substring-no-properties (point-min) (point-max)) t t)))
      (when (and process (process-live-p process)) (delete-process process))
      (kill-buffer output)
      (kill-buffer errors))))

(defun my/wayland-clipboard-paste ()
  "Use the current clipboard unless it is already the current yank item."
  (let ((text (my/wayland-read-clipboard)))
    ;; Compare against the actual yank item, not a separate clipboard cache.
    ;; Returning nil in this case is safe: current-kill will return that item.
    (unless (equal text (car-safe kill-ring-yank-pointer)) text)))

(provide 'my-wayland-clipboard)
;;; my-wayland-clipboard.el ends here
