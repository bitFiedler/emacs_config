;;; my-pair-editing.el --- Shifted pair deletion keys -*- lexical-binding: t; -*-

(require 'lisp-mode)

(require 'cl-lib)

(defun my/pair-editing--pairs ()
  "Normalize the configured `insert-pair-alist' to delimiter pairs."
  (mapcar (lambda (entry) (if (= (length entry) 3) (cdr entry) entry))
          insert-pair-alist))

(defun my/pair-editing--escaped-p (position)
  "Whether the character at POSITION follows an odd number of backslashes."
  (let ((slashes 0))
    (save-excursion
      (goto-char position)
      (while (eq (char-before) ?\\)
        (cl-incf slashes)
        (backward-char)))
    (= (% slashes 2) 1)))

(defun my/pair-editing--opening (closing pairs)
  "Find a configured matching opener for CLOSING using PAIRS.
Use the syntax scanner directly rather than mode-specific expression
movement, which can include the dollar sign in shell ${...} expansions.
Temporarily give the requested delimiters bracket syntax so they also
work literally inside strings or in modes where braces are punctuation."
  (unless (my/pair-editing--escaped-p closing)
    (cl-loop
     for (open close) in pairs
     when (eq close (char-after closing))
     thereis
     (let ((table (copy-syntax-table (syntax-table))))
       (if (eq open close)
           (modify-syntax-entry open "\"" table)
         (modify-syntax-entry open (format "(%c" close) table)
         (modify-syntax-entry close (format ")%c" open) table))
       (with-syntax-table table
         (let ((parse-sexp-lookup-properties nil))
           (condition-case nil
               (let ((position (scan-sexps (1+ closing) -1)))
                 (when (and position (< position closing)
                            (eq (char-after position) open)
                            (not (my/pair-editing--escaped-p position)))
                   position))
             (scan-error nil))))))))

(defun my/delete-pair-backward ()
  "Remove a pair at or just before point, preserving the enclosed text.
Point may be on the closing bracket or immediately after it.  A closing
bracket under point takes priority; immediately before a quote after a
closing bracket, prefer the bracket behind point.  Shell ${...} pairs
are supported inside strings, preserving the dollar sign and quotes."
  (interactive)
  (let* ((pairs (my/pair-editing--pairs))
         (closers (mapcar #'cadr pairs))
         (here (char-after))
         (before (char-before))
         ;; After ${...}, point is also on an enclosing closing quote.
         ;; Keep that usual backward-deletion position targeting the braces.
         (candidates
          (cond ((and (memq here closers) (not (memq here '(?\" ?\'))))
                 (list (point)))
                ((and (memq here '(?\" ?\')) (eq here before)
                      (nth 3 (syntax-ppss)))
                 (list (point) (1- (point))))
                (t (append (when (memq before closers) (list (1- (point))))
                           (when (memq here closers) (list (point)))))))
         (match (cl-loop for closing in candidates
                         for opening = (my/pair-editing--opening closing pairs)
                         when opening return (cons opening closing))))
    (unless match
      (user-error "No matching delimiter pair at or immediately before point"))
    (atomic-change-group
      (delete-region (cdr match) (1+ (cdr match)))
      (delete-region (car match) (1+ (car match))))))

;; Never use (kbd "C-D"): it normalizes to C-d and would replace ordinary
;; character deletion.  An explicit Shift modifier keeps the keys separate.
(global-set-key (kbd "C-S-d") #'delete-pair)
;; GUI/terminal event encodings can represent Alt+Shift+D in either form.
(global-set-key (kbd "M-D") #'my/delete-pair-backward)
(global-set-key (kbd "M-S-d") #'my/delete-pair-backward)

(provide 'my-pair-editing)
;;; my-pair-editing.el ends here
