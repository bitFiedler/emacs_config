;; ######### mode line -> DOOM
;; for doom-modeline
;; - install all-the-icons from package manager
;; - run M-x all-the-icons-install-fonts.
;; - run M-x nerd-icons-install-fonts
(require 'doom-modeline)
;; enable doom mode line
(doom-modeline-mode 1)
(size-indication-mode 1)
(setq doom-modeline-buffer-file-name-style 'relative-to-project)
;; display the indentation information.
(setq doom-modeline-indent-info t)

;; How tall the mode-line should be. It's only respected in GUI.
;; If the actual char height is larger, it respects the actual height.
;;(setq doom-modeline-height 50)
(setq doom-modeline-height 18)

;; How wide the mode-line bar should be. It's only respected in GUI.
(setq doom-modeline-bar-width 4)

;; Whether to use hud instead of default bar. It's only respected in GUI.
(setq doom-modeline-hud nil)

(setq doom-modeline-window-width-limit nil)
(setq doom-modeline-vcs-max-length 60)
(setq all-the-icons-scale-factor 1.0)

(with-eval-after-load 'doom-modeline
  (doom-modeline-def-modeline 'main
    '(bar matches buffer-info remote-host buffer-position parrot selection-info)
    '(misc-info minor-modes checker input-method buffer-encoding major-mode process vcs "  ")))

;; limit project detection 
;; built-in `project'
(setq doom-modeline-project-detection 'project)
;; or `find-in-project'
(setq doom-modeline-project-detection 'ffip)

;; ######### mode line end
