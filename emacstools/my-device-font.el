;;; my-device-font.el --- Shared config with per-device font sizes -*- lexical-binding: t; -*-

(defgroup my/device-font nil
  "Graphical editing fonts selected by hostname."
  :group 'faces)

(defcustom my/device-font-family "JetBrains Mono"
  "Font family used for graphical editing frames."
  :type 'string
  :group 'my/device-font)

(defcustom my/device-font-sizes
  '(("N900D9658" . 9) ("mp-linux" . 11))
  "Short hostnames and their graphical font sizes in points.
Matching ignores case and domain suffixes.  Unlisted devices use
`my/device-font-default-size'."
  :type '(alist :key-type string :value-type integer)
  :group 'my/device-font)

(defcustom my/device-font-default-size 11
  "Graphical font size in points for devices not listed explicitly."
  :type 'integer
  :group 'my/device-font)

(defun my/device-font-size (&optional hostname)
  "Return the font size for HOSTNAME, defaulting to `system-name'."
  (let ((host (car (split-string (or hostname (system-name)) "\\." t))))
    (or (cdr (assoc-string host my/device-font-sizes t))
        my/device-font-default-size)))

(defun my/device-font ()
  "Return the graphical font specification for this device."
  (format "%s-%d" my/device-font-family (my/device-font-size)))

(defun my/fontify-frame (&optional frame)
  "Apply this device's editing font to graphical FRAME."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (set-frame-parameter frame 'font (my/device-font)))))

(defun my/apply-device-font ()
  "Apply the device font to existing GUI frames and future GUI frames.
Terminal font sizes are controlled by the terminal application."
  (interactive)
  (setf (alist-get 'font default-frame-alist) (my/device-font))
  (add-hook 'after-make-frame-functions #'my/fontify-frame)
  (dolist (frame (frame-list))
    (my/fontify-frame frame))
  (when (called-interactively-p 'interactive)
    (message "Device %s: %s" (system-name) (my/device-font))))

(my/apply-device-font)

(provide 'my-device-font)
;;; my-device-font.el ends here
