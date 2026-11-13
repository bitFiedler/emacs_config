;;; my-buffer-reload.el --- Reload files without losing your place -*- lexical-binding: t; -*-

(require 'cl-lib)

(defun my/buffer-reload--location (position)
  "Return POSITION as a line number and display column in the widened buffer."
  (save-excursion
    (goto-char position)
    (cons (line-number-at-pos) (current-column))))

(defun my/buffer-reload--position (location)
  "Resolve LOCATION, clamping to the end of a shorter line or file."
  (save-excursion
    (goto-char (point-min))
    (if (zerop (forward-line (1- (car location))))
        (move-to-column (cdr location))
      (goto-char (point-max)))
    (point)))

(defun my/reload-buffer ()
  "Reload the visited file, retaining cursor and window positions when possible.
Preserve the logical line/column, scroll start and horizontal/pixel scroll
for each window displaying the buffer.  Clamp positions if the file shrank.
Ask before discarding unsaved edits.  Read the disk file, not an auto-save,
and preserve the major/minor modes instead of restarting their hooks."
  (interactive)
  (unless buffer-file-name
    (user-error "This buffer is not visiting a file"))
  (save-restriction
    (widen)
    (let ((buffer (current-buffer))
          (location (my/buffer-reload--location (point)))
          (windows
           (mapcar (lambda (window)
                     (list :window window
                           :point (my/buffer-reload--location (window-point window))
                           :start (my/buffer-reload--location (window-start window))
                           :hscroll (window-hscroll window)
                           :vscroll (window-vscroll window t)))
                   (get-buffer-window-list (current-buffer) nil t))))
      ;; Modified buffers retain the built-in discard-edits question.
      (when (revert-buffer t (not (buffer-modified-p)) t)
        (dolist (state windows)
          (let ((window (plist-get state :window)))
            (when (and (window-live-p window) (eq (window-buffer window) buffer))
              (set-window-point window
                                (my/buffer-reload--position (plist-get state :point)))
              (set-window-start window
                                (my/buffer-reload--position (plist-get state :start)) t)
              (set-window-hscroll window (plist-get state :hscroll))
              (set-window-vscroll window (plist-get state :vscroll) t))))
        (goto-char (my/buffer-reload--position location))
        (message "Reloaded %s at line %d, column %d"
                 (buffer-name) (line-number-at-pos) (current-column))))))

(global-set-key (kbd "C-<f5>") #'my/reload-buffer)

(provide 'my-buffer-reload)
;;; my-buffer-reload.el ends here
