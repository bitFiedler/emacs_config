;;; my-markdown-preview.el --- Livedown and portable Nerd Font HTML -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)

(defvar markdown-command)
(defvar markdown-command-needs-filename)
(defvar markdown-xhtml-header-content)
(defvar markdown-xhtml-body-preamble)
(defvar xwidget-webkit-mode-map)
(declare-function xwidget-webkit-browse-url "xwidget" (url &optional new-session))

(defgroup my-markdown-preview nil
  "Livedown previews and Markdown HTML exports."
  :group 'markdown)
(defconst my/markdown--directory
  (file-name-directory (or load-file-name buffer-file-name)))
(defcustom my/markdown-livedown-program
  (or (executable-find "livedown")
      (car (file-expand-wildcards (expand-file-name "~/.nvm/versions/node/*/bin/livedown")))
      "livedown")
  "Livedown executable, also used to find its Markdown renderer."
  :type 'string)
(defcustom my/markdown-livedown-port 1337
  "Port for the single active Livedown preview."
  :type 'integer)
(defcustom my/markdown-livedown-open-browser t
  "Open a browser when starting Livedown."
  :type 'boolean)
(defcustom my/markdown-preview-browser 'auto
  "Browser for Livedown previews.
Auto uses xwidget WebKit in a graphical frame when compiled in, otherwise
the external browser.  External always uses Livedown's browser launcher."
  :type '(choice (const auto) (const external)))
(defcustom my/markdown-nerd-font-file
  (expand-file-name "assets/nerd-symbols.woff2" my/markdown--directory)
  "Symbols Nerd Font WOFF2 embedded in preview and exported HTML."
  :type 'file)

(defvar my/markdown--font-cache nil)
(defvar my/markdown--preview-process nil)
(defvar my/markdown--preview-buffer nil)
(defvar my/markdown--preview-file nil)
(defvar my/markdown--preview-timer nil)

(defun my/markdown--xwidget-available-p (&optional frame)
  "Whether FRAME can display an embedded WebKit preview."
  (and (display-graphic-p frame)
       (featurep 'xwidget-internal)
       (require 'xwidget nil t)
       (fboundp 'xwidget-webkit-browse-url)))

(defun my/markdown--open-internal-preview (process frame url)
  "Open URL only after PROCESS is ready and still owns this preview."
  (when (and (eq process my/markdown--preview-process)
             (process-live-p process) (frame-live-p frame))
    (with-selected-frame frame
      (condition-case err
          (xwidget-webkit-browse-url url t)
        (error
         (require 'browse-url)
         (message "Embedded Markdown browser failed (%s); opening externally"
                  (error-message-string err))
         (browse-url-default-browser url))))))

(defun my/markdown--livedown-filter (process chunk frame url internal)
  "Log CHUNK and launch the internal browser once Livedown is listening."
  (when (buffer-live-p (process-buffer process))
    (with-current-buffer (process-buffer process)
      (let ((inhibit-read-only t))
        (save-excursion (goto-char (point-max)) (insert chunk)))))
  (when (and internal (not (process-get process 'markdown-browser-scheduled)))
    (let ((output (concat (process-get process 'markdown-ready-output) chunk)))
      (process-put process 'markdown-ready-output (substring output (max 0 (- (length output) 2048))))
      (when (string-match-p "markdowning started on http://localhost:" output)
        (process-put process 'markdown-browser-scheduled t)
        ;; Do not switch the source buffer from inside a process filter.
        (run-at-time 0 nil #'my/markdown--open-internal-preview process frame url)))))

(defun my/markdown--programs ()
  "Return absolute Node and Livedown executable paths."
  (let* ((livedown (or (executable-find my/markdown-livedown-program)
                       (and (file-executable-p my/markdown-livedown-program)
                            my/markdown-livedown-program)))
         (sibling (and livedown (expand-file-name "node" (file-name-directory livedown))))
         (node (or (and sibling (file-executable-p sibling) sibling)
                   (executable-find "node"))))
    (unless (and livedown node) (user-error "Livedown and Node.js are required"))
    (list node livedown)))

(defun my/markdown--font-style ()
  "Return self-contained CSS so browsers need no installed Nerd Font."
  (unless (file-readable-p my/markdown-nerd-font-file)
    (user-error "Nerd Font file is missing: %s" my/markdown-nerd-font-file))
  (let ((key (list my/markdown-nerd-font-file
                   (file-attribute-modification-time (file-attributes my/markdown-nerd-font-file)))))
    (unless (equal key (car my/markdown--font-cache))
      (setq my/markdown--font-cache
            (cons key
                  (concat
                   "<style id=\"emacs-nerd-symbols\">\n"
                   "@font-face{font-family:'Emacs Nerd Symbols';src:url(data:font/woff2;base64,"
                   (with-temp-buffer
                     (set-buffer-multibyte nil)
                     (insert-file-contents-literally my/markdown-nerd-font-file)
                     (base64-encode-string (buffer-string) t))
                   ") format('woff2');font-weight:100 900;font-style:normal;"
                   "unicode-range:U+E000-F8FF,U+F0000-FFFFD,U+100000-10FFFD;}\n"
                   "body,.markdown-body{font-family:'Emacs Nerd Symbols',system-ui,sans-serif;}\n"
                   "pre,code,kbd,samp,.markdown-body pre,.markdown-body code{"
                   "font-family:'Emacs Nerd Symbols',ui-monospace,monospace;}\n</style>\n"))))
    (cdr my/markdown--font-cache)))

(defun my/markdown-render (begin end output)
  "Render BEGIN..END into OUTPUT with Livedown's Markdown parser."
  (pcase-let* ((`(,node ,livedown) (my/markdown--programs))
               (stderr (make-temp-file "markdown-render-error-")))
    (unwind-protect
        (let ((coding-system-for-read 'utf-8-unix)
              (coding-system-for-write 'utf-8-unix))
          (unless (eq 0 (call-process-region
                         begin end node nil (list output stderr) nil
                         (expand-file-name "my-markdown-render.cjs" my/markdown--directory)
                         livedown))
            (user-error "Markdown render failed: %s"
                        (with-temp-buffer (insert-file-contents stderr)
                                          (string-trim (buffer-string))))))
      (delete-file stderr))))

(defun my/markdown--appearance ()
  "Return portable fonts, dark/light styling and the browser theme chooser."
  (concat (my/markdown--font-style)
          "<style id=\"emacs-markdown-theme\">\n"
          (with-temp-buffer
            (insert-file-contents (expand-file-name "assets/markdown-theme.css" my/markdown--directory))
            (buffer-string))
          "\n</style>\n<script>\n"
          (with-temp-buffer
            (insert-file-contents (expand-file-name "assets/markdown-theme.js" my/markdown--directory))
            (buffer-string))
          "\n</script>\n"))

(defun my/markdown--standalone-with-font (original &rest args)
  "Include the embedded icon font in standalone Markdown HTML."
  (let ((markdown-xhtml-header-content
         (concat markdown-xhtml-header-content "\n" (my/markdown--appearance)))
        (markdown-xhtml-body-preamble
         (concat markdown-xhtml-body-preamble "\n" (my/markdown--theme-controls))))
    (apply original args)))

(defun my/markdown--theme-controls ()
  "Return native theme controls, usable without JavaScript."
  (with-temp-buffer
    (insert-file-contents (expand-file-name "assets/markdown-theme-controls.html" my/markdown--directory))
    (buffer-string)))

(defun my/markdown--write-preview ()
  "Atomically update the preview copy without modifying the source buffer.
Livedown must never see the empty/truncated file during a rewrite."
  (when (timerp my/markdown--preview-timer) (cancel-timer my/markdown--preview-timer))
  (setq my/markdown--preview-timer nil)
  (when (and (buffer-live-p my/markdown--preview-buffer) my/markdown--preview-file)
    (let ((content (with-current-buffer my/markdown--preview-buffer
                     (save-restriction (widen) (buffer-substring-no-properties (point-min) (point-max)))))
          (coding-system-for-write 'utf-8-unix)
          (staging (make-temp-file
                    (expand-file-name ".emacs-livedown-write-"
                                      (file-name-directory my/markdown--preview-file)))))
      (unwind-protect
          (progn
            (with-temp-file staging
              (insert (my/markdown--theme-controls) "\n" (my/markdown--appearance) "\n" content))
            (rename-file staging my/markdown--preview-file t))
        (when (file-exists-p staging) (delete-file staging))))))

(defun my/markdown--schedule-preview (&rest _)
  (when (timerp my/markdown--preview-timer) (cancel-timer my/markdown--preview-timer))
  (setq my/markdown--preview-timer (run-with-idle-timer 0.4 nil #'my/markdown--write-preview)))

(defun my/markdown-preview-stop ()
  "Stop the owned Livedown process and remove its disposable Markdown copy."
  (interactive)
  (when (timerp my/markdown--preview-timer) (cancel-timer my/markdown--preview-timer))
  (setq my/markdown--preview-timer nil)
  (let ((process my/markdown--preview-process))
    (setq my/markdown--preview-process nil)
    (when (process-live-p process) (delete-process process)))
  (when (buffer-live-p my/markdown--preview-buffer)
    (with-current-buffer my/markdown--preview-buffer
      (remove-hook 'after-change-functions #'my/markdown--schedule-preview t)
      (remove-hook 'after-save-hook #'my/markdown--write-preview t)
      (remove-hook 'kill-buffer-hook #'my/markdown-preview-stop t)))
  (when (and my/markdown--preview-file (file-exists-p my/markdown--preview-file))
    (delete-file my/markdown--preview-file))
  (setq my/markdown--preview-file nil my/markdown--preview-buffer nil))

(defun my/markdown-livedown-preview (&optional _output-buffer-name)
  "Preview the current Markdown buffer using Livedown, with embedded icons.
Updates follow edits after a short idle delay; the source is not saved.
Relative images resolve beside the source through a temporary sibling file."
  (interactive)
  (when (file-remote-p default-directory) (user-error "Livedown needs a local directory"))
  (pcase-let* ((`(,node ,livedown) (my/markdown--programs))
               (frame (selected-frame))
               (url (format "http://localhost:%d" my/markdown-livedown-port))
               (internal (and my/markdown-livedown-open-browser
                              (eq my/markdown-preview-browser 'auto)
                              (my/markdown--xwidget-available-p frame))))
    (my/markdown--font-style)
    (my/markdown-preview-stop)
    (setq my/markdown--preview-file
          (make-temp-file (expand-file-name ".emacs-livedown-" default-directory) nil ".md")
          my/markdown--preview-buffer (current-buffer))
    (condition-case err
        (progn
          (my/markdown--write-preview)
          (setq my/markdown--preview-process
                (let ((process-environment (copy-sequence process-environment)))
                  ;; Livedown's old native watcher loses replaced file inodes.
                  ;; Poll this one preview path so every atomic update is seen.
                  (setenv "CHOKIDAR_USEPOLLING" "1")
                  (setenv "CHOKIDAR_INTERVAL" "100")
                  (make-process
                 :name "markdown-livedown" :buffer "*Markdown Livedown*"
                 :command (append (list node livedown "start" my/markdown--preview-file
                                        "--port" (number-to-string my/markdown-livedown-port)
                                        "--verbose")
                                  (when (and my/markdown-livedown-open-browser (not internal)) '("--open")))
                 :noquery t
                 :filter (lambda (process chunk)
                           (my/markdown--livedown-filter process chunk frame url internal))
                 :sentinel (lambda (process event)
                             (when (and (eq process my/markdown--preview-process)
                                        (not (process-live-p process)))
                               (my/markdown-preview-stop)
                               (message "Livedown stopped: %s; see *Markdown Livedown*"
                                        (string-trim event)))))))
          (add-hook 'after-change-functions #'my/markdown--schedule-preview nil t)
          (add-hook 'after-save-hook #'my/markdown--write-preview nil t)
          (add-hook 'kill-buffer-hook #'my/markdown-preview-stop nil t)
          (message "Livedown preview: http://localhost:%d" my/markdown-livedown-port))
      (error (my/markdown-preview-stop) (signal (car err) (cdr err))))))

(with-eval-after-load 'markdown-mode
  (setq markdown-command #'my/markdown-render
        markdown-command-needs-filename nil)
  (advice-add 'markdown-preview :override #'my/markdown-livedown-preview)
  (advice-add 'markdown-standalone :around #'my/markdown--standalone-with-font))

(with-eval-after-load 'xwidget
  ;; Bind directly instead of depending on the global scrolling command
  ;; remaps.  GTK can report shifted space as either a character or symbol.
  (dolist (key (list (kbd "M-v") (kbd "S-SPC") [S-space] [prior]))
    (define-key xwidget-webkit-mode-map key #'xwidget-webkit-scroll-down))
  (dolist (key (list (kbd "C-v") [next]))
    (define-key xwidget-webkit-mode-map key #'xwidget-webkit-scroll-up)))

(add-hook 'kill-emacs-hook #'my/markdown-preview-stop)
(provide 'my-markdown-preview)
;;; my-markdown-preview.el ends here
