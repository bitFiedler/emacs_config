;;; my-buffer-navigation.el --- Helm-like next/previous buffers -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'window)

(defconst my/buffer-navigation-default-exclusions
  '("\\` " "\\`\\*helm" "\\`\\*Echo Area" "\\`\\*Minibuf")
  "Helm's standard hidden-buffer patterns, used before Helm is loaded.")

(defun my/buffer-navigation-skip-p (_window buffer _bury-or-kill)
  "Skip BUFFER when Helm Mini would hide its name.
Use Helm's live boring-buffer and whitelist settings when available.
Used by both next/previous-buffer and their window-switching helpers."
  (or (not (buffer-live-p buffer))
      (minibufferp buffer)
      (let ((name (buffer-name buffer))
            (excluded (if (boundp 'helm-boring-buffer-regexp-list)
                          (symbol-value 'helm-boring-buffer-regexp-list)
                        my/buffer-navigation-default-exclusions))
            (allowed (when (boundp 'helm-white-buffer-regexp-list)
                       (symbol-value 'helm-white-buffer-regexp-list))))
        (and (cl-some (lambda (regexp) (string-match-p regexp name)) excluded)
             (not (cl-some (lambda (regexp) (string-match-p regexp name)) allowed))))))

;; Built-in next-buffer/previous-buffer and their existing key bindings use
;; this predicate.  Unlike a regexp-only setting it does not fall back to
;; hidden buffers just because no eligible alternative is available.
(setq switch-to-prev-buffer-skip #'my/buffer-navigation-skip-p)

(provide 'my-buffer-navigation)
;;; my-buffer-navigation.el ends here
