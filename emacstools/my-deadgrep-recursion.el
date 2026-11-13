;;; my-deadgrep-recursion.el --- A visible recursion control -*- lexical-binding: t; -*-

(require 'deadgrep)
(require 'button)

(defcustom my/deadgrep-friendly-error-summary t
  "Explain ripgrep exit code 2 while preserving matches and error details.
Ripgrep continues past unreadable paths.  Exit code 2 reports errors
encountered during the search; it does not discard accessible matches.
Set nil to retain Deadgrep's original abnormal-exit wording."
  :type 'boolean
  :group 'deadgrep)

(defun my/deadgrep--explain-search-errors (original process output)
  "Call ORIGINAL for PROCESS with clearer wording for error OUTPUT.
The process status and diagnostic lines are left intact."
  (funcall original process
           (if (and my/deadgrep-friendly-error-summary
                    (eq (process-status process) 'exit)
                    (= (process-exit-status process) 2)
                    (equal output "exited abnormally with code 2\n"))
               (concat "Search finished with errors (ripgrep exit 2). "
                       "Results may be incomplete; see errors above.\n")
             output)))

(defvar-local my/deadgrep-recursive-p t
  "Whether this Deadgrep search descends into subdirectories.
New results buffers default to recursive search.  The setting belongs to
one results buffer and survives reinitialization, like Deadgrep's other
search settings.")
(put 'my/deadgrep-recursive-p 'permanent-local t)

(defvar my/deadgrep--launch-context nil
  "Dynamically bound search buffer, recursion state and launched argv.
Only Deadgrep's process-start call binds this context.")
(defvar-local my/deadgrep--last-command nil
  "Actual command passed to the process launcher for this search.")

(defvar-local my/deadgrep--hidden-results nil
  "Stack of overlays for manually hidden results, file groups and errors.")

(defun my/deadgrep--clear-hidden-results (&rest _)
  "Remove this buffer's manually created hiding overlays."
  (mapc #'delete-overlay my/deadgrep--hidden-results)
  (setq my/deadgrep--hidden-results nil))

(defun my/deadgrep-hide-result ()
  "Hide the result, file group or diagnostic at point.
On a filename, hide its heading and currently displayed results.
On a result line, hide that line.  On an rg error or warning, hide
that diagnostic line.  Source files and search text remain unchanged.
Use `my/deadgrep-unhide-result' to restore the last hidden item."
  (interactive)
  (unless (derived-mode-p 'deadgrep-mode)
    (user-error "Use this command in a Deadgrep results buffer"))
  (beginning-of-line)
  (when (invisible-p (point))
    (user-error "This item is already hidden"))
  (let* ((start (point))
         (kind (cond
                ((get-text-property start 'deadgrep-line-number) 'result)
                ((get-text-property start 'deadgrep-filename) 'file)
                ((looking-at-p "\\(?:rg: \\|WARNING: \\|Search finished with errors\\|exited abnormally with code \\)")
                 'diagnostic)
                (t (user-error "Place point on a result, filename or error message"))))
         (end (save-excursion
                (forward-line 1)
                (when (eq kind 'file)
                  (while (and (< (point) (point-max))
                              (or (get-text-property (point) 'deadgrep-line-number)
                                  (get-text-property (point) 'deadgrep-separator)
                                  (looking-at-p "[ \t]*$")))
                    (forward-line 1)))
                (when (eq kind 'diagnostic)
                  (while (and (< (point) (point-max)) (looking-at-p "[ \t]*$"))
                    (forward-line 1)))
                (point)))
         (overlay (make-overlay start end)))
    (add-hook 'change-major-mode-hook #'my/deadgrep--clear-hidden-results nil t)
    (add-to-invisibility-spec 'my/deadgrep-dismissed)
    ;; Use a distinct value so file-folding code cannot delete our overlays.
    (overlay-put overlay 'invisible 'my/deadgrep-dismissed)
    (overlay-put overlay 'evaporate t)
    (push overlay my/deadgrep--hidden-results)
    (goto-char end))
  (while (and (< (point) (point-max)) (invisible-p (point)))
    (forward-line 1))
  (message "Item hidden; u restores the last, U restores all (%d hidden)"
           (length my/deadgrep--hidden-results)))

(defun my/deadgrep-unhide-result ()
  "Restore the most recently hidden result, file group or error."
  (interactive)
  (unless (derived-mode-p 'deadgrep-mode)
    (user-error "Use this command in a Deadgrep results buffer"))
  (while (and my/deadgrep--hidden-results
              (not (overlay-buffer (car my/deadgrep--hidden-results))))
    (pop my/deadgrep--hidden-results))
  (unless my/deadgrep--hidden-results
    (user-error "No manually hidden items to restore"))
  (let* ((overlay (pop my/deadgrep--hidden-results))
         (start (overlay-start overlay)))
    (delete-overlay overlay)
    (goto-char start))
  (message "Item restored (%d still hidden)" (length my/deadgrep--hidden-results)))

(defun my/deadgrep-unhide-all-results ()
  "Restore every manually hidden result, file group and error in this buffer.
File groups folded with TAB retain their separate folding state."
  (interactive)
  (unless (derived-mode-p 'deadgrep-mode)
    (user-error "Use this command in a Deadgrep results buffer"))
  (my/deadgrep--clear-hidden-results)
  (message "All manually hidden items restored"))

(defun my/deadgrep--skip-hidden-matches (original &rest arguments)
  "Call movement ORIGINAL with ARGUMENTS, skipping invisible matches."
  (let ((start (point)))
    (condition-case err
        (progn
          (apply original arguments)
          (while (invisible-p (point))
            (apply original arguments)))
      ((beginning-of-buffer end-of-buffer)
       (goto-char start)
       (signal (car err) (cdr err))))))

(defun my/deadgrep--without-depth (arguments)
  "Copy ARGUMENTS without ripgrep depth options owned by the recursion UI."
  (let ((rest arguments) result)
    (while rest
      (let ((argument (pop rest)))
        (cond
         ((member argument '("--max-depth" "--maxdepth" "-d"))
          (when (and rest (string-match-p "\\`[0-9]+\\'" (car rest)))
            (pop rest)))
         ((string-match-p "\\`\\(?:--max-?depth=\\|-d[0-9]+\\'\\)" argument))
         (t (push argument result)))))
    (nreverse result)))

(defun my/deadgrep--arguments-with-recursion (arguments)
  "Apply the recursion policy to Deadgrep's finished command ARGUMENTS.
Only edit options before --; preserve search text and paths verbatim.
Filtering the final list avoids relying on how the package reads extra
arguments, including an already-compiled or cached argument builder."
  (let ((rest arguments) options)
    (while (and rest (not (equal (car rest) "--")))
      (push (pop rest) options))
    (append (unless my/deadgrep-recursive-p '("--max-depth=1"))
            (my/deadgrep--without-depth (nreverse options))
            rest)))

(defun my/deadgrep--launch-arguments (arguments)
  "Enforce depth in process launch ARGUMENTS during a Deadgrep start.
The target buffer must match the explicitly scoped search buffer."
  (if (and my/deadgrep--launch-context
           (eq (get-buffer (nth 1 arguments))
               (car my/deadgrep--launch-context)))
      (let* ((my/deadgrep-recursive-p (nth 1 my/deadgrep--launch-context))
             (argv (cons (nth 2 arguments)
                         (my/deadgrep--arguments-with-recursion (nthcdr 3 arguments)))))
        (setcar (nthcdr 2 my/deadgrep--launch-context) argv)
        (append (list (car arguments) (nth 1 arguments)) argv))
    arguments))

(defun my/deadgrep--start-with-recursion (original &rest arguments)
  "Call ORIGINAL with ARGUMENTS and enforce recursion at process launch.
Capture the buffer's state before any argument builder changes context."
  (let ((my/deadgrep--launch-context
         (list (current-buffer) my/deadgrep-recursive-p nil)))
    (prog1 (apply original arguments)
      (when-let* ((argv (nth 2 my/deadgrep--launch-context)))
        (with-current-buffer (car my/deadgrep--launch-context)
          (setq my/deadgrep--last-command argv
                deadgrep--debug-command (combine-and-quote-strings argv)))))))

(defun my/deadgrep-diagnose ()
  "Show this search's directory, recursion setting and actual launch command."
  (interactive)
  (unless (derived-mode-p 'deadgrep-mode)
    (user-error "Use this command in a Deadgrep results buffer"))
  (message "Deadgrep directory=%s recursive=%s actual command=%s"
           default-directory my/deadgrep-recursive-p
           (if my/deadgrep--last-command
               (combine-and-quote-strings my/deadgrep--last-command)
             "not captured yet; press g after loading the extension")))

(defun my/deadgrep-set-recursive (recursive)
  "Set this search's RECURSIVE state and restart when it changed."
  (unless (derived-mode-p 'deadgrep-mode)
    (user-error "Use this command in a Deadgrep results buffer"))
  (unless (eq my/deadgrep-recursive-p (and recursive t))
    (setq my/deadgrep-recursive-p (and recursive t))
    (deadgrep-restart)))

(defun my/deadgrep-toggle-recursive ()
  "Toggle recursive searching in this Deadgrep buffer and rerun the search."
  (interactive)
  (my/deadgrep-set-recursive (not my/deadgrep-recursive-p)))

(define-button-type 'my/deadgrep-recursive
  'action (lambda (button)
            (my/deadgrep-set-recursive (button-get button 'recursive)))
  'help-echo "Change whether this search includes subdirectories")

(defun my/deadgrep--write-recursion (&rest _)
  "Add a clickable recursion row after Deadgrep's standard heading."
  (let ((inhibit-read-only t) (start (point)))
    (insert (propertize "Recursive: " 'face 'deadgrep-meta-face)
            (if my/deadgrep-recursive-p "on"
              (deadgrep--button "on" 'my/deadgrep-recursive 'recursive t))
            " "
            (if my/deadgrep-recursive-p
                (deadgrep--button "off" 'my/deadgrep-recursive 'recursive nil)
              "off")
            (propertize (if my/deadgrep-recursive-p
                            "  (includes subdirectories)"
                          "  (current directory only)")
                        'face 'deadgrep-meta-face)
            "\n\n")
    (add-text-properties start (point) '(read-only t front-sticky t))))

;; Remove the former :around advice as well when reloading this update.
(advice-remove 'deadgrep--arguments #'my/deadgrep--arguments-with-recursion)
(advice-add 'deadgrep--arguments :filter-return #'my/deadgrep--arguments-with-recursion)
(unless (advice-member-p #'my/deadgrep--start-with-recursion 'deadgrep--start)
  (advice-add 'deadgrep--start :around #'my/deadgrep--start-with-recursion))
(unless (advice-member-p #'my/deadgrep--launch-arguments 'start-file-process)
  (advice-add 'start-file-process :filter-args #'my/deadgrep--launch-arguments))
(unless (advice-member-p #'my/deadgrep--explain-search-errors 'deadgrep--process-sentinel)
  (advice-add 'deadgrep--process-sentinel :around #'my/deadgrep--explain-search-errors))
(unless (advice-member-p #'my/deadgrep--clear-hidden-results 'deadgrep--stop-and-reset)
  (advice-add 'deadgrep--stop-and-reset :before #'my/deadgrep--clear-hidden-results))
(unless (advice-member-p #'my/deadgrep--skip-hidden-matches 'deadgrep--move-match)
  (advice-add 'deadgrep--move-match :around #'my/deadgrep--skip-hidden-matches))
(unless (advice-member-p #'my/deadgrep--write-recursion 'deadgrep--write-heading)
  (advice-add 'deadgrep--write-heading :after #'my/deadgrep--write-recursion))
(define-key deadgrep-mode-map (kbd "R") #'my/deadgrep-toggle-recursive)
(define-key deadgrep-mode-map (kbd "z") #'my/deadgrep-hide-result)
(define-key deadgrep-mode-map (kbd "u") #'my/deadgrep-unhide-result)
(define-key deadgrep-mode-map (kbd "U") #'my/deadgrep-unhide-all-results)

(provide 'my-deadgrep-recursion)
;;; my-deadgrep-recursion.el ends here
