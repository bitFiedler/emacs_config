;;; my-emacs-geometry.el --- Frame geometry management -*- lexical-binding: t; -*-

;;; Code:

(defgroup my-emacs-geometry nil
  "Manage Emacs frame geometry."
  :group 'frames
  :prefix "my/geometry-")

(defcustom my/geometry-file
  (expand-file-name "frame-geometry.el" user-emacs-directory)
  "File containing saved frame dimensions."
  :type 'file
  :group 'my-emacs-geometry)

(defcustom my/geometry-default
  '(:width 1511 :height 931)
  "Default frame dimensions in pixels."
  :type 'plist
  :group 'my-emacs-geometry)

(defun my/geometry-load ()
  "Load saved frame dimensions or return defaults."
  (let ((geometry
         (when (file-readable-p my/geometry-file)
           (condition-case nil
               (with-temp-buffer
                 (insert-file-contents my/geometry-file)
                 (goto-char (point-min))
                 (read (current-buffer)))
             (error nil)))))
    (if (and (listp geometry)
             (integerp (plist-get geometry :width))
             (> (plist-get geometry :width) 0)
             (integerp (plist-get geometry :height))
             (> (plist-get geometry :height) 0))
        geometry
      my/geometry-default)))

(defun my/geometry-save ()
  "Save the selected graphical frame dimensions."
  (when (display-graphic-p)
    (let ((geometry
           (list :width (frame-width)
                 :height (frame-height))))
      (with-temp-file my/geometry-file
        (prin1 geometry (current-buffer))
        (insert "\n")))))

(add-hook 'kill-emacs-hook #'my/geometry-save)

(provide 'my-emacs-geometry)

;;; my-emacs-geometry.el ends here
