;; ######### setup helm
(setq
 helmg-gtags-ignore-case t
 ;; helm-gtags-auto-update t
 helm-gtags-use-input-at-cursor t
 helm-gtags-pulse-at-cursor t
 helm-gtags-suggested-key-mapping t 
 helm-gtags-direct-helm-completing t
 )

;; reset to standard emacs key bindings, because of helm-gtags
;; (define-key c++mode-map (kbd "C-t") 'transpose-chars)
;; (define-key c-mode-map (kbd "C-t") 'transpose-chars)
;; (define-key c++mode-map (kbd "M-t") 'transpose-words)
;; (define-key c-mode-map (kbd "M-t") 'transpose-words)
;; (define-key c++mode-map (kbd "C-M-t") 'transpose-sexps)
;; (define-key c-mode-map (kbd "C-M-t") 'transpose-sexps)
;; (define-key c++mode-map (kbd "C-x M-t") 'transpose-lines)
;; (define-key c-mode-map (kbd "C-x M-t") 'transpose-lines)

(require 'helm)
(require 'helm-xref)
;;(require 'helm-config)
;;(require 'helm-org)
(require 'helm-rg)

;; The default "C-x c" is quite close to "C-x C-c", which quits Emacs.
;; Changed to "C-c h". Note: We must set "C-c h" globally, because we
;; cannot change `helm-command-prefix-key' once `helm-config' is loaded.
(global-set-key (kbd "C-c h") 'helm-command-prefix)
(global-unset-key (kbd "C-x c"))

(global-set-key (kbd "M-x") #'helm-M-x)
(global-set-key (kbd "C-x r b") #'helm-filtered-bookmarks)
(global-set-key (kbd "C-x C-f") #'helm-find-files)
;;(global-set-key (kbd "C-x b") 'helm-buffers-list)
(global-set-key (kbd "C-x b") 'helm-mini)
(global-set-key (kbd "M-y") 'helm-show-kill-ring)

(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebind tab to run persistent action
(define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB work in terminal
(define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z

(when (executable-find "curl")
  (setq helm-net-prefer-curl t))


(setq helm-M-x-fuzzy-match                  t
      helm-bookmark-show-location           t
      helm-buffers-fuzzy-matching           t
      helm-completion-in-region-fuzzy-match t
      helm-file-cache-fuzzy-match           t
      helm-imenu-fuzzy-match                t
      helm-mode-fuzzy-match                 t
      helm-locate-fuzzy-match               t 
      helm-quick-update                     t
      helm-recentf-fuzzy-match              t
      helm-gtags-fuzzy-match                t
      helm-semantic-fuzzy-match             t)



(setq helm-split-window-inside-p            t ; open helm buffer inside current window, not occupy whole other window
      helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
      helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
      helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
      helm-ff-file-name-history-use-recentf t
      helm-echo-input-in-header-line t
      helm-gtags-direct-helm-completing t
      helm-buffer-max-length 40
      )

(defun spacemacs//helm-hide-minibuffer-maybe ()
  "Hide minibuffer in Helm session if we use the header line as input field."
  (when (with-helm-buffer helm-echo-input-in-header-line)
    (let ((ov (make-overlay (point-min) (point-max) nil nil t)))
      (overlay-put ov 'window (selected-window))
      (overlay-put ov 'face
                   (let ((bg-color (face-background 'default nil)))
                     `(:background ,bg-color :foreground ,bg-color)))
      (setq-local cursor-type nil))))


(add-hook 'helm-minibuffer-set-up-hook
          'spacemacs//helm-hide-minibuffer-maybe)

(setq helm-autoresize-max-height 0)
(setq helm-autoresize-min-height 40)
(helm-autoresize-mode 1)

;;better gtags browsing if more are possible
(require 'helm-gtags)
;;Enable helm-gtags-mode
(add-hook 'dired-mode-hook 'helm-gtags-mode)
(add-hook 'eshell-mode-hook 'helm-gtags-mode)
(add-hook 'c-ts-mode-hook 'helm-gtags-mode)
(add-hook 'c++-ts-mode-hook 'helm-gtags-mode)
(add-hook 'c-mode-hook 'helm-gtags-mode)
(add-hook 'c++-mode-hook 'helm-gtags-mode)
(add-hook 'asm-mode-hook 'helm-gtags-mode)

;;(define-key helm-gtags-mode-map (kbd "C-c g a") 'helm-gtags-tags-in-this-function)
;;(define-key helm-gtags-mode-map (kbd "C-j") 'helm-gtags-select)
(define-key helm-gtags-mode-map (kbd "C-.") 'helm-gtags-dwim)
(define-key helm-gtags-mode-map (kbd "C-,") 'helm-gtags-pop-stack)
;; remap xref goto definition, because helm-gtags overwrite it
(define-key helm-gtags-mode-map (kbd "M-.") 'xref-find-definitions)
;;(define-key helm-gtags-mode-map (kbd "C-<tab>") 'company-complete)
;;(define-key helm-gtags-mode-map (kbd "C-C <") 'helm-gtags-previous-history)
;;(define-key helm-gtags-mode-map (kbd "C-C >") 'helm-gtags-next-history)
(define-key helm-gtags-mode-map (kbd "s-<backspace>") 'helm-all-mark-rings)
(define-key helm-gtags-mode-map (kbd "C-t") 'transpose-chars)



;; (require 'ac-helm) ;; Not necessary if using ELPA package
;; (global-set-key (kbd "C-:") 'ac-complete-with-helm)
;; (define-key ac-complete-mode-map (kbd "C-:") 'ac-complete-with-helm)

(helm-mode 1)

;; check faces with M-x list-faces-display
;; show color options M-x list-colors-display
(set-face-attribute 'helm-ff-directory nil 
                    :background "black"
                    :foreground "cyan")

;; ########## helm end #######
