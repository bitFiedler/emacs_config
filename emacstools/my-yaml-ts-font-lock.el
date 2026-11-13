;;; my-yaml-ts-font-lock.el --- Restrained YAML string colors -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'yaml-ts-mode)

(defun my-yaml-ts--fontify-embedded-quotes (node override start end &rest _)
  "Highlight paired quotes within NODE, bounded to that YAML scalar.
This is lightweight quote highlighting, not a shell language parser.
OVERRIDE, START and END follow Tree-sitter font-lock callback conventions."
  (save-excursion
    (let ((limit (treesit-node-end node))
          (begin (treesit-node-start node)))
      (goto-char begin)
      (while (re-search-forward "[\"']" limit t)
        (let* ((quote (char-before))
               (opening (1- (point)))
               (previous (and (> opening begin) (char-before opening))))
          ;; Apostrophes in words and escaped quote characters aren't openers.
          (unless (or (and (eq quote ?') previous
                           (memq (char-syntax previous) '(?w ?_)))
                      (let ((pos opening) (slashes 0))
                        (while (and (> pos begin) (eq (char-before pos) ?\\))
                          (setq pos (1- pos) slashes (1+ slashes)))
                        (= (% slashes 2) 1)))
            (let ((closing
                   (if (eq quote ?')
                       (search-forward "'" limit t)
                     (catch 'closed
                       (while (re-search-forward "[\\\"]" limit t)
                         (if (eq (char-before) ?\\)
                             (when (< (point) limit) (forward-char))
                           (throw 'closed (point))))
                       nil))))
              (when closing
                (treesit-fontify-with-override
                 opening closing 'font-lock-string-face override start end)))))))))

(defun my/yaml-ts-font-lock-setup ()
  "Keep plain YAML scalars and script bodies neutral, but color quotes."
  (let ((strings
         (treesit-font-lock-rules
          :language 'yaml :feature 'string :override t
          '([(double_quote_scalar) (single_quote_scalar)] @font-lock-string-face)
          :language 'yaml :feature 'string
          '([(block_scalar) (string_scalar)] @my-yaml-ts--fontify-embedded-quotes))))
    ;; Preserve rule order so escapes and mapping-key faces override strings.
    (setq-local treesit-font-lock-settings
                (cl-loop for rule in yaml-ts-mode--font-lock-settings
                         append (if (eq (treesit-font-lock-setting-feature rule) 'string)
                                    strings (list rule)))))
  (treesit-font-lock-recompute-features)
  (when font-lock-mode (font-lock-flush)))

(add-hook 'yaml-ts-mode-hook #'my/yaml-ts-font-lock-setup)

;; Apply the fix to YAML Tree-sitter buffers already open when reloading.
(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (when (eq major-mode 'yaml-ts-mode)
      (my/yaml-ts-font-lock-setup))))

(provide 'my-yaml-ts-font-lock)
;;; my-yaml-ts-font-lock.el ends here
