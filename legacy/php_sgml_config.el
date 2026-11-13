;; ================================ php mode ===================================
(require 'mmm-mode)
(require 'sgml-mode)
(setq mmm-global-mode 'maybe)
(mmm-add-mode-ext-class nil "\\.php3?\\'" 'html-php)
(mmm-add-classes
 '((html-php
    :submode php-mode
    :front "<\\?\\(php\\)?"
    :back "\\?>")))
(autoload 'php-mode "php-mode" "PHP editing mode" t)
(add-to-list 'auto-mode-alist '("\\.php3?\\'" . html-mode))
;; =============================================================================

;; =================================== my sgml mode ============================
(setq sgml-auto-activate-dtd t)
(setq-default sgml-set-face t)
;;
;; Faces.
;;
(make-face 'sgml-comment-face)
(make-face 'sgml-doctype-face)
(make-face 'sgml-end-tag-face)
(make-face 'sgml-entity-face)
(make-face 'sgml-ignored-face)
(make-face 'sgml-ms-end-face)
(make-face 'sgml-ms-start-face)
(make-face 'sgml-pi-face)
(make-face 'sgml-sgml-face)
(make-face 'sgml-short-ref-face)
(make-face 'sgml-start-tag-face)

(set-face-foreground 'sgml-comment-face "dark turquoise")
(set-face-foreground 'sgml-doctype-face "red")
(set-face-foreground 'sgml-end-tag-face "blue")
(set-face-foreground 'sgml-entity-face "magenta")
(set-face-foreground 'sgml-ignored-face "gray40")
(set-face-background 'sgml-ignored-face "gray60")
(set-face-foreground 'sgml-ms-end-face "green")
(set-face-foreground 'sgml-ms-start-face "yellow")
(set-face-foreground 'sgml-pi-face "lime green")
(set-face-foreground 'sgml-sgml-face "brown")
(set-face-foreground 'sgml-short-ref-face "deep sky blue")
(set-face-foreground 'sgml-start-tag-face "dark green")

(setq-default sgml-markup-faces
              '((comment . sgml-comment-face)
                (doctype . sgml-doctype-face)
                (end-tag . sgml-end-tag-face)
                (entity . sgml-entity-face)
                (ignored . sgml-ignored-face)
                (ms-end . sgml-ms-end-face)
                (ms-start . sgml-ms-start-face)
                (pi . sgml-pi-face)
                (sgml . sgml-sgml-face)
                (short-ref . sgml-short-ref-face)
                (start-tag . sgml-start-tag-face)))

;;; ============================================================================
